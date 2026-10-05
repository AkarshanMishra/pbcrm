from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from django.utils import timezone
from apps.core.models import TimeStampedUUIDModel
from apps.organization.models import Department, Position
from apps.employees.models import Employee

class Project(TimeStampedUUIDModel):
    class Status(models.TextChoices):
        PLANNING = 'PLANNING', _('Planning')
        ACTIVE = 'ACTIVE', _('Active')
        ON_HOLD = 'ON_HOLD', _('On Hold')
        COMPLETED = 'COMPLETED', _('Completed')
        CANCELLED = 'CANCELLED', _('Cancelled')

    name = models.CharField(_("Project Name"), max_length=200, db_index=True)
    code = models.CharField(_("Project Code"), max_length=50, unique=True, db_index=True)
    description = models.TextField(_("Project Description"), blank=True)
    
    department = models.ForeignKey(
        Department,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='projects',
        verbose_name=_("Department")
    )
    manager = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='managed_projects',
        verbose_name=_("Project Manager")
    )
    members = models.ManyToManyField(
        Employee,
        blank=True,
        related_name='projects',
        verbose_name=_("Team Members")
    )
    
    status = models.CharField(
        _("Status"),
        max_length=20,
        choices=Status.choices,
        default=Status.ACTIVE,
        db_index=True
    )
    start_date = models.DateField(_("Start Date"), null=True, blank=True)
    due_date = models.DateField(_("Due Date"), null=True, blank=True)
    budget_hours = models.DecimalField(_("Budget / Estimated Hours"), max_digits=8, decimal_places=2, default=0.0)
    progress_percentage = models.IntegerField(_("Progress %"), default=0)

    class Meta:
        verbose_name = _("Project")
        verbose_name_plural = _("Projects")
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.code}] {self.name} ({self.status})"

    def recalculate_progress(self):
        total_tasks = self.tasks.count()
        if total_tasks == 0:
            return
        completed_tasks = self.tasks.filter(status=Task.Status.COMPLETED).count()
        self.progress_percentage = int((completed_tasks / total_tasks) * 100)
        self.save(update_fields=['progress_percentage', 'updated_at'])


class Task(TimeStampedUUIDModel):
    class Priority(models.TextChoices):
        LOW = 'LOW', _('Low (Can be handled later)')
        MEDIUM = 'MEDIUM', _('Medium (Normal work)')
        HIGH = 'HIGH', _('High (Important)')
        URGENT = 'URGENT', _('Urgent (Immediate attention)')

    class Status(models.TextChoices):
        DRAFT = 'DRAFT', _('Draft')
        ASSIGNED = 'ASSIGNED', _('Assigned')
        ACCEPTED = 'ACCEPTED', _('Accepted')
        IN_PROGRESS = 'IN_PROGRESS', _('In Progress')
        BLOCKED = 'BLOCKED', _('Blocked')
        SUBMITTED = 'SUBMITTED', _('Submitted for Review')
        UNDER_REVIEW = 'UNDER_REVIEW', _('Under Review')
        COMPLETED = 'COMPLETED', _('Completed')
        REJECTED = 'REJECTED', _('Changes Requested / Rejected')
        CANCELLED = 'CANCELLED', _('Cancelled')
        OVERDUE = 'OVERDUE', _('Overdue')

    class RecurringPattern(models.TextChoices):
        NONE = 'NONE', _('Not Recurring')
        DAILY = 'DAILY', _('Daily')
        WEEKLY = 'WEEKLY', _('Weekly')
        MONTHLY = 'MONTHLY', _('Monthly')

    project = models.ForeignKey(
        Project,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='tasks',
        verbose_name=_("Project")
    )
    parent_task = models.ForeignKey(
        'self',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='subtasks',
        verbose_name=_("Parent Task")
    )

    title = models.CharField(_("Task Title"), max_length=255, db_index=True)
    description = models.TextField(_("Task Description"))

    department = models.ForeignKey(
        Department,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='tasks',
        verbose_name=_("Department")
    )
    position = models.ForeignKey(
        Position,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='tasks',
        verbose_name=_("Position")
    )

    assigned_to = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name='assigned_tasks',
        verbose_name=_("Assigned Employee")
    )
    assigned_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_tasks',
        verbose_name=_("Assigned By")
    )

    priority = models.CharField(
        _("Priority"),
        max_length=20,
        choices=Priority.choices,
        default=Priority.MEDIUM,
        db_index=True
    )
    status = models.CharField(
        _("Status"),
        max_length=20,
        choices=Status.choices,
        default=Status.ASSIGNED,
        db_index=True
    )

    start_date = models.DateField(_("Start Date"), null=True, blank=True)
    due_date = models.DateField(_("Due Date"), null=True, blank=True, db_index=True)
    due_time = models.TimeField(_("Due Time"), null=True, blank=True)
    
    # Time Tracking & Estimates
    estimated_hours = models.DecimalField(_("Estimated Hours"), max_digits=6, decimal_places=2, null=True, blank=True)
    actual_hours = models.DecimalField(_("Actual Hours"), max_digits=6, decimal_places=2, default=0.0)
    is_timer_running = models.BooleanField(_("Timer Currently Running"), default=False)

    progress_percentage = models.IntegerField(_("Progress Percentage"), default=0)

    # Tags & Department Custom Data
    tags = models.JSONField(_("Tags / Labels"), default=list, blank=True)
    department_data = models.JSONField(_("Department Custom Form Fields"), default=dict, blank=True)

    # Blocked task details
    blocked_reason = models.CharField(_("Blocked Reason"), max_length=255, blank=True)
    blocked_expected_resolution = models.DateField(_("Expected Resolution Date"), null=True, blank=True)
    blocked_comment = models.TextField(_("Blocked Detailed Comment"), blank=True)

    # Review & Completion details
    completed_at = models.DateTimeField(_("Completed At"), null=True, blank=True)
    reviewed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reviewed_tasks',
        verbose_name=_("Reviewed By")
    )
    reviewed_at = models.DateTimeField(_("Reviewed At"), null=True, blank=True)
    manager_remarks = models.TextField(_("Manager Remarks"), blank=True)

    # Recurring
    is_recurring = models.BooleanField(_("Is Recurring"), default=False)
    recurring_pattern = models.CharField(
        _("Recurring Pattern"),
        max_length=20,
        choices=RecurringPattern.choices,
        default=RecurringPattern.NONE
    )
    parent_recurring_task = models.ForeignKey(
        'self',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='recurring_instances'
    )

    class Meta:
        verbose_name = _("Task")
        verbose_name_plural = _("Tasks")
        ordering = ['-due_date', '-created_at']

    def __str__(self):
        return f"[{self.priority}] {self.title} ({self.status}) -> {self.assigned_to.user.employee_code}"

    @property
    def is_overdue(self):
        if self.status in [self.Status.COMPLETED, self.Status.CANCELLED]:
            return False
        if self.due_date:
            today = timezone.localdate()
            if self.due_date < today:
                return True
            if self.due_date == today and self.due_time:
                return timezone.localtime().time() > self.due_time
        return False

    def log_activity(self, actor, action, description):
        return TaskActivityLog.objects.create(
            task=self,
            actor=actor,
            action=action,
            description=description
        )

    def recalculate_subtask_progress(self):
        total_subtasks = self.subtasks.count()
        if total_subtasks == 0:
            return
        completed_subtasks = self.subtasks.filter(status=self.Status.COMPLETED).count()
        self.progress_percentage = int((completed_subtasks / total_subtasks) * 100)
        if self.progress_percentage == 100 and self.status != self.Status.COMPLETED:
            self.status = self.Status.COMPLETED
            self.completed_at = timezone.now()
        self.save(update_fields=['progress_percentage', 'status', 'completed_at', 'updated_at'])
        if self.project:
            self.project.recalculate_progress()


class TaskTimeLog(TimeStampedUUIDModel):
    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='time_logs')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='task_time_logs')
    start_time = models.DateTimeField(_("Start Time"), default=timezone.now)
    end_time = models.DateTimeField(_("End Time"), null=True, blank=True)
    duration_minutes = models.PositiveIntegerField(_("Duration in Minutes"), default=0)
    notes = models.CharField(_("Work Notes"), max_length=255, blank=True)
    is_running = models.BooleanField(_("Is Currently Running"), default=True)

    class Meta:
        ordering = ['-start_time']

    def __str__(self):
        return f"{self.user.employee_code} on {self.task.title}: {self.duration_minutes}m"


class TaskChecklistItem(TimeStampedUUIDModel):
    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='checklist_items')
    item_text = models.CharField(max_length=255)
    is_completed = models.BooleanField(default=False)
    completed_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['order', 'created_at']

    def __str__(self):
        return f"[{'X' if self.is_completed else ' '}] {self.item_text}"


class TaskDependency(TimeStampedUUIDModel):
    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='dependencies')
    depends_on = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='blocking_for')

    class Meta:
        verbose_name_plural = 'Task Dependencies'
        unique_together = ('task', 'depends_on')

    def __str__(self):
        return f"{self.task.title} depends on {self.depends_on.title}"


class TaskComment(TimeStampedUUIDModel):
    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='comments')
    author = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='task_comments')
    comment_text = models.TextField()
    mentions = models.JSONField(default=list, blank=True, help_text="List of mentioned usernames/employee_codes")

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"Comment by {self.author.employee_code} on {self.task.title}"


class TaskAttachment(TimeStampedUUIDModel):
    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='attachments')
    uploaded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='task_attachments')
    file = models.FileField(upload_to='task_attachments/%Y/%m/')
    filename = models.CharField(max_length=255)
    file_size = models.PositiveIntegerField(default=0)
    mime_type = models.CharField(max_length=100, blank=True)
    version = models.PositiveIntegerField(default=1)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.filename} (v{self.version}, {self.file_size} bytes)"


class TaskActivityLog(TimeStampedUUIDModel):
    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='activity_logs')
    actor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    action = models.CharField(max_length=100)
    description = models.TextField()

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.created_at.strftime('%H:%M')}] {self.action}: {self.description}"


class TaskTemplate(TimeStampedUUIDModel):
    name = models.CharField(max_length=150)
    department = models.ForeignKey(Department, on_delete=models.SET_NULL, null=True, blank=True, related_name='task_templates')
    default_priority = models.CharField(max_length=20, choices=Task.Priority.choices, default=Task.Priority.MEDIUM)
    description = models.TextField(blank=True)
    estimated_hours = models.DecimalField(max_digits=5, decimal_places=2, default=1.0)
    checklist_template = models.JSONField(default=list, help_text="List of checklist strings")
    department_fields_template = models.JSONField(default=dict, blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return f"{self.name} ({self.department.name if self.department else 'General'})"
