from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    LeadViewSet,
    VisitViewSet,
    FollowUpViewSet,
    PartnerOnboardingViewSet,
    MarketingDailyReportViewSet,
    MarketingTelemetryView,
)

router = DefaultRouter()
router.register(r'leads', LeadViewSet, basename='marketing-leads')
router.register(r'visits', VisitViewSet, basename='marketing-visits')
router.register(r'followups', FollowUpViewSet, basename='marketing-followups')
router.register(r'onboardings', PartnerOnboardingViewSet, basename='marketing-onboardings')
router.register(r'reports', MarketingDailyReportViewSet, basename='marketing-reports')

urlpatterns = [
    path('telemetry/', MarketingTelemetryView.as_view(), name='marketing-telemetry'),
    path('', include(router.urls)),
]
