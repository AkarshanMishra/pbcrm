import pytest
from rest_framework import status
from rest_framework.test import APIClient
from django.utils import timezone
from datetime import timedelta
from apps.accounts.models import User
from apps.employees.models import Employee, Role
from apps.organization.models import Department, Position
from apps.operations.models import (
    BookingOperation, EventReadinessChecklist, OperationsIssue,
    QualityInspection, OperationalAsset, OperationsRequest,
    OperationsDailyReport
)


@pytest.fixture
def ops_setup(db):
    dept, _ = Department.objects.get_or_create(code="OPS_TEST", defaults={"name": "Operations Testing Dept"})
    pos, _ = Position.objects.get_or_create(code="OPS_EXEC_TEST", defaults={"title": "Test Operations Executive", "department": dept})
    role, _ = Role.objects.get_or_create(code="OPS_ROLE", defaults={"name": "Operations Executive"})

    user_exec = User.objects.create_user(email="exec.ops@pcrm.local", employee_code="PBE000081", password="OpsPassword@123!")
    emp_exec = Employee.objects.create(
        user=user_exec,
        first_name="Operations",
        last_name="Executive",
        department=dept,
        position=pos,
        role=role
    )

    user_mgr = User.objects.create_user(email="mgr.ops@pcrm.local", employee_code="PBE000082", password="MgrOpsPassword@123!")
    emp_mgr = Employee.objects.create(
        user=user_mgr,
        first_name="Operations",
        last_name="Manager",
        department=dept,
        position=pos,
        role=role
    )

    booking = BookingOperation.objects.create(
        booking_code="PB-9999",
        customer_name="Test Customer",
        customer_phone="+91 99999 88888",
        partner_name="Grand Test Venue",
        partner_phone="+91 99999 77777",
        partner_type=BookingOperation.PartnerType.BANQUET,
        event_type=BookingOperation.EventType.WEDDING,
        event_date=timezone.now().date(),
        amount=150000.00,
        payment_status=BookingOperation.PaymentStatus.PAID,
        partner_confirmation_status=BookingOperation.PartnerConfirmationStatus.CONFIRMED,
        operations_status=BookingOperation.OperationsStatus.COORDINATION,
        assigned_executive=user_exec,
        manager=user_mgr
    )

    checklist = EventReadinessChecklist.objects.create(
        booking=booking,
        hall_confirmed=True,
        seating_confirmed=True
    )

    return {
        'user_exec': user_exec,
        'emp_exec': emp_exec,
        'user_mgr': user_mgr,
        'emp_mgr': emp_mgr,
        'booking': booking,
        'checklist': checklist
    }


@pytest.mark.django_db
def test_operations_bookings_and_readiness(ops_setup):
    client = APIClient()
    client.force_authenticate(user=ops_setup['user_exec'])

    # 1. Test booking list
    response = client.get('/api/v1/operations/bookings/')
    assert response.status_code == status.HTTP_200_OK
    assert len(response.data['results']) >= 1

    # 2. Test today timeline
    response = client.get('/api/v1/operations/bookings/today_timeline/')
    assert response.status_code == status.HTTP_200_OK

    # 3. Test dashboard stats
    response = client.get('/api/v1/operations/bookings/dashboard_stats/')
    assert response.status_code == status.HTTP_200_OK
    assert 'total_bookings' in response.data

    # 4. Test update readiness
    booking_id = ops_setup['booking'].id
    response = client.post(f'/api/v1/operations/bookings/{booking_id}/update_readiness/', {
        'decoration_confirmed': True,
        'catering_confirmed': True,
        'parking_confirmed': True,
        'setup_confirmed': True,
        'staff_confirmed': True,
        'power_backup_confirmed': True,
        'notes': 'All 8 checks passed!'
    })
    assert response.status_code == status.HTTP_200_OK
    assert response.data['score_percentage'] == 100

    # 5. Verify status updated to READY
    ops_setup['booking'].refresh_from_db()
    assert ops_setup['booking'].readiness_percentage == 100
    assert ops_setup['booking'].operations_status == BookingOperation.OperationsStatus.READY


@pytest.mark.django_db
def test_operations_issues_and_escalation(ops_setup):
    client = APIClient()
    client.force_authenticate(user=ops_setup['user_exec'])

    # Create issue
    response = client.post('/api/v1/operations/issues/', {
        'category': 'EQUIPMENT_FAILURE',
        'priority': 'CRITICAL',
        'booking': str(ops_setup['booking'].id),
        'problem_statement': 'Mic feedback issue during live ceremony',
        'sla_hours': 2
    })
    assert response.status_code == status.HTTP_201_CREATED
    issue_id = response.data['id']

    # Escalate issue
    response = client.post(f'/api/v1/operations/issues/{issue_id}/escalate/')
    assert response.status_code == status.HTTP_200_OK
    assert response.data['escalation_level'] == 'MANAGER'
    assert response.data['status'] == 'ESCALATED'

    # Resolve issue
    response = client.post(f'/api/v1/operations/issues/{issue_id}/resolve/', {
        'resolution_notes': 'Replaced wireless transmitter.'
    })
    assert response.status_code == status.HTTP_200_OK
    assert response.data['status'] == 'RESOLVED'


@pytest.mark.django_db
def test_quality_inspection_auto_issue(ops_setup):
    client = APIClient()
    client.force_authenticate(user=ops_setup['user_exec'])

    # Create failing QC inspection
    response = client.post('/api/v1/operations/inspections/', {
        'partner_name': 'Grand Test Venue',
        'booking': str(ops_setup['booking'].id),
        'result': 'FAIL',
        'score': 45,
        'notes': 'Emergency exit blocked by scaffolding.'
    })
    assert response.status_code == status.HTTP_201_CREATED
    assert response.data['auto_generated_issue'] is not None


@pytest.mark.django_db
def test_operations_assets_checkout_checkin(ops_setup):
    client = APIClient()
    client.force_authenticate(user=ops_setup['user_exec'])

    asset = OperationalAsset.objects.create(
        asset_code="AST-999",
        name="Test Projector 4K",
        category=OperationalAsset.Category.AUDIO_VISUAL,
        status=OperationalAsset.Status.AVAILABLE
    )

    # Checkout
    response = client.post(f'/api/v1/operations/assets/{asset.id}/checkout/', {
        'booking_id': str(ops_setup['booking'].id)
    })
    assert response.status_code == status.HTTP_200_OK
    assert response.data['status'] == 'IN_USE'

    # Checkin
    response = client.post(f'/api/v1/operations/assets/{asset.id}/checkin/', {
        'condition': 'EXCELLENT'
    })
    assert response.status_code == status.HTTP_200_OK
    assert response.data['status'] == 'AVAILABLE'


@pytest.mark.django_db
def test_operations_requests_and_daily_report(ops_setup):
    client = APIClient()
    client.force_authenticate(user=ops_setup['user_exec'])

    # Create request
    response = client.post('/api/v1/operations/requests/', {
        'request_type': 'ADDITIONAL_STAFF',
        'title': 'Need 2 extra ushers',
        'description': 'Guest count increased',
        'amount': 2000.00
    })
    assert response.status_code == status.HTTP_201_CREATED
    req_id = response.data['id']

    # Manager approves
    client.force_authenticate(user=ops_setup['user_mgr'])
    response = client.post(f'/api/v1/operations/requests/{req_id}/approve/', {
        'approval_notes': 'Approved.'
    })
    assert response.status_code == status.HTTP_200_OK
    assert response.data['status'] == 'APPROVED'

    # Test daily telemetry
    response = client.get('/api/v1/operations/daily-reports/today_telemetry/')
    assert response.status_code == status.HTTP_200_OK
    assert 'report_date' in response.data

    # Test manager overview
    response = client.get('/api/v1/operations/manager-overview/')
    assert response.status_code == status.HTTP_200_OK
    assert 'team_workload' in response.data
