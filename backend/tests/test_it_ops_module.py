import pytest
from rest_framework import status
from rest_framework.test import APIClient
from django.utils import timezone
from apps.accounts.models import User
from apps.employees.models import Employee, Role
from apps.organization.models import Department, Position
from apps.it_ops.models import (
    SystemComponent, ITIncident, ITIncidentComment,
    PullRequest, DeploymentRecord, ITAsset, ITAccessRequest,
    KnowledgeArticle, ITDailyReport
)


@pytest.fixture
def it_setup(db):
    dept, _ = Department.objects.get_or_create(code="IT_TEST", defaults={"name": "IT Testing Dept"})
    pos, _ = Position.objects.get_or_create(code="DEV_TEST", defaults={"title": "Test Developer", "department": dept})
    role, _ = Role.objects.get_or_create(code="SDE_TEST", defaults={"name": "Software Developer"})

    user_dev = User.objects.create_user(email="dev.test@pcrm.local", employee_code="PBE000091", password="DevPassword@123!")
    emp_dev = Employee.objects.create(
        user=user_dev,
        first_name="Test",
        last_name="Developer",
        department=dept,
        position=pos,
        role=role
    )

    user_mgr = User.objects.create_user(email="mgr.test@pcrm.local", employee_code="PBE000092", password="MgrPassword@123!")
    emp_mgr = Employee.objects.create(
        user=user_mgr,
        first_name="IT",
        last_name="Manager",
        department=dept,
        position=pos,
        role=role
    )

    system = SystemComponent.objects.create(
        name="Test API Gateway",
        slug="test-api-gateway",
        component_type=SystemComponent.ComponentType.API,
        status=SystemComponent.HealthStatus.OPERATIONAL,
        uptime_percentage=99.99
    )

    return {
        'user_dev': user_dev,
        'emp_dev': emp_dev,
        'user_mgr': user_mgr,
        'emp_mgr': emp_mgr,
        'system': system
    }


@pytest.mark.django_db
def test_it_telemetry(it_setup):
    client = APIClient()
    client.force_authenticate(user=it_setup['user_dev'])
    response = client.get('/api/v1/it/telemetry/')
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert 'scorecard' in data
    assert 'systems' in data
    assert 'needs_attention' in data
    assert 'today_work_schedule' in data
    assert 'team_workload' in data


@pytest.mark.django_db
def test_system_components_health(it_setup):
    client = APIClient()
    client.force_authenticate(user=it_setup['user_dev'])
    response = client.get('/api/v1/it/systems/health_overview/')
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data['total_components'] >= 1
    assert data['operational'] >= 1


@pytest.mark.django_db
def test_it_incident_lifecycle(it_setup):
    client = APIClient()
    client.force_authenticate(user=it_setup['user_dev'])
    
    # 1. Create Incident
    payload = {
        'title': 'Payment Webhook Latency Alert',
        'description': '504 timeout when contacting upstream payment provider',
        'category': 'APPLICATION_BUG',
        'priority': 'CRITICAL',
        'affected_system': str(it_setup['system'].id)
    }
    create_resp = client.post('/api/v1/it/incidents/', payload, format='json')
    assert create_resp.status_code == status.HTTP_201_CREATED
    inc_id = create_resp.json()['id']
    
    # 2. Take ownership
    take_resp = client.post(f'/api/v1/it/incidents/{inc_id}/take_ownership/')
    assert take_resp.status_code == status.HTTP_200_OK
    assert take_resp.json()['status'] == 'INVESTIGATING'
    
    # 3. Add internal log comment
    comment_resp = client.post(f'/api/v1/it/incidents/{inc_id}/add_comment/', {
        'comment_text': 'Worker pool threads doubled.',
        'is_internal_log': True
    }, format='json')
    assert comment_resp.status_code == status.HTTP_201_CREATED
    
    # 4. Resolve incident
    resolve_resp = client.post(f'/api/v1/it/incidents/{inc_id}/resolve/', {
        'resolution_notes': 'Pool saturation resolved. Worker threads configured to 32.',
        'root_cause': 'Gunicorn connection pool starvation'
    }, format='json')
    assert resolve_resp.status_code == status.HTTP_200_OK
    assert resolve_resp.json()['status'] == 'RESOLVED'


@pytest.mark.django_db
def test_pull_request_and_deployment(it_setup):
    client = APIClient()
    client.force_authenticate(user=it_setup['user_dev'])
    
    # Create PR
    pr = PullRequest.objects.create(
        pr_number=991,
        title="Payment Worker Scale Patch",
        source_branch="feat/payment-worker",
        target_branch="main",
        author=it_setup['emp_dev'],
        reviewer=it_setup['emp_mgr']
    )
    
    # Approve PR
    mgr_client = APIClient()
    mgr_client.force_authenticate(user=it_setup['user_mgr'])
    appr_resp = mgr_client.post(f'/api/v1/it/pull-requests/{pr.id}/approve/')
    assert appr_resp.status_code == status.HTTP_200_OK
    assert appr_resp.json()['review_status'] == 'APPROVED'
    
    # Create & Execute Deployment
    deploy_resp = client.post('/api/v1/it/deployments/', {
        'application': 'PartyBala Core API',
        'environment': 'STAGING',
        'version_tag': 'v2.9.0-rc1',
        'commit_hash': 'c8f12a3',
        'build_passed': True,
        'tests_passed': True
    }, format='json')
    assert deploy_resp.status_code == status.HTTP_201_CREATED
    deploy_id = deploy_resp.json()['id']
    
    exec_resp = client.post(f'/api/v1/it/deployments/{deploy_id}/execute_deploy/')
    assert exec_resp.status_code == status.HTTP_200_OK
    assert exec_resp.json()['status'] == 'SUCCESS'


@pytest.mark.django_db
def test_knowledge_base_and_daily_report(it_setup):
    client = APIClient()
    client.force_authenticate(user=it_setup['user_dev'])
    
    # Knowledge Article
    article = KnowledgeArticle.objects.create(
        title="Payment Worker SOP",
        slug="payment-worker-sop",
        category=KnowledgeArticle.Category.SOPS,
        summary="How to scale workers",
        content="Step 1: Check metrics. Step 2: Scale pod."
    )
    view_resp = client.post(f'/api/v1/it/knowledge-base/{article.id}/increment_view/')
    assert view_resp.status_code == status.HTTP_200_OK
    assert view_resp.json()['view_count'] == 1
    
    # Daily Report
    report_resp = client.post('/api/v1/it/daily-reports/', {
        'tasks_completed_count': 4,
        'bugs_fixed_count': 1,
        'tickets_resolved_count': 2,
        'deployments_count': 1,
        'code_reviews_count': 1,
        'incidents_handled': 'Resolved 504 gateway timeout',
        'tomorrow_plan': 'Deploy canary to production'
    }, format='json')
    assert report_resp.status_code == status.HTTP_201_CREATED
