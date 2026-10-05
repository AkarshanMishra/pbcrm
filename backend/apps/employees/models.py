import re
from django.db import models, transaction
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from django.utils import timezone
from apps.core.models import TimeStampedUUIDModel
from apps.organization.models import Department, Position, Role

def generate_next_employee_code():
    """
    Generates sequential Employee ID e.g., PBE000001, PBE000002.
    """
    from apps.accounts.models import User
    last_user = User.objects.filter(employee_code__startswith='PBE').order_by('-employee_code').first()
    if not last_user:
        return 'PBE000001'

    match = re.search(r'PBE(\d+)', last_user.employee_code)
    if match:
        next_num = int(match.group(1)) + 1
        return f"PBE{next_num:06d}"
    return f"PBE{User.objects.count() + 1:06d}"


class Employee(TimeStampedUUIDModel):
    class EmploymentType(models.TextChoices):
        FULL_TIME = 'FULL_TIME', _('Full Time')
        PART_TIME = 'PART_TIME', _('Part Time')
        CONTRACT = 'CONTRACT', _('Contractor')
        INTERN = 'INTERN', _('Intern')

    class Gender(models.TextChoices):
        MALE = 'MALE', _('Male')
        FEMALE = 'FEMALE', _('Female')
        OTHER = 'OTHER', _('Other / Prefer not to say')

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='employee_profile',
        verbose_name=_("User Account")
    )
    first_name = models.CharField(_("First Name"), max_length=100)
    last_name = models.CharField(_("Last Name"), max_length=100)
    gender = models.CharField(_("Gender"), max_length=20, choices=Gender.choices, default=Gender.MALE)
    date_of_birth = models.DateField(_("Date of Birth"), blank=True, null=True)

    department = models.ForeignKey(
        Department,
        on_delete=models.PROTECT,
        related_name='employees',
        verbose_name=_("Department")
    )
    position = models.ForeignKey(
        Position,
        on_delete=models.PROTECT,
        related_name='employees',
        verbose_name=_("Position")
    )
    role = models.ForeignKey(
        Role,
        on_delete=models.PROTECT,
        related_name='employees',
        verbose_name=_("System Access Role")
    )
    reporting_manager = models.ForeignKey(
        'self',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='direct_reports',
        verbose_name=_("Reporting Manager")
    )

    joining_date = models.DateField(_("Joining Date"), default=timezone.localdate)
    employment_type = models.CharField(
        _("Employment Type"),
        max_length=30,
        choices=EmploymentType.choices,
        default=EmploymentType.FULL_TIME
    )
    emergency_contact_name = models.CharField(_("Emergency Contact Name"), max_length=150, blank=True)
    emergency_contact_phone = models.CharField(_("Emergency Contact Phone"), max_length=25, blank=True)
    address = models.TextField(_("Residential Address"), blank=True)

    class Meta:
        verbose_name = _("Employee Profile")
        verbose_name_plural = _("Employee Profiles")
        ordering = ['user__employee_code']

    def __str__(self):
        return f"{self.user.employee_code} - {self.full_name}"

    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}".strip()

    @property
    def employee_code(self):
        return self.user.employee_code

    @property
    def email(self):
        return self.user.email

    @property
    def status(self):
        return self.user.status


class EmployeeLifecycleHistory(TimeStampedUUIDModel):
    employee = models.ForeignKey(Employee, on_delete=models.CASCADE, related_name='lifecycle_events')
    previous_status = models.CharField(max_length=50)
    new_status = models.CharField(max_length=50)
    reason = models.TextField(blank=True)
    changed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )

    class Meta:
        verbose_name = _("Employee Lifecycle History")
        verbose_name_plural = _("Employee Lifecycle Histories")
        ordering = ['-created_at']
