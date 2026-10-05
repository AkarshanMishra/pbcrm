from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    SystemComponentViewSet, ITIncidentViewSet, PullRequestViewSet,
    DeploymentRecordViewSet, ITAssetViewSet, ITAccessRequestViewSet,
    KnowledgeArticleViewSet, ITDailyReportViewSet, ITTelemetryView
)

router = DefaultRouter()
router.register('systems', SystemComponentViewSet, basename='it-system')
router.register('incidents', ITIncidentViewSet, basename='it-incident')
router.register('pull-requests', PullRequestViewSet, basename='it-pr')
router.register('deployments', DeploymentRecordViewSet, basename='it-deploy')
router.register('assets', ITAssetViewSet, basename='it-asset')
router.register('access-requests', ITAccessRequestViewSet, basename='it-access-req')
router.register('knowledge-base', KnowledgeArticleViewSet, basename='it-kb')
router.register('daily-reports', ITDailyReportViewSet, basename='it-daily-report')

urlpatterns = [
    path('telemetry/', ITTelemetryView.as_view(), name='it-telemetry'),
    path('', include(router.urls)),
]
