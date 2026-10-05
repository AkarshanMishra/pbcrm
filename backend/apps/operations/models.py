import uuid
from django.db import models
from django.conf import settings
from django.utils import timezone


class BookingOperation(models.Model):
    class PartnerType(models.TextChoices):
        BANQUET = 'banquet', 'Banquet / Venue'
        CAFE = 'cafe', 'Cafe / Lounge'
        RESORT = 'resort', 'Resort / Hotel'
        CATERER = 'caterer', 'Catering Partner'
        DECORATOR = 'decorator', 'Decoration Specialist'
        LOGISTICS = 'logistics', 'Logistics Partner'
        OTHER = 'other', 'Other Partner'

    class EventType(models.TextChoices):
        WEDDING = 'wedding', 'Wedding / Reception'
        CORPORATE = 'corporate_event', 'Corporate Event'
        BIRTHDAY = 'birthday_party', 'Birthday / Social'
        LIVE_MUSIC = 'live_music', 'Live Music / Night'
        SEMINAR = 'seminar', 'Conference / Seminar'
        CATERING = 'catering_order', 'Bulk Catering Order'
        BANQUET = 'banquet_booking', 'Banquet Booking'
        OTHER = 'other', 'Custom Event'

    class PaymentStatus(models.TextChoices):
        PAID = 'PAID', 'Fully Paid'
        PARTIAL = 'PARTIAL', 'Partially Paid (Deposit Received)'
        PENDING = 'PENDING', 'Payment Pending'
        REFUNDED = 'REFUNDED', 'Refund Processed'

    class PartnerConfirmationStatus(models.TextChoices):
        PENDING = 'PENDING', 'Pending Confirmation'
        CONFIRMED = 'CONFIRMED', 'Partner Confirmed'
        REJECTED = 'REJECTED', 'Partner Rejected'
        CHANGES_REQUESTED = 'CHANGES_REQUESTED', 'Changes Requested'

    class OperationsStatus(models.TextChoices):
        PREPARATION_PENDING = 'PREPARATION_PENDING', 'Preparation Pending'
        COORDINATION = 'COORDINATION', 'In Coordination'
        READINESS_CHECK = 'READINESS_CHECK', 'Readiness Inspection'
        IN_PROGRESS = 'IN_PROGRESS', 'In Progress'
        READY = 'READY', 'Service Ready'
        EXECUTING = 'EXECUTING', 'Currently Live / Executing'
        COMPLETED = 'COMPLETED', 'Completed & Verified'
        ISSUE_REPORTED = 'ISSUE_REPORTED', 'Issue Reported / Delayed'
        CANCELLED = 'CANCELLED', 'Cancelled'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    booking_code = models.CharField(max_length=32, unique=True, db_index=True)
    customer_name = models.CharField(max_length=255)
    customer_phone = models.CharField(max_length=32)
    customer_email = models.EmailField(blank=True, null=True)

    partner_name = models.CharField(max_length=255)
    partner_phone = models.CharField(max_length=32)
    partner_type = models.CharField(max_length=32, choices=PartnerType.choices, default=PartnerType.BANQUET)

    event_type = models.CharField(max_length=32, choices=EventType.choices, default=EventType.BANQUET)
    event_date = models.DateField(db_index=True)
    event_time_slot = models.CharField(max_length=100, default='10:00 AM - 04:00 PM')
    guest_count = models.IntegerField(default=50)

    package_name = models.CharField(max_length=255, default='Standard Executive Service')
    amount = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    payment_status = models.CharField(max_length=32, choices=PaymentStatus.choices, default=PaymentStatus.PARTIAL)
    partner_confirmation_status = models.CharField(max_length=32, choices=PartnerConfirmationStatus.choices, default=PartnerConfirmationStatus.CONFIRMED)
    
    operations_status = models.CharField(max_length=32, choices=OperationsStatus.choices, default=OperationsStatus.COORDINATION, db_index=True)
    readiness_percentage = models.IntegerField(default=0)
    
    special_instructions = models.TextField(blank=True, null=True)
    venue_address = models.TextField(blank=True, null=True)
    
    assigned_executive = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_operations_bookings'
    )
    manager = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='managed_operations_bookings'
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['event_date', 'created_at']

    def __str__(self):
        return f"{self.booking_code} - {self.customer_name} ({self.partner_name})"


class EventReadinessChecklist(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    booking = models.OneToOneField(BookingOperation, on_delete=models.CASCADE, related_name='readiness_checklist')
    
    hall_confirmed = models.BooleanField(default=False)
    seating_confirmed = models.BooleanField(default=False)
    decoration_confirmed = models.BooleanField(default=False)
    catering_confirmed = models.BooleanField(default=False)
    parking_confirmed = models.BooleanField(default=False)
    setup_confirmed = models.BooleanField(default=False)
    staff_confirmed = models.BooleanField(default=False)
    power_backup_confirmed = models.BooleanField(default=False)

    score_percentage = models.IntegerField(default=0)
    notes = models.TextField(blank=True, null=True)
    verified_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    verified_at = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def calculate_score(self):
        checks = [
            self.hall_confirmed,
            self.seating_confirmed,
            self.decoration_confirmed,
            self.catering_confirmed,
            self.parking_confirmed,
            self.setup_confirmed,
            self.staff_confirmed,
            self.power_backup_confirmed,
        ]
        score = int((sum(1 for c in checks if c) / len(checks)) * 100)
        self.score_percentage = score
        return score

    def save(self, *args, **kwargs):
        self.calculate_score()
        super().save(*args, **kwargs)
        # sync with booking readiness
        if self.booking:
            self.booking.readiness_percentage = self.score_percentage
            if self.score_percentage == 100 and self.booking.operations_status == BookingOperation.OperationsStatus.COORDINATION:
                self.booking.operations_status = BookingOperation.OperationsStatus.READY
            self.booking.save(update_fields=['readiness_percentage', 'operations_status'])

    def __str__(self):
        return f"Checklist for {self.booking.booking_code} ({self.score_percentage}%)"


class OperationsIssue(models.Model):
    class IssueCategory(models.TextChoices):
        PARTNER_DELAY = 'PARTNER_DELAY', 'Partner Response Delay'
        VENUE_DEFECT = 'VENUE_DEFECT', 'Venue Physical Defect / Missing Amenity'
        PAYMENT_DISPUTE = 'PAYMENT_DISPUTE', 'Payment / Invoice Dispute'
        CUSTOMER_COMPLAINT = 'CUSTOMER_COMPLAINT', 'Customer Service Complaint'
        CATERING_QUALITY = 'CATERING_QUALITY', 'Catering / Food Quality Issue'
        DECORATION_MISMATCH = 'DECORATION_MISMATCH', 'Decoration / Theme Mismatch'
        STAFF_SHORTAGE = 'STAFF_SHORTAGE', 'Operations Staff Shortage'
        LOGISTICS_DELAY = 'LOGISTICS_DELAY', 'Logistics / Transport Delay'
        EQUIPMENT_FAILURE = 'EQUIPMENT_FAILURE', 'Equipment / AV Failure'
        OTHER = 'OTHER', 'Other Operational Issue'

    class Priority(models.TextChoices):
        LOW = 'LOW', 'Low'
        MEDIUM = 'MEDIUM', 'Medium'
        HIGH = 'HIGH', 'High'
        CRITICAL = 'CRITICAL', 'Critical / Blocker'

    class Status(models.TextChoices):
        OPEN = 'OPEN', 'Open'
        ASSIGNED = 'ASSIGNED', 'Assigned'
        IN_PROGRESS = 'IN_PROGRESS', 'In Progress'
        ESCALATED = 'ESCALATED', 'Escalated to Management'
        RESOLVED = 'RESOLVED', 'Resolved'
        CLOSED = 'CLOSED', 'Closed'

    class EscalationLevel(models.TextChoices):
        EXECUTIVE = 'EXECUTIVE', 'Operations Executive'
        MANAGER = 'MANAGER', 'Operations Manager'
        ADMIN = 'ADMIN', 'Executive Management / Admin'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    issue_code = models.CharField(max_length=32, unique=True, db_index=True)
    category = models.CharField(max_length=32, choices=IssueCategory.choices, default=IssueCategory.PARTNER_DELAY)
    priority = models.CharField(max_length=20, choices=Priority.choices, default=Priority.HIGH)
    
    booking = models.ForeignKey(BookingOperation, on_delete=models.SET_NULL, null=True, blank=True, related_name='operations_issues')
    problem_statement = models.TextField()
    
    assigned_to = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_operations_issues')
    reported_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='reported_operations_issues')

    sla_hours = models.IntegerField(default=2)
    sla_deadline = models.DateTimeField()
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.OPEN, db_index=True)
    escalation_level = models.CharField(max_length=20, choices=EscalationLevel.choices, default=EscalationLevel.EXECUTIVE)

    resolution_notes = models.TextField(blank=True, null=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-priority', 'sla_deadline']

    def __str__(self):
        return f"{self.issue_code} [{self.priority}] - {self.category}"


class QualityInspection(models.Model):
    class InspectionResult(models.TextChoices):
        PASS = 'PASS', 'Pass / Approved'
        PASS_WITH_ISSUES = 'PASS_WITH_ISSUES', 'Pass with Minor Flags'
        FAIL = 'FAIL', 'Failed / Non-Compliant'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    inspection_code = models.CharField(max_length=32, unique=True, db_index=True)
    partner_name = models.CharField(max_length=255)
    booking = models.ForeignKey(BookingOperation, on_delete=models.SET_NULL, null=True, blank=True, related_name='quality_inspections')
    inspector = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='inspections_performed')
    
    inspection_date = models.DateField(default=timezone.localdate)
    result = models.CharField(max_length=32, choices=InspectionResult.choices, default=InspectionResult.PASS)
    score = models.IntegerField(default=100) # 0 to 100
    
    checklist_data = models.JSONField(default=dict)
    photos = models.JSONField(default=list)
    notes = models.TextField(blank=True, null=True)
    
    auto_generated_issue = models.ForeignKey(OperationsIssue, on_delete=models.SET_NULL, null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-inspection_date', '-created_at']

    def __str__(self):
        return f"{self.inspection_code} - {self.partner_name} ({self.result})"


class OperationalAsset(models.Model):
    class Category(models.TextChoices):
        AUDIO_VISUAL = 'AUDIO_VISUAL', 'Audio / Visual Equipment'
        POS_DEVICE = 'POS_DEVICE', 'POS Terminal & Scanner'
        FURNITURE = 'FURNITURE', 'Event Furniture & Staging'
        DECOR_PROP = 'DECOR_PROP', 'Decorative Props & Lighting'
        UNIFORM = 'UNIFORM', 'Operations Uniforms & Badges'
        SAFETY_EQUIPMENT = 'SAFETY_EQUIPMENT', 'Safety & First Aid Kit'
        LOGISTICS = 'LOGISTICS', 'Logistics & Trolleys'

    class Status(models.TextChoices):
        AVAILABLE = 'AVAILABLE', 'Available in Warehouse'
        ASSIGNED = 'ASSIGNED', 'Assigned to Event'
        IN_USE = 'IN_USE', 'Currently in Live Use'
        RETURNED = 'RETURNED', 'Returned Pending Check'
        MAINTENANCE = 'MAINTENANCE', 'Under Maintenance'
        DAMAGED = 'DAMAGED', 'Damaged / Write-off'

    class Condition(models.TextChoices):
        EXCELLENT = 'EXCELLENT', 'Excellent'
        GOOD = 'GOOD', 'Good'
        FAIR = 'FAIR', 'Fair'
        NEEDS_REPAIR = 'NEEDS_REPAIR', 'Needs Repair'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    asset_code = models.CharField(max_length=32, unique=True, db_index=True)
    name = models.CharField(max_length=255)
    category = models.CharField(max_length=32, choices=Category.choices, default=Category.AUDIO_VISUAL)
    status = models.CharField(max_length=32, choices=Status.choices, default=Status.AVAILABLE, db_index=True)
    condition = models.CharField(max_length=32, choices=Condition.choices, default=Condition.EXCELLENT)

    assigned_to = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_operational_assets')
    current_booking = models.ForeignKey(BookingOperation, on_delete=models.SET_NULL, null=True, blank=True)
    location = models.CharField(max_length=255, default='Central Operations Warehouse')
    serial_number = models.CharField(max_length=100, blank=True, null=True)
    last_inspected_at = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return f"[{self.asset_code}] {self.name} - {self.status}"


class OperationsRequest(models.Model):
    class RequestType(models.TextChoices):
        ADDITIONAL_STAFF = 'ADDITIONAL_STAFF', 'Additional Operations Staff'
        EQUIPMENT_REQUISITION = 'EQUIPMENT_REQUISITION', 'Equipment / Asset Requisition'
        BUDGET_APPROVAL = 'BUDGET_APPROVAL', 'Emergency Expense / Budget Approval'
        TIMELINE_EXTENSION = 'TIMELINE_EXTENSION', 'Service Timeline Extension'
        PARTNER_REPLACEMENT = 'PARTNER_REPLACEMENT', 'Emergency Partner Replacement'
        REFUND_OVERRIDE = 'REFUND_OVERRIDE', 'Customer Refund / Discount Override'
        TRANSPORT_SUPPORT = 'TRANSPORT_SUPPORT', 'Logistics / Transport Vehicle Support'

    class Status(models.TextChoices):
        NEW = 'NEW', 'New Request'
        REVIEW = 'REVIEW', 'Under Review'
        PROCESSING = 'PROCESSING', 'Processing'
        APPROVED = 'APPROVED', 'Approved'
        REJECTED = 'REJECTED', 'Rejected'
        COMPLETED = 'COMPLETED', 'Fulfilled & Completed'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    request_code = models.CharField(max_length=32, unique=True, db_index=True)
    request_type = models.CharField(max_length=32, choices=RequestType.choices, default=RequestType.ADDITIONAL_STAFF)
    title = models.CharField(max_length=255)
    description = models.TextField()
    amount = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)

    status = models.CharField(max_length=32, choices=Status.choices, default=Status.NEW, db_index=True)
    requester = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='operations_requests_made')
    approved_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='operations_requests_approved')
    approval_notes = models.TextField(blank=True, null=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.request_code} [{self.request_type}] - {self.title} ({self.status})"


class OperationsDailyReport(models.Model):
    class Status(models.TextChoices):
        DRAFT = 'DRAFT', 'Draft'
        SUBMITTED = 'SUBMITTED', 'Submitted'
        REVIEWED = 'REVIEWED', 'Reviewed by Manager'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    executive = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='operations_daily_reports')
    report_date = models.DateField(default=timezone.localdate, db_index=True)
    
    tasks_completed_count = models.IntegerField(default=0)
    bookings_handled_count = models.IntegerField(default=0)
    issues_resolved_count = models.IntegerField(default=0)
    followups_count = models.IntegerField(default=0)
    visits_count = models.IntegerField(default=0)
    quality_checks_count = models.IntegerField(default=0)

    summary_notes = models.TextField()
    challenges = models.TextField(blank=True, null=True)
    tomorrow_plan = models.TextField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.SUBMITTED)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('executive', 'report_date')
        ordering = ['-report_date']

    def __str__(self):
        return f"Daily Report - {self.executive.get_full_name()} ({self.report_date})"
