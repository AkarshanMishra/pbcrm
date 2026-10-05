from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    BatchSyncAPIView,
    HeartbeatAPIView,
    SyncStatusAPIView,
    SyncConflictsViewSet,
    AdminSyncHealthAPIView,
    AdminDeviceViewSet
)

router = DefaultRouter()
router.register(r'conflicts', SyncConflictsViewSet, basename='sync-conflicts')
router.register(r'admin/devices', AdminDeviceViewSet, basename='admin-sync-devices')

urlpatterns = [
    path('batch/', BatchSyncAPIView.as_view(), name='sync-batch'),
    path('heartbeat/', HeartbeatAPIView.as_view(), name='sync-heartbeat'),
    path('status/', SyncStatusAPIView.as_view(), name='sync-status'),
    path('admin/health/', AdminSyncHealthAPIView.as_view(), name='admin-sync-health'),
    path('', include(router.urls)),
]
