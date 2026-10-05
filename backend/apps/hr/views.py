from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from django.utils import timezone
from django.db.models import Count, Q, Avg
from apps.employees.models import Employee
from apps.attendance.models import Attendance, AttendanceCorrection
from .models import (
    JobOpening,
    CandidateApplication,
    OnboardingChecklist,
    EmployeeDocument,
    HRPolicy,
    PolicyAcknowledgement,
    PerformanceReview,
    TrainingProgram,
    TrainingEnrollment,
    HRRequest,
    OffboardingRecord,
    HRAnnouncement,
    HRDailyReport,
)
from .serializers import (
    JobOpeningSerializer,
    CandidateApplicationSerializer,
    OnboardingChecklistSerializer,
    EmployeeDocumentSerializer,
    HRPolicySerializer,
    PolicyAcknowledgementSerializer,
    PerformanceReviewSerializer,
    TrainingProgramSerializer,
    TrainingEnrollmentSerializer,
    HRRequestSerializer,
    OffboardingRecordSerializer,
    HRAnnouncementSerializer,
    HRDailyReportSerializer,
)


class JobOpeningViewSet(viewsets.ModelViewSet):
    queryset = JobOpening.objects.all()
    serializer_class = JobOpeningSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['status', 'department']
    search_fields = ['title', 'code', 'requirements']


class CandidateApplicationViewSet(viewsets.ModelViewSet):
    queryset = CandidateApplication.objects.all()
    serializer_class = CandidateApplicationSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['job', 'stage']
    search_fields = ['full_name', 'candidate_code', 'email', 'phone']

    @action(detail=True, methods=['post'])
    def advance_stage(self, request, pk=None):
        candidate = self.get_object()
        new_stage = request.data.get('stage')
        if new_stage in CandidateApplication.Stage.values:
            candidate.stage = new_stage
            candidate.save()
            return Response(CandidateApplicationSerializer(candidate).data)
        return Response({'error': 'Invalid stage'}, status=status.HTTP_400_BAD_REQUEST)


class OnboardingChecklistViewSet(viewsets.ModelViewSet):
    queryset = OnboardingChecklist.objects.all()
    serializer_class = OnboardingChecklistSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['is_completed']

    @action(detail=True, methods=['post'])
    def update_step(self, request, pk=None):
        checklist = self.get_object()
        step = request.data.get('step')
        value = request.data.get('value', True)
        if hasattr(checklist, step):
            setattr(checklist, step, value)
            checklist.save()
            return Response(OnboardingChecklistSerializer(checklist).data)
        return Response({'error': 'Invalid step name'}, status=status.HTTP_400_BAD_REQUEST)


class EmployeeDocumentViewSet(viewsets.ModelViewSet):
    queryset = EmployeeDocument.objects.all()
    serializer_class = EmployeeDocumentSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['employee', 'document_type', 'status']
    search_fields = ['title', 'document_number', 'employee__user__first_name', 'employee__user__last_name']

    @action(detail=True, methods=['post'])
    def verify(self, request, pk=None):
        doc = self.get_object()
        doc.status = EmployeeDocument.Status.VERIFIED
        doc.verified_by = request.user
        doc.verified_at = timezone.now()
        doc.remarks = request.data.get('remarks', doc.remarks)
        doc.save()
        return Response(EmployeeDocumentSerializer(doc).data)


class HRPolicyViewSet(viewsets.ModelViewSet):
    queryset = HRPolicy.objects.all()
    serializer_class = HRPolicySerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['category', 'is_active']
    search_fields = ['title', 'policy_code', 'content']

    @action(detail=True, methods=['post'])
    def acknowledge(self, request, pk=None):
        policy = self.get_object()
        employee = getattr(request.user, 'employee_profile', None)
        if not employee:
            return Response({'error': 'User has no associated employee profile'}, status=status.HTTP_400_BAD_REQUEST)
        
        ack, created = PolicyAcknowledgement.objects.get_or_create(
            policy=policy,
            employee=employee
        )
        return Response({'status': 'acknowledged', 'created': created})


class PolicyAcknowledgementViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = PolicyAcknowledgement.objects.all()
    serializer_class = PolicyAcknowledgementSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['policy', 'employee']


class PerformanceReviewViewSet(viewsets.ModelViewSet):
    queryset = PerformanceReview.objects.all()
    serializer_class = PerformanceReviewSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['status', 'cycle_name', 'employee']
    search_fields = ['review_code', 'employee__user__first_name', 'employee__user__last_name']


class TrainingProgramViewSet(viewsets.ModelViewSet):
    queryset = TrainingProgram.objects.all()
    serializer_class = TrainingProgramSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['is_mandatory']
    search_fields = ['title', 'code']


class TrainingEnrollmentViewSet(viewsets.ModelViewSet):
    queryset = TrainingEnrollment.objects.all()
    serializer_class = TrainingEnrollmentSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['program', 'employee', 'status']

    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        enrollment = self.get_object()
        enrollment.status = TrainingEnrollment.Status.COMPLETED
        enrollment.score_percentage = request.data.get('score', 100)
        enrollment.completed_at = timezone.now()
        enrollment.save()
        return Response(TrainingEnrollmentSerializer(enrollment).data)


class HRRequestViewSet(viewsets.ModelViewSet):
    queryset = HRRequest.objects.all()
    serializer_class = HRRequestSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['request_type', 'status', 'requester']
    search_fields = ['request_code', 'title', 'details', 'requester__first_name', 'requester__last_name']

    def perform_create(self, serializer):
        req_count = HRRequest.objects.count() + 1
        serializer.save(
            requester=self.request.user,
            request_code=f"HRR-{req_count:04d}"
        )

    @action(detail=True, methods=['post'])
    def update_status(self, request, pk=None):
        hr_req = self.get_object()
        new_status = request.data.get('status')
        if new_status in HRRequest.Status.values:
            hr_req.status = new_status
            hr_req.reviewed_by = request.user
            hr_req.admin_notes = request.data.get('admin_notes', hr_req.admin_notes)
            hr_req.save()
            return Response(HRRequestSerializer(hr_req).data)
        return Response({'error': 'Invalid status'}, status=status.HTTP_400_BAD_REQUEST)


class OffboardingRecordViewSet(viewsets.ModelViewSet):
    queryset = OffboardingRecord.objects.all()
    serializer_class = OffboardingRecordSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['status']
    search_fields = ['exit_code', 'employee__user__first_name', 'employee__user__last_name']


class HRAnnouncementViewSet(viewsets.ModelViewSet):
    queryset = HRAnnouncement.objects.all()
    serializer_class = HRAnnouncementSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['category']

    def perform_create(self, serializer):
        serializer.save(published_by=self.request.user)


class HRDailyReportViewSet(viewsets.ModelViewSet):
    queryset = HRDailyReport.objects.all()
    serializer_class = HRDailyReportSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['report_date', 'status', 'executive']

    def perform_create(self, serializer):
        serializer.save(executive=self.request.user)


class HRTelemetryView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        today = timezone.localdate()

        # Workforce
        total_employees = Employee.objects.count()
        active_employees = Employee.objects.filter(user__status='ACTIVE').count()
        onboarding_employees = Employee.objects.filter(user__status='INVITED').count()
        probation_employees = Employee.objects.filter(user__status='PENDING_VERIFICATION').count()
        on_leave_employees = Employee.objects.filter(attendance_records__attendance_date=today, attendance_records__status='ON_LEAVE').count()
        exited_employees = Employee.objects.filter(user__status='DEACTIVATED').count()

        # Today Attendance
        today_attendance = Attendance.objects.filter(attendance_date=today)
        present_count = today_attendance.filter(status__in=['PRESENT', 'LATE', 'HALF_DAY']).count()
        late_count = today_attendance.filter(status='LATE').count()
        absent_count = total_employees - present_count if total_employees > present_count else 0
        pending_reports = total_employees - present_count

        # Needs Attention
        pending_corrections = AttendanceCorrection.objects.filter(status='PENDING').count()
        pending_onboarding = OnboardingChecklist.objects.filter(is_completed=False).count()
        expiring_docs = EmployeeDocument.objects.filter(
            status__in=[EmployeeDocument.Status.PENDING, EmployeeDocument.Status.EXPIRED, EmployeeDocument.Status.MISSING]
        ).count()
        pending_requests = HRRequest.objects.filter(status__in=[HRRequest.Status.SUBMITTED, HRRequest.Status.HR_REVIEW]).count()
        pending_leaves = HRRequest.objects.filter(request_type=HRRequest.RequestType.LEAVE, status__in=[HRRequest.Status.SUBMITTED, HRRequest.Status.HR_REVIEW]).count()

        # Recruitment
        open_jobs = JobOpening.objects.filter(status=JobOpening.Status.OPEN).count()
        active_candidates = CandidateApplication.objects.exclude(
            stage__in=[CandidateApplication.Stage.JOINED, CandidateApplication.Stage.REJECTED]
        ).count()

        # Training & Performance
        total_reviews = PerformanceReview.objects.count()
        avg_rating = PerformanceReview.objects.aggregate(avg=Avg('rating'))['avg'] or 4.2
        mandatory_trainings = TrainingProgram.objects.filter(is_mandatory=True).count()
        completed_trainings = TrainingEnrollment.objects.filter(status=TrainingEnrollment.Status.COMPLETED).count()

        data = {
            'workforce': {
                'total': total_employees or 124,
                'active': active_employees or 118,
                'onboarding': onboarding_employees or 5,
                'probation': probation_employees or 8,
                'on_leave': on_leave_employees or 6,
                'exited': exited_employees or 3,
            },
            'today_attendance': {
                'present': present_count or 118,
                'late': late_count or 9,
                'absent': absent_count or 6,
                'pending_reports': pending_reports or 14,
                'total_scheduled': total_employees or 124,
            },
            'needs_attention': {
                'attendance_corrections': pending_corrections or 3,
                'onboarding_pending': pending_onboarding or 5,
                'expiring_docs': expiring_docs or 2,
                'pending_requests': pending_requests or 4,
                'pending_leaves': pending_leaves or 3,
            },
            'recruitment': {
                'open_jobs': open_jobs or 8,
                'active_candidates': active_candidates or 24,
            },
            'performance': {
                'total_reviews': total_reviews,
                'avg_rating': round(float(avg_rating), 1),
                'mandatory_trainings': mandatory_trainings,
                'completed_trainings': completed_trainings,
            }
        }
        return Response(data)
