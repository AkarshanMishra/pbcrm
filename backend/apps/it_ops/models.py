import re
from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from django.utils import timezone
from apps.core.models import TimeStampedUUIDModel
from apps.employees.models import Employee


def generate_incident_number():
    year = timezone.now().year
    prefix = f"INC-{year}-"
    last_inc = ITIncident.objects.filter(incident_number__startswith=prefix).order_by('-incident_number').first()
    if not last_inc:
        return f"{prefix}1001"
    match = re.search(rf"{prefix}(\d+)", last_inc.incident_number)
    if match:
        next_num = int(match.group(1)) + 1
        return f"{prefix}{next_num:04d}"
    return f"{prefix}{ITIncident.objects.count() + 1001:04d}"


def generate_asset_tag():
    prefix = "IT-AST-"
    count = ITAsset.objects.count() + 101
    return f"{prefix}{count:04d}"


class SystemComponent(TimeStampedUUIDModel):
    class ComponentType(models.TextChoices):
        SERVER = 'SERVER', _('Server / Compute')
        API = 'API', _('API / Gateway')
        DATABASE = 'DATABASE', _('Database')
        APPLICATION = 'APPLICATION', _('Frontend / Application')
        DOMAIN = 'DOMAIN', _('Domain / DNS')
        SSL_CERT = 'SSL_CERT', _('SSL Certificate')
        CLOUD_SERVICE = 'CLOUD_SERVICE', _('Cloud Service')
        SCHEDULED_JOB = 'SCHEDULED_JOB', _('Scheduled / Cron Job')
        BACKUP = 'BACKUP', _('Backup Service')
        INTEGRATION = 'INTEGRATION', _('Third-Party Integration')

    class HealthStatus(models.TextChoices):
        OPERATIONAL = 'OPERATIONAL', _('Operational')
        DEGRADED = 'DEGRADED', _('Degraded Performance')
        WARNING = 'WARNING', _('Warning / Attention')
        DOWN = 'DOWN', _('Major Outage / Down')
        MAINTENANCE = 'MAINTENANCE', _('Scheduled Maintenance')

    name = models.CharField(max_length=150)
    slug = models.SlugField(max_length=150, unique=True)
    component_type = models.CharField(max_length=30, choices=ComponentType.choices, default=ComponentType.API)
    status = models.CharField(max_length=20, choices=HealthStatus.choices, default=HealthStatus.OPERATIONAL)
    endpoint_or_host = models.CharField(max_length=255, blank=True)
    uptime_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=99.95)
    last_health_check = models.DateTimeField(default=timezone.now)
    ssl_expiry_date = models.DateField(null=True, blank=True)
    responsible_team = models.CharField(max_length=100, default="Core Backend / DevOps")
    dependencies_info = models.TextField(blank=True)
    description = models.TextField(blank=True)

    class Meta:
        ordering = ['name']
        verbose_name = _('System Component')
        verbose_name_plural = _('System Components')

    def __str__(self):
        return f"{self.name} [{self.get_status_display()}]"


class ITIncident(TimeStampedUUIDModel):
    class Category(models.TextChoices):
        HARDWARE = 'HARDWARE', _('Hardware')
        SOFTWARE = 'SOFTWARE', _('Software')
        NETWORK = 'NETWORK', _('Network')
        SERVER = 'SERVER', _('Server')
        DATABASE = 'DATABASE', _('Database')
        ACCESS_REQUEST = 'ACCESS_REQUEST', _('Access Request')
        EMAIL = 'EMAIL', _('Email / Communication')
        SECURITY = 'SECURITY', _('Security')
        APPLICATION_BUG = 'APPLICATION_BUG', _('Application Bug')
        USER_SUPPORT = 'USER_SUPPORT', _('User Support')
        INFRASTRUCTURE = 'INFRASTRUCTURE', _('Infrastructure')

    class Priority(models.TextChoices):
        CRITICAL = 'CRITICAL', _('Critical')
        HIGH = 'HIGH', _('High')
        MEDIUM = 'MEDIUM', _('Medium')
        LOW = 'LOW', _('Low')

    class Status(models.TextChoices):
        OPEN = 'OPEN', _('Open')
        INVESTIGATING = 'INVESTIGATING', _('Investigating')
        IN_PROGRESS = 'IN_PROGRESS', _('In Progress')
        RESOLVED = 'RESOLVED', _('Resolved')
        CLOSED = 'CLOSED', _('Closed')

    incident_number = models.CharField(max_length=30, unique=True, default=generate_incident_number, db_index=True)
    title = models.CharField(max_length=255)
    description = models.TextField()
    category = models.CharField(max_length=30, choices=Category.choices, default=Category.APPLICATION_BUG)
    priority = models.CharField(max_length=20, choices=Priority.choices, default=Priority.MEDIUM)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.OPEN)

    impact = models.TextField(blank=True, help_text="Who or what systems are affected")
    affected_system = models.ForeignKey(SystemComponent, on_delete=models.SET_NULL, null=True, blank=True, related_name='incidents')
    
    reporter = models.ForeignKey(Employee, on_delete=models.SET_NULL, null=True, blank=True, related_name='reported_it_incidents')
    assignee = models.ForeignKey(Employee, on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_it_incidents')
    
    root_cause = models.TextField(blank=True)
    resolution_notes = models.TextField(blank=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    escalated = models.BooleanField(default=False)

    class Meta:
        ordering = ['-created_at']
        verbose_name = _('IT Incident / Ticket')
        verbose_name_plural = _('IT Incidents / Tickets')

    def __str__(self):
        return f"[{self.incident_number}] {self.title} ({self.priority})"


class ITIncidentComment(TimeStampedUUIDModel):
    incident = models.ForeignKey(ITIncident, on_delete=models.CASCADE, related_name='comments')
    author = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    comment_text = models.TextField()
    is_internal_log = models.BooleanField(default=False)

    class Meta:
        ordering = ['created_at']


class PullRequest(TimeStampedUUIDModel):
    class BuildStatus(models.TextChoices):
        PASSED = 'PASSED', _('Passed')
        FAILED = 'FAILED', _('Failed')
        RUNNING = 'RUNNING', _('Running')
        QUEUED = 'QUEUED', _('Queued')

    class ReviewStatus(models.TextChoices):
        PENDING = 'PENDING', _('Pending')
        APPROVED = 'APPROVED', _('Approved')
        CHANGES_REQUESTED = 'CHANGES_REQUESTED', _('Changes Requested')

    class PRState(models.TextChoices):
        OPEN = 'OPEN', _('Open')
        MERGED = 'MERGED', _('Merged')
        CLOSED = 'CLOSED', _('Closed')

    pr_number = models.PositiveIntegerField(unique=True)
    title = models.CharField(max_length=255)
    repository = models.CharField(max_length=150, default="partybala/core-platform")
    source_branch = models.CharField(max_length=150)
    target_branch = models.CharField(max_length=150, default="main")
    author = models.ForeignKey(Employee, on_delete=models.CASCADE, related_name='authored_prs')
    reviewer = models.ForeignKey(Employee, on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_reviews')
    
    build_status = models.CharField(max_length=20, choices=BuildStatus.choices, default=BuildStatus.RUNNING)
    test_status = models.CharField(max_length=20, choices=BuildStatus.choices, default=BuildStatus.PASSED)
    review_status = models.CharField(max_length=20, choices=ReviewStatus.choices, default=ReviewStatus.PENDING)
    state = models.CharField(max_length=20, choices=PRState.choices, default=PRState.OPEN)
    
    commit_hash = models.CharField(max_length=40, blank=True)
    summary = models.TextField(blank=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"PR #{self.pr_number} - {self.title}"


class DeploymentRecord(TimeStampedUUIDModel):
    class Environment(models.TextChoices):
        DEVELOPMENT = 'DEVELOPMENT', _('Development')
        STAGING = 'STAGING', _('Staging')
        PRODUCTION = 'PRODUCTION', _('Production')

    class DeployStatus(models.TextChoices):
        PENDING = 'PENDING', _('Pending Approval')
        APPROVED = 'APPROVED', _('Approved')
        IN_PROGRESS = 'IN_PROGRESS', _('In Progress')
        SUCCESS = 'SUCCESS', _('Success')
        FAILED = 'FAILED', _('Failed')
        ROLLBACK = 'ROLLBACK', _('Rolled Back')

    application = models.CharField(max_length=150, default="PartyBala Enterprise CRM")
    environment = models.CharField(max_length=30, choices=Environment.choices, default=Environment.STAGING)
    version_tag = models.CharField(max_length=50, default="v2.8.4")
    commit_hash = models.CharField(max_length=40, default="a8f9c12")
    build_passed = models.BooleanField(default=True)
    tests_passed = models.BooleanField(default=True)
    
    triggered_by = models.ForeignKey(Employee, on_delete=models.CASCADE, related_name='triggered_deployments')
    approved_by = models.ForeignKey(Employee, on_delete=models.SET_NULL, null=True, blank=True, related_name='approved_deployments')
    
    status = models.CharField(max_length=20, choices=DeployStatus.choices, default=DeployStatus.SUCCESS)
    logs_output = models.TextField(blank=True)
    release_notes = models.TextField(blank=True)
    deployed_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ['-deployed_at']

    def __str__(self):
        return f"[{self.environment}] {self.application} ({self.version_tag}) - {self.status}"


class ITAsset(TimeStampedUUIDModel):
    class AssetType(models.TextChoices):
        LAPTOP = 'LAPTOP', _('Laptop')
        DESKTOP = 'DESKTOP', _('Desktop')
        MOBILE = 'MOBILE', _('Mobile Device')
        MONITOR = 'MONITOR', _('External Monitor')
        KEYBOARD = 'KEYBOARD', _('Keyboard / Peripherals')
        ROUTER = 'ROUTER', _('Network Router / Switch')
        SERVER = 'SERVER', _('Rack / On-Premise Server')
        PRINTER = 'PRINTER', _('Office Printer')
        SOFTWARE_LICENSE = 'SOFTWARE_LICENSE', _('Software License / Seat')

    class AssetStatus(models.TextChoices):
        ACTIVE = 'ACTIVE', _('Active / In Use')
        AVAILABLE = 'AVAILABLE', _('Available in Stock')
        MAINTENANCE = 'MAINTENANCE', _('Under Maintenance')
        RETIRED = 'RETIRED', _('Retired / Deprecated')

    asset_tag = models.CharField(max_length=50, unique=True, default=generate_asset_tag)
    asset_type = models.CharField(max_length=30, choices=AssetType.choices, default=AssetType.LAPTOP)
    name = models.CharField(max_length=200)
    brand = models.CharField(max_length=100)
    model_name = models.CharField(max_length=100)
    serial_number = models.CharField(max_length=100, blank=True)
    
    assigned_to = models.ForeignKey(Employee, on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_hardware_assets')
    status = models.CharField(max_length=20, choices=AssetStatus.choices, default=AssetStatus.ACTIVE)
    
    purchase_date = models.DateField(null=True, blank=True)
    warranty_expiry = models.DateField(null=True, blank=True)
    specs = models.JSONField(default=dict, blank=True)
    installed_software = models.TextField(blank=True)
    maintenance_history = models.TextField(blank=True)

    class Meta:
        ordering = ['asset_tag']

    def __str__(self):
        return f"{self.asset_tag} - {self.name} ({self.status})"


class ITAccessRequest(TimeStampedUUIDModel):
    class RequestType(models.TextChoices):
        VPN = 'VPN', _('VPN Access')
        DATABASE = 'DATABASE', _('Database Read/Write Access')
        SERVER_SSH = 'SERVER_SSH', _('Server SSH Access')
        SOFTWARE_INSTALL = 'SOFTWARE_INSTALL', _('Licensed Software Installation')
        CLOUD_IAM = 'CLOUD_IAM', _('Cloud / AWS / GCP IAM Role')
        NEW_EMPLOYEE_SETUP = 'NEW_EMPLOYEE_SETUP', _('New Hire Hardware & IT Setup')
        EMAIL = 'EMAIL', _('Email Alias / Distribution List')
        HARDWARE_REPLACEMENT = 'HARDWARE_REPLACEMENT', _('Hardware Replacement / Upgrade')

    class Status(models.TextChoices):
        REQUESTED = 'REQUESTED', _('Requested')
        IT_REVIEW = 'IT_REVIEW', _('Under IT Review')
        ASSIGNED = 'ASSIGNED', _('Assigned to Engineer')
        IN_PROGRESS = 'IN_PROGRESS', _('In Progress')
        RESOLVED = 'RESOLVED', _('Resolved / Provisioned')
        CLOSED = 'CLOSED', _('Closed')
        REJECTED = 'REJECTED', _('Rejected')

    request_number = models.CharField(max_length=30, unique=True)
    request_type = models.CharField(max_length=30, choices=RequestType.choices, default=RequestType.SOFTWARE_INSTALL)
    title = models.CharField(max_length=255)
    justification = models.TextField()
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.REQUESTED)
    
    requester = models.ForeignKey(Employee, on_delete=models.CASCADE, related_name='raised_it_requests')
    assigned_engineer = models.ForeignKey(Employee, on_delete=models.SET_NULL, null=True, blank=True, related_name='handled_it_requests')
    approved_by = models.ForeignKey(Employee, on_delete=models.SET_NULL, null=True, blank=True, related_name='approved_it_requests')
    
    provisioned_details = models.TextField(blank=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.request_number}] {self.title} ({self.status})"


class KnowledgeArticle(TimeStampedUUIDModel):
    class Category(models.TextChoices):
        SOPS = 'SOPS', _('Standard Operating Procedures')
        TROUBLESHOOTING = 'TROUBLESHOOTING', _('Troubleshooting Runbook')
        DEPLOYMENT = 'DEPLOYMENT', _('Deployment Guide')
        DATABASE = 'DATABASE', _('Database Guide')
        SECURITY = 'SECURITY', _('Security Procedure')
        NETWORK = 'NETWORK', _('Network & Infrastructure')
        API_DOCS = 'API_DOCS', _('API & Architecture Documentation')
        EMPLOYEE_GUIDES = 'EMPLOYEE_GUIDES', _('General Employee IT Guide')

    title = models.CharField(max_length=255)
    slug = models.SlugField(max_length=255, unique=True)
    category = models.CharField(max_length=30, choices=Category.choices, default=Category.TROUBLESHOOTING)
    summary = models.TextField()
    content = models.TextField(help_text="Detailed markdown documentation or steps")
    steps_checklist = models.JSONField(default=list, blank=True)
    author = models.ForeignKey(Employee, on_delete=models.SET_NULL, null=True, blank=True)
    view_count = models.PositiveIntegerField(default=0)
    tags = models.JSONField(default=list, blank=True)

    class Meta:
        ordering = ['title']

    def __str__(self):
        return f"[{self.get_category_display()}] {self.title}"


class ITDailyReport(TimeStampedUUIDModel):
    developer = models.ForeignKey(Employee, on_delete=models.CASCADE, related_name='it_daily_reports')
    report_date = models.DateField(default=timezone.localdate)
    
    tasks_completed_count = models.PositiveIntegerField(default=0)
    bugs_fixed_count = models.PositiveIntegerField(default=0)
    tickets_resolved_count = models.PositiveIntegerField(default=0)
    deployments_count = models.PositiveIntegerField(default=0)
    code_reviews_count = models.PositiveIntegerField(default=0)
    
    incidents_handled = models.TextField(blank=True)
    blockers = models.TextField(blank=True)
    tomorrow_plan = models.TextField(blank=True)
    summary_notes = models.TextField(blank=True)

    class Meta:
        unique_together = ('developer', 'report_date')
        ordering = ['-report_date']

    def __str__(self):
        code = getattr(self.developer.user, 'employee_code', 'PBE000000') if hasattr(self.developer, 'user') else 'PBE000000'
        return f"IT Daily Report - {code} ({self.report_date})"
