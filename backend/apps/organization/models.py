from django.db import models
from django.utils.translation import gettext_lazy as _
from apps.core.models import TimeStampedUUIDModel

class Department(TimeStampedUUIDModel):
    name = models.CharField(_("Department Name"), max_length=100, unique=True)
    code = models.CharField(_("Department Code"), max_length=20, unique=True, db_index=True)
    description = models.TextField(_("Description"), blank=True, null=True)
    is_active = models.BooleanField(_("Active Status"), default=True)

    class Meta:
        verbose_name = _("Department")
        verbose_name_plural = _("Departments")
        ordering = ['name']

    def __str__(self):
        return f"{self.name} ({self.code})"


class Position(TimeStampedUUIDModel):
    department = models.ForeignKey(
        Department,
        on_delete=models.CASCADE,
        related_name='positions',
        verbose_name=_("Department")
    )
    title = models.CharField(_("Position Title"), max_length=100)
    code = models.CharField(_("Position Code"), max_length=30, blank=True)
    description = models.TextField(_("Job Description"), blank=True, null=True)
    is_active = models.BooleanField(_("Active Status"), default=True)

    class Meta:
        verbose_name = _("Position")
        verbose_name_plural = _("Positions")
        unique_together = ('department', 'title')
        ordering = ['department__name', 'title']

    def __str__(self):
        return f"{self.title} - {self.department.name}"


class Role(TimeStampedUUIDModel):
    class RoleCode(models.TextChoices):
        ADMIN = 'ADMIN', _('Administrator')
        MARKETING = 'MARKETING', _('Marketing')
        IT = 'IT', _('Information Technology')
        OPERATIONS = 'OPERATIONS', _('Operations')
        ACCOUNTS = 'ACCOUNTS', _('Accounts & Finance')

    code = models.CharField(
        _("Role Code"),
        max_length=50,
        unique=True,
        db_index=True
    )
    name = models.CharField(_("Role Display Name"), max_length=100)
    description = models.TextField(_("Role Scope Description"), blank=True)
    is_system_reserved = models.BooleanField(_("System Reserved"), default=False)

    class Meta:
        verbose_name = _("Role")
        verbose_name_plural = _("Roles")
        ordering = ['name']

    def __str__(self):
        return self.name


class Permission(TimeStampedUUIDModel):
    class Category(models.TextChoices):
        PROFILE = 'PROFILE', _('Personal Profile')
        ATTENDANCE = 'ATTENDANCE', _('Attendance & Leave')
        EMPLOYEE = 'EMPLOYEE', _('Employee Management')
        ORGANIZATION = 'ORGANIZATION', _('Organization Structure')
        SECURITY = 'SECURITY', _('Security & Audit')

    code = models.CharField(_("Permission Code"), max_length=100, unique=True, db_index=True)
    name = models.CharField(_("Permission Name"), max_length=150)
    category = models.CharField(_("Category"), max_length=50, choices=Category.choices, default=Category.PROFILE)
    description = models.TextField(_("Permission Description"), blank=True)

    class Meta:
        verbose_name = _("Permission")
        verbose_name_plural = _("Permissions")
        ordering = ['category', 'code']

    def __str__(self):
        return f"[{self.category}] {self.name} ({self.code})"


class RolePermission(TimeStampedUUIDModel):
    role = models.ForeignKey(Role, on_delete=models.CASCADE, related_name='role_permissions')
    permission = models.ForeignKey(Permission, on_delete=models.CASCADE, related_name='permission_roles')

    class Meta:
        verbose_name = _("Role Permission")
        verbose_name_plural = _("Role Permissions")
        unique_together = ('role', 'permission')

    def __str__(self):
        return f"{self.role.name} -> {self.permission.code}"
