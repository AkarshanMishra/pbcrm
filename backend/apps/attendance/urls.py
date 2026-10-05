from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    CheckInView,
    CheckOutView,
    TodayStatusView,
    AttendanceViewSet,
    AttendanceCorrectionViewSet
)

router = DefaultRouter()
router.register(r'records', AttendanceViewSet, basename='attendance-records')
router.register(r'corrections', AttendanceCorrectionViewSet, basename='attendance-corrections')

urlpatterns = [
    path('check-in/', CheckInView.as_view(), name='attendance-check-in'),
    path('check-out/', CheckOutView.as_view(), name='attendance-check-out'),
    path('today/', TodayStatusView.as_view(), name='attendance-today'),
    path('', include(router.urls)),
]
