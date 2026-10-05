import uuid
from django.db import models
from django.conf import settings
from django.utils import timezone


class Lead(models.Model):
    class LeadType(models.TextChoices):
        VENUE = 'venue', 'Venue / Banquet'
        VENDOR = 'vendor', 'Vendor / Supplier'
        PARTNER = 'partner', 'Corporate Partner'
        SPONSOR = 'sponsor', 'Sponsor / Event Organizer'
        CLIENT = 'client', 'Direct Client'

    class LeadStatus(models.TextChoices):
        NEW = 'new', 'New Lead'
        CONTACTED = 'contacted', 'Contacted'
        INTERESTED = 'interested', 'Interested'
        VISIT_SCHEDULED = 'visit_scheduled', 'Visit Scheduled'
        VISITED = 'visited', 'Visited'
        NEGOTIATION = 'negotiation', 'In Negotiation'
        ONBOARDING = 'onboarding', 'Onboarding'
        ACTIVE = 'active', 'Active / Won'
        LOST = 'lost', 'Lost / Dropped'

    class Priority(models.TextChoices):
        LOW = 'low', 'Low'
        MEDIUM = 'medium', 'Medium'
        HIGH = 'high', 'High'
        URGENT = 'urgent', 'Urgent'

    class InterestLevel(models.TextChoices):
        HIGH = 'high', 'High Interest'
        MEDIUM = 'medium', 'Medium Interest'
        LOW = 'low', 'Low Interest'
        UNDECIDED = 'undecided', 'Undecided'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    lead_code = models.CharField(max_length=32, unique=True, db_index=True)
    business_name = models.CharField(max_length=255)
    lead_type = models.CharField(max_length=32, choices=LeadType.choices, default=LeadType.VENUE)
    contact_person = models.CharField(max_length=150)
    phone = models.CharField(max_length=32, db_index=True)
    email = models.EmailField(blank=True, null=True)
    
    city = models.CharField(max_length=100, default='Kanpur')
    area = models.CharField(max_length=150, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    geo_latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    geo_longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)

    status = models.CharField(max_length=32, choices=LeadStatus.choices, default=LeadStatus.NEW, db_index=True)
    priority = models.CharField(max_length=20, choices=Priority.choices, default=Priority.MEDIUM)
    interest_level = models.CharField(max_length=20, choices=InterestLevel.choices, default=InterestLevel.UNDECIDED)
    source = models.CharField(max_length=50, default='field_scouting')
    estimated_deal_value = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)

    assigned_to = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_leads'
    )
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_leads'
    )
    
    next_follow_up_at = models.DateTimeField(null=True, blank=True, db_index=True)
    expected_decision_date = models.DateField(null=True, blank=True)
    notes = models.TextField(blank=True, null=True)
    tags = models.JSONField(default=list, blank=True)
    activity_timeline = models.JSONField(default=list, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', 'assigned_to']),
            models.Index(fields=['lead_type', 'city']),
        ]

    def __str__(self):
        return f"{self.business_name} ({self.lead_code})"

    def save(self, *args, **kwargs):
        if not self.lead_code:
            count = Lead.objects.count() + 1
            self.lead_code = f"PBL{count:06d}"
        super().save(*args, **kwargs)


class Visit(models.Model):
    class VisitPurpose(models.TextChoices):
        VENUE_ONBOARDING = 'venue_onboarding', 'Venue Onboarding'
        VENDOR_MEETING = 'vendor_meeting', 'Vendor Meeting'
        LEAD_FOLLOWUP = 'lead_followup', 'Lead Follow-up'
        SITE_AUDIT = 'site_audit', 'Site Audit & Verification'
        RELATIONSHIP = 'relationship', 'Relationship Management'

    class VisitStatus(models.TextChoices):
        SCHEDULED = 'scheduled', 'Scheduled'
        IN_PROGRESS = 'in_progress', 'In Progress'
        COMPLETED = 'completed', 'Completed'
        CANCELLED = 'cancelled', 'Cancelled'
        MISSED = 'missed', 'Missed'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    visit_code = models.CharField(max_length=32, unique=True, db_index=True)
    lead = models.ForeignKey(Lead, on_delete=models.CASCADE, related_name='visits', null=True, blank=True)
    partner_name = models.CharField(max_length=255)
    purpose = models.CharField(max_length=50, choices=VisitPurpose.choices, default=VisitPurpose.VENUE_ONBOARDING)
    assigned_employee = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='marketing_visits'
    )

    scheduled_start = models.DateTimeField(db_index=True)
    scheduled_end = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=32, choices=VisitStatus.choices, default=VisitStatus.SCHEDULED, db_index=True)
    
    check_in_time = models.DateTimeField(null=True, blank=True)
    check_out_time = models.DateTimeField(null=True, blank=True)
    
    location_name = models.CharField(max_length=255)
    expected_lat = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    expected_lng = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    actual_checkin_lat = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    actual_checkin_lng = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    is_location_verified = models.BooleanField(default=True)

    partner_interest = models.CharField(max_length=20, default='medium')
    expected_decision_date = models.DateField(null=True, blank=True)
    discussion_notes = models.TextField(blank=True, null=True)
    next_action = models.TextField(blank=True, null=True)
    next_follow_up_date = models.DateTimeField(null=True, blank=True)

    # Rich Onboarding Checklist: { "owner_details": true, "pan": true, "gst": true, "photos": true, ... }
    checklist = models.JSONField(default=dict, blank=True)
    # Uploaded / Captured Photos: [ { "category": "exterior", "url": "..." }, ... ]
    photos = models.JSONField(default=list, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['scheduled_start']

    def __str__(self):
        return f"{self.partner_name} - {self.scheduled_start.strftime('%Y-%m-%d %H:%M')}"

    def save(self, *args, **kwargs):
        if not self.visit_code:
            count = Visit.objects.count() + 1
            self.visit_code = f"PBV{count:06d}"
        super().save(*args, **kwargs)


class FollowUp(models.Model):
    class FollowUpType(models.TextChoices):
        CALL = 'call', 'Phone Call'
        WHATSAPP = 'whatsapp', 'WhatsApp Chat'
        MEETING = 'meeting', 'In-Person Meeting'
        VISIT = 'visit', 'Site Visit'
        EMAIL = 'email', 'Email'

    class FollowUpStatus(models.TextChoices):
        PENDING = 'pending', 'Pending'
        COMPLETED = 'completed', 'Completed'
        CANCELLED = 'cancelled', 'Cancelled'
        RESCHEDULED = 'rescheduled', 'Rescheduled'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    lead = models.ForeignKey(Lead, on_delete=models.CASCADE, related_name='followups')
    employee = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='marketing_followups')
    type = models.CharField(max_length=32, choices=FollowUpType.choices, default=FollowUpType.CALL)
    scheduled_at = models.DateTimeField(db_index=True)
    status = models.CharField(max_length=32, choices=FollowUpStatus.choices, default=FollowUpStatus.PENDING, db_index=True)
    reminder_sent = models.BooleanField(default=False)
    notes = models.TextField(blank=True, null=True)
    outcome = models.CharField(max_length=255, blank=True, null=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['scheduled_at']

    def __str__(self):
        return f"{self.type.upper()} with {self.lead.business_name} at {self.scheduled_at}"


class PartnerOnboarding(models.Model):
    class PartnerType(models.TextChoices):
        VENUE = 'venue', 'Venue / Banquet'
        VENDOR = 'vendor', 'General Vendor'
        CATERER = 'caterer', 'Catering Partner'
        DECORATOR = 'decorator', 'Decorator'
        PHOTOGRAPHER = 'photographer', 'Photographer / Media'

    class WorkflowStep(models.TextChoices):
        INFO = 'info', '1. Partner Information'
        DOCUMENTS = 'documents', '2. Documents Collection'
        KYC = 'kyc', '3. KYC Verification'
        PHOTOS = 'photos', '4. Property Photos'
        AMENITIES = 'amenities', '5. Amenities & Services'
        PACKAGES = 'packages', '6. Packages & Pricing'
        MANAGER_REVIEW = 'manager_review', '7. Manager Review'
        ADMIN_APPROVAL = 'admin_approval', '8. Admin Approval'
        ACTIVE = 'active', '9. Active Live Partner'

    class OnboardingStatus(models.TextChoices):
        DRAFT = 'draft', 'Draft / In Progress'
        UNDER_REVIEW = 'under_review', 'Submitted for Review'
        CHANGES_REQUESTED = 'changes_requested', 'Changes Requested'
        APPROVED = 'approved', 'Approved'
        ACTIVE = 'active', 'Active & Live'
        REJECTED = 'rejected', 'Rejected'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    onboarding_code = models.CharField(max_length=32, unique=True, db_index=True)
    lead = models.ForeignKey(Lead, on_delete=models.SET_NULL, null=True, blank=True, related_name='onboardings')
    partner_name = models.CharField(max_length=255)
    partner_type = models.CharField(max_length=50, choices=PartnerType.choices, default=PartnerType.VENUE)
    assigned_executive = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='onboarding_submissions')

    workflow_step = models.CharField(max_length=32, choices=WorkflowStep.choices, default=WorkflowStep.INFO)
    status = models.CharField(max_length=32, choices=OnboardingStatus.choices, default=OnboardingStatus.DRAFT, db_index=True)
    progress_percentage = models.IntegerField(default=10)

    # Step Data Stores
    info_data = models.JSONField(default=dict, blank=True)
    documents_data = models.JSONField(default=dict, blank=True) # { "aadhaar": "...", "pan": "...", "gst": "..." }
    kyc_verified = models.BooleanField(default=False)
    photos_data = models.JSONField(default=list, blank=True) # [ { "category": "exterior", "url": "..." } ]
    amenities_data = models.JSONField(default=list, blank=True) # [ "AC", "Power Backup", "Valet Parking" ]
    packages_data = models.JSONField(default=list, blank=True) # [ { "name": "Royal Package", "price": 120000 } ]
    terms_accepted = models.BooleanField(default=False)

    manager_approved_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='manager_approved_onboardings')
    admin_approved_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='admin_approved_onboardings')
    approval_notes = models.TextField(blank=True, null=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        if not self.onboarding_code:
            count = PartnerOnboarding.objects.count() + 1
            self.onboarding_code = f"PBO{count:06d}"
        super().save(*args, **kwargs)


class MarketingTarget(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    employee = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='marketing_targets')
    month = models.CharField(max_length=7, db_index=True) # "YYYY-MM"
    
    target_visits = models.IntegerField(default=20)
    completed_visits = models.IntegerField(default=0)
    
    target_followups = models.IntegerField(default=50)
    completed_followups = models.IntegerField(default=0)
    
    target_leads = models.IntegerField(default=15)
    completed_leads = models.IntegerField(default=0)

    target_onboardings = models.IntegerField(default=5)
    completed_onboardings = models.IntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('employee', 'month')


class MarketingDailyReport(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    employee = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='marketing_reports')
    date = models.DateField(default=timezone.now, db_index=True)

    auto_tasks_completed = models.IntegerField(default=0)
    auto_visits_completed = models.IntegerField(default=0)
    auto_followups_completed = models.IntegerField(default=0)
    auto_leads_created = models.IntegerField(default=0)
    auto_onboardings_completed = models.IntegerField(default=0)

    summary = models.TextField()
    challenges = models.TextField(blank=True, null=True)
    tomorrow_plan = models.TextField(blank=True, null=True)

    status = models.CharField(max_length=20, default='submitted')
    reviewed_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='reviewed_marketing_reports')
    review_feedback = models.TextField(blank=True, null=True)
    submitted_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date']
        unique_together = ('employee', 'date')
