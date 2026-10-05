from datetime import timedelta
from django.utils import timezone
from django.shortcuts import get_object_or_404
from rest_framework import views, status, permissions
from rest_framework.response import Response

from apps.core.permissions import IsAdminUserOnly
from apps.accounts.models import User, UserDevice, UserSession
from apps.audit.models import AuditLog
from apps.audit.serializers import AuditLogSerializer

class SecurityDashboardMetricsView(views.APIView):
    """
    Returns high-level security metrics matching Screen #24 (Security Center):
    - Failed Logins (24h)
    - Locked Accounts
    - Active Sessions
    - New Devices (7d)
    - Password Resets (7d)
    - Recent Security Events
    """
    permission_classes = [permissions.IsAuthenticated, IsAdminUserOnly]

    def get(self, request):
        now = timezone.now()
        day_ago = now - timedelta(days=1)
        week_ago = now - timedelta(days=7)

        failed_logins_24h = AuditLog.objects.filter(
            event_type__in=[
                AuditLog.EventType.AUTH_LOGIN_FAILED,
                AuditLog.EventType.AUTH_MFA_FAILED
            ],
            created_at__gte=day_ago
        ).count()

        locked_accounts_count = User.objects.filter(
            models_locked_filter(now)
        ).count()

        active_sessions_count = UserSession.objects.filter(
            is_active=True,
            expires_at__gt=now
        ).count()

        new_devices_7d = UserDevice.objects.filter(
            created_at__gte=week_ago,
            is_revoked=False
        ).count()

        password_resets_7d = AuditLog.objects.filter(
            event_type__in=[
                AuditLog.EventType.PASSWORD_CHANGED,
                AuditLog.EventType.PASSWORD_RESET_REQ
            ],
            created_at__gte=week_ago
        ).count()

        recent_events = AuditLog.objects.filter(
            event_type__in=[
                AuditLog.EventType.AUTH_LOGIN_FAILED,
                AuditLog.EventType.AUTH_MFA_FAILED,
                AuditLog.EventType.MFA_ENABLED,
                AuditLog.EventType.EMPLOYEE_STATUS_CHANGED,
                AuditLog.EventType.POSITION_CHANGED,
                AuditLog.EventType.ATTENDANCE_CORRECTION_APPROVED,
                AuditLog.EventType.DEVICE_REVOKED,
                AuditLog.EventType.SESSION_REVOKED
            ]
        ).select_related('actor')[:10]

        return Response({
            'success': True,
            'metrics': {
                'failed_logins_24h': failed_logins_24h,
                'locked_accounts': locked_accounts_count,
                'active_sessions': active_sessions_count,
                'new_devices_7d': new_devices_7d,
                'password_resets_7d': password_resets_7d,
            },
            'recent_security_events': AuditLogSerializer(recent_events, many=True).data
        })


def models_locked_filter(now):
    from django.db.models import Q
    return Q(status=User.AccountStatus.LOCKED) | Q(locked_until__gt=now)


class UnlockUserAccountView(views.APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminUserOnly]

    def post(self, request, user_id):
        user = get_object_or_404(User, id=user_id)
        user.status = User.AccountStatus.ACTIVE
        user.failed_login_attempts = 0
        user.locked_until = None
        user.is_active = True
        user.save()

        AuditLog.log_event(
            actor=request.user,
            event_type=AuditLog.EventType.ADMIN_ACTION,
            target_model='User',
            target_id=str(user.id),
            request=request,
            metadata={'action': 'Admin manually unlocked user account', 'unlocked_user': user.employee_code}
        )

        return Response({
            'success': True,
            'message': f"Account for employee {user.employee_code} ({user.email}) has been successfully unlocked."
        })


class ForceRevokeUserSessionsView(views.APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminUserOnly]

    def post(self, request, user_id):
        user = get_object_or_404(User, id=user_id)
        revoked_sessions = UserSession.objects.filter(user=user, is_active=True).update(is_active=False)
        revoked_devices = UserDevice.objects.filter(user=user, is_revoked=False).update(is_revoked=True)

        AuditLog.log_event(
            actor=request.user,
            event_type=AuditLog.EventType.ADMIN_ACTION,
            target_model='User',
            target_id=str(user.id),
            request=request,
            metadata={
                'action': 'Force revoked all sessions and devices',
                'target_employee': user.employee_code,
                'sessions_revoked': revoked_sessions,
                'devices_revoked': revoked_devices
            }
        )

        return Response({
            'success': True,
            'message': f"Force revoked {revoked_sessions} session(s) and {revoked_devices} device(s) for {user.employee_code}."
        })
