import uuid
from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from django.utils import timezone
from apps.core.models import TimeStampedUUIDModel
from apps.employees.models import Employee

class DeviceRegistration(TimeStampedUUIDModel):
    """
    Tracks mobile and web client devices authorized for offline-first replication.
    """
    device_id = models.CharField(_("Unique Device Identifier"), max_length=100, unique=True, db_index=True)
    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name='registered_devices',
        null=True,
        blank=True,
        verbose_name=_("Associated Employee")
    )
    device_name = models.CharField(_("Device Name"), max_length=150, blank=True)
    device_model = models.CharField(_("Device Hardware Model"), max_length=100, blank=True)
    os_version = models.CharField(_("OS Version"), max_length=50, blank=True)
    app_version = models.CharField(_("App Version"), max_length=50, default='1.0.0')
    
    is_online = models.BooleanField(_("Is Currently Online"), default=True)
    is_revoked = models.BooleanField(_("Is Device Revoked / Blocked"), default=False)
    
    last_synced_at = models.DateTimeField(_("Last Successful Sync"), default=timezone.now)
    last_heartbeat_at = models.DateTimeField(_("Last Heartbeat Received"), default=timezone.now)
    
    pending_sync_count = models.IntegerField(_("Pending Sync Queue Count"), default=0)
    successful_sync_count = models.IntegerField(_("Lifetime Successful Sync Items"), default=0)
    failed_sync_count = models.IntegerField(_("Lifetime Failed Sync Items"), default=0)

    class Meta:
        verbose_name = _("Registered Device")
        verbose_name_plural = _("Registered Devices")
        ordering = ['-last_heartbeat_at']

    def __str__(self):
        emp_name = self.employee.user.username if self.employee and self.employee.user else "Unassigned"
        return f"{self.device_name or self.device_id} ({emp_name})"


class SyncQueueRecord(TimeStampedUUIDModel):
    """
    Authoritative audit record of every offline operation uploaded by client devices.
    """
    class ActionType(models.TextChoices):
        TASK_CREATE = 'TASK_CREATE', _('Create Task')
        TASK_UPDATE = 'TASK_UPDATE', _('Update Task Status/Details')
        TASK_COMMENT = 'TASK_COMMENT', _('Add Task Comment')
        ATTENDANCE_PUNCH = 'ATTENDANCE_PUNCH', _('Offline Attendance Punch')
        DAILY_REPORT = 'DAILY_REPORT', _('Submit Daily Work Report')
        MARKETING_VISIT = 'MARKETING_VISIT', _('Record Field Visit & Checklist')
        MARKETING_LEAD = 'MARKETING_LEAD', _('Create / Update Marketing Lead')
        OPERATIONS_CHECKLIST = 'OPERATIONS_CHECKLIST', _('Operations Venue/Readiness Checklist')
        IT_TICKET_NOTE = 'IT_TICKET_NOTE', _('IT Ticket Troubleshooting Note')
        HR_REQUEST = 'HR_REQUEST', _('Employee HR Request')
        GENERIC_MUTATION = 'GENERIC_MUTATION', _('Generic Offline Action')

    class SyncStatus(models.TextChoices):
        SYNCED = 'SYNCED', _('Successfully Reconciled')
        CONFLICT = 'CONFLICT', _('Conflict Detected - Awaiting Resolution')
        REJECTED = 'REJECTED', _('Server Authority Rejected (e.g. Tampering / Invalid Window)')
        ERROR = 'ERROR', _('Processing Exception')

    client_id = models.CharField(_("Client-side UUID / Local ID"), max_length=100, db_index=True)
    device = models.ForeignKey(
        DeviceRegistration,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='sync_records'
    )
    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name='sync_records',
        null=True,
        blank=True
    )
    action_type = models.CharField(_("Action Type"), max_length=50, choices=ActionType.choices)
    client_timestamp = models.DateTimeField(_("Client Timestamp when action was performed offline"))
    server_timestamp = models.DateTimeField(_("Authoritative Server Reception Timestamp"), auto_now_add=True)
    
    payload = models.JSONField(_("Action Payload"), default=dict)
    status = models.CharField(_("Sync Status"), max_length=30, choices=SyncStatus.choices, default=SyncStatus.SYNCED)
    server_version = models.IntegerField(_("Server Record Version"), default=1)
    server_entity_id = models.CharField(_("Created/Updated Server Entity ID"), max_length=100, blank=True)
    
    conflict_details = models.JSONField(_("Conflict Metadata"), null=True, blank=True)
    error_message = models.TextField(_("Error Trace / Reason"), blank=True)

    class Meta:
        verbose_name = _("Sync Queue Audit Record")
        verbose_name_plural = _("Sync Queue Audit Records")
        ordering = ['-created_at']

    def __str__(self):
        return f"Sync [{self.action_type}] ({self.client_id}) -> {self.status}"


class SyncConflict(TimeStampedUUIDModel):
    """
    Manages non-destructive conflict reconciliation for records modified offline.
    """
    class ConflictStatus(models.TextChoices):
        PENDING_REVIEW = 'PENDING_REVIEW', _('Pending Review')
        RESOLVED_SERVER_WINS = 'RESOLVED_SERVER_WINS', _('Resolved: Server Authority Kept')
        RESOLVED_CLIENT_WINS = 'RESOLVED_CLIENT_WINS', _('Resolved: Client Offline Update Applied')
        RESOLVED_MERGED = 'RESOLVED_MERGED', _('Resolved: Merged Attributes')

    sync_record = models.ForeignKey(
        SyncQueueRecord,
        on_delete=models.CASCADE,
        related_name='conflicts',
        verbose_name=_("Originating Sync Record")
    )
    entity_type = models.CharField(_("Entity Type (e.g. Task, Partner, Report)"), max_length=50)
    entity_id = models.CharField(_("Server Entity ID"), max_length=100)
    
    server_data = models.JSONField(_("Current Live Server State"), default=dict)
    client_data = models.JSONField(_("Offline Client Submitted State"), default=dict)
    
    status = models.CharField(_("Conflict Status"), max_length=30, choices=ConflictStatus.choices, default=ConflictStatus.PENDING_REVIEW)
    resolution_notes = models.TextField(_("Resolution Explanation / Audit Note"), blank=True)
    resolved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='resolved_conflicts'
    )
    resolved_at = models.DateTimeField(_("Resolution Timestamp"), null=True, blank=True)

    class Meta:
        verbose_name = _("Sync Conflict")
        verbose_name_plural = _("Sync Conflicts")
        ordering = ['-created_at']

    def __str__(self):
        return f"Conflict on {self.entity_type} #{self.entity_id} [{self.status}]"
