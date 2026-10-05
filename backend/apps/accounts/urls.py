from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    LoginView,
    MFAVerifyView,
    MFASetupView,
    MFAConfirmView,
    PasswordChangeView,
    DeviceListView,
    RevokeDeviceView,
    SessionListView,
    RevokeAllOtherSessionsView,
    UserProfileView
)

urlpatterns = [
    path('login/', LoginView.as_view(), name='login'),
    path('mfa/verify/', MFAVerifyView.as_view(), name='mfa-verify'),
    path('mfa/setup/', MFASetupView.as_view(), name='mfa-setup'),
    path('mfa/confirm/', MFAConfirmView.as_view(), name='mfa-confirm'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),
    path('profile/', UserProfileView.as_view(), name='user-profile'),
    path('password/change/', PasswordChangeView.as_view(), name='password-change'),
    path('devices/', DeviceListView.as_view(), name='device-list'),
    path('devices/<uuid:pk>/revoke/', RevokeDeviceView.as_view(), name='device-revoke'),
    path('sessions/', SessionListView.as_view(), name='session-list'),
    path('sessions/revoke-others/', RevokeAllOtherSessionsView.as_view(), name='session-revoke-others'),
]
