from django.utils import timezone
from django.db.models import Count, Q
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Lead, Visit, FollowUp, PartnerOnboarding, MarketingTarget, MarketingDailyReport
from .serializers import (
    LeadSerializer,
    VisitSerializer,
    FollowUpSerializer,
    PartnerOnboardingSerializer,
    MarketingTargetSerializer,
    MarketingDailyReportSerializer,
)


def _is_manager_or_admin(user):
    if not user or not user.is_authenticated:
        return False
    if user.is_superuser:
        return True
    role = getattr(user, 'role', None)
    if role:
        role_code = getattr(role, 'code', str(role)).upper()
        if role_code in ['ADMIN', 'SUPER_ADMIN', 'MARKETING_MANAGER', 'DIRECTOR']:
            return True
    if hasattr(user, 'employee_profile') and user.employee_profile and user.employee_profile.position:
        if 'manager' in user.employee_profile.position.title.lower():
            return True
    return False


class LeadViewSet(viewsets.ModelViewSet):
    serializer_class = LeadSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = Lead.objects.all().select_related('assigned_to', 'created_by')
        
        # RBAC Filtering: If normal marketing exec, show assigned + created. If manager/admin, show all
        if not _is_manager_or_admin(user):
            qs = qs.filter(Q(assigned_to=user) | Q(created_by=user))

        # Query Filters
        status_param = self.request.query_params.get('status')
        type_param = self.request.query_params.get('type')
        priority_param = self.request.query_params.get('priority')
        search_param = self.request.query_params.get('search')

        if status_param:
            qs = qs.filter(status=status_param)
        if type_param:
            qs = qs.filter(lead_type=type_param)
        if priority_param:
            qs = qs.filter(priority=priority_param)
        if search_param:
            qs = qs.filter(
                Q(business_name__icontains=search_param) |
                Q(contact_person__icontains=search_param) |
                Q(phone__icontains=search_param) |
                Q(city__icontains=search_param) |
                Q(area__icontains=search_param)
            )

        return qs

    def perform_create(self, serializer):
        user = self.request.user
        assigned = serializer.validated_data.get('assigned_to') or user
        lead = serializer.save(created_by=user, assigned_to=assigned)
        
        # Append initial activity
        timeline = lead.activity_timeline or []
        timeline.append({
            'type': 'lead_created',
            'timestamp': timezone.now().isoformat(),
            'by': user.get_full_name() or user.username,
            'note': f'Lead created with status {lead.get_status_display()}',
        })
        lead.activity_timeline = timeline
        lead.save(update_fields=['activity_timeline'])

    @action(detail=False, methods=['get'])
    def pipeline(self, request):
        qs = self.get_queryset()
        pipeline_data = {}
        for status_key, status_label in Lead.LeadStatus.choices:
            leads_in_stage = qs.filter(status=status_key)
            pipeline_data[status_key] = {
                'label': status_label,
                'count': leads_in_stage.count(),
                'leads': LeadSerializer(leads_in_stage[:25], many=True).data,
            }
        return Response(pipeline_data)

    @action(detail=True, methods=['post'], url_path='add-activity')
    def add_activity(self, request, pk=None):
        lead = self.get_object()
        activity_type = request.data.get('type', 'note')
        note = request.data.get('note', '')
        
        timeline = lead.activity_timeline or []
        timeline.insert(0, {
            'type': activity_type,
            'timestamp': timezone.now().isoformat(),
            'by': request.user.get_full_name() or request.user.username,
            'note': note,
        })
        lead.activity_timeline = timeline
        lead.save(update_fields=['activity_timeline', 'updated_at'])
        return Response({'detail': 'Activity logged successfully', 'activity_timeline': timeline})

    @action(detail=True, methods=['post'], url_path='quick-status')
    def quick_status(self, request, pk=None):
        lead = self.get_object()
        new_status = request.data.get('status')
        if new_status not in dict(Lead.LeadStatus.choices):
            return Response({'error': 'Invalid status'}, status=status.HTTP_400_BAD_REQUEST)
        
        old_status = lead.status
        lead.status = new_status
        
        timeline = lead.activity_timeline or []
        timeline.insert(0, {
            'type': 'status_change',
            'timestamp': timezone.now().isoformat(),
            'by': request.user.get_full_name() or request.user.username,
            'note': f'Status transitioned from {old_status.upper()} to {new_status.upper()}',
        })
        lead.activity_timeline = timeline
        lead.save(update_fields=['status', 'activity_timeline', 'updated_at'])
        return Response({'detail': 'Status updated successfully', 'status': lead.status})


class VisitViewSet(viewsets.ModelViewSet):
    serializer_class = VisitSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = Visit.objects.all().select_related('lead', 'assigned_employee')
        
        if not _is_manager_or_admin(user):
            qs = qs.filter(assigned_employee=user)

        status_param = self.request.query_params.get('status')
        date_param = self.request.query_params.get('date') # YYYY-MM-DD
        
        if status_param:
            qs = qs.filter(status=status_param)
        if date_param:
            qs = qs.filter(scheduled_start__date=date_param)

        return qs

    def perform_create(self, serializer):
        user = self.request.user
        assigned = serializer.validated_data.get('assigned_employee') or user
        serializer.save(assigned_employee=assigned)

    @action(detail=True, methods=['post'], url_path='start-visit')
    def start_visit(self, request, pk=None):
        visit = self.get_object()
        lat = request.data.get('latitude')
        lng = request.data.get('longitude')

        visit.status = Visit.VisitStatus.IN_PROGRESS
        visit.check_in_time = timezone.now()
        if lat is not None and lng is not None:
            visit.actual_checkin_lat = lat
            visit.actual_checkin_lng = lng
            visit.is_location_verified = True
        
        visit.save(update_fields=['status', 'check_in_time', 'actual_checkin_lat', 'actual_checkin_lng', 'is_location_verified', 'updated_at'])
        
        # Log to lead activity if attached
        if visit.lead:
            timeline = visit.lead.activity_timeline or []
            timeline.insert(0, {
                'type': 'visit_started',
                'timestamp': timezone.now().isoformat(),
                'by': request.user.get_full_name() or request.user.username,
                'note': f'In-person visit started at {visit.location_name}',
            })
            visit.lead.activity_timeline = timeline
            visit.lead.status = Lead.LeadStatus.VISITED
            visit.lead.save(update_fields=['activity_timeline', 'status', 'updated_at'])

        return Response(VisitSerializer(visit).data)

    @action(detail=True, methods=['post'], url_path='complete-visit')
    def complete_visit(self, request, pk=None):
        visit = self.get_object()
        checklist = request.data.get('checklist')
        photos = request.data.get('photos')
        partner_interest = request.data.get('partner_interest', 'medium')
        expected_decision_date = request.data.get('expected_decision_date')
        discussion_notes = request.data.get('discussion_notes', '')
        next_action = request.data.get('next_action', '')
        next_follow_up_date = request.data.get('next_follow_up_date')

        visit.status = Visit.VisitStatus.COMPLETED
        visit.check_out_time = timezone.now()
        visit.partner_interest = partner_interest
        visit.discussion_notes = discussion_notes
        visit.next_action = next_action
        if checklist is not None:
            visit.checklist = checklist
        if photos is not None:
            visit.photos = photos
        if expected_decision_date:
            visit.expected_decision_date = expected_decision_date
        if next_follow_up_date:
            visit.next_follow_up_date = next_follow_up_date
            # Automatically create a FollowUp if lead exists
            if visit.lead:
                FollowUp.objects.create(
                    lead=visit.lead,
                    employee=request.user,
                    type=FollowUp.FollowUpType.CALL,
                    scheduled_at=next_follow_up_date,
                    notes=f"Auto follow-up created after visit at {visit.partner_name}. Next Action: {next_action}"
                )

        visit.save()

        # Update Lead
        if visit.lead:
            visit.lead.interest_level = partner_interest
            if next_follow_up_date:
                visit.lead.next_follow_up_at = next_follow_up_date
            timeline = visit.lead.activity_timeline or []
            timeline.insert(0, {
                'type': 'visit_completed',
                'timestamp': timezone.now().isoformat(),
                'by': request.user.get_full_name() or request.user.username,
                'note': f'Visit completed. Interest: {partner_interest.upper()}. Next: {next_action}',
            })
            visit.lead.activity_timeline = timeline
            visit.lead.save()

        return Response(VisitSerializer(visit).data)

    @action(detail=False, methods=['get'], url_path='today-route')
    def today_route(self, request):
        today = timezone.localdate()
        visits = self.get_queryset().filter(scheduled_start__date=today).order_by('scheduled_start')
        return Response(VisitSerializer(visits, many=True).data)


class FollowUpViewSet(viewsets.ModelViewSet):
    serializer_class = FollowUpSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = FollowUp.objects.all().select_related('lead', 'employee')
        
        if not _is_manager_or_admin(user):
            qs = qs.filter(employee=user)

        status_param = self.request.query_params.get('status')
        if status_param:
            qs = qs.filter(status=status_param)
        return qs

    def perform_create(self, serializer):
        user = self.request.user
        employee = serializer.validated_data.get('employee') or user
        followup = serializer.save(employee=employee)
        
        # Update lead's next follow-up pointer
        if followup.lead:
            followup.lead.next_follow_up_at = followup.scheduled_at
            followup.lead.save(update_fields=['next_follow_up_at', 'updated_at'])

    @action(detail=True, methods=['post'], url_path='mark-complete')
    def mark_complete(self, request, pk=None):
        followup = self.get_object()
        outcome = request.data.get('outcome', 'Completed successfully')
        notes = request.data.get('notes', '')

        followup.status = FollowUp.FollowUpStatus.COMPLETED
        followup.completed_at = timezone.now()
        followup.outcome = outcome
        if notes:
            followup.notes = f"{followup.notes or ''}\n{notes}".strip()
        followup.save()

        # Log to lead timeline
        if followup.lead:
            timeline = followup.lead.activity_timeline or []
            timeline.insert(0, {
                'type': f'followup_{followup.type}',
                'timestamp': timezone.now().isoformat(),
                'by': request.user.get_full_name() or request.user.username,
                'note': f'Completed {followup.get_type_display()}: {outcome}',
            })
            followup.lead.activity_timeline = timeline
            followup.lead.save(update_fields=['activity_timeline', 'updated_at'])

        return Response(FollowUpSerializer(followup).data)


class PartnerOnboardingViewSet(viewsets.ModelViewSet):
    serializer_class = PartnerOnboardingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = PartnerOnboarding.objects.all().select_related('lead', 'assigned_executive', 'manager_approved_by', 'admin_approved_by')
        return qs

    def perform_create(self, serializer):
        user = self.request.user
        assigned = serializer.validated_data.get('assigned_executive') or user
        serializer.save(assigned_executive=assigned)

    @action(detail=True, methods=['post'], url_path='submit-step')
    def submit_step(self, request, pk=None):
        onboarding = self.get_object()
        step = request.data.get('step') # 'info', 'documents', 'kyc', 'photos', 'amenities', 'packages'
        step_data = request.data.get('data', {})

        if step == 'info':
            onboarding.info_data = step_data
            onboarding.workflow_step = PartnerOnboarding.WorkflowStep.DOCUMENTS
            onboarding.progress_percentage = 25
        elif step == 'documents':
            onboarding.documents_data = step_data
            onboarding.workflow_step = PartnerOnboarding.WorkflowStep.KYC
            onboarding.progress_percentage = 40
        elif step == 'kyc':
            onboarding.kyc_verified = step_data.get('verified', True)
            onboarding.workflow_step = PartnerOnboarding.WorkflowStep.PHOTOS
            onboarding.progress_percentage = 55
        elif step == 'photos':
            onboarding.photos_data = step_data.get('photos', [])
            onboarding.workflow_step = PartnerOnboarding.WorkflowStep.AMENITIES
            onboarding.progress_percentage = 70
        elif step == 'amenities':
            onboarding.amenities_data = step_data.get('amenities', [])
            onboarding.workflow_step = PartnerOnboarding.WorkflowStep.PACKAGES
            onboarding.progress_percentage = 85
        elif step == 'packages':
            onboarding.packages_data = step_data.get('packages', [])
            onboarding.workflow_step = PartnerOnboarding.WorkflowStep.MANAGER_REVIEW
            onboarding.status = PartnerOnboarding.OnboardingStatus.UNDER_REVIEW
            onboarding.progress_percentage = 95

        onboarding.save()
        return Response(PartnerOnboardingSerializer(onboarding).data)

    @action(detail=True, methods=['post'], url_path='approve')
    def approve(self, request, pk=None):
        user = self.request.user
        onboarding = self.get_object()
        notes = request.data.get('notes', 'Approved for live listing')

        if getattr(user, 'is_admin_role', False) or user.is_superuser:
            onboarding.admin_approved_by = user
            onboarding.status = PartnerOnboarding.OnboardingStatus.ACTIVE
            onboarding.workflow_step = PartnerOnboarding.WorkflowStep.ACTIVE
            onboarding.progress_percentage = 100
        else:
            onboarding.manager_approved_by = user
            onboarding.workflow_step = PartnerOnboarding.WorkflowStep.ADMIN_APPROVAL
            onboarding.status = PartnerOnboarding.OnboardingStatus.APPROVED
            onboarding.progress_percentage = 98

        onboarding.approval_notes = notes
        onboarding.save()
        return Response(PartnerOnboardingSerializer(onboarding).data)


class MarketingTelemetryView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        today = timezone.localdate()
        is_manager = _is_manager_or_admin(user)

        # Personal / Assigned Filter or All
        exec_filter = Q(assigned_employee=user) if not is_manager else Q()
        lead_filter = Q(assigned_to=user) if not is_manager else Q()
        follow_filter = Q(employee=user) if not is_manager else Q()

        # Today's Metrics
        today_visits = Visit.objects.filter(exec_filter, scheduled_start__date=today)
        today_visits_count = today_visits.count()
        today_visits_completed = today_visits.filter(status=Visit.VisitStatus.COMPLETED).count()
        today_visits_active = today_visits.filter(status=Visit.VisitStatus.IN_PROGRESS).count()

        today_followups = FollowUp.objects.filter(follow_filter, scheduled_at__date=today)
        today_followups_count = today_followups.count()
        today_followups_completed = today_followups.filter(status=FollowUp.FollowUpStatus.COMPLETED).count()

        new_leads_today = Lead.objects.filter(lead_filter, created_at__date=today).count()
        active_onboardings = PartnerOnboarding.objects.filter(
            Q(assigned_executive=user) if not is_manager else Q(),
            status__in=[PartnerOnboarding.OnboardingStatus.DRAFT, PartnerOnboarding.OnboardingStatus.UNDER_REVIEW]
        ).count()

        # Funnel Metrics
        all_leads = Lead.objects.all()
        funnel_counts = {
            'total_leads': all_leads.count(),
            'contacted': all_leads.filter(status__in=['contacted', 'interested', 'visit_scheduled', 'visited', 'negotiation', 'onboarding', 'active']).count(),
            'interested': all_leads.filter(status__in=['interested', 'visit_scheduled', 'visited', 'negotiation', 'onboarding', 'active']).count(),
            'visited': all_leads.filter(status__in=['visited', 'negotiation', 'onboarding', 'active']).count(),
            'onboarding': all_leads.filter(status__in=['onboarding', 'active']).count(),
            'active_won': all_leads.filter(status='active').count(),
        }

        # Conversion Percentages
        funnel_conversion = {
            'lead_to_contact': round((funnel_counts['contacted'] / max(funnel_counts['total_leads'], 1)) * 100, 1),
            'contact_to_interest': round((funnel_counts['interested'] / max(funnel_counts['contacted'], 1)) * 100, 1),
            'visit_to_onboard': round((funnel_counts['onboarding'] / max(funnel_counts['visited'], 1)) * 100, 1),
            'onboard_to_active': round((funnel_counts['active_won'] / max(funnel_counts['onboarding'], 1)) * 100, 1),
        }

        # Active Field Team (For Managers)
        active_field_team = []
        if is_manager:
            active_visits = Visit.objects.filter(status=Visit.VisitStatus.IN_PROGRESS).select_related('assigned_employee', 'lead')
            for v in active_visits:
                active_field_team.append({
                    'employee_id': str(v.assigned_employee.id),
                    'employee_name': v.assigned_employee.get_full_name() or v.assigned_employee.username,
                    'status': 'active_visit',
                    'location_name': v.location_name,
                    'partner_name': v.partner_name,
                    'check_in_time': v.check_in_time.isoformat() if v.check_in_time else None,
                })

        # Today's Itinerary (Scheduled Plan)
        itinerary = []
        for v in today_visits.order_by('scheduled_start')[:8]:
            itinerary.append({
                'id': str(v.id),
                'type': 'visit',
                'time': v.scheduled_start.strftime('%I:%M %p'),
                'title': f"📍 {v.partner_name}",
                'subtitle': v.get_purpose_display(),
                'status': v.status,
            })
        for f in today_followups.order_by('scheduled_at')[:8]:
            itinerary.append({
                'id': str(f.id),
                'type': 'followup',
                'time': f.scheduled_at.strftime('%I:%M %p'),
                'title': f"📞 {f.lead.business_name}",
                'subtitle': f"{f.get_type_display()} - {f.notes or 'Routine follow-up'}",
                'status': f.status,
            })

        itinerary.sort(key=lambda x: x['time'])

        return Response({
            'today': {
                'visits_total': today_visits_count,
                'visits_completed': today_visits_completed,
                'visits_active': today_visits_active,
                'followups_total': today_followups_count,
                'followups_completed': today_followups_completed,
                'new_leads': new_leads_today,
                'active_onboardings': active_onboardings,
            },
            'funnel': funnel_counts,
            'conversion': funnel_conversion,
            'itinerary': itinerary,
            'active_field_team': active_field_team,
            'is_manager': is_manager,
        })


class MarketingDailyReportViewSet(viewsets.ModelViewSet):
    serializer_class = MarketingDailyReportSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = MarketingDailyReport.objects.all().select_related('employee', 'reviewed_by')
        if not _is_manager_or_admin(user):
            qs = qs.filter(employee=user)
        return qs

    @action(detail=False, methods=['get'], url_path='draft-summary')
    def draft_summary(self, request):
        user = request.user
        today = timezone.localdate()

        visits_done = Visit.objects.filter(assigned_employee=user, scheduled_start__date=today, status=Visit.VisitStatus.COMPLETED).count()
        followups_done = FollowUp.objects.filter(employee=user, scheduled_at__date=today, status=FollowUp.FollowUpStatus.COMPLETED).count()
        leads_created = Lead.objects.filter(created_by=user, created_at__date=today).count()
        onboardings_done = PartnerOnboarding.objects.filter(assigned_executive=user, updated_at__date=today, status__in=[PartnerOnboarding.OnboardingStatus.UNDER_REVIEW, PartnerOnboarding.OnboardingStatus.APPROVED]).count()

        return Response({
            'date': str(today),
            'auto_visits_completed': visits_done,
            'auto_followups_completed': followups_done,
            'auto_leads_created': leads_created,
            'auto_onboardings_completed': onboardings_done,
            'auto_tasks_completed': visits_done + followups_done,
        })
