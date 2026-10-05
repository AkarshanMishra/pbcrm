from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    JobOpeningViewSet,
    CandidateApplicationViewSet,
    OnboardingChecklistViewSet,
    EmployeeDocumentViewSet,
    HRPolicyViewSet,
    PolicyAcknowledgementViewSet,
    PerformanceReviewViewSet,
    TrainingProgramViewSet,
    TrainingEnrollmentViewSet,
    HRRequestViewSet,
    OffboardingRecordViewSet,
    HRAnnouncementViewSet,
    HRDailyReportViewSet,
    HRTelemetryView,
)

router = DefaultRouter()
router.register(r'jobs', JobOpeningViewSet)
router.register(r'candidates', CandidateApplicationViewSet)
router.register(r'onboarding', OnboardingChecklistViewSet)
router.register(r'documents', EmployeeDocumentViewSet)
router.register(r'policies', HRPolicyViewSet)
router.register(r'acknowledgements', PolicyAcknowledgementViewSet)
router.register(r'reviews', PerformanceReviewViewSet)
router.register(r'training-programs', TrainingProgramViewSet)
router.register(r'training-enrollments', TrainingEnrollmentViewSet)
router.register(r'requests', HRRequestViewSet)
router.register(r'offboarding', OffboardingRecordViewSet)
router.register(r'announcements', HRAnnouncementViewSet)
router.register(r'daily-reports', HRDailyReportViewSet)

urlpatterns = [
    path('telemetry/', HRTelemetryView.as_view(), name='hr-telemetry'),
    path('', include(router.urls)),
]
