import re
from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from django.utils import timezone
from apps.core.models import TimeStampedUUIDModel
from apps.employees.models import Employee
from apps.organization.models import Department

def generate_ticket_number():
    year = timezone.now().year
    prefix = f"TKT-{year}-"
    last_ticket = SupportTicket.objects.filter(ticket_number__startswith=prefix).order_by('-ticket_number').first()
    if not last_ticket:
        return f"{prefix}0001"
    match = re.search(rf"{prefix}(\d+)", last_ticket.ticket_number)
    if match:
        next_num = int(match.group(1)) + 1
        return f"{prefix}{next_num:04d}"
    return f"{prefix}{SupportTicket.objects.count() + 1:04d}"


class SupportTicket(TimeStampedUUIDModel):
    class Category(models.TextChoices):
        IT_SUPPORT = 'IT_SUPPORT', _('IT & Technical Support')
        ASSET_REQUEST = 'ASSET_REQUEST', _('Hardware / Asset Request')
        LEAVE_REQUEST = 'LEAVE_REQUEST', _('Leave & Attendance Regularization')
        PURCHASE = 'PURCHASE', _('Purchase & Expense Requisition')
        ACCOUNTS = 'ACCOUNTS', _('Accounts & Salary Query')
        OPERATIONS = 'OPERATIONS', _('Operations & Field Support')
        GENERAL = 'GENERAL', _('General Administrative Request')

    class Priority(models.TextChoices):
        LOW = 'LOW', _('Low')
        MEDIUM = 'MEDIUM', _('Medium')
        HIGH = 'HIGH', _('High')
        URGENT = 'URGENT', _('Urgent')

    class Status(models.TextChoices):
        OPEN = 'OPEN', _('Open')
        IN_PROGRESS = 'IN_PROGRESS', _('In Progress')
        RESOLVED = 'RESOLVED', _('Resolved')
        CLOSED = 'CLOSED', _('Closed')

    ticket_number = models.CharField(max_length=30, unique=True, default=generate_ticket_number, db_index=True)
    category = models.CharField(max_length=30, choices=Category.choices, default=Category.IT_SUPPORT, db_index=True)
    title = models.CharField(max_length=255)
    description = models.TextField()
    priority = models.CharField(max_length=20, choices=Priority.choices, default=Priority.MEDIUM, db_index=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.OPEN, db_index=True)

    requester = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name='raised_tickets',
        verbose_name=_("Requester Employee")
    )
    target_department = models.ForeignKey(
        Department,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_tickets',
        verbose_name=_("Target Department")
    )
    assigned_technician = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_helpdesk_tickets',
        verbose_name=_("Assigned Technician / Handler")
    )

    resolution_notes = models.TextField(blank=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    closed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = _("Support Ticket")
        verbose_name_plural = _("Support Tickets")
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.ticket_number}] {self.title} ({self.status})"


class TicketComment(TimeStampedUUIDModel):
    ticket = models.ForeignKey(SupportTicket, on_delete=models.CASCADE, related_name='comments')
    author = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='ticket_comments')
    comment_text = models.TextField()

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"Comment on {self.ticket.ticket_number} by {self.author.employee_code}"
