import pyotp
from rest_framework import serializers
from django.contrib.auth import authenticate
from django.utils import timezone
from django.utils.translation import gettext_lazy as _
from django.contrib.auth.password_validation import validate_password
from rest_framework_simplejwt.tokens import RefreshToken
from .models import User, UserDevice, UserSession, MFASetting, RecoveryCode

class DeviceInfoSerializer(serializers.Serializer):
    device_id = serializers.CharField(max_length=255)
    device_name = serializers.CharField(max_length=150, default='Mobile Device')
    device_type = serializers.ChoiceField(choices=UserDevice.DeviceType.choices, default=UserDevice.DeviceType.ANDROID)
    os_version = serializers.CharField(max_length=50, required=False, default='')
    app_version = serializers.CharField(max_length=30, required=False, default='1.0.0')
    push_token = serializers.CharField(required=False, allow_blank=True, default='')


class LoginSerializer(serializers.Serializer):
    identifier = serializers.CharField(
        help_text=_("Employee ID (e.g. PBE000001) or Email Address")
    )
    password = serializers.CharField(
        write_only=True,
        style={'input_type': 'password'}
    )
    device_info = DeviceInfoSerializer(required=False)

    def validate(self, attrs):
        identifier = attrs.get('identifier', '').strip()
        password = attrs.get('password')

        # Find user by employee_code or email
        user = User.objects.filter(models_Q_match(identifier)).first()
        
        if not user:
            raise serializers.ValidationError(_("Invalid credentials provided."))

        if user.status == User.AccountStatus.DEACTIVATED:
            raise serializers.ValidationError(_("This account has been deactivated. Contact Admin."))

        if user.status == User.AccountStatus.SUSPENDED:
            raise serializers.ValidationError(_("This account is currently suspended. Contact HR."))

        if user.is_locked:
            minutes_left = int((user.locked_until - timezone.now()).total_seconds() / 60) + 1
            raise serializers.ValidationError(
                _(f"Account is temporarily locked due to excessive failed logins. Try again in {minutes_left} minutes.")
            )

        if not user.check_password(password):
            user.failed_login_attempts += 1
            if user.failed_login_attempts >= 5:
                user.status = User.AccountStatus.LOCKED
                user.locked_until = timezone.now() + timezone.timedelta(minutes=15)
                user.save(update_fields=['failed_login_attempts', 'status', 'locked_until'])
                raise serializers.ValidationError(
                    _("Account locked due to 5 consecutive failed login attempts. Locked for 15 minutes.")
                )
            user.save(update_fields=['failed_login_attempts'])
            raise serializers.ValidationError(_("Invalid credentials provided."))

        attrs['user'] = user
        return attrs


def models_Q_match(identifier):
    from django.db.models import Q
    return Q(employee_code__iexact=identifier) | Q(email__iexact=identifier)


class MFAVerifySerializer(serializers.Serializer):
    mfa_token = serializers.CharField(help_text="Temporary MFA session token")
    code = serializers.CharField(max_length=16, help_text="6-digit TOTP or 10-char Recovery code")
    device_info = DeviceInfoSerializer(required=False)


class PasswordChangeSerializer(serializers.Serializer):
    old_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(write_only=True)
    confirm_new_password = serializers.CharField(write_only=True)

    def validate_old_password(self, value):
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError(_("Current password is incorrect."))
        return value

    def validate(self, attrs):
        if attrs['new_password'] != attrs['confirm_new_password']:
            raise serializers.ValidationError({"confirm_new_password": _("New passwords do not match.")})
        validate_password(attrs['new_password'], self.context['request'].user)
        return attrs


class UserDeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserDevice
        fields = ['id', 'device_id', 'device_name', 'device_type', 'os_version', 'app_version', 'is_trusted', 'is_revoked', 'last_active_at', 'created_at']


class UserSessionSerializer(serializers.ModelSerializer):
    device_name = serializers.CharField(source='device.device_name', read_only=True)
    device_type = serializers.CharField(source='device.device_type', read_only=True)
    is_current = serializers.SerializerMethodField()

    class Meta:
        model = UserSession
        fields = ['id', 'device_name', 'device_type', 'ip_address', 'user_agent', 'is_active', 'last_activity', 'is_current']

    def get_is_current(self, obj):
        current_jti = self.context.get('current_jti')
        return obj.refresh_token_jti == current_jti
