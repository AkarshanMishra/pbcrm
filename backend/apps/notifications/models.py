from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from django.utils import timezone
from apps.core.models import TimeStampedUUIDModel

class Notification(TimeStampedUUIDModel):
    class NotificationType(models.TextChoices):
        TASK_ASSIGNED = 'TASK_ASSIGNED', _('New Task Assigned')
        TASK_UPDATED = 'TASK_UPDATED', _('Task Updated')
        TASK_DEADLINE = 'TASK_DEADLINE', _('Task Deadline Approaching')
        TASK_OVERDUE = 'TASK_OVERDUE', _('Task Overdue')
        TASK_BLOCKED = 'TASK_BLOCKED', _('Task Blocked - Action Required')
        TASK_SUBMITTED = 'TASK_SUBMITTED', _('Task Submitted for Review')
        TASK_APPROVED = 'TASK_APPROVED', _('Task Approved')
        TASK_REJECTED = 'TASK_REJECTED', _('Task Changes Requested')
        REPORT_REMINDER = 'REPORT_REMINDER', _('Daily Work Report Reminder')
        REPORT_SUBMITTED = 'REPORT_SUBMITTED', _('Daily Work Report Submitted')
        REPORT_CHANGES_REQUESTED = 'REPORT_CHANGES_REQUESTED', _('Report Changes Requested')
        REPORT_APPROVED = 'REPORT_APPROVED', _('Daily Work Report Approved')
        SYSTEM_ALERT = 'SYSTEM_ALERT', _('System Security Alert')

    class Priority(models.TextChoices):
        LOW = 'LOW', _('Low')
        MEDIUM = 'MEDIUM', _('Medium')
        HIGH = 'HIGH', _('High')
        URGENT = 'URGENT', _('Urgent')

    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='notifications',
        verbose_name=_("Recipient")
    )
    title = models.CharField(_("Title"), max_length=255)
    message = models.TextField(_("Message Content"))
    notification_type = models.CharField(
        _("Notification Type"),
        max_length=40,
        choices=NotificationType.choices,
        default=NotificationType.TASK_ASSIGNED
    )
    priority = models.CharField(
        _("Priority"),
        max_length=20,
        choices=Priority.choices,
        default=Priority.MEDIUM
    )
    link_type = models.CharField(_("Link Type"), max_length=50, blank=True, null=True, help_text="e.g. TASK, REPORT, SECURITY")
    link_id = models.CharField(_("Link ID"), max_length=100, blank=True, null=True)
    is_read = models.BooleanField(_("Is Read"), default=False, db_index=True)
    read_at = models.DateTimeField(_("Read At"), null=True, blank=True)

    class Meta:
        verbose_name = _("Notification")
        verbose_name_plural = _("Notifications")
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.priority}] {self.title} -> {self.recipient.employee_code}"

    def mark_as_read(self):
        if not self.is_read:
            self.is_read = True
            self.read_at = timezone.now()
            self.save(update_fields=['is_read', 'read_at', 'updated_at'])

    @classmethod
    def send_notification(cls, recipient, title, message, notification_type=NotificationType.TASK_ASSIGNED, priority=Priority.MEDIUM, link_type=None, link_id=None):
        return cls.objects.create(
            recipient=recipient,
            title=title,
            message=message,
            notification_type=notification_type,
            priority=priority,
            link_type=link_type,
            link_id=str(link_id) if link_id else None
        )
