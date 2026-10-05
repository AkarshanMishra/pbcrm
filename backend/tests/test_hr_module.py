import pytest
from rest_framework import status
from rest_framework.test import APIClient
from django.utils import timezone
from datetime import timedelta, date
from decimal import Decimal
from apps.accounts.models import User
from apps.employees.models import Employee
from apps.organization.models import Department, Position, Role
from apps.hr.models import (
    JobOpening, CandidateApplication, OnboardingChecklist,
    EmployeeDocument, HRPolicy, PolicyAcknowledgement,
    PerformanceReview, TrainingProgram, TrainingEnrollment,
    HRRequest, OffboardingRecord, HRAnnouncement, HRDailyReport
)


@pytest.fixture
def hr_setup(db):
    dept, _ = Department.objects.get_or_create(code="HR_TEST", defaults={"name": "HR Testing Dept"})
    pos, _ = Position.objects.get_or_create(title="HR Specialist", department=dept, defaults={"code": "HR_SPEC"})
    role, _ = Role.objects.get_or_create(code="HR_ROLE", defaults={"name": "HR Role"})

    user_hr = User.objects.create_user(email="hr.exec@pcrm.local", employee_code="PBH000991", password="HRPassword@123!")
    emp_hr = Employee.objects.create(
        user=user_hr,
        first_name="Pooja",
        last_name="Sharma",
        department=dept,
        position=pos,
        role=role
    )

    user_candidate_emp = User.objects.create_user(email="emp.test@pcrm.local", employee_code="PBE000992", password="TestPassword@123!")
    emp_test = Employee.objects.create(
        user=user_candidate_emp,
        first_name="Rohan",
        last_name="Verma",
        department=dept,
        position=pos,
        role=role
    )

    job = JobOpening.objects.create(
        title="Flutter Architect",
        code="JOB-TEST-01",
        department=dept,
        position=pos,
        openings_count=2,
        status=JobOpening.Status.OPEN
    )

    candidate = CandidateApplication.objects.create(
        candidate_code="CAN-TEST-01",
        job=job,
        full_name="Aman Gupta",
        email="aman.g@test.local",
        phone="+91 99999 11111",
        stage=CandidateApplication.Stage.APPLIED
    )

    policy = HRPolicy.objects.create(
        policy_code="POL-TEST-01",
        title="Leave Policy 2026",
        category=HRPolicy.Category.LEAVE,
        content="Test leave policy content",
        published_by=user_hr
    )

    training = TrainingProgram.objects.create(
        code="TRN-TEST-01",
        title="Security Awareness",
        description="Mandatory security awareness training",
        is_mandatory=True,
        deadline=timezone.now().date() + timedelta(days=30)
    )

    enrollment = TrainingEnrollment.objects.create(
        program=training,
        employee=emp_test,
        status=TrainingEnrollment.Status.ASSIGNED
    )

    return {
        'dept': dept,
        'pos': pos,
        'user_hr': user_hr,
        'emp_hr': emp_hr,
        'emp_test': emp_test,
        'job': job,
        'candidate': candidate,
        'policy': policy,
        'training': training,
        'enrollment': enrollment,
    }


@pytest.mark.django_db
def test_job_openings_api(hr_setup):
    client = APIClient()
    client.force_authenticate(user=hr_setup['user_hr'])

    response = client.get('/api/v1/hr/jobs/')
    assert response.status_code == status.HTTP_200_OK
    results = response.data.get('results', response.data)
    assert len(results) >= 1
    assert results[0]['code'] == 'JOB-TEST-01'


@pytest.mark.django_db
def test_candidate_advance_stage(hr_setup):
    client = APIClient()
    client.force_authenticate(user=hr_setup['user_hr'])

    candidate_id = hr_setup['candidate'].id
    response = client.post(f'/api/v1/hr/candidates/{candidate_id}/advance_stage/', {'stage': 'INTERVIEW'}, format='json')
    assert response.status_code == status.HTTP_200_OK
    assert response.data['stage'] == 'INTERVIEW'


@pytest.mark.django_db
def test_onboarding_checklist_progress(hr_setup):
    emp = hr_setup['emp_test']
    checklist = OnboardingChecklist.objects.create(
        employee=emp,
        personal_verified=True,
        employment_details_set=True
    )
    assert checklist.completion_percentage == 25
    assert not checklist.is_completed

    client = APIClient()
    client.force_authenticate(user=hr_setup['user_hr'])

    response = client.post(f'/api/v1/hr/onboarding/{checklist.id}/update_step/', {'step': 'documents_uploaded', 'value': True}, format='json')
    assert response.status_code == status.HTTP_200_OK
    assert response.data['documents_uploaded'] is True
    assert response.data['completion_percentage'] == 37


@pytest.mark.django_db
def test_document_verification(hr_setup):
    emp = hr_setup['emp_test']
    doc = EmployeeDocument.objects.create(
        employee=emp,
        document_type=EmployeeDocument.DocType.ID_PROOF,
        title="Aadhaar Card",
        status=EmployeeDocument.Status.PENDING
    )

    client = APIClient()
    client.force_authenticate(user=hr_setup['user_hr'])

    response = client.post(f'/api/v1/hr/documents/{doc.id}/verify/', {'remarks': 'Original verified'}, format='json')
    assert response.status_code == status.HTTP_200_OK
    assert response.data['status'] == EmployeeDocument.Status.VERIFIED


@pytest.mark.django_db
def test_policy_acknowledgement(hr_setup):
    client = APIClient()
    client.force_authenticate(user=hr_setup['emp_test'].user)

    policy_id = hr_setup['policy'].id
    response = client.post(f'/api/v1/hr/policies/{policy_id}/acknowledge/', format='json')
    assert response.status_code == status.HTTP_200_OK
    assert response.data['status'] == 'acknowledged'
    assert PolicyAcknowledgement.objects.filter(policy_id=policy_id, employee=hr_setup['emp_test']).exists()


@pytest.mark.django_db
def test_training_completion(hr_setup):
    client = APIClient()
    client.force_authenticate(user=hr_setup['user_hr'])

    enrollment_id = hr_setup['enrollment'].id
    response = client.post(f'/api/v1/hr/training-enrollments/{enrollment_id}/complete/', {'score': 95}, format='json')
    assert response.status_code == status.HTTP_200_OK
    assert response.data['status'] == TrainingEnrollment.Status.COMPLETED
    assert response.data['score_percentage'] == 95


@pytest.mark.django_db
def test_hr_request_workflow(hr_setup):
    client = APIClient()
    client.force_authenticate(user=hr_setup['emp_test'].user)

    # Create Request
    response = client.post('/api/v1/hr/requests/', {
        'request_type': 'ATTENDANCE_CORRECTION',
        'title': 'Forgot check-in',
        'details': 'Punch machine was offline'
    }, format='json')
    assert response.status_code == status.HTTP_201_CREATED
    req_id = response.data['id']
    assert response.data['status'] == 'SUBMITTED'

    # Review by HR
    client.force_authenticate(user=hr_setup['user_hr'])
    res_review = client.post(f'/api/v1/hr/requests/{req_id}/update_status/', {
        'status': 'APPROVED',
        'admin_notes': 'Verified with CCTV log'
    }, format='json')
    assert res_review.status_code == status.HTTP_200_OK
    assert res_review.data['status'] == 'APPROVED'


@pytest.mark.django_db
def test_hr_telemetry(hr_setup):
    client = APIClient()
    client.force_authenticate(user=hr_setup['user_hr'])

    response = client.get('/api/v1/hr/telemetry/')
    assert response.status_code == status.HTTP_200_OK
    assert 'workforce' in response.data
    assert 'today_attendance' in response.data
    assert 'needs_attention' in response.data
    assert 'recruitment' in response.data
    assert 'performance' in response.data
