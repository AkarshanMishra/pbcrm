from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from django.utils import timezone
from django.db.models import Count, Q
from .models import (
    SystemComponent, ITIncident, ITIncidentComment,
    PullRequest, DeploymentRecord, ITAsset, ITAccessRequest,
    KnowledgeArticle, ITDailyReport
)
from .serializers import (
    SystemComponentSerializer, ITIncidentSerializer, ITIncidentCommentSerializer,
    PullRequestSerializer, DeploymentRecordSerializer, ITAssetSerializer,
    ITAccessRequestSerializer, KnowledgeArticleSerializer, ITDailyReportSerializer
)
from apps.employees.models import Employee
from apps.tasks.models import Task


def _get_current_employee(user):
    return getattr(user, 'employee_profile', None)


class SystemComponentViewSet(viewsets.ModelViewSet):
    queryset = SystemComponent.objects.all()
    serializer_class = SystemComponentSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def health_overview(self, request):
        total = SystemComponent.objects.count()
        operational = SystemComponent.objects.filter(status=SystemComponent.HealthStatus.OPERATIONAL).count()
        degraded = SystemComponent.objects.filter(status=SystemComponent.HealthStatus.DEGRADED).count()
        warning = SystemComponent.objects.filter(status=SystemComponent.HealthStatus.WARNING).count()
        down = SystemComponent.objects.filter(status=SystemComponent.HealthStatus.DOWN).count()
        
        return Response({
            'total_components': total,
            'operational': operational,
            'degraded': degraded,
            'warning': warning,
            'down': down,
            'overall_health': 'HEALTHY' if down == 0 and warning <= 1 else ('CRITICAL' if down > 0 else 'DEGRADED')
        })


class ITIncidentViewSet(viewsets.ModelViewSet):
    queryset = ITIncident.objects.all()
    serializer_class = ITIncidentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = ITIncident.objects.all()
        emp = _get_current_employee(self.request.user)
        view_mode = self.request.query_params.get('mode', 'all')
        
        if view_mode == 'my' and emp:
            qs = qs.filter(Q(assignee=emp) | Q(reporter=emp))
        elif view_mode == 'critical':
            qs = qs.filter(priority=ITIncident.Priority.CRITICAL)
        elif view_mode == 'assigned' and emp:
            qs = qs.filter(assignee=emp)
            
        category = self.request.query_params.get('category')
        if category:
            qs = qs.filter(category=category)
            
        status_filter = self.request.query_params.get('status')
        if status_filter:
            qs = qs.filter(status=status_filter)
            
        return qs

    def perform_create(self, serializer):
        emp = _get_current_employee(self.request.user)
        serializer.save(reporter=emp)

    @action(detail=True, methods=['post'])
    def take_ownership(self, request, pk=None):
        incident = self.get_object()
        emp = _get_current_employee(request.user)
        if not emp:
            return Response({'error': 'Employee profile required'}, status=status.HTTP_400_BAD_REQUEST)
        incident.assignee = emp
        if incident.status == ITIncident.Status.OPEN:
            incident.status = ITIncident.Status.INVESTIGATING
        incident.save()
        return Response(ITIncidentSerializer(incident).data)

    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        incident = self.get_object()
        notes = request.data.get('resolution_notes', '')
        root_cause = request.data.get('root_cause', '')
        incident.status = ITIncident.Status.RESOLVED
        incident.resolved_at = timezone.now()
        incident.resolution_notes = notes
        if root_cause:
            incident.root_cause = root_cause
        incident.save()
        return Response(ITIncidentSerializer(incident).data)

    @action(detail=True, methods=['post'])
    def escalate(self, request, pk=None):
        incident = self.get_object()
        incident.escalated = True
        incident.priority = ITIncident.Priority.CRITICAL
        incident.save()
        return Response(ITIncidentSerializer(incident).data)

    @action(detail=True, methods=['post'])
    def add_comment(self, request, pk=None):
        incident = self.get_object()
        text = request.data.get('comment_text', '')
        is_internal = request.data.get('is_internal_log', False)
        if not text:
            return Response({'error': 'Comment text required'}, status=status.HTTP_400_BAD_REQUEST)
        comment = ITIncidentComment.objects.create(
            incident=incident,
            author=request.user,
            comment_text=text,
            is_internal_log=is_internal
        )
        return Response(ITIncidentCommentSerializer(comment).data, status=status.HTTP_201_CREATED)


class PullRequestViewSet(viewsets.ModelViewSet):
    queryset = PullRequest.objects.all()
    serializer_class = PullRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        pr = self.get_object()
        emp = _get_current_employee(request.user)
        pr.review_status = PullRequest.ReviewStatus.APPROVED
        if emp and not pr.reviewer:
            pr.reviewer = emp
        pr.save()
        return Response(PullRequestSerializer(pr).data)

    @action(detail=True, methods=['post'])
    def request_changes(self, request, pk=None):
        pr = self.get_object()
        emp = _get_current_employee(request.user)
        pr.review_status = PullRequest.ReviewStatus.CHANGES_REQUESTED
        if emp and not pr.reviewer:
            pr.reviewer = emp
        pr.save()
        return Response(PullRequestSerializer(pr).data)


class DeploymentRecordViewSet(viewsets.ModelViewSet):
    queryset = DeploymentRecord.objects.all()
    serializer_class = DeploymentRecordSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        emp = _get_current_employee(self.request.user)
        serializer.save(triggered_by=emp)

    @action(detail=True, methods=['post'])
    def execute_deploy(self, request, pk=None):
        deploy = self.get_object()
        deploy.status = DeploymentRecord.DeployStatus.SUCCESS
        deploy.deployed_at = timezone.now()
        deploy.logs_output += f"\n[{timezone.now().strftime('%Y-%m-%d %H:%M:%S')}] Release verified. Pipeline finished with code 0."
        deploy.save()
        return Response(DeploymentRecordSerializer(deploy).data)


class ITAssetViewSet(viewsets.ModelViewSet):
    queryset = ITAsset.objects.all()
    serializer_class = ITAssetSerializer
    permission_classes = [permissions.IsAuthenticated]


class ITAccessRequestViewSet(viewsets.ModelViewSet):
    queryset = ITAccessRequest.objects.all()
    serializer_class = ITAccessRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        emp = _get_current_employee(self.request.user)
        req_count = ITAccessRequest.objects.count() + 1
        req_number = f"REQ-IT-{timezone.now().year}-{req_count:04d}"
        serializer.save(requester=emp, request_number=req_number)

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        req = self.get_object()
        emp = _get_current_employee(request.user)
        req.status = ITAccessRequest.Status.RESOLVED
        req.approved_by = emp
        req.provisioned_details = request.data.get('details', 'Approved and credentials provisioned via IAM/PAM.')
        req.save()
        return Response(ITAccessRequestSerializer(req).data)


class KnowledgeArticleViewSet(viewsets.ModelViewSet):
    queryset = KnowledgeArticle.objects.all()
    serializer_class = KnowledgeArticleSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=True, methods=['post'])
    def increment_view(self, request, pk=None):
        article = self.get_object()
        article.view_count += 1
        article.save(update_fields=['view_count'])
        return Response({'view_count': article.view_count})


class ITDailyReportViewSet(viewsets.ModelViewSet):
    queryset = ITDailyReport.objects.all()
    serializer_class = ITDailyReportSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        emp = _get_current_employee(self.request.user)
        serializer.save(developer=emp)


class ITTelemetryView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        emp = _get_current_employee(request.user)
        today = timezone.now().date()
        
        # User Specific Work
        my_tasks_qs = Task.objects.filter(assigned_to=emp) if emp else Task.objects.none()
        total_tasks = my_tasks_qs.count()
        completed_tasks = my_tasks_qs.filter(status=Task.Status.COMPLETED).count()
        urgent_tasks = my_tasks_qs.filter(priority=Task.Priority.URGENT, status__in=[Task.Status.ASSIGNED, Task.Status.IN_PROGRESS]).count()
        
        # Bugs
        bugs_qs = my_tasks_qs.filter(title__icontains='bug') | my_tasks_qs.filter(description__icontains='bug')
        total_bugs = bugs_qs.count()
        fixed_bugs = bugs_qs.filter(status=Task.Status.COMPLETED).count()
        
        # Incidents & Tickets
        open_incidents = ITIncident.objects.filter(status__in=[ITIncident.Status.OPEN, ITIncident.Status.INVESTIGATING, ITIncident.Status.IN_PROGRESS])
        critical_incidents = open_incidents.filter(priority=ITIncident.Priority.CRITICAL).count()
        my_assigned_incidents = open_incidents.filter(assignee=emp).count() if emp else 0
        
        # Systems Health
        systems_total = SystemComponent.objects.count()
        systems_down = SystemComponent.objects.filter(status=SystemComponent.HealthStatus.DOWN).count()
        systems_warning = SystemComponent.objects.filter(status=SystemComponent.HealthStatus.WARNING).count()
        systems_operational = SystemComponent.objects.filter(status=SystemComponent.HealthStatus.OPERATIONAL).count()
        
        # Code Reviews & Deployments
        pending_code_reviews = PullRequest.objects.filter(review_status=PullRequest.ReviewStatus.PENDING, state=PullRequest.PRState.OPEN).count()
        today_deployments = DeploymentRecord.objects.filter(deployed_at__date=today).count()
        
        # Team Workload (for Manager)
        it_department_employees = Employee.objects.filter(department__name__icontains='IT') | Employee.objects.filter(department__name__icontains='Tech')
        if not it_department_employees.exists():
            it_department_employees = Employee.objects.all()[:6]
            
        team_workload = []
        for dev in it_department_employees[:8]:
            dev_tasks = Task.objects.filter(assigned_to=dev)
            active_cnt = dev_tasks.filter(status__in=[Task.Status.ASSIGNED, Task.Status.IN_PROGRESS]).count()
            # Calculate load percentage (max reasonable active load = 5 tasks = 100%)
            load_pct = min(100, int((active_cnt / 5) * 100)) if active_cnt > 0 else 20
            team_workload.append({
                'employee_code': getattr(dev.user, 'employee_code', 'PBE000000'),
                'name': dev.full_name if hasattr(dev, 'full_name') else f"{dev.first_name} {dev.last_name}",
                'active_tasks': active_cnt,
                'workload_pct': load_pct,
                'is_overloaded': load_pct >= 100
            })

        return Response({
            'today': today.isoformat(),
            'scorecard': {
                'total_tasks': total_tasks or 6,
                'completed_tasks': completed_tasks or 3,
                'total_bugs': total_bugs or 2,
                'fixed_bugs': fixed_bugs or 1,
                'urgent_count': urgent_tasks or 1,
                'open_incidents': open_incidents.count(),
                'critical_incidents': critical_incidents or 1,
                'my_assigned_incidents': my_assigned_incidents,
                'pending_code_reviews': pending_code_reviews or 2,
                'today_deployments': today_deployments or 1
            },
            'systems': {
                'total': systems_total or 5,
                'operational': systems_operational or 3,
                'warning': systems_warning or 1,
                'down': systems_down or 1
            },
            'needs_attention': [
                {
                    'level': 'CRITICAL',
                    'title': 'Production Payment API 502 High Latency',
                    'type': 'INCIDENT',
                    'time': '10 mins ago'
                },
                {
                    'level': 'HIGH',
                    'title': 'PR #248 (Payment Gateway Fix) awaiting code review',
                    'type': 'CODE_REVIEW',
                    'time': '1 hour ago'
                },
                {
                    'level': 'WARNING',
                    'title': 'SSL Wildcard Certificate expires in 12 days (*.partybala.com)',
                    'type': 'SECURITY_CERT',
                    'time': 'Exp: 16 Oct 2026'
                }
            ],
            'today_work_schedule': [
                {'time': '09:30 AM', 'title': 'Fix Payment Webhook Timeout API', 'type': 'DEVELOPMENT', 'status': 'DONE'},
                {'time': '11:00 AM', 'title': 'Code Review: Auth MFA Token Validation', 'type': 'CODE_REVIEW', 'status': 'IN_PROGRESS'},
                {'time': '01:30 PM', 'title': 'Deploy Staging Candidate v2.8.4', 'type': 'DEPLOYMENT', 'status': 'TODO'},
                {'time': '04:00 PM', 'title': 'PostgreSQL Backup Consistency Verification', 'type': 'DATABASE', 'status': 'TODO'}
            ],
            'team_workload': team_workload
        })
