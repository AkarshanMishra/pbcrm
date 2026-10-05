from django.utils import timezone
from django.db.models import Q
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response

from apps.employees.models import Employee
from apps.notifications.models import Notification
from .models import DailyWorkPlan, DailyWorkReport, DailyStandup, WorkDiaryEntry, Announcement
from .serializers import (
    DailyWorkPlanSerializer,
    DailyWorkReportSerializer,
    ReportReviewSerializer,
    DailyStandupSerializer,
    WorkDiaryEntrySerializer,
    AnnouncementSerializer
)

class DailyWorkPlanViewSet(viewsets.ModelViewSet):
    serializer_class = DailyWorkPlanSerializer
    filterset_fields = ['plan_date', 'is_started']
    ordering_fields = ['-plan_date', '-created_at']

    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            return DailyWorkPlan.objects.none()

        if user.is_admin or (hasattr(user, 'employee_profile') and user.employee_profile.role.code in ['ADMIN', 'IT', 'MARKETING', 'OPERATIONS', 'ACCOUNTS']):
            emp_id = self.request.query_params.get('employee')
            if emp_id:
                return DailyWorkPlan.objects.select_related('employee__user').filter(employee_id=emp_id)
            return DailyWorkPlan.objects.select_related('employee__user').all()

        if hasattr(user, 'employee_profile'):
            return DailyWorkPlan.objects.select_related('employee__user').filter(employee=user.employee_profile)
        return DailyWorkPlan.objects.none()

    def perform_create(self, serializer):
        emp = getattr(self.request.user, 'employee_profile', None)
        serializer.save(employee=emp)

    @action(detail=False, methods=['get', 'post'], url_path='today')
    def today_plan(self, request):
        emp = getattr(request.user, 'employee_profile', None)
        if not emp:
            return Response({'error': 'No employee profile linked to user.'}, status=status.HTTP_400_BAD_REQUEST)

        today = timezone.localdate()
        plan, _ = DailyWorkPlan.objects.get_or_create(employee=emp, plan_date=today)

        if request.method == 'POST':
            planned_items = request.data.get('planned_items', plan.planned_items)
            notes = request.data.get('notes', plan.notes)
            start_day = request.data.get('start_day', False) or request.data.get('is_started', False)

            plan.planned_items = planned_items
            plan.notes = notes
            if start_day and not plan.is_started:
                plan.is_started = True
                plan.started_at = timezone.now()
            plan.save()

        return Response(DailyWorkPlanSerializer(plan).data)


class DailyWorkReportViewSet(viewsets.ModelViewSet):
    serializer_class = DailyWorkReportSerializer
    filterset_fields = ['report_date', 'status']
    ordering_fields = ['-report_date', '-created_at']

    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            return DailyWorkReport.objects.none()

        if user.is_admin or (hasattr(user, 'employee_profile') and user.employee_profile.role.code in ['ADMIN', 'IT', 'MARKETING', 'OPERATIONS', 'ACCOUNTS']):
            emp_id = self.request.query_params.get('employee')
            if emp_id:
                return DailyWorkReport.objects.select_related('employee__user', 'employee__department', 'reviewed_by').filter(employee_id=emp_id)
            return DailyWorkReport.objects.select_related('employee__user', 'employee__department', 'reviewed_by').all()

        if hasattr(user, 'employee_profile'):
            return DailyWorkReport.objects.select_related('employee__user', 'employee__department', 'reviewed_by').filter(employee=user.employee_profile)
        return DailyWorkReport.objects.none()

    def perform_create(self, serializer):
        user = self.request.user
        emp = getattr(user, 'employee_profile', None)
        target_emp_id = self.request.data.get('employee') or self.request.data.get('employee_id')
        if (user.is_superuser or user.is_admin or (emp and emp.role.code == 'ADMIN')) and target_emp_id:
            target_emp = Employee.objects.filter(id=target_emp_id).first()
            if target_emp:
                serializer.save(employee=target_emp)
                return
        serializer.save(employee=emp)

    @action(detail=False, methods=['get', 'post'], url_path='today')
    def today_report(self, request):
        emp = getattr(request.user, 'employee_profile', None)
        if not emp:
            return Response({'error': 'No employee profile linked.'}, status=status.HTTP_400_BAD_REQUEST)

        today = timezone.localdate()
        report, _ = DailyWorkReport.objects.get_or_create(employee=emp, report_date=today)

        if request.method == 'POST':
            report.summary_text = request.data.get('summary_text', report.summary_text)
            report.completed_summary = request.data.get('completed_summary', report.completed_summary)
            report.pending_summary = request.data.get('pending_summary', report.pending_summary)
            report.blocked_summary = request.data.get('blocked_summary', report.blocked_summary)
            report.tomorrow_plan = request.data.get('tomorrow_plan', report.tomorrow_plan)
            
            if request.data.get('submit', False):
                report.status = DailyWorkReport.ReportStatus.SUBMITTED
                report.submitted_at = timezone.now()
            report.save()

        return Response(DailyWorkReportSerializer(report).data)

    @action(detail=True, methods=['post'], url_path='review')
    def review_report(self, request, pk=None):
        report = self.get_object()
        serializer = ReportReviewSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        decision = serializer.validated_data['decision']
        remarks = serializer.validated_data.get('remarks', '')

        report.reviewed_by = request.user
        report.reviewed_at = timezone.now()
        report.manager_remarks = remarks
        report.status = DailyWorkReport.ReportStatus.APPROVED if decision == 'APPROVE' else DailyWorkReport.ReportStatus.CHANGES_REQUESTED
        report.save()

        Notification.send_notification(
            recipient=report.employee.user,
            title="Daily Report Reviewed",
            message=f"Your report for {report.report_date} was {report.get_status_display()}.",
            notification_type=Notification.NotificationType.REPORT_APPROVED if decision == 'APPROVE' else Notification.NotificationType.REPORT_CHANGES_REQUESTED,
            link_type='REPORT',
            link_id=report.id
        )
        return Response(DailyWorkReportSerializer(report).data)

    @action(detail=False, methods=['get'], url_path='team-summary')
    def team_summary(self, request):
        today = timezone.localdate()
        reports = DailyWorkReport.objects.filter(report_date=today).select_related('employee__user', 'employee__department')
        return Response({
            'total_reports': reports.count(),
            'submitted': reports.filter(status=DailyWorkReport.ReportStatus.SUBMITTED).count(),
            'approved': reports.filter(status=DailyWorkReport.ReportStatus.APPROVED).count(),
            'changes_requested': reports.filter(status=DailyWorkReport.ReportStatus.CHANGES_REQUESTED).count(),
            'reports': DailyWorkReportSerializer(reports, many=True).data
        })


class DailyStandupViewSet(viewsets.ModelViewSet):
    serializer_class = DailyStandupSerializer
    filterset_fields = ['standup_date']
    ordering_fields = ['-standup_date', '-submitted_at']

    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            return DailyStandup.objects.none()

        if user.is_admin or (hasattr(user, 'employee_profile') and user.employee_profile.role.code in ['ADMIN', 'IT', 'MARKETING', 'OPERATIONS', 'ACCOUNTS']):
            dept = self.request.query_params.get('department')
            if dept:
                return DailyStandup.objects.filter(employee__department_id=dept).select_related('employee__user', 'employee__department', 'reviewed_by')
            return DailyStandup.objects.select_related('employee__user', 'employee__department', 'reviewed_by').all()

        if hasattr(user, 'employee_profile'):
            return DailyStandup.objects.filter(employee=user.employee_profile).select_related('employee__user', 'employee__department', 'reviewed_by')
        return DailyStandup.objects.none()

    @action(detail=False, methods=['get', 'post'], url_path='today')
    def today_standup(self, request):
        emp = getattr(request.user, 'employee_profile', None)
        if not emp:
            return Response({'error': 'No employee profile linked.'}, status=status.HTTP_400_BAD_REQUEST)

        today = timezone.localdate()
        standup, _ = DailyStandup.objects.get_or_create(
            employee=emp,
            standup_date=today,
            defaults={'yesterday_completed': '', 'today_planned': '', 'blockers_encountered': ''}
        )

        if request.method == 'POST':
            standup.yesterday_completed = request.data.get('yesterday_completed', standup.yesterday_completed)
            standup.today_planned = request.data.get('today_planned', standup.today_planned)
            standup.blockers_encountered = request.data.get('blockers_encountered', standup.blockers_encountered)
            standup.submitted_at = timezone.now()
            standup.save()

        return Response(DailyStandupSerializer(standup).data)


class WorkDiaryViewSet(viewsets.ModelViewSet):
    serializer_class = WorkDiaryEntrySerializer
    filterset_fields = ['category', 'task']
    ordering_fields = ['-logged_at']

    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            return WorkDiaryEntry.objects.none()
        if hasattr(user, 'employee_profile'):
            return WorkDiaryEntry.objects.filter(employee=user.employee_profile).select_related('task')
        return WorkDiaryEntry.objects.none()

    def perform_create(self, serializer):
        serializer.save(employee=self.request.user.employee_profile)


class AnnouncementViewSet(viewsets.ModelViewSet):
    serializer_class = AnnouncementSerializer
    filterset_fields = ['target_type', 'priority', 'is_pinned']
    ordering_fields = ['-is_pinned', '-created_at']

    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            return Announcement.objects.none()

        today = timezone.localdate()
        qs = Announcement.objects.filter(Q(valid_until__isnull=True) | Q(valid_until__gte=today))
        
        if user.is_admin:
            return qs.select_related('author', 'target_department').all()

        if hasattr(user, 'employee_profile'):
            emp = user.employee_profile
            return qs.filter(
                Q(target_type=Announcement.TargetType.ALL) |
                Q(target_type=Announcement.TargetType.DEPARTMENT, target_department=emp.department)
            ).select_related('author', 'target_department')
        
        return qs.filter(target_type=Announcement.TargetType.ALL)

    def perform_create(self, serializer):
        announcement = serializer.save(author=self.request.user)
        # Notify all target employees
        from apps.accounts.models import User
        target_users = User.objects.filter(status='ACTIVE')
        if announcement.target_type == Announcement.TargetType.DEPARTMENT and announcement.target_department:
            target_users = target_users.filter(employee_profile__department=announcement.target_department)
        
        for u in target_users:
            if u != self.request.user:
                Notification.send_notification(
                    recipient=u,
                    title=f"📢 {announcement.title}",
                    message=announcement.content[:100] + ("..." if len(announcement.content) > 100 else ""),
                    notification_type=Notification.NotificationType.SYSTEM_ALERT,
                    link_type='ANNOUNCEMENT',
                    link_id=announcement.id
                )
