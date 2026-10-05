import os
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))

import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

from django.utils import timezone
from datetime import timedelta, date
from decimal import Decimal
from django.contrib.auth import get_user_model
from apps.organization.models import Department, Position, Role
from apps.employees.models import Employee
from apps.attendance.models import Attendance, AttendanceCorrection
from apps.hr.models import (
    JobOpening,
    CandidateApplication,
    OnboardingChecklist,
    EmployeeDocument,
    HRPolicy,
    PolicyAcknowledgement,
    PerformanceReview,
    TrainingProgram,
    TrainingEnrollment,
    HRRequest,
    OffboardingRecord,
    HRAnnouncement,
    HRDailyReport,
)

User = get_user_model()

def seed_hr():
    print("[HR] Seeding HR Enterprise Lifecycle & Management Data...")
    
    # 1. Ensure HR Department & Positions
    hr_dept, _ = Department.objects.get_or_create(
        name="Human Resources",
        defaults={"code": "HR", "description": "HR, Talent Acquisition, People Operations & Lifecycle"}
    )

    it_dept, _ = Department.objects.get_or_create(
        name="Information Technology",
        defaults={"code": "IT", "description": "Software Development, Cloud & Technical Operations"}
    )
    
    ops_dept, _ = Department.objects.get_or_create(
        name="Operations",
        defaults={"code": "OPS", "description": "Ground Operations, Logistics & Quality Assurance"}
    )

    pos_hr_mgr, _ = Position.objects.get_or_create(
        title="HR Manager",
        department=hr_dept,
        defaults={"code": "HR-MGR", "description": "HR Leadership"}
    )
    pos_hr_exec, _ = Position.objects.get_or_create(
        title="HR Executive",
        department=hr_dept,
        defaults={"code": "HR-EXEC", "description": "HR Operations & Lifecycle"}
    )
    pos_recruiter, _ = Position.objects.get_or_create(
        title="Talent Acquisition Specialist",
        department=hr_dept,
        defaults={"code": "HR-REC", "description": "Recruitment & Hiring"}
    )

    # 2. Get Users / Employees
    admin_user = User.objects.filter(is_superuser=True).first()
    if not admin_user:
        admin_user = User.objects.create_superuser('admin@pcrm.local', 'PBA000001', 'AdminPassword@123!')

    hr_user = User.objects.filter(email='hr.lead@pcrm.local').first()
    if not hr_user:
        hr_user = User.objects.filter(employee_profile__department__code='HR').first()
    if not hr_user:
        hr_user = User.objects.create_user(
            email='hr.lead@pcrm.local',
            employee_code='PBH000001',
            password='Password@123!'
        )
    
    role_admin, _ = Role.objects.get_or_create(
        code=Role.RoleCode.ADMIN,
        defaults={"name": "Administrator", "is_system_reserved": True}
    )

    # Ensure HR employee profile
    hr_emp, _ = Employee.objects.get_or_create(
        user=hr_user,
        defaults={
            'first_name': 'Ananya',
            'last_name': 'Sharma',
            'department': hr_dept,
            'position': pos_hr_mgr,
            'role': role_admin,
            'employment_type': 'FULL_TIME',
            'joining_date': date(2023, 6, 1),
            'address': 'Civil Lines, Kanpur, Uttar Pradesh'
        }
    )

    all_employees = list(Employee.objects.all())
    print(f"  Found {len(all_employees)} total employees in database.")

    # 3. Seed Job Openings
    jobs_data = [
        ("Senior Flutter / Mobile Architect", "JOB-2026-001", it_dept, "Kanpur / Remote", 2, "OPEN", "5-8 Years", "Lead the cross-platform mobile & desktop client architecture using Flutter."),
        ("Lead Cloud & DevOps Engineer", "JOB-2026-002", it_dept, "Kanpur / Hybrid", 1, "OPEN", "4-6 Years", "Manage GCP, Kubernetes, CI/CD pipelines, and PostgreSQL databases."),
        ("Operations Field Manager", "JOB-2026-003", ops_dept, "Lucknow & Kanpur", 3, "OPEN", "3-5 Years", "Oversee venue operations, partner SLAs, and team inspections."),
        ("B2B Marketing & Growth Specialist", "JOB-2026-004", None, "Kanpur HQ", 2, "OPEN", "2-4 Years", "Scale enterprise lead generation and institutional partnerships."),
        ("Senior HR Generalist", "JOB-2026-005", hr_dept, "Kanpur HQ", 1, "OPEN", "3-5 Years", "Drive onboarding, employee relations, performance reviews, and compliance."),
        ("Quality Assurance Automation Engineer", "JOB-2026-006", it_dept, "Kanpur / Hybrid", 2, "ON_HOLD", "2-4 Years", "Build automated test suites for Django APIs and Flutter apps."),
        ("Accounts & Financial Analyst", "JOB-2026-007", None, "Kanpur HQ", 1, "OPEN", "2-5 Years", "Manage payroll calculations, GST filings, and monthly P&L audits."),
        ("Customer Experience Lead", "JOB-2026-008", ops_dept, "Kanpur HQ", 1, "FILLED", "3-5 Years", "Lead customer happiness and resolve client escalations."),
    ]

    job_instances = []
    for title, code, dept, loc, count, status, exp, desc in jobs_data:
        job, _ = JobOpening.objects.update_or_create(
            code=code,
            defaults={
                'title': title,
                'department': dept,
                'location': loc,
                'openings_count': count,
                'status': status,
                'experience_required': exp,
                'description': desc,
                'requirements': "Relevant degree, proven track record, and strong communication skills."
            }
        )
        job_instances.append(job)
    print(f"  Created {len(job_instances)} Job Openings.")

    # 4. Seed Candidates Pipeline
    candidates_data = [
        ("CAN-101", "Pooja Verma", "pooja.v@gmail.com", "+91 9876543210", job_instances[0], CandidateApplication.Stage.INTERVIEW, 4, "Strong Flutter state management and clean architecture experience. Technical round completed."),
        ("CAN-102", "Vikram Rathore", "vikram.r@gmail.com", "+91 9876543211", job_instances[0], CandidateApplication.Stage.SELECTED, 5, "Exceptional problem solving. Recommended for offer rollout."),
        ("CAN-103", "Rohan Mehta", "rohan.m@outlook.com", "+91 9876543212", job_instances[1], CandidateApplication.Stage.OFFER, 5, "Offer letter sent. Expected joining date next Monday."),
        ("CAN-104", "Sneha Kapoor", "sneha.k@yahoo.com", "+91 9876543213", job_instances[2], CandidateApplication.Stage.SCREENING, 3, "Experience in FMCG and venue management. Screening call scheduled."),
        ("CAN-105", "Amitabh Sen", "amitabh.sen@rediffmail.com", "+91 9876543214", job_instances[3], CandidateApplication.Stage.APPLIED, 0, "Application received via LinkedIn."),
        ("CAN-106", "Kavita Nair", "kavita.nair@gmail.com", "+91 9876543215", job_instances[4], CandidateApplication.Stage.JOINED, 5, "Joined on 1st October. Onboarding initiated."),
        ("CAN-107", "Deepak Joshi", "deepak.j@gmail.com", "+91 9876543216", job_instances[0], CandidateApplication.Stage.REJECTED, 2, "Lacks production mobile architecture depth."),
    ]

    for c_code, c_name, c_email, c_phone, c_job, c_stage, c_rating, c_notes in candidates_data:
        CandidateApplication.objects.update_or_create(
            candidate_code=c_code,
            defaults={
                'job': c_job,
                'full_name': c_name,
                'email': c_email,
                'phone': c_phone,
                'stage': c_stage,
                'rating': c_rating,
                'notes': c_notes,
                'interviewer': hr_user,
                'interview_date': timezone.now() + timedelta(days=2) if c_stage == CandidateApplication.Stage.INTERVIEW else None
            }
        )

    # 5. Seed HR Policies & Acknowledgements
    policies_data = [
        ("POL-001", "Comprehensive Leave & Time-Off Policy 2026", HRPolicy.Category.LEAVE, "v2.1", "Employees are entitled to 12 Casual Leaves, 10 Sick Leaves, and 15 Earned Leaves annually. Applications must be submitted via the PCRM mobile app with 48 hours notice.", date(2026, 1, 1)),
        ("POL-002", "Attendance & Working Hours Standard", HRPolicy.Category.ATTENDANCE, "v3.0", "Core hours are 09:30 AM to 06:30 PM. Geofenced check-in is mandatory via mobile. Grace period is 15 minutes up to 3 times per month.", date(2026, 1, 1)),
        ("POL-003", "Hybrid Work & Work From Home (WFH) Guidelines", HRPolicy.Category.WFH, "v1.5", "Employees in eligible technical and executive roles may avail up to 2 WFH days per week with prior manager approval.", date(2026, 2, 1)),
        ("POL-004", "Enterprise Code of Conduct & Workplace Ethics", HRPolicy.Category.CODE_OF_CONDUCT, "v4.0", "PCRM maintains zero tolerance for harassment, discrimination, or conflict of interest. Integrity and client data privacy are foundational.", date(2026, 1, 1)),
        ("POL-005", "Information Security, BYOD & Device Policy", HRPolicy.Category.SECURITY, "v2.0", "Company-issued devices and personal devices accessing PCRM infrastructure must adhere to multi-factor authentication and full disk encryption.", date(2026, 1, 15)),
        ("POL-006", "Prevention of Sexual Harassment (POSH) Policy", HRPolicy.Category.POSH, "v3.2", "Strict guidelines and internal complaints committee (ICC) procedures for a safe and respectful workplace.", date(2026, 1, 1)),
    ]

    policy_instances = []
    for p_code, p_title, p_cat, p_ver, p_cont, p_eff in policies_data:
        pol, _ = HRPolicy.objects.update_or_create(
            policy_code=p_code,
            defaults={
                'title': p_title,
                'category': p_cat,
                'version': p_ver,
                'content': p_cont,
                'effective_date': p_eff,
                'is_active': True,
                'published_by': hr_user
            }
        )
        policy_instances.append(pol)

    # Acknowledge policies for some employees
    for emp in all_employees[:10]:
        for pol in policy_instances[:4]:
            PolicyAcknowledgement.objects.get_or_create(policy=pol, employee=emp)

    # 6. Seed Onboarding Checklists & Documents for Employees
    for idx, emp in enumerate(all_employees):
        # Onboarding
        is_new = (idx == 0 or emp.status in ['ONBOARDING', 'PROBATION'])
        ob, _ = OnboardingChecklist.objects.get_or_create(
            employee=emp,
            defaults={
                'personal_verified': True,
                'employment_details_set': True,
                'documents_uploaded': not is_new,
                'id_verified': not is_new,
                'account_created': True,
                'assets_assigned': not is_new,
                'training_assigned': True,
                'manager_assigned': True,
                'is_completed': not is_new,
            }
        )
        ob.save()

        # Documents
        doc_types = [
            (EmployeeDocument.DocType.ID_PROOF, "Aadhaar Card Copy", "AADHAAR-8902", EmployeeDocument.Status.VERIFIED, None),
            (EmployeeDocument.DocType.PAN, "PAN Card Copy", "PAN-ABC992", EmployeeDocument.Status.VERIFIED, None),
            (EmployeeDocument.DocType.OFFER_LETTER, "Signed Offer & Appointment Letter", "OFF-2026", EmployeeDocument.Status.VERIFIED, None),
            (EmployeeDocument.DocType.NDA, "Confidentiality & NDA Agreement", "NDA-2026", EmployeeDocument.Status.VERIFIED if not is_new else EmployeeDocument.Status.PENDING, None),
            (EmployeeDocument.DocType.EXPERIENCE, "Previous Relieving Certificate", "EXP-098", EmployeeDocument.Status.VERIFIED if not is_new else EmployeeDocument.Status.PENDING, None),
        ]
        if idx == 1:
            doc_types.append((EmployeeDocument.DocType.OTHER, "Passport / Visa Copy", "PASS-90821", EmployeeDocument.Status.EXPIRED, date(2026, 3, 15)))

        for d_type, d_title, d_num, d_status, d_exp in doc_types:
            EmployeeDocument.objects.update_or_create(
                employee=emp,
                document_type=d_type,
                defaults={
                    'title': d_title,
                    'document_number': d_num,
                    'status': d_status,
                    'expiry_date': d_exp,
                    'verified_by': hr_user if d_status == EmployeeDocument.Status.VERIFIED else None,
                    'verified_at': timezone.now() if d_status == EmployeeDocument.Status.VERIFIED else None,
                    'remarks': "Verified against official originals" if d_status == EmployeeDocument.Status.VERIFIED else "Awaiting HR verification"
                }
            )

    # 7. Seed Training Programs & Enrollments
    trainings = [
        ("TRN-101", "Information Security, Phishing & Data Privacy", "Mandatory training on cyber hygiene and handling customer information.", True, date(2026, 11, 30), 2),
        ("TRN-102", "Workplace Safety, POSH & Anti-Harassment", "Essential corporate guidelines and compliance certification.", True, date(2026, 12, 15), 1),
        ("TRN-103", "PCRM Enterprise Architecture & Flutter Best Practices", "Technical enablement on clean architecture, repository patterns, and DRF APIs.", False, date(2026, 12, 31), 8),
        ("TRN-104", "Operational Excellence & Vendor SLA Compliance", "Field operations protocols and customer quality assurance standards.", False, date(2026, 12, 31), 4),
    ]

    for t_code, t_title, t_desc, t_mand, t_dead, t_dur in trainings:
        prog, _ = TrainingProgram.objects.update_or_create(
            code=t_code,
            defaults={
                'title': t_title,
                'description': t_desc,
                'is_mandatory': t_mand,
                'deadline': t_dead,
                'duration_hours': t_dur
            }
        )
        for emp in all_employees:
            TrainingEnrollment.objects.get_or_create(
                program=prog,
                employee=emp,
                defaults={
                    'status': TrainingEnrollment.Status.COMPLETED if t_mand else TrainingEnrollment.Status.IN_PROGRESS,
                    'score_percentage': 95 if t_mand else 50,
                    'completed_at': timezone.now() if t_mand else None
                }
            )

    # 8. Seed Performance Reviews
    for idx, emp in enumerate(all_employees[:6]):
        PerformanceReview.objects.update_or_create(
            review_code=f"REV-2026-{idx+1:03d}",
            defaults={
                'employee': emp,
                'cycle_name': "Annual Performance Appraisal 2026",
                'reviewer': hr_user,
                'status': PerformanceReview.Status.MANAGER_REVIEW,
                'rating': Decimal('4.5') if idx % 2 == 0 else Decimal('4.0'),
                'kpi_score': 88,
                'competencies_score': 85,
                'manager_feedback': "Consistent high quality output, strong ownership, and excellent team collaboration.",
                'employee_self_review': "Delivered key roadmap features ahead of schedule and mentored juniors.",
                'development_areas': "Enhance automated testing coverage and cross-departmental documentation.",
                'goals_data': [
                    {"goal": "Deliver module on schedule", "weight": 40, "achievement": 95},
                    {"goal": "Maintain code quality > 90%", "weight": 30, "achievement": 90},
                    {"goal": "Team knowledge sharing session", "weight": 30, "achievement": 80}
                ]
            }
        )

    # 9. Seed HR Requests
    requests_data = [
        ("HRR-0001", HRRequest.RequestType.ATTENDANCE_CORRECTION, "Forgot Geofence Check-in on 3rd Oct", "Checked in at reception at 09:30 AM but phone battery had died. Requesting regularisation.", HRRequest.Status.SUBMITTED),
        ("HRR-0002", HRRequest.RequestType.LEAVE, "Family Emergency Leave (2 Days)", "Need casual leave for 8th and 9th Oct due to personal commitment.", HRRequest.Status.HR_REVIEW),
        ("HRR-0003", HRRequest.RequestType.EMPLOYMENT_LETTER, "Bank Home Loan Verification Letter", "Applying for a home loan, require official employment verification letter.", HRRequest.Status.APPROVED),
        ("HRR-0004", HRRequest.RequestType.ASSET_REQUEST, "Secondary Monitor Request for Dev Work", "Require an additional 27-inch 4K monitor for multi-screen debugging.", HRRequest.Status.COMPLETED),
        ("HRR-0005", HRRequest.RequestType.DOC_UPDATE, "Updated Aadhaar with Married Name", "Attached scanned updated card for HR records.", HRRequest.Status.SUBMITTED),
        ("HRR-0006", HRRequest.RequestType.SALARY_QUERY, "Tax Deduction Query for September Payslip", "Clarification needed regarding Section 80C investment declarations.", HRRequest.Status.HR_REVIEW),
    ]

    for req_code, req_type, title, details, req_status in requests_data:
        target_emp = all_employees[0] if all_employees else None
        target_user = target_emp.user if target_emp else hr_user
        HRRequest.objects.update_or_create(
            request_code=req_code,
            defaults={
                'request_type': req_type,
                'requester': target_user,
                'title': title,
                'details': details,
                'status': req_status,
                'reviewed_by': hr_user if req_status != HRRequest.Status.SUBMITTED else None,
                'admin_notes': "Approved by HR operations" if req_status == HRRequest.Status.APPROVED else None
            }
        )

    # 10. Seed Offboarding Record
    if len(all_employees) > 3:
        exit_emp = all_employees[-1]
        OffboardingRecord.objects.update_or_create(
            exit_code="EXT-2026-001",
            defaults={
                'employee': exit_emp,
                'resignation_date': date(2026, 9, 15),
                'last_working_day': date(2026, 10, 15),
                'notice_period_days': 30,
                'status': OffboardingRecord.Status.NOTICE_PERIOD,
                'reason_for_leaving': "Relocating to Bangalore for family reasons.",
                'checklist_data': {
                    'resignation_acknowledged': True,
                    'knowledge_transfer': True,
                    'it_hardware_returned': False,
                    'access_deactivated': False,
                    'finance_dues_cleared': False,
                    'nda_reaffirmed': True,
                    'exit_interview_completed': True,
                    'pf_gratuity_processed': False,
                    'fnf_settlement': False,
                    'experience_letter_generated': False
                },
                'exit_interview_notes': "Pleasant experience working with the team. Strong praise for culture.",
                'experience_letter_issued': False
            }
        )

    # 11. Seed HR Announcements
    announcements = [
        ("Company Annual All-Hands & Awards Gala 2026", HRAnnouncement.Category.EVENT, "Join us this Friday at 5:00 PM in the Main Auditorium or via virtual broadcast for our Annual Townhall & Employee Excellence Awards!", date(2026, 10, 10)),
        ("Dussehra & Diwali Festive Holiday Schedule", HRAnnouncement.Category.HOLIDAY, "Offices will remain closed on designated festival dates. Please refer to the updated Holiday Calendar 2026 in the Policies tab.", date(2026, 10, 20)),
        ("PCRM Reaches 120+ Team Milestone Across 4 Cities", HRAnnouncement.Category.MILESTONE, "Huge congratulations to all team members on achieving our expansion targets for Q3 2026!", None),
        ("Updated Medical Insurance & Wellness Policy", HRAnnouncement.Category.GENERAL, "Enhanced cashless hospital coverage is now active for all employees and their dependents.", None),
    ]

    for title, cat, cont, ev_date in announcements:
        HRAnnouncement.objects.get_or_create(
            title=title,
            defaults={
                'category': cat,
                'content': cont,
                'event_date': ev_date,
                'published_by': hr_user
            }
        )

    # 12. Seed HR Daily Report
    HRDailyReport.objects.update_or_create(
        executive=hr_user,
        report_date=timezone.localdate(),
        defaults={
            'onboardings_count': 2,
            'leaves_processed_count': 4,
            'corrections_approved_count': 3,
            'candidates_interviewed_count': 5,
            'documents_verified_count': 8,
            'requests_resolved_count': 6,
            'summary_notes': "Completed 2 new joiner document verifications, held 3 technical screening calls for Flutter Developer position, and resolved all pending attendance regularisation requests.",
            'challenges': "Document verification delay on candidate PAN card due to blurred upload; follow-up sent.",
            'tomorrow_plan': "Conduct onboarding session for QA recruit, finalize Q3 appraisal review meetings, and publish updated POSH committee roster.",
            'status': HRDailyReport.Status.SUBMITTED
        }
    )

    print("[HR] Successfully seeded all HR Enterprise models, records, and telemetry!")

if __name__ == '__main__':
    seed_hr()
