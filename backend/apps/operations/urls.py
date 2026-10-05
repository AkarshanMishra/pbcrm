from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    BookingOperationViewSet, EventReadinessChecklistViewSet,
    OperationsIssueViewSet, QualityInspectionViewSet,
    OperationalAssetViewSet, OperationsRequestViewSet,
    OperationsDailyReportViewSet, OperationsManagerOverviewView
)

router = DefaultRouter()
router.register(r'bookings', BookingOperationViewSet, basename='operations-booking')
router.register(r'checklists', EventReadinessChecklistViewSet, basename='operations-checklist')
router.register(r'issues', OperationsIssueViewSet, basename='operations-issue')
router.register(r'inspections', QualityInspectionViewSet, basename='operations-inspection')
router.register(r'assets', OperationalAssetViewSet, basename='operations-asset')
router.register(r'requests', OperationsRequestViewSet, basename='operations-request')
router.register(r'daily-reports', OperationsDailyReportViewSet, basename='operations-daily-report')

urlpatterns = [
    path('manager-overview/', OperationsManagerOverviewView.as_view(), name='operations-manager-overview'),
    path('', include(router.urls)),
]
