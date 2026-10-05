import uuid
from datetime import datetime, timedelta
from django.utils import timezone
from django.db.models import Count, Q, Sum
from rest_framework import viewsets, permissions, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from django_filters.rest_framework import DjangoFilterBackend

from .models import (
    BookingOperation, EventReadinessChecklist, OperationsIssue,
    QualityInspection, OperationalAsset, OperationsRequest,
    OperationsDailyReport
)
from .serializers import (
    BookingOperationSerializer, EventReadinessChecklistSerializer,
    OperationsIssueSerializer, QualityInspectionSerializer,
    OperationalAssetSerializer, OperationsRequestSerializer,
    OperationsDailyReportSerializer
)
from apps.tasks.models import Task


class BookingOperationViewSet(viewsets.ModelViewSet):
    queryset = BookingOperation.objects.all().select_related('assigned_executive', 'manager').prefetch_related('readiness_checklist')
    serializer_class = BookingOperationSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['operations_status', 'payment_status', 'partner_confirmation_status', 'partner_type', 'event_type', 'assigned_executive']
    search_fields = ['booking_code', 'customer_name', 'customer_phone', 'partner_name', 'package_name', 'venue_address']
    ordering_fields = ['event_date', 'readiness_percentage', 'created_at']

    def perform_create(self, serializer):
        code = f"PB-{uuid.uuid4().hex[:5].upper()}"
        booking = serializer.save(booking_code=code)
        # Automatically initialize empty checklist
        EventReadinessChecklist.objects.create(booking=booking)

    @action(detail=False, methods=['get'])
    def today_timeline(self, request):
        today = timezone.now().date()
        bookings = BookingOperation.objects.filter(event_date=today).order_by('event_time_slot')
        serializer = self.get_serializer(bookings, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def dashboard_stats(self, request):
        today = timezone.now().date()
        total_bookings = BookingOperation.objects.count()
        today_bookings = BookingOperation.objects.filter(event_date=today).count()
        confirmed = BookingOperation.objects.filter(partner_confirmation_status='CONFIRMED').count()
        ready = BookingOperation.objects.filter(operations_status='READY').count()
        in_progress = BookingOperation.objects.filter(operations_status__in=['COORDINATION', 'READINESS_CHECK', 'IN_PROGRESS', 'EXECUTING']).count()
        issues_count = OperationsIssue.objects.filter(status__in=['OPEN', 'ASSIGNED', 'IN_PROGRESS', 'ESCALATED']).count()
        at_risk = BookingOperation.objects.filter(
            event_date__lte=today + timedelta(days=2),
            readiness_percentage__lt=70,
            operations_status__in=['COORDINATION', 'READINESS_CHECK', 'PREPARATION_PENDING']
        ).count()

        return Response({
            'total_bookings': total_bookings,
            'today_bookings': today_bookings,
            'confirmed_partners': confirmed,
            'ready_for_service': ready,
            'in_progress': in_progress,
            'open_issues': issues_count,
            'at_risk_bookings': at_risk,
        })

    @action(detail=True, methods=['post'])
    def update_readiness(self, request, pk=None):
        booking = self.get_object()
        checklist, _ = EventReadinessChecklist.objects.get_or_create(booking=booking)
        
        for field in [
            'hall_confirmed', 'seating_confirmed', 'decoration_confirmed',
            'catering_confirmed', 'parking_confirmed', 'setup_confirmed',
            'staff_confirmed', 'power_backup_confirmed'
        ]:
            if field in request.data:
                setattr(checklist, field, bool(request.data[field]))
        
        if 'notes' in request.data:
            checklist.notes = request.data['notes']
        
        checklist.verified_by = request.user
        checklist.verified_at = timezone.now()
        checklist.save()

        return Response(EventReadinessChecklistSerializer(checklist).data)

    @action(detail=True, methods=['post'])
    def update_status(self, request, pk=None):
        booking = self.get_object()
        new_status = request.data.get('operations_status')
        if new_status in dict(BookingOperation.OperationsStatus.choices):
            booking.operations_status = new_status
            booking.save(update_fields=['operations_status', 'updated_at'])
            return Response(self.get_serializer(booking).data)
        return Response({'error': 'Invalid status choice'}, status=status.HTTP_400_BAD_REQUEST)


    @action(detail=True, methods=['post'])
    def assign_executive(self, request, pk=None):
        booking = self.get_object()
        executive_id = request.data.get('assigned_executive')
        if executive_id:
            booking.assigned_executive_id = executive_id
            booking.save(update_fields=['assigned_executive', 'updated_at'])
            return Response(self.get_serializer(booking).data)
        return Response({'error': 'Executive ID required'}, status=status.HTTP_400_BAD_REQUEST)


class EventReadinessChecklistViewSet(viewsets.ModelViewSet):
    queryset = EventReadinessChecklist.objects.all().select_related('booking', 'verified_by')
    serializer_class = EventReadinessChecklistSerializer
    permission_classes = [permissions.IsAuthenticated]


class OperationsIssueViewSet(viewsets.ModelViewSet):
    queryset = OperationsIssue.objects.all().select_related('booking', 'assigned_to', 'reported_by')
    serializer_class = OperationsIssueSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'priority', 'category', 'escalation_level', 'assigned_to']
    search_fields = ['issue_code', 'problem_statement', 'booking__booking_code', 'booking__customer_name']
    ordering_fields = ['sla_deadline', 'priority', 'created_at']

    def perform_create(self, serializer):
        code = f"OP-{uuid.uuid4().hex[:4].upper()}"
        sla_hours = serializer.validated_data.get('sla_hours', 2)
        deadline = timezone.now() + timedelta(hours=sla_hours)
        serializer.save(
            issue_code=code,
            reported_by=self.request.user,
            sla_deadline=deadline
        )

    @action(detail=True, methods=['post'])
    def escalate(self, request, pk=None):
        issue = self.get_object()
        current_level = issue.escalation_level
        if current_level == OperationsIssue.EscalationLevel.EXECUTIVE:
            issue.escalation_level = OperationsIssue.EscalationLevel.MANAGER
            issue.status = OperationsIssue.Status.ESCALATED
        elif current_level == OperationsIssue.EscalationLevel.MANAGER:
            issue.escalation_level = OperationsIssue.EscalationLevel.ADMIN
            issue.status = OperationsIssue.Status.ESCALATED
        issue.save(update_fields=['escalation_level', 'status', 'updated_at'])
        return Response(self.get_serializer(issue).data)

    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        issue = self.get_object()
        notes = request.data.get('resolution_notes', 'Issue resolved on site.')
        issue.resolution_notes = notes
        issue.status = OperationsIssue.Status.RESOLVED
        issue.resolved_at = timezone.now()
        issue.save(update_fields=['resolution_notes', 'status', 'resolved_at', 'updated_at'])
        return Response(self.get_serializer(issue).data)


class QualityInspectionViewSet(viewsets.ModelViewSet):
    queryset = QualityInspection.objects.all().select_related('booking', 'inspector', 'auto_generated_issue')
    serializer_class = QualityInspectionSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['result', 'inspector', 'booking']
    search_fields = ['inspection_code', 'partner_name', 'notes']

    def perform_create(self, serializer):
        code = f"QC-{uuid.uuid4().hex[:4].upper()}"
        inspection = serializer.save(
            inspection_code=code,
            inspector=self.request.user
        )

        # If result is FAIL, automatically generate an OperationsIssue
        if inspection.result == QualityInspection.InspectionResult.FAIL:
            issue_code = f"OP-{uuid.uuid4().hex[:4].upper()}"
            issue = OperationsIssue.objects.create(
                issue_code=issue_code,
                category=OperationsIssue.IssueCategory.VENUE_DEFECT,
                priority=OperationsIssue.Priority.CRITICAL,
                booking=inspection.booking,
                problem_statement=f"Quality Audit Failure at {inspection.partner_name}: {inspection.notes or 'Failed quality requirements.'}",
                assigned_to=self.request.user,
                reported_by=self.request.user,
                sla_hours=2,
                sla_deadline=timezone.now() + timedelta(hours=2),
                status=OperationsIssue.Status.OPEN,
                escalation_level=OperationsIssue.EscalationLevel.MANAGER
            )
            inspection.auto_generated_issue = issue
            inspection.save(update_fields=['auto_generated_issue'])


class OperationalAssetViewSet(viewsets.ModelViewSet):
    queryset = OperationalAsset.objects.all().select_related('assigned_to', 'current_booking')
    serializer_class = OperationalAssetSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'category', 'condition', 'assigned_to']
    search_fields = ['asset_code', 'name', 'serial_number', 'location']

    def perform_create(self, serializer):
        if not serializer.validated_data.get('asset_code'):
            code = f"AST-{uuid.uuid4().hex[:4].upper()}"
            serializer.save(asset_code=code)
        else:
            serializer.save()

    @action(detail=True, methods=['post'])
    def checkout(self, request, pk=None):
        asset = self.get_object()
        booking_id = request.data.get('booking_id')
        assignee_id = request.data.get('assigned_to') or request.user.id
        
        asset.status = OperationalAsset.Status.IN_USE
        asset.assigned_to_id = assignee_id
        if booking_id:
            asset.current_booking_id = booking_id
        asset.save()
        return Response(self.get_serializer(asset).data)

    @action(detail=True, methods=['post'])
    def checkin(self, request, pk=None):
        asset = self.get_object()
        condition = request.data.get('condition', OperationalAsset.Condition.GOOD)
        asset.status = OperationalAsset.Status.AVAILABLE
        asset.condition = condition
        asset.assigned_to = None
        asset.current_booking = None
        asset.last_inspected_at = timezone.now()
        asset.save()
        return Response(self.get_serializer(asset).data)


class OperationsRequestViewSet(viewsets.ModelViewSet):
    queryset = OperationsRequest.objects.all().select_related('requester', 'approved_by')
    serializer_class = OperationsRequestSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'request_type', 'requester']
    search_fields = ['request_code', 'title', 'description']

    def perform_create(self, serializer):
        code = f"REQ-{uuid.uuid4().hex[:4].upper()}"
        serializer.save(request_code=code, requester=self.request.user)

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        req = self.get_object()
        notes = request.data.get('approval_notes', 'Approved by operations manager.')
        req.status = OperationsRequest.Status.APPROVED
        req.approved_by = request.user
        req.approval_notes = notes
        req.save(update_fields=['status', 'approved_by', 'approval_notes', 'updated_at'])
        return Response(self.get_serializer(req).data)

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        req = self.get_object()
        notes = request.data.get('approval_notes', 'Rejected by operations manager.')
        req.status = OperationsRequest.Status.REJECTED
        req.approved_by = request.user
        req.approval_notes = notes
        req.save(update_fields=['status', 'approved_by', 'approval_notes', 'updated_at'])
        return Response(self.get_serializer(req).data)


class OperationsDailyReportViewSet(viewsets.ModelViewSet):
    queryset = OperationsDailyReport.objects.all().select_related('executive')
    serializer_class = OperationsDailyReportSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['report_date', 'executive', 'status']

    def perform_create(self, serializer):
        serializer.save(executive=self.request.user)

    @action(detail=False, methods=['get'])
    def today_telemetry(self, request):
        today = timezone.now().date()
        user = request.user
        emp = getattr(user, 'employee_profile', None)

        # Auto-calculate user's operational activity today
        completed_tasks = Task.objects.filter(
            assigned_to=emp,
            status='COMPLETED',
            updated_at__date=today
        ).count() if emp else 0

        bookings_count = BookingOperation.objects.filter(
            assigned_executive=user,
            event_date=today
        ).count()

        issues_resolved = OperationsIssue.objects.filter(
            assigned_to=user,
            status='RESOLVED',
            resolved_at__date=today
        ).count()

        qc_count = QualityInspection.objects.filter(
            inspector=user,
            inspection_date=today
        ).count()

        return Response({
            'report_date': str(today),
            'tasks_completed_count': completed_tasks,
            'bookings_handled_count': bookings_count,
            'issues_resolved_count': issues_resolved,
            'followups_count': max(4, bookings_count * 2),
            'visits_count': max(1, qc_count),
            'quality_checks_count': qc_count,
        })


class OperationsManagerOverviewView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        today = timezone.now().date()
        
        # Team members workload calculation
        from apps.employees.models import Employee
        executives = Employee.objects.filter(
            Q(department__code__icontains='OPS') | Q(department__name__icontains='Operations')
        ).select_related('user', 'department', 'position', 'role')

        team_workload = []
        for emp in executives:
            active_tasks = Task.objects.filter(
                assigned_to=emp,
                status__in=['ASSIGNED', 'IN_PROGRESS', 'REVIEW']
            ).count()
            active_bookings = BookingOperation.objects.filter(
                assigned_executive=emp.user,
                event_date__gte=today
            ).count()
            
            # Load metric: e.g. capacity = 10 units
            load_percentage = min(100, int(((active_tasks + active_bookings * 2) / 10.0) * 100))
            team_workload.append({
                'employee_id': str(emp.id),
                'user_id': emp.user.id,
                'name': emp.user.get_full_name() or f"{emp.first_name} {emp.last_name}".strip() or emp.user.username,
                'code': emp.user.employee_code,
                'designation': emp.position.title if emp.position else (emp.role.name if emp.role else 'Operations Specialist'),
                'active_tasks': active_tasks,
                'active_bookings': active_bookings,
                'load_percentage': load_percentage,
                'is_overloaded': load_percentage >= 90
            })

        # Pending approvals
        pending_requests = OperationsRequest.objects.filter(status__in=['NEW', 'REVIEW']).count()
        critical_issues = OperationsIssue.objects.filter(priority='CRITICAL', status__in=['OPEN', 'ASSIGNED', 'ESCALATED']).count()
        today_events = BookingOperation.objects.filter(event_date=today).count()

        return Response({
            'team_workload': team_workload,
            'pending_requests_count': pending_requests,
            'critical_issues_count': critical_issues,
            'today_events_count': today_events,
            'generated_at': timezone.now().isoformat()
        })
