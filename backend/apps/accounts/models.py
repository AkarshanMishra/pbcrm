import uuid
import secrets
from django.db import models
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager
from django.utils.translation import gettext_lazy as _
from django.utils import timezone
from apps.core.models import TimeStampedUUIDModel
from apps.organization.models import Role, Permission

class UserManager(BaseUserManager):
    def create_user(self, email, employee_code, password=None, **extra_fields):
        if not email:
            raise ValueError(_("The Email field must be set."))
        if not employee_code:
            raise ValueError(_("The Employee Code field must be set."))

        email = self.normalize_email(email)
        user = self.model(email=email, employee_code=employee_code, **extra_fields)
        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()
        user.save(using=self._db)
        return user

    def create_superuser(self, email, employee_code, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('status', User.AccountStatus.ACTIVE)

        if extra_fields.get('is_staff') is not True:
            raise ValueError(_("Superuser must have is_staff=True."))
        if extra_fields.get('is_superuser') is not True:
            raise ValueError(_("Superuser must have is_superuser=True."))

        return self.create_user(email, employee_code, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin, TimeStampedUUIDModel):
    class AccountStatus(models.TextChoices):
        ACTIVE = 'ACTIVE', _('Active')
        INVITED = 'INVITED', _('Invited / Unverified')
        PENDING_VERIFICATION = 'PENDING_VERIFICATION', _('Pending Verification')
        SUSPENDED = 'SUSPENDED', _('Suspended')
        LOCKED = 'LOCKED', _('Locked (Failed Logins)')
        DEACTIVATED = 'DEACTIVATED', _('Deactivated / Offboarded')

    email = models.EmailField(_("Email Address"), unique=True, db_index=True)
    employee_code = models.CharField(_("Employee Code"), max_length=20, unique=True, db_index=True)
    phone = models.CharField(_("Phone Number"), max_length=25, blank=True, null=True)

    status = models.CharField(
        _("Account Status"),
        max_length=30,
        choices=AccountStatus.choices,
        default=AccountStatus.ACTIVE,
        db_index=True
    )

    is_staff = models.BooleanField(_("Staff Status"), default=False)
    is_active = models.BooleanField(_("Is Active"), default=True)
    is_mfa_enabled = models.BooleanField(_("MFA Enabled"), default=False)

    failed_login_attempts = models.PositiveIntegerField(_("Failed Login Attempts"), default=0)
    locked_until = models.DateTimeField(_("Locked Until"), blank=True, null=True)
    last_login_ip = models.GenericIPAddressField(_("Last Login IP"), blank=True, null=True)
    password_changed_at = models.DateTimeField(_("Password Changed At"), default=timezone.now)

    objects = UserManager()

    USERNAME_FIELD = 'employee_code'
    REQUIRED_FIELDS = ['email']

    class Meta:
        verbose_name = _("User")
        verbose_name_plural = _("Users")
        ordering = ['employee_code']

    def __str__(self):
        return f"{self.employee_code} ({self.email})"

    @property
    def is_locked(self):
        if self.status == self.AccountStatus.LOCKED:
            if self.locked_until and self.locked_until > timezone.now():
                return True
        return False

    @property
    def role(self):
        if hasattr(self, 'employee_profile') and self.employee_profile.role:
            return self.employee_profile.role
        return None

    @property
    def is_admin(self):
        return self.is_admin_role

    @property
    def is_admin_role(self):
        if self.is_superuser:
            return True
        if self.role and self.role.code == Role.RoleCode.ADMIN:
            return True
        return False

    @property
    def is_manager_role(self):
        if hasattr(self, 'employee_profile'):
            # Any employee who has subordinates or has position title containing Manager
            return self.employee_profile.direct_reports.exists() or 'manager' in self.employee_profile.position.title.lower() if self.employee_profile.position else False
        return False

    def get_full_name(self):
        if hasattr(self, 'employee_profile'):
            return self.employee_profile.full_name
        return self.employee_code

    def get_short_name(self):
        if hasattr(self, 'employee_profile'):
            return self.employee_profile.first_name
        return self.employee_code

    def has_permission_code(self, permission_code):
        if self.is_superuser or self.is_admin_role:
            return True
        if not self.role:
            return False
        return Permission.objects.filter(
            permission_roles__role=self.role,
            code=permission_code
        ).exists()


class PasswordHistory(TimeStampedUUIDModel):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='password_histories')
    password_hash = models.CharField(max_length=255)

    class Meta:
        verbose_name = _("Password History")
        verbose_name_plural = _("Password Histories")
        ordering = ['-created_at']


class UserDevice(TimeStampedUUIDModel):
    class DeviceType(models.TextChoices):
        ANDROID = 'ANDROID', _('Android Phone / Tablet')
        IOS = 'IOS', _('iPhone / iPad')
        WEB = 'WEB', _('Web Browser')
        OTHER = 'OTHER', _('Other Device')

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='devices')
    device_id = models.CharField(_("Device Fingerprint ID"), max_length=255, db_index=True)
    device_name = models.CharField(_("Device Model/Name"), max_length=150)
    device_type = models.CharField(_("Device Type"), max_length=20, choices=DeviceType.choices, default=DeviceType.ANDROID)
    os_version = models.CharField(_("OS Version"), max_length=50, blank=True)
    app_version = models.CharField(_("App Version"), max_length=30, blank=True)
    push_token = models.TextField(_("FCM Push Token"), blank=True, null=True)
    is_trusted = models.BooleanField(_("Trusted Device"), default=True)
    is_revoked = models.BooleanField(_("Is Revoked"), default=False)
    last_active_at = models.DateTimeField(_("Last Active Timestamp"), default=timezone.now)

    class Meta:
        verbose_name = _("User Device")
        verbose_name_plural = _("User Devices")
        unique_together = ('user', 'device_id')
        ordering = ['-last_active_at']

    def __str__(self):
        return f"{self.user.employee_code} - {self.device_name} ({self.device_type})"


class UserSession(TimeStampedUUIDModel):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sessions')
    device = models.ForeignKey(UserDevice, on_delete=models.SET_NULL, null=True, blank=True, related_name='sessions')
    refresh_token_jti = models.CharField(_("JWT JTI Token Identifier"), max_length=255, unique=True, db_index=True)
    ip_address = models.GenericIPAddressField(_("IP Address"), blank=True, null=True)
    user_agent = models.TextField(_("User Agent String"), blank=True)
    is_active = models.BooleanField(_("Session Active"), default=True)
    last_activity = models.DateTimeField(_("Last Activity"), default=timezone.now)
    expires_at = models.DateTimeField(_("Expiration Timestamp"))

    class Meta:
        verbose_name = _("User Session")
        verbose_name_plural = _("User Sessions")
        ordering = ['-last_activity']

    def __str__(self):
        return f"Session {self.user.employee_code} [{self.ip_address}]"


class MFASetting(TimeStampedUUIDModel):
    class MFAMethod(models.TextChoices):
        TOTP = 'TOTP', _('Authenticator App (TOTP)')
        EMAIL = 'EMAIL', _('Email Verification Code')

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='mfa_setting')
    method = models.CharField(_("MFA Method"), max_length=20, choices=MFAMethod.choices, default=MFAMethod.TOTP)
    totp_secret = models.CharField(_("TOTP Secret Key"), max_length=64, blank=True)
    is_verified = models.BooleanField(_("MFA Verified"), default=False)
    last_used_at = models.DateTimeField(_("Last Used Timestamp"), blank=True, null=True)

    class Meta:
        verbose_name = _("MFA Setting")
        verbose_name_plural = _("MFA Settings")

    def __str__(self):
        return f"MFA ({self.method}) for {self.user.employee_code}"


class RecoveryCode(TimeStampedUUIDModel):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='recovery_codes')
    code_hash = models.CharField(_("Hashed Recovery Code"), max_length=255)
    is_used = models.BooleanField(_("Is Code Used"), default=False)
    used_at = models.DateTimeField(_("Used Timestamp"), blank=True, null=True)

    class Meta:
        verbose_name = _("Recovery Code")
        verbose_name_plural = _("Recovery Codes")
