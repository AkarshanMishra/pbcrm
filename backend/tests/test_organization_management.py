import pytest
from rest_framework.test import APIClient
from django.contrib.auth import get_user_model
from apps.organization.models import Department, Position, Role, Permission

User = get_user_model()

@pytest.fixture
def api_client():
    return APIClient()

@pytest.fixture
def seeded_db(db):
    from django.core.management import call_command
    call_command('seed_phase1_data')
    call_command('seed_phase2_templates')

@pytest.mark.django_db
def test_admin_can_create_department_position_and_role(api_client, seeded_db):
    admin_user = User.objects.get(employee_code='PBE000001')
    api_client.force_authenticate(user=admin_user)

    # 1. Create Department
    dept_res = api_client.post('/api/v1/organization/departments/', {
        'name': 'Human Resources & Talent',
        'code': 'HR',
        'description': 'Talent acquisition, employee welfare, and onboarding'
    })
    assert dept_res.status_code == 201
    dept_id = dept_res.data['id']
    assert dept_res.data['code'] == 'HR'

    # 2. Create Position
    pos_res = api_client.post('/api/v1/organization/positions/', {
        'department': dept_id,
        'title': 'Senior Talent Specialist',
        'code': 'HR_TALENT_SR',
        'description': 'Leads technical and executive recruitment'
    })
    assert pos_res.status_code == 201
    assert pos_res.data['department_name'] == 'Human Resources & Talent'

    # 3. Create Custom Role with Permissions
    perm = Permission.objects.first()
    role_res = api_client.post('/api/v1/organization/roles/', {
        'name': 'HR Talent Manager',
        'code': 'HR_MGR',
        'description': 'Full access to recruitment and candidate screening',
        'permission_ids': [str(perm.id)]
    })
    assert role_res.status_code == 201
    assert role_res.data['code'] == 'HR_MGR'
    assert len(role_res.data['permissions']) == 1


@pytest.mark.django_db
def test_employee_cannot_create_or_modify_organization(api_client, seeded_db):
    emp_user = User.objects.get(employee_code='PBE000003')
    api_client.force_authenticate(user=emp_user)

    # Employee tries to create department
    dept_res = api_client.post('/api/v1/organization/departments/', {
        'name': 'Unauthorized Dept',
        'code': 'UNAUTH'
    })
    assert dept_res.status_code == 403

    # Employee tries to create role
    role_res = api_client.post('/api/v1/organization/roles/', {
        'name': 'Super Role',
        'code': 'SUPER'
    })
    assert role_res.status_code == 403
