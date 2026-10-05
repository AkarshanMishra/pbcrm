import uuid
from django.db import models
from django.conf import settings
from django.utils import timezone
from apps.employees.models import Employee
from apps.organization.models import Department, Position


class JobOpening(models.Model):
    class Status(models.TextChoices):
        DRAFT = 'DRAFT', 'Draft'
        OPEN = 'OPEN', 'Open & Active'
        ON_HOLD = 'ON_HOLD', 'On Hold'
        FILLED = 'FILLED', 'Filled'
        CLOSED = 'CLOSED', 'Closed'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=255)
    code = models.CharField(max_length=32, unique=True, db_index=True)
    department = models.ForeignKey(Department, on_delete=models.SET_NULL, null=True, blank=True, related_name='job_openings')
    position = models.ForeignKey(Position, on_delete=models.SET_NULL, null=True, blank=True)
    location = models.CharField(max_length=150, default='Kanpur Headquarters / Hybrid')
    openings_count = models.IntegerField(default=1)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.OPEN, db_index=True)
    description = models.TextField(blank=True, null=True)
    requirements = models.TextField(blank=True, null=True)
    experience_required = models.CharField(max_length=50, default='1-3 Years')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.code}] {self.title} ({self.status})"


class CandidateApplication(models.Model):
    class Stage(models.TextChoices):
        APPLIED = 'APPLIED', 'Applied / New'
        SCREENING = 'SCREENING', 'Resume Screening'
        INTERVIEW = 'INTERVIEW', 'Interview Scheduled'
        SELECTED = 'SELECTED', 'Selected for Offer'
        OFFER = 'OFFER', 'Offer Rolled Out'
        JOINED = 'JOINED', 'Offer Accepted / Joined'
        REJECTED = 'REJECTED', 'Rejected'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    candidate_code = models.CharField(max_length=32, unique=True, db_index=True)
    job = models.ForeignKey(JobOpening, on_delete=models.CASCADE, related_name='applications')
    full_name = models.CharField(max_length=255)
    email = models.EmailField()
    phone = models.CharField(max_length=32)
    stage = models.CharField(max_length=20, choices=Stage.choices, default=Stage.APPLIED, db_index=True)
    resume_url = models.URLField(blank=True, null=True)
    interview_date = models.DateTimeField(null=True, blank=True)
    interviewer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='candidate_interviews')
    rating = models.IntegerField(default=0) # 1 to 5
    notes = models.TextField(blank=True, null=True)
    expected_salary = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.candidate_code} - {self.full_name} [{self.stage}]"


class OnboardingChecklist(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    employee = models.OneToOneField(Employee, on_delete=models.CASCADE, related_name='onboarding_checklist')
    
    # Steps in Wizard
    personal_verified = models.BooleanField(default=False)
    employment_details_set = models.BooleanField(default=False)
    documents_uploaded = models.BooleanField(default=False)
    id_verified = models.BooleanField(default=False)
    account_created = models.BooleanField(default=False)
    assets_assigned = models.BooleanField(default=False)
    training_assigned = models.BooleanField(default=False)
    manager_assigned = models.BooleanField(default=False)
    
    is_completed = models.BooleanField(default=False)
    completion_percentage = models.IntegerField(default=0)
    notes = models.TextField(blank=True, null=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def calculate_progress(self):
        steps = [
            self.personal_verified,
            self.employment_details_set,
            self.documents_uploaded,
            self.id_verified,
            self.account_created,
            self.assets_assigned,
            self.training_assigned,
            self.manager_assigned,
        ]
        pct = int((sum(1 for s in steps if s) / len(steps)) * 100)
        self.completion_percentage = pct
        self.is_completed = (pct == 100)
        return pct

    def save(self, *args, **kwargs):
        self.calculate_progress()
        if self.is_completed and not self.completed_at:
            self.completed_at = timezone.now()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Onboarding for {self.employee.user.employee_code} ({self.completion_percentage}%)"


class EmployeeDocument(models.Model):
    class DocType(models.TextChoices):
        ID_PROOF = 'ID_PROOF', 'Aadhaar / National ID'
        PAN = 'PAN', 'PAN Card'
        ADDRESS_PROOF = 'ADDRESS_PROOF', 'Address Proof'
        EDUCATION = 'EDUCATION', 'Education Degrees & Certificates'
        EXPERIENCE = 'EXPERIENCE', 'Experience & Relieving Letters'
        OFFER_LETTER = 'OFFER_LETTER', 'Signed Offer Letter'
        APPOINTMENT_LETTER = 'APPOINTMENT_LETTER', 'Appointment Letter'
        NDA = 'NDA', 'Signed Non-Disclosure Agreement'
        POLICY_AGREEMENT = 'POLICY_AGREEMENT', 'Employee Handbook & Policy Signoff'
        OTHER = 'OTHER', 'Other Verified Document'

    class Status(models.TextChoices):
        VERIFIED = 'VERIFIED', 'Verified 🟢'
        PENDING = 'PENDING', 'Pending Verification 🟠'
        EXPIRED = 'EXPIRED', 'Expired / Needs Renewal 🔴'
        MISSING = 'MISSING', 'Missing ⚠️'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    employee = models.ForeignKey(Employee, on_delete=models.CASCADE, related_name='hr_documents')
    document_type = models.CharField(max_length=32, choices=DocType.choices, default=DocType.ID_PROOF)
    title = models.CharField(max_length=255)
    document_number = models.CharField(max_length=100, blank=True, null=True)
    file_url = models.URLField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING, db_index=True)
    expiry_date = models.DateField(null=True, blank=True)
    verified_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    verified_at = models.DateTimeField(null=True, blank=True)
    remarks = models.TextField(blank=True, null=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['employee', 'document_type']

    def __str__(self):
        return f"{self.employee.user.employee_code} - {self.title} [{self.status}]"


class HRPolicy(models.Model):
    class Category(models.TextChoices):
        LEAVE = 'LEAVE', 'Leave & Time Off Policy'
        ATTENDANCE = 'ATTENDANCE', 'Attendance & Punctuality Policy'
        WFH = 'WFH', 'Work From Home / Remote Work Policy'
        CODE_OF_CONDUCT = 'CODE_OF_CONDUCT', 'Employee Code of Conduct'
        SECURITY = 'SECURITY', 'IT, Cyber Security & Device Usage'
        TRAVEL_EXPENSE = 'TRAVEL_EXPENSE', 'Travel & Expense Reimbursement'
        POSH = 'POSH', 'POSH & Workplace Safety Policy'
        HANDBOOK = 'HANDBOOK', 'General Employee Handbook'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    policy_code = models.CharField(max_length=32, unique=True, db_index=True)
    title = models.CharField(max_length=255)
    category = models.CharField(max_length=32, choices=Category.choices, default=Category.LEAVE)
    version = models.CharField(max_length=20, default='v1.0')
    content = models.TextField()
    effective_date = models.DateField(default=timezone.localdate)
    is_active = models.BooleanField(default=True)
    published_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-effective_date']

    def __str__(self):
        return f"{self.title} ({self.version})"


class PolicyAcknowledgement(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    policy = models.ForeignKey(HRPolicy, on_delete=models.CASCADE, related_name='acknowledgements')
    employee = models.ForeignKey(Employee, on_delete=models.CASCADE, related_name='policy_acknowledgements')
    acknowledged_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('policy', 'employee')

    def __str__(self):
        return f"{self.employee.user.employee_code} ack {self.policy.title}"


class PerformanceReview(models.Model):
    class Status(models.TextChoices):
        GOAL_SETTING = 'GOAL_SETTING', 'Goal Setting'
        MID_YEAR = 'MID_YEAR', 'Mid-Year Review'
        MANAGER_REVIEW = 'MANAGER_REVIEW', 'Manager Review'
        EMPLOYEE_FEEDBACK = 'EMPLOYEE_FEEDBACK', 'Employee Feedback'
        FINAL_REVIEW = 'FINAL_REVIEW', 'Final HR Review'
        COMPLETED = 'COMPLETED', 'Completed'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    review_code = models.CharField(max_length=32, unique=True, db_index=True)
    employee = models.ForeignKey(Employee, on_delete=models.CASCADE, related_name='performance_reviews')
    cycle_name = models.CharField(max_length=100, default='Annual Appraisal 2026')
    reviewer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='reviews_conducted')
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.MANAGER_REVIEW, db_index=True)
    rating = models.DecimalField(max_digits=3, decimal_places=1, default=4.0) # 1.0 to 5.0
    kpi_score = models.IntegerField(default=85) # 0 to 100
    competencies_score = models.IntegerField(default=80)
    manager_feedback = models.TextField(blank=True, null=True)
    employee_self_review = models.TextField(blank=True, null=True)
    development_areas = models.TextField(blank=True, null=True)
    goals_data = models.JSONField(default=list)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.review_code} - {self.employee.user.employee_code} ({self.rating}/5.0)"


class TrainingProgram(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.CharField(max_length=32, unique=True, db_index=True)
    title = models.CharField(max_length=255)
    description = models.TextField()
    is_mandatory = models.BooleanField(default=True)
    deadline = models.DateField()
    duration_hours = models.IntegerField(default=2)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"[{self.code}] {self.title}"


class TrainingEnrollment(models.Model):
    class Status(models.TextChoices):
        ASSIGNED = 'ASSIGNED', 'Assigned / Pending'
        IN_PROGRESS = 'IN_PROGRESS', 'In Progress'
        COMPLETED = 'COMPLETED', 'Completed'
        EXPIRED = 'EXPIRED', 'Overdue / Expired'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    program = models.ForeignKey(TrainingProgram, on_delete=models.CASCADE, related_name='enrollments')
    employee = models.ForeignKey(Employee, on_delete=models.CASCADE, related_name='training_enrollments')
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ASSIGNED, db_index=True)
    score_percentage = models.IntegerField(default=0)
    completed_at = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('program', 'employee')

    def __str__(self):
        return f"{self.employee.user.employee_code} - {self.program.title} [{self.status}]"


class HRRequest(models.Model):
    class RequestType(models.TextChoices):
        ATTENDANCE_CORRECTION = 'ATTENDANCE_CORRECTION', 'Attendance Correction'
        LEAVE = 'LEAVE', 'Leave Request'
        DOC_UPDATE = 'DOC_UPDATE', 'Document / ID Update'
        ADDRESS_UPDATE = 'ADDRESS_UPDATE', 'Address / Contact Update'
        BANK_UPDATE = 'BANK_UPDATE', 'Bank Details Update'
        EMPLOYMENT_LETTER = 'EMPLOYMENT_LETTER', 'Employment Verification Letter'
        EXPERIENCE_LETTER = 'EXPERIENCE_LETTER', 'Experience / Service Letter'
        SALARY_QUERY = 'SALARY_QUERY', 'Salary / Compensation Inquiry'
        TRANSFER = 'TRANSFER', 'Department Transfer'
        PROMOTION = 'PROMOTION', 'Promotion Consideration'
        RESIGNATION = 'RESIGNATION', 'Resignation / Exit Notice'
        ASSET_REQUEST = 'ASSET_REQUEST', 'Device / ID Card Re-issue'
        GRIEVANCE = 'GRIEVANCE', 'HR Confidential Grievance'

    class Status(models.TextChoices):
        SUBMITTED = 'SUBMITTED', 'Submitted'
        HR_REVIEW = 'HR_REVIEW', 'Under HR Review'
        MANAGER_REVIEW = 'MANAGER_REVIEW', 'Under Manager Review'
        APPROVED = 'APPROVED', 'Approved'
        REJECTED = 'REJECTED', 'Rejected'
        COMPLETED = 'COMPLETED', 'Completed / Fulfilled'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    request_code = models.CharField(max_length=32, unique=True, db_index=True)
    request_type = models.CharField(max_length=32, choices=RequestType.choices, default=RequestType.ATTENDANCE_CORRECTION)
    requester = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='hr_requests_made')
    title = models.CharField(max_length=255)
    details = models.TextField()
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.SUBMITTED, db_index=True)
    
    reviewed_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='hr_requests_reviewed')
    admin_notes = models.TextField(blank=True, null=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.request_code} [{self.request_type}] - {self.title} ({self.status})"


class OffboardingRecord(models.Model):
    class Status(models.TextChoices):
        RESIGNED = 'RESIGNED', 'Resignation Submitted'
        NOTICE_PERIOD = 'NOTICE_PERIOD', 'Serving Notice Period'
        CLEARANCE_PENDING = 'CLEARANCE_PENDING', 'Department Clearance Pending'
        FNF_COMPLETED = 'FNF_COMPLETED', 'Full & Final Settled'
        EXITED = 'EXITED', 'Formal Exit Complete'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    exit_code = models.CharField(max_length=32, unique=True, db_index=True)
    employee = models.OneToOneField(Employee, on_delete=models.CASCADE, related_name='offboarding_record')
    resignation_date = models.DateField(default=timezone.localdate)
    last_working_day = models.DateField()
    notice_period_days = models.IntegerField(default=30)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.RESIGNED, db_index=True)
    reason_for_leaving = models.TextField(blank=True, null=True)
    
    # 10-point offboarding checklist
    checklist_data = models.JSONField(default=dict)
    exit_interview_notes = models.TextField(blank=True, null=True)
    experience_letter_issued = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Exit {self.exit_code} - {self.employee.user.employee_code} ({self.status})"


class HRAnnouncement(models.Model):
    class Category(models.TextChoices):
        EVENT = 'EVENT', 'Company Event'
        HOLIDAY = 'HOLIDAY', 'Holiday Notice'
        GENERAL = 'GENERAL', 'General Announcement'
        MILESTONE = 'MILESTONE', 'Company Milestone / Celebration'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=255)
    category = models.CharField(max_length=20, choices=Category.choices, default=Category.EVENT)
    content = models.TextField()
    event_date = models.DateField(null=True, blank=True)
    published_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.category}] {self.title}"


class HRDailyReport(models.Model):
    class Status(models.TextChoices):
        DRAFT = 'DRAFT', 'Draft'
        SUBMITTED = 'SUBMITTED', 'Submitted'
        REVIEWED = 'REVIEWED', 'Reviewed by HR Manager'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    executive = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='hr_daily_reports')
    report_date = models.DateField(default=timezone.localdate, db_index=True)

    onboardings_count = models.IntegerField(default=0)
    leaves_processed_count = models.IntegerField(default=0)
    corrections_approved_count = models.IntegerField(default=0)
    candidates_interviewed_count = models.IntegerField(default=0)
    documents_verified_count = models.IntegerField(default=0)
    requests_resolved_count = models.IntegerField(default=0)

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
        return f"HR Report - {self.executive.get_full_name()} ({self.report_date})"
