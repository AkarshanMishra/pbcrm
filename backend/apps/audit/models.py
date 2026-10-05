from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from apps.core.models import TimeStampedUUIDModel

class AuditLog(TimeStampedUUIDModel):
    class EventType(models.TextChoices):
        # Auth events
        AUTH_LOGIN_SUCCESS = 'AUTH_LOGIN_SUCCESS', _('User Login Successful')
        AUTH_LOGIN_FAILED = 'AUTH_LOGIN_FAILED', _('User Login Failed')
        AUTH_MFA_FAILED = 'AUTH_MFA_FAILED', _('MFA Verification Failed')
        MFA_ENABLED = 'MFA_ENABLED', _('MFA Enabled')
        MFA_DISABLED = 'MFA_DISABLED', _('MFA Disabled')
        PASSWORD_CHANGED = 'PASSWORD_CHANGED', _('Password Changed')
        PASSWORD_RESET_REQ = 'PASSWORD_RESET_REQ', _('Password Reset Requested')
        
        # Employee & Org events
        EMPLOYEE_CREATED = 'EMPLOYEE_CREATED', _('Employee Created')
        EMPLOYEE_UPDATED = 'EMPLOYEE_UPDATED', _('Employee Profile Updated')
        EMPLOYEE_STATUS_CHANGED = 'EMPLOYEE_STATUS_CHANGED', _('Employee Status Changed')
        POSITION_CHANGED = 'POSITION_CHANGED', _('Employee Position Changed')
        ROLE_CHANGED = 'ROLE_CHANGED', _('Employee Role Changed')
        PERMISSION_CHANGED = 'PERMISSION_CHANGED', _('Role Permissions Changed')
        
        # Attendance events
        ATTENDANCE_CHECKIN = 'ATTENDANCE_CHECKIN', _('Attendance Check-In')
        ATTENDANCE_CHECKOUT = 'ATTENDANCE_CHECKOUT', _('Attendance Check-Out')
        ATTENDANCE_CORRECTION_REQ = 'ATTENDANCE_CORRECTION_REQ', _('Attendance Correction Requested')
        ATTENDANCE_CORRECTION_APPROVED = 'ATTENDANCE_CORRECTION_APPROVED', _('Attendance Correction Approved')
        ATTENDANCE_CORRECTION_REJECTED = 'ATTENDANCE_CORRECTION_REJECTED', _('Attendance Correction Rejected')

        # Session & Device events
        DEVICE_REVOKED = 'DEVICE_REVOKED', _('Device Revoked')
        SESSION_REVOKED = 'SESSION_REVOKED', _('Session Revoked')
        ADMIN_ACTION = 'ADMIN_ACTION', _('Administrative Override')

    actor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='audit_actions',
        verbose_name=_("Actor User")
    )
    event_type = models.CharField(
        _("Event Type"),
        max_length=60,
        choices=EventType.choices,
        db_index=True
    )
    target_model = models.CharField(_("Target Model"), max_length=100, blank=True)
    target_id = models.CharField(_("Target ID / Key"), max_length=255, blank=True)
    ip_address = models.GenericIPAddressField(_("IP Address"), blank=True, null=True)
    user_agent = models.TextField(_("User Agent"), blank=True)
    metadata = models.JSONField(_("Event Metadata / Diff"), default=dict, blank=True)

    class Meta:
        verbose_name = _("Audit Log")
        verbose_name_plural = _("Audit Logs")
        ordering = ['-created_at']

    def __str__(self):
        actor_code = self.actor.employee_code if self.actor else "SYSTEM/ANONYMOUS"
        return f"[{self.created_at.strftime('%Y-%m-%d %H:%M')}] {actor_code} -> {self.event_type}"

    @classmethod
    def log_event(cls, actor, event_type, target_model="", target_id="", request=None, metadata=None):
        ip_addr = None
        ua_str = ""
        if request:
            x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
            ip_addr = x_forwarded_for.split(',')[0].strip() if x_forwarded_for else request.META.get('REMOTE_ADDR')
            ua_str = request.META.get('HTTP_USER_AGENT', '')

        return cls.objects.create(
            actor=actor if (actor and actor.is_authenticated) else None,
            event_type=event_type,
            target_model=target_model,
            target_id=str(target_id),
            ip_address=ip_addr,
            user_agent=ua_str,
            metadata=metadata or {}
        )
