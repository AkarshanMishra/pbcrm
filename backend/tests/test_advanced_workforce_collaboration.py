import pytest
from rest_framework.test import APIClient
from django.contrib.auth import get_user_model
from apps.employees.models import Employee
from apps.organization.models import Department, Position, Role
from apps.tasks.models import Task, Project, TaskChecklistItem
from apps.work_management.models import DailyStandup, Announcement
from apps.tickets.models import SupportTicket

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
def test_project_and_subtasks_workflow(api_client, seeded_db):
    admin_user = User.objects.get(employee_code='PBE000001')
    emp_user = User.objects.get(employee_code='PBE000003')
    emp_profile = Employee.objects.get(user=emp_user)
    dept = Department.objects.first()

    api_client.force_authenticate(user=admin_user)

    # 1. Create Project
    prj_res = api_client.post('/api/v1/tasks/projects/', {
        'name': 'PartyBala Vendor Expansion Q4',
        'code': 'PRJ-MKT-2026',
        'department': dept.id,
        'description': 'Onboarding 200 key venues and suppliers in Q4'
    })
    assert prj_res.status_code == 201
    prj_id = prj_res.data['id']

    # 2. Create Parent Task
    task_res = api_client.post('/api/v1/tasks/', {
        'title': 'Venue Verification - Hotel Grand Palace',
        'description': 'Complete inspection and onboarding checklist',
        'department': dept.id,
        'assigned_to': emp_profile.id,
        'project': prj_id,
        'priority': 'HIGH'
    })
    assert task_res.status_code == 201
    parent_id = task_res.data['id']

    # 3. Create Subtasks
    sub1_res = api_client.post('/api/v1/tasks/', {
        'title': 'Collect Owner KYC & GST',
        'description': 'Verify PAN and GST certificate',
        'parent_task': parent_id,
        'assigned_to': emp_profile.id,
        'project': prj_id
    })
    assert sub1_res.status_code == 201
    sub1_id = sub1_res.data['id']

    sub2_res = api_client.post('/api/v1/tasks/', {
        'title': 'Capture Venue Photos',
        'description': 'Exterior and interior high-res shots',
        'parent_task': parent_id,
        'assigned_to': emp_profile.id,
        'project': prj_id
    })
    assert sub2_res.status_code == 201

    # 4. Complete subtask 1 and verify parent task progress updates to 50%
    api_client.post(f'/api/v1/tasks/{sub1_id}/progress/', {'progress_percentage': 100})
    api_client.post(f'/api/v1/tasks/{sub1_id}/review/', {'decision': 'APPROVE'})

    parent_task = Task.objects.get(id=parent_id)
    assert parent_task.progress_percentage == 50


@pytest.mark.django_db
def test_time_tracking_and_cloning(api_client, seeded_db):
    admin_user = User.objects.get(employee_code='PBE000001')
    emp_profile = Employee.objects.first()
    api_client.force_authenticate(user=admin_user)

    # Create task
    task = Task.objects.create(
        title='Fix Booking API Failure',
        description='Investigate 500 error',
        assigned_to=emp_profile,
        assigned_by=admin_user
    )

    # 1. Start timer
    start_res = api_client.post(f'/api/v1/tasks/{task.id}/start-timer/', {'notes': 'Debugging SQL queries'})
    assert start_res.status_code == 200

    # 2. Stop timer
    stop_res = api_client.post(f'/api/v1/tasks/{task.id}/stop-timer/', {'notes': 'Patch applied'})
    assert stop_res.status_code == 200
    assert stop_res.data['duration_minutes'] >= 1

    # 3. Clone Task
    clone_res = api_client.post(f'/api/v1/tasks/{task.id}/clone/')
    assert clone_res.status_code == 201
    assert 'Copy of Fix Booking API Failure' in clone_res.data['title']


@pytest.mark.django_db
def test_work_handover_and_workload(api_client, seeded_db):
    admin_user = User.objects.get(employee_code='PBE000001')
    emp1 = Employee.objects.get(user__employee_code='PBE000003')
    emp2 = Employee.objects.get(user__employee_code='PBE000002')
    api_client.force_authenticate(user=admin_user)

    # Create tasks for emp1
    t1 = Task.objects.create(title='Follow up Vendor A', description='Call vendor', assigned_to=emp1, assigned_by=admin_user)
    t2 = Task.objects.create(title='Follow up Vendor B', description='Email vendor', assigned_to=emp1, assigned_by=admin_user)

    # Bulk Handover to emp2
    handover_res = api_client.post('/api/v1/tasks/handover/', {
        'from_employee_id': emp1.id,
        'to_employee_id': emp2.id,
        'handover_notes': 'Going on annual leave for 3 days'
    })
    assert handover_res.status_code == 200
    assert handover_res.data['transferred_count'] >= 2

    # Check workload analysis endpoint
    workload_res = api_client.get('/api/v1/tasks/workload/')
    assert workload_res.status_code == 200
    assert len(workload_res.data) > 0


@pytest.mark.django_db
def test_standup_announcements_and_tickets(api_client, seeded_db):
    admin_user = User.objects.get(employee_code='PBE000001')
    emp_user = User.objects.get(employee_code='PBE000003')
    dept = Department.objects.first()

    # 1. Employee creates Daily Standup
    api_client.force_authenticate(user=emp_user)
    standup_res = api_client.post('/api/v1/work/standups/today/', {
        'yesterday_completed': 'Resolved authentication bug',
        'today_planned': 'Building Kanban view',
        'blockers_encountered': 'None'
    })
    assert standup_res.status_code == 200
    assert standup_res.data['today_planned'] == 'Building Kanban view'

    # 2. Employee creates Support Ticket
    ticket_res = api_client.post('/api/v1/tickets/', {
        'title': 'Need Second Monitor for Development',
        'category': 'ASSET_REQUEST',
        'priority': 'MEDIUM',
        'description': 'Requesting a 27-inch monitor for backend API development'
    })
    assert ticket_res.status_code == 201
    ticket_id = ticket_res.data['id']
    assert 'TKT-' in ticket_res.data['ticket_number']

    # 3. Admin assigns and resolves ticket
    api_client.force_authenticate(user=admin_user)
    resolve_res = api_client.post(f'/api/v1/tickets/{ticket_id}/resolve/', {
        'resolution_notes': 'Monitor allocated from IT inventory'
    })
    assert resolve_res.status_code == 200
    assert resolve_res.data['data']['status'] == 'RESOLVED'

    # 4. Admin broadcasts company announcement
    ann_res = api_client.post('/api/v1/work/announcements/', {
        'title': 'Q4 Strategy All-Hands Meeting',
        'content': 'All department teams are requested to attend tomorrow at 10 AM.',
        'target_type': 'ALL',
        'priority': 'HIGH',
        'is_pinned': True
    })
    assert ann_res.status_code == 201
    assert ann_res.data['is_pinned'] == True
