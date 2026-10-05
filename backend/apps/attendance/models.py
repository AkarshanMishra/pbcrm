from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from django.utils import timezone
from apps.core.models import TimeStampedUUIDModel
from apps.employees.models import Employee
from apps.accounts.models import UserDevice

class Attendance(TimeStampedUUIDModel):
    class AttendanceStatus(models.TextChoices):
        PRESENT = 'PRESENT', _('Present')
        HALF_DAY = 'HALF_DAY', _('Half Day')
        LATE = 'LATE', _('Late Arrival')
        ON_LEAVE = 'ON_LEAVE', _('On Leave')
        ABSENT = 'ABSENT', _('Absent')

    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name='attendance_records',
        verbose_name=_("Employee")
    )
    attendance_date = models.DateField(_("Attendance Date"), db_index=True)
    server_check_in_time = models.TimeField(_("Authoritative Server Check-in Time"), null=True, blank=True)
    server_check_out_time = models.TimeField(_("Authoritative Server Check-out Time"), null=True, blank=True)
    status = models.CharField(
        _("Attendance Status"),
        max_length=20,
        choices=AttendanceStatus.choices,
        default=AttendanceStatus.PRESENT
    )

    check_in_ip = models.GenericIPAddressField(_("Check-in IP Address"), null=True, blank=True)
    check_out_ip = models.GenericIPAddressField(_("Check-out IP Address"), null=True, blank=True)
    check_in_device = models.ForeignKey(
        UserDevice,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='check_in_attendances'
    )
    check_out_device = models.ForeignKey(
        UserDevice,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='check_out_attendances'
    )
    check_in_latitude = models.DecimalField(_("Check-in Latitude"), max_digits=9, decimal_places=6, null=True, blank=True)
    check_in_longitude = models.DecimalField(_("Check-in Longitude"), max_digits=9, decimal_places=6, null=True, blank=True)
    check_out_latitude = models.DecimalField(_("Check-out Latitude"), max_digits=9, decimal_places=6, null=True, blank=True)
    check_out_longitude = models.DecimalField(_("Check-out Longitude"), max_digits=9, decimal_places=6, null=True, blank=True)

    notes = models.TextField(_("Attendance Notes / Remarks"), blank=True)
    is_corrected = models.BooleanField(_("Is Manually Corrected"), default=False)

    class Meta:
        verbose_name = _("Attendance Record")
        verbose_name_plural = _("Attendance Records")
        # Rule #16: Employee + Attendance Date UNIQUE CONSTRAINT
        unique_together = ('employee', 'attendance_date')
        ordering = ['-attendance_date', '-server_check_in_time']

    def __str__(self):
        return f"{self.employee.user.employee_code} - {self.attendance_date} [{self.status}]"


class AttendanceCorrection(TimeStampedUUIDModel):
    class CorrectionStatus(models.TextChoices):
        PENDING = 'PENDING', _('Pending Approval')
        APPROVED = 'APPROVED', _('Approved')
        REJECTED = 'REJECTED', _('Rejected')

    attendance = models.ForeignKey(
        Attendance,
        on_delete=models.CASCADE,
        related_name='corrections',
        verbose_name=_("Attendance Record")
    )
    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name='attendance_corrections',
        verbose_name=_("Employee")
    )
    requested_check_in_time = models.TimeField(_("Requested Check-in Time"), null=True, blank=True)
    requested_check_out_time = models.TimeField(_("Requested Check-out Time"), null=True, blank=True)
    requested_status = models.CharField(
        _("Requested Status"),
        max_length=20,
        choices=Attendance.AttendanceStatus.choices,
        default=Attendance.AttendanceStatus.PRESENT
    )
    reason = models.TextField(_("Reason for Correction"))

    status = models.CharField(
        _("Correction Status"),
        max_length=20,
        choices=CorrectionStatus.choices,
        default=CorrectionStatus.PENDING,
        db_index=True
    )
    reviewed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reviewed_corrections',
        verbose_name=_("Reviewed By")
    )
    reviewed_at = models.DateTimeField(_("Reviewed At"), null=True, blank=True)
    review_remarks = models.TextField(_("Manager/Admin Review Remarks"), blank=True)

    class Meta:
        verbose_name = _("Attendance Correction")
        verbose_name_plural = _("Attendance Corrections")
        ordering = ['-created_at']

    def __str__(self):
        return f"Correction for {self.employee.user.employee_code} on {self.attendance.attendance_date} [{self.status}]"
