from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    DailyWorkPlanViewSet,
    DailyWorkReportViewSet,
    DailyStandupViewSet,
    WorkDiaryViewSet,
    AnnouncementViewSet
)

router = DefaultRouter()
router.register(r'plans', DailyWorkPlanViewSet, basename='work-plan')
router.register(r'reports', DailyWorkReportViewSet, basename='work-report')
router.register(r'standups', DailyStandupViewSet, basename='daily-standup')
router.register(r'diary', WorkDiaryViewSet, basename='work-diary')
router.register(r'announcements', AnnouncementViewSet, basename='announcement')

urlpatterns = [
    path('', include(router.urls)),
]
