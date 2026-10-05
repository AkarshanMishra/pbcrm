import uuid
from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _

class TimeStampedUUIDModel(models.Model):
    """
    Abstract base model using UUID primary keys and tracking creation/update timestamps.
    """
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text=_("Unique identifier across all systems.")
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        db_index=True,
        help_text=_("Timestamp when the record was created.")
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text=_("Timestamp when the record was last modified.")
    )

    class Meta:
        abstract = True
        ordering = ['-created_at']


class MasterWorkflowProcess(TimeStampedUUIDModel):
    """
    Central cross-department workflow orchestrator.
    Binds any business record (Employee, Partner, Booking, Incident, Leave, Expense, Exit)
    to a standard organizational lifecycle pipeline.
    """
    class WorkflowType(models.TextChoices):
        EMPLOYEE_ONBOARDING = 'EMPLOYEE_ONBOARDING', _('Employee Onboarding (HR + IT + Manager + Admin)')
        PARTNER_ONBOARDING = 'PARTNER_ONBOARDING', _('PartyBala Partner Pipeline (Marketing + Admin + Operations + Accounts)')
        BOOKING_OPERATIONS = 'BOOKING_OPERATIONS', _('Booking & Event Execution (Operations + Accounts + Marketing)')
        IT_INCIDENT = 'IT_INCIDENT', _('IT Incident & Resolution (Operations + IT + DevOps)')
        LEAVE_REQUEST = 'LEAVE_REQUEST', _('Employee Leave (Employee + Manager + HR + Attendance)')
        EXPENSE_PURCHASE = 'EXPENSE_PURCHASE', _('Purchase & Expense Approval (Employee + Manager + Dept Head + Accounts)')
        EMPLOYEE_EXIT = 'EMPLOYEE_EXIT', _('Employee Offboarding (Manager + HR + IT + Accounts)')
        CUSTOM = 'CUSTOM', _('Custom Organization Workflow')

    class Status(models.TextChoices):
        DRAFT = 'DRAFT', _('Draft')
        SUBMITTED = 'SUBMITTED', _('Submitted')
        UNDER_REVIEW = 'UNDER_REVIEW', _('Under Review')
        ASSIGNED = 'ASSIGNED', _('Assigned')
        IN_PROGRESS = 'IN_PROGRESS', _('In Progress')
        WAITING = 'WAITING', _('Waiting on External / Dependency')
        PENDING_APPROVAL = 'PENDING_APPROVAL', _('Pending Approval')
        APPROVED = 'APPROVED', _('Approved')
        COMPLETED = 'COMPLETED', _('Completed')
        VERIFIED = 'VERIFIED', _('Verified')
        CLOSED = 'CLOSED', _('Closed')
        # Exception States
        BLOCKED = 'BLOCKED', _('Blocked')
        REJECTED = 'REJECTED', _('Rejected')
        ESCALATED = 'ESCALATED', _('Escalated')
        CANCELLED = 'CANCELLED', _('Cancelled')
        REOPENED = 'REOPENED', _('Reopened')

    process_code = models.CharField(_("Workflow Reference Code"), max_length=50, unique=True, db_index=True)
    title = models.CharField(_("Workflow Title"), max_length=255)
    workflow_type = models.CharField(_("Workflow Type"), max_length=50, choices=WorkflowType.choices, db_index=True)
    
    entity_type = models.CharField(_("Linked Entity Type"), max_length=50, db_index=True) # e.g. employee, partner, booking, issue, leave
    entity_id = models.CharField(_("Linked Entity ID"), max_length=100, db_index=True) # e.g. PBE000001, PBV0000001, PB-10482
    
    status = models.CharField(_("Status"), max_length=30, choices=Status.choices, default=Status.IN_PROGRESS, db_index=True)
    current_stage_name = models.CharField(_("Current Stage Name"), max_length=150)
    current_department = models.CharField(_("Current Responsible Department"), max_length=100, db_index=True)
    current_role = models.CharField(_("Current Responsible Role"), max_length=100)
    
    initiator = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='initiated_workflows',
        verbose_name=_("Initiator")
    )
    current_assignee = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_workflows',
        verbose_name=_("Current Assignee")
    )

    sla_hours = models.IntegerField(_("Total SLA Hours"), default=24)
    sla_deadline = models.DateTimeField(_("SLA Target Deadline"), null=True, blank=True)
    is_escalated = models.BooleanField(_("Is Escalated"), default=False)
    progress_percentage = models.IntegerField(_("Workflow Progress %"), default=0)
    
    metadata = models.JSONField(_("Workflow Metadata & State"), default=dict, blank=True)

    class Meta:
        verbose_name = _("Master Workflow Process")
        verbose_name_plural = _("Master Workflow Processes")
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.process_code}] {self.title} ({self.status}) - {self.current_department}"

    def recalculate_progress(self):
        steps = self.steps.all()
        if not steps.exists():
            return
        total = steps.count()
        completed = steps.filter(status__in=[
            MasterWorkflowStep.Status.COMPLETED,
            MasterWorkflowStep.Status.APPROVED,
            MasterWorkflowStep.Status.SKIPPED
        ]).count()
        self.progress_percentage = int((completed / total) * 100)
        if completed == total and self.status != self.Status.CLOSED:
            self.status = self.Status.CLOSED
        self.save(update_fields=['progress_percentage', 'status', 'updated_at'])


class MasterWorkflowStep(TimeStampedUUIDModel):
    """
    Individual stage/handoff within a Master Workflow Process.
    """
    class Status(models.TextChoices):
        PENDING = 'PENDING', _('Pending')
        ASSIGNED = 'ASSIGNED', _('Assigned')
        IN_PROGRESS = 'IN_PROGRESS', _('In Progress')
        PENDING_APPROVAL = 'PENDING_APPROVAL', _('Pending Approval')
        APPROVED = 'APPROVED', _('Approved')
        REJECTED = 'REJECTED', _('Rejected')
        COMPLETED = 'COMPLETED', _('Completed')
        BLOCKED = 'BLOCKED', _('Blocked')
        SKIPPED = 'SKIPPED', _('Skipped')

    class ActionType(models.TextChoices):
        TASK_EXECUTION = 'TASK_EXECUTION', _('Task Execution')
        APPROVAL = 'APPROVAL', _('Manager/Admin Approval')
        DOCUMENT_VERIFICATION = 'DOCUMENT_VERIFICATION', _('Document Verification / KYC')
        SYSTEM_PROVISIONING = 'SYSTEM_PROVISIONING', _('System Access & Device Provisioning')
        COMMERCIAL_SETUP = 'COMMERCIAL_SETUP', _('Banking & Commercial Configuration')
        QUALITY_AUDIT = 'QUALITY_AUDIT', _('Service Readiness Inspection')
        HANDOVER = 'HANDOVER', _('Formal Handover & Knowledge Transfer')

    process = models.ForeignKey(
        MasterWorkflowProcess,
        on_delete=models.CASCADE,
        related_name='steps',
        verbose_name=_("Parent Process")
    )
    step_order = models.PositiveIntegerField(_("Step Order Index"), default=1)
    title = models.CharField(_("Step Title"), max_length=200)
    description = models.TextField(_("Step Instructions"), blank=True)
    
    department = models.CharField(_("Target Department"), max_length=100)
    responsible_role = models.CharField(_("Responsible Role"), max_length=100)
    action_type = models.CharField(_("Action Type"), max_length=50, choices=ActionType.choices, default=ActionType.TASK_EXECUTION)
    
    assignee = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='workflow_step_tasks',
        verbose_name=_("Assignee")
    )
    status = models.CharField(_("Status"), max_length=30, choices=Status.choices, default=Status.PENDING)
    
    sla_hours = models.IntegerField(_("Step SLA Hours"), default=8)
    due_date = models.DateTimeField(_("Step Due Date"), null=True, blank=True)
    
    linked_task_id = models.CharField(_("Linked Task ID"), max_length=100, blank=True, null=True)
    completed_at = models.DateTimeField(_("Completed At"), null=True, blank=True)
    completed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='completed_workflow_steps',
        verbose_name=_("Completed By")
    )
    comments = models.TextField(_("Outcome Notes / Rejection Reason"), blank=True)

    class Meta:
        verbose_name = _("Master Workflow Step")
        verbose_name_plural = _("Master Workflow Steps")
        ordering = ['step_order']
        unique_together = ('process', 'step_order')

    def __str__(self):
        return f"{self.process.process_code} - Step {self.step_order}: {self.title} [{self.department}]"


class CentralEventRecord(TimeStampedUUIDModel):
    """
    Central event audit and dispatch log.
    Ensures that every event across all 5 departments is immutable, observable, and replayable.
    """
    class EventType(models.TextChoices):
        EMPLOYEE_CREATED = 'EMPLOYEE_CREATED', _('Employee Created')
        EMPLOYEE_ACTIVATED = 'EMPLOYEE_ACTIVATED', _('Employee Activated')
        EMPLOYEE_RESIGNED = 'EMPLOYEE_RESIGNED', _('Employee Resigned')
        EMPLOYEE_EXITED = 'EMPLOYEE_EXITED', _('Employee Exited')
        
        PARTNER_CREATED = 'PARTNER_CREATED', _('Partner Created')
        PARTNER_KYC_SUBMITTED = 'PARTNER_KYC_SUBMITTED', _('Partner KYC Submitted')
        PARTNER_APPROVED = 'PARTNER_APPROVED', _('Partner Approved by Admin')
        PARTNER_ACTIVATED = 'PARTNER_ACTIVATED', _('Partner Activated across Ops & Accounts')
        
        BOOKING_CREATED = 'BOOKING_CREATED', _('Booking Created')
        BOOKING_CONFIRMED = 'BOOKING_CONFIRMED', _('Booking Confirmed')
        EVENT_COMPLETED = 'EVENT_COMPLETED', _('Event Completed')
        
        ISSUE_REPORTED = 'ISSUE_REPORTED', _('Operations Issue Reported')
        TICKET_CREATED = 'TICKET_CREATED', _('IT Ticket Created')
        TICKET_RESOLVED = 'TICKET_RESOLVED', _('IT Ticket Resolved')
        
        LEAVE_REQUESTED = 'LEAVE_REQUESTED', _('Leave Requested')
        LEAVE_APPROVED = 'LEAVE_APPROVED', _('Leave Approved')
        LEAVE_REJECTED = 'LEAVE_REJECTED', _('Leave Rejected')
        
        EXPENSE_REQUESTED = 'EXPENSE_REQUESTED', _('Expense Requested')
        EXPENSE_APPROVED = 'EXPENSE_APPROVED', _('Expense Approved')
        
        TASK_CREATED = 'TASK_CREATED', _('Task Created')
        TASK_COMPLETED = 'TASK_COMPLETED', _('Task Completed')
        TASK_BLOCKED = 'TASK_BLOCKED', _('Task Blocked')
        TASK_ESCALATED = 'TASK_ESCALATED', _('Task Escalated')
        
        WORKFLOW_STARTED = 'WORKFLOW_STARTED', _('Workflow Started')
        WORKFLOW_STEP_COMPLETED = 'WORKFLOW_STEP_COMPLETED', _('Workflow Step Completed')
        WORKFLOW_COMPLETED = 'WORKFLOW_COMPLETED', _('Workflow Completed')

    event_type = models.CharField(_("Event Type"), max_length=60, choices=EventType.choices, db_index=True)
    entity_type = models.CharField(_("Entity Type"), max_length=50, db_index=True)
    entity_id = models.CharField(_("Entity Reference ID"), max_length=100, db_index=True)
    
    actor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='triggered_central_events',
        verbose_name=_("Actor")
    )
    payload = models.JSONField(_("Event Payload"), default=dict, blank=True)
    processed = models.BooleanField(_("Processed by Engine"), default=True)

    class Meta:
        verbose_name = _("Central Event Record")
        verbose_name_plural = _("Central Event Records")
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.event_type}] {self.entity_type}:{self.entity_id} at {self.created_at}"
