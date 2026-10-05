from django.urls import path
from .views import (
    SecurityDashboardMetricsView,
    UnlockUserAccountView,
    ForceRevokeUserSessionsView
)

urlpatterns = [
    path('metrics/', SecurityDashboardMetricsView.as_view(), name='security-metrics'),
    path('users/<uuid:user_id>/unlock/', UnlockUserAccountView.as_view(), name='security-unlock-user'),
    path('users/<uuid:user_id>/revoke-all/', ForceRevokeUserSessionsView.as_view(), name='security-revoke-all'),
]
