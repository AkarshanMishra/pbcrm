import pyotp
import qrcode
import io
import base64
import secrets
from datetime import datetime, timedelta, timezone as dt_timezone
from django.utils import timezone
from django.conf import settings
from django.contrib.auth.hashers import make_password, check_password
from rest_framework import views, generics, status, permissions
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken, AccessToken
from rest_framework_simplejwt.token_blacklist.models import OutstandingToken, BlacklistedToken

from apps.core.permissions import IsAdminUserOnly
from apps.audit.models import AuditLog
from .models import User, UserDevice, UserSession, MFASetting, RecoveryCode
from .serializers import (
    LoginSerializer,
    MFAVerifySerializer,
    PasswordChangeSerializer,
    UserDeviceSerializer,
    UserSessionSerializer,
    DeviceInfoSerializer
)

def get_client_ip(request):
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        return x_forwarded_for.split(',')[0].strip()
    return request.META.get('REMOTE_ADDR')

def register_user_device_and_session(user, request, device_info, refresh_token):
    ip_addr = get_client_ip(request)
    user_agent = request.META.get('HTTP_USER_AGENT', '')
    
    device = None
    if device_info and device_info.get('device_id'):
        device, _ = UserDevice.objects.update_or_create(
            user=user,
            device_id=device_info['device_id'],
            defaults={
                'device_name': device_info.get('device_name', 'Mobile Device'),
                'device_type': device_info.get('device_type', UserDevice.DeviceType.ANDROID),
                'os_version': device_info.get('os_version', ''),
                'app_version': device_info.get('app_version', ''),
                'push_token': device_info.get('push_token', ''),
                'is_revoked': False,
                'last_active_at': timezone.now()
            }
        )

    # Decode refresh token jti
    jti = refresh_token.get('jti')
    exp_timestamp = refresh_token.get('exp')
    expires_at = datetime.fromtimestamp(exp_timestamp, tz=dt_timezone.utc) if exp_timestamp else timezone.now() + timedelta(days=7)

    session = UserSession.objects.create(
        user=user,
        device=device,
        refresh_token_jti=jti,
        ip_address=ip_addr,
        user_agent=user_agent,
        expires_at=expires_at
    )
    return device, session


class LoginView(views.APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data['user']
        device_info = serializer.validated_data.get('device_info')
        ip_addr = get_client_ip(request)

        # Require MFA only if user has activated and verified MFA setup
        must_use_mfa = user.is_mfa_enabled and hasattr(user, 'mfa_setting') and user.mfa_setting.is_verified

        if must_use_mfa:
            # Issue short-lived MFA challenge token (valid for 5 mins)
            mfa_refresh = RefreshToken.for_user(user)
            mfa_refresh['mfa_pending'] = True
            mfa_token = str(mfa_refresh.access_token)

            return Response({
                'success': True,
                'mfa_required': True,
                'mfa_token': mfa_token,
                'message': 'Multi-Factor Authentication required. Enter verification code.'
            })

        # Login success without MFA
        user.failed_login_attempts = 0
        user.last_login_ip = ip_addr
        user.last_login = timezone.now()
        user.save(update_fields=['failed_login_attempts', 'last_login_ip', 'last_login'])

        refresh = RefreshToken.for_user(user)
        device, session = register_user_device_and_session(user, request, device_info, refresh)

        AuditLog.log_event(
            actor=user,
            event_type=AuditLog.EventType.AUTH_LOGIN_SUCCESS,
            target_model='User',
            target_id=str(user.id),
            request=request,
            metadata={'device_id': device_info.get('device_id') if device_info else 'Unknown'}
        )

        return Response({
            'success': True,
            'mfa_required': False,
            'access_token': str(refresh.access_token),
            'refresh_token': str(refresh),
            'user': self._build_user_payload(user)
        })

    def _build_user_payload(self, user):
        permissions_list = []
        name = user.email.split('@')[0] if user.email else user.employee_code
        if hasattr(user, 'employee_profile') and user.employee_profile:
            if user.employee_profile.first_name or user.employee_profile.last_name:
                name = f"{user.employee_profile.first_name} {user.employee_profile.last_name}".strip()
            if user.employee_profile.role:
                permissions_list = list(user.employee_profile.role.role_permissions.values_list('permission__code', flat=True))

        return {
            'id': str(user.id),
            'employee_code': user.employee_code,
            'email': user.email,
            'name': name,
            'status': user.status,
            'is_mfa_enabled': user.is_mfa_enabled,
            'is_admin': user.is_admin_role,
            'is_manager': user.is_manager_role,
            'role': user.employee_profile.role.code if hasattr(user, 'employee_profile') and user.employee_profile.role else None,
            'department': user.employee_profile.department.name if hasattr(user, 'employee_profile') and user.employee_profile.department else None,
            'position': user.employee_profile.position.title if hasattr(user, 'employee_profile') and user.employee_profile.position else None,
            'permissions': permissions_list
        }


class MFAVerifyView(views.APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = MFAVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        mfa_token = serializer.validated_data['mfa_token']
        code = serializer.validated_data['code'].strip()
        device_info = serializer.validated_data.get('device_info')

        try:
            token_obj = AccessToken(mfa_token)
            user_id = token_obj['user_id']
            user = User.objects.get(id=user_id)
        except Exception:
            return Response({'success': False, 'message': 'Invalid or expired MFA token.'}, status=status.HTTP_401_UNAUTHORIZED)

        # Verify Code: Check TOTP first
        mfa_setting = getattr(user, 'mfa_setting', None)
        verified = False

        if mfa_setting and mfa_setting.totp_secret:
            totp = pyotp.TOTP(mfa_setting.totp_secret)
            if totp.verify(code, valid_window=1):
                verified = True
                mfa_setting.last_used_at = timezone.now()
                mfa_setting.save(update_fields=['last_used_at'])

        # If not verified via TOTP, check Recovery Codes
        if not verified:
            recovery_codes = RecoveryCode.objects.filter(user=user, is_used=False)
            for rec in recovery_codes:
                if check_password(code, rec.code_hash):
                    rec.is_used = True
                    rec.used_at = timezone.now()
                    rec.save(update_fields=['is_used', 'used_at'])
                    verified = True
                    break

        if not verified:
            AuditLog.log_event(
                actor=user,
                event_type=AuditLog.EventType.AUTH_MFA_FAILED,
                target_model='User',
                target_id=str(user.id),
                request=request
            )
            return Response({'success': False, 'message': 'Invalid verification code.'}, status=status.HTTP_400_BAD_REQUEST)

        # MFA Success
        user.failed_login_attempts = 0
        user.last_login_ip = get_client_ip(request)
        user.last_login = timezone.now()
        user.save(update_fields=['failed_login_attempts', 'last_login_ip', 'last_login'])

        refresh = RefreshToken.for_user(user)
        device, session = register_user_device_and_session(user, request, device_info, refresh)

        AuditLog.log_event(
            actor=user,
            event_type=AuditLog.EventType.AUTH_LOGIN_SUCCESS,
            target_model='User',
            target_id=str(user.id),
            request=request,
            metadata={'mfa_verified': True}
        )

        return Response({
            'success': True,
            'access_token': str(refresh.access_token),
            'refresh_token': str(refresh),
            'user': LoginView()._build_user_payload(user)
        })


class MFASetupView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        secret = pyotp.random_base32()
        issuer = getattr(settings, 'MFA_ISSUER_NAME', 'PCRM_Enterprise')
        totp_uri = pyotp.totp.TOTP(secret).provisioning_uri(name=user.email, issuer_name=issuer)

        # Generate QR code in base64
        qr = qrcode.QRCode(box_size=8, border=2)
        qr.add_data(totp_uri)
        qr.make(fit=True)
        img = qr.make_image(fill_color="black", back_color="white")
        buffered = io.BytesIO()
        img.save(buffered, format="PNG")
        qr_base64 = base64.b64encode(buffered.getvalue()).decode('utf-8')

        # Store pending secret in session/db
        MFASetting.objects.update_or_create(
            user=user,
            defaults={'totp_secret': secret, 'is_verified': False}
        )

        return Response({
            'success': True,
            'secret': secret,
            'qr_code_base64': f"data:image/png;base64,{qr_base64}",
            'otpauth_url': totp_uri
        })


class MFAConfirmView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        user = request.user
        code = request.data.get('code', '').strip()
        mfa_setting = MFASetting.objects.filter(user=user).first()

        if not mfa_setting or not mfa_setting.totp_secret:
            return Response({'success': False, 'message': 'MFA setup has not been initiated.'}, status=status.HTTP_400_BAD_REQUEST)

        totp = pyotp.TOTP(mfa_setting.totp_secret)
        if not totp.verify(code, valid_window=1):
            return Response({'success': False, 'message': 'Invalid OTP code. Ensure device clock is synced.'}, status=status.HTTP_400_BAD_REQUEST)

        # Activate MFA
        mfa_setting.is_verified = True
        mfa_setting.save()
        user.is_mfa_enabled = True
        user.save(update_fields=['is_mfa_enabled'])

        # Generate 8 single-use plain recovery codes for user backup
        raw_recovery_codes = []
        RecoveryCode.objects.filter(user=user).delete()
        recovery_objs = []
        for _ in range(8):
            raw_code = secrets.token_hex(4).upper()  # e.g. "A1B2-C3D4"
            formatted_code = f"{raw_code[:4]}-{raw_code[4:]}"
            raw_recovery_codes.append(formatted_code)
            recovery_objs.append(RecoveryCode(
                user=user,
                code_hash=make_password(formatted_code)
            ))
        RecoveryCode.objects.bulk_create(recovery_objs)

        AuditLog.log_event(
            actor=user,
            event_type=AuditLog.EventType.MFA_ENABLED,
            target_model='User',
            target_id=str(user.id),
            request=request
        )

        return Response({
            'success': True,
            'message': 'MFA successfully enabled.',
            'recovery_codes': raw_recovery_codes
        })


class PasswordChangeView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = PasswordChangeSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)

        user = request.user
        new_password = serializer.validated_data['new_password']
        user.set_password(new_password)
        user.save()

        # Invalidate other user sessions
        UserSession.objects.filter(user=user).update(is_active=False)

        AuditLog.log_event(
            actor=user,
            event_type=AuditLog.EventType.PASSWORD_CHANGED,
            target_model='User',
            target_id=str(user.id),
            request=request
        )

        return Response({
            'success': True,
            'message': 'Password updated successfully. All other active sessions have been terminated.'
        })


class DeviceListView(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = UserDeviceSerializer

    def get_queryset(self):
        return UserDevice.objects.filter(user=self.request.user, is_revoked=False)


class RevokeDeviceView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        device = UserDevice.objects.filter(user=request.user, pk=pk).first()
        if not device:
            return Response({'success': False, 'message': 'Device not found.'}, status=status.HTTP_404_NOT_FOUND)

        device.is_revoked = True
        device.save(update_fields=['is_revoked'])

        # Terminate associated sessions
        UserSession.objects.filter(user=request.user, device=device).update(is_active=False)

        AuditLog.log_event(
            actor=request.user,
            event_type=AuditLog.EventType.DEVICE_REVOKED,
            target_model='UserDevice',
            target_id=str(device.id),
            request=request,
            metadata={'device_name': device.device_name}
        )

        return Response({'success': True, 'message': f"Device '{device.device_name}' revoked successfully."})


class SessionListView(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = UserSessionSerializer

    def get_queryset(self):
        return UserSession.objects.filter(user=self.request.user, is_active=True).select_related('device')

    def get_serializer_context(self):
        context = super().get_serializer_context()
        token = self.request.auth
        if hasattr(token, 'payload'):
            context['current_jti'] = token.payload.get('jti')
        return context


class RevokeAllOtherSessionsView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        token = request.auth
        current_jti = token.payload.get('jti') if hasattr(token, 'payload') else None

        qs = UserSession.objects.filter(user=request.user, is_active=True)
        if current_jti:
            qs = qs.exclude(refresh_token_jti=current_jti)
        revoked_count = qs.update(is_active=False)

        AuditLog.log_event(
            actor=request.user,
            event_type=AuditLog.EventType.SESSION_REVOKED,
            target_model='UserSession',
            target_id=str(request.user.id),
            request=request,
            metadata={'revoked_count': revoked_count}
        )

        return Response({
            'success': True,
            'message': f"Terminated {revoked_count} other active session(s)."
        })


class UserProfileView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response({
            'success': True,
            'user': LoginView()._build_user_payload(request.user)
        })
