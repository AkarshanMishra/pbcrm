from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from django.utils import timezone
from apps.core.models import TimeStampedUUIDModel
from apps.employees.models import Employee
from apps.organization.models import Department, Position
from apps.tasks.models import Task

class DailyWorkPlan(TimeStampedUUIDModel):
    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name='daily_plans',
        verbose_name=_("Employee")
    )
    plan_date = models.DateField(_("Plan Date"), db_index=True)
    planned_items = models.JSONField(_("Planned Tasks / Goals"), default=list, help_text="List of goal items")
    is_started = models.BooleanField(_("Day Started"), default=False)
    started_at = models.DateTimeField(_("Started At"), null=True, blank=True)
    notes = models.TextField(_("Plan Notes"), blank=True)

    class Meta:
        verbose_name = _("Daily Work Plan")
        verbose_name_plural = _("Daily Work Plans")
        unique_together = ('employee', 'plan_date')
        ordering = ['-plan_date']

    def __str__(self):
        return f"Plan: {self.employee.user.employee_code} ({self.plan_date})"


class DailyWorkReport(TimeStampedUUIDModel):
    class ReportStatus(models.TextChoices):
        DRAFT = 'DRAFT', _('Draft')
        SUBMITTED = 'SUBMITTED', _('Submitted (Awaiting Review)')
        CHANGES_REQUESTED = 'CHANGES_REQUESTED', _('Changes Requested')
        APPROVED = 'APPROVED', _('Approved')

    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name='daily_reports',
        verbose_name=_("Employee")
    )
    report_date = models.DateField(_("Report Date"), db_index=True)
    summary_text = models.TextField(_("Summary of Day's Work"))
    completed_summary = models.TextField(_("Completed Work Highlights"), blank=True)
    pending_summary = models.TextField(_("Pending Items"), blank=True)
    blocked_summary = models.TextField(_("Blockers / Issues Encountered"), blank=True)
    tomorrow_plan = models.TextField(_("Tomorrow's Plan"), blank=True)

    status = models.CharField(
        _("Report Status"),
        max_length=25,
        choices=ReportStatus.choices,
        default=ReportStatus.DRAFT,
        db_index=True
    )
    submitted_at = models.DateTimeField(_("Submitted At"), null=True, blank=True)

    reviewed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reviewed_work_reports',
        verbose_name=_("Reviewed By")
    )
    reviewed_at = models.DateTimeField(_("Reviewed At"), null=True, blank=True)
    manager_remarks = models.TextField(_("Manager Remarks / Feedback"), blank=True)

    class Meta:
        verbose_name = _("Daily Work Report")
        verbose_name_plural = _("Daily Work Reports")
        unique_together = ('employee', 'report_date')
        ordering = ['-report_date']

    def __str__(self):
        return f"Report: {self.employee.user.employee_code} ({self.report_date}) [{self.status}]"


class DailyStandup(TimeStampedUUIDModel):
    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name='daily_standups',
        verbose_name=_("Employee")
    )
    standup_date = models.DateField(_("Standup Date"), default=timezone.localdate, db_index=True)
    yesterday_completed = models.TextField(_("What did you complete yesterday?"))
    today_planned = models.TextField(_("What will you work on today?"))
    blockers_encountered = models.TextField(_("Any blockers or help needed?"), blank=True)
    
    submitted_at = models.DateTimeField(default=timezone.now)
    reviewed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reviewed_standups'
    )
    manager_feedback = models.TextField(blank=True)

    class Meta:
        verbose_name = _("Daily Standup")
        verbose_name_plural = _("Daily Standups")
        unique_together = ('employee', 'standup_date')
        ordering = ['-standup_date', '-submitted_at']

    def __str__(self):
        return f"Standup: {self.employee.user.employee_code} ({self.standup_date})"


class WorkDiaryEntry(TimeStampedUUIDModel):
    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name='work_diary_entries',
        verbose_name=_("Employee")
    )
    task = models.ForeignKey(
        Task,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='diary_entries',
        verbose_name=_("Related Task")
    )
    logged_at = models.DateTimeField(_("Log Timestamp"), default=timezone.now)
    activity_text = models.CharField(_("Activity Description"), max_length=255)
    duration_minutes = models.PositiveIntegerField(_("Duration (Minutes)"), default=0)
    category = models.CharField(_("Activity Category"), max_length=50, default='DEVELOPMENT')

    class Meta:
        verbose_name = _("Work Diary Entry")
        verbose_name_plural = _("Work Diary Entries")
        ordering = ['-logged_at']

    def __str__(self):
        return f"[{self.logged_at.strftime('%H:%M')}] {self.employee.user.employee_code}: {self.activity_text}"


class Announcement(TimeStampedUUIDModel):
    class TargetType(models.TextChoices):
        ALL = 'ALL', _('Entire Company')
        DEPARTMENT = 'DEPARTMENT', _('Department Specific')
        POSITION = 'POSITION', _('Position Specific')

    class Priority(models.TextChoices):
        NORMAL = 'NORMAL', _('Normal')
        HIGH = 'HIGH', _('High Priority')
        URGENT = 'URGENT', _('Urgent Broadcast')

    title = models.CharField(_("Announcement Title"), max_length=200)
    content = models.TextField(_("Announcement Body"))
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='published_announcements'
    )
    target_type = models.CharField(
        _("Target Audience"),
        max_length=20,
        choices=TargetType.choices,
        default=TargetType.ALL
    )
    target_department = models.ForeignKey(
        Department,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='announcements'
    )
    priority = models.CharField(
        _("Priority"),
        max_length=20,
        choices=Priority.choices,
        default=Priority.NORMAL
    )
    is_pinned = models.BooleanField(_("Pinned to Top"), default=False)
    valid_until = models.DateField(_("Valid Until Date"), null=True, blank=True)

    class Meta:
        verbose_name = _("Company Announcement")
        verbose_name_plural = _("Company Announcements")
        ordering = ['-is_pinned', '-created_at']

    def __str__(self):
        return f"[{self.priority}] {self.title} ({self.target_type})"
