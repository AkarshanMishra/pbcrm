import pytest
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from apps.accounts.models import User
from apps.organization.models import Department, Position, Role
from apps.employees.models import Employee
from apps.tasks.models import Task, TaskChecklistItem, TaskComment, TaskTemplate
from apps.work_management.models import DailyWorkPlan, DailyWorkReport
from apps.notifications.models import Notification

@pytest.mark.django_db
class TestPhase2TasksAndWork:
    def setup_method(self):
        self.client = APIClient()
        self.dept = Department.objects.create(name='Marketing Group', code='MKTG')
        self.pos = Position.objects.create(department=self.dept, title='Growth Lead', code='GL')
        self.admin_role = Role.objects.create(code=Role.RoleCode.ADMIN, name='Admin')
        self.manager_role = Role.objects.create(code=Role.RoleCode.MARKETING, name='Marketing')
        self.staff_role = Role.objects.create(code=Role.RoleCode.IT, name='IT')

        # Admin
        self.admin_user = User.objects.create_superuser(
            email='admin@pcrm.local',
            employee_code='PBE000001',
            password='AdminPassword@123!'
        )
        self.admin_emp = Employee.objects.create(
            user=self.admin_user,
            first_name='Admin',
            last_name='User',
            department=self.dept,
            position=self.pos,
            role=self.admin_role
        )

        # Manager
        self.mgr_user = User.objects.create_user(
            email='manager@pcrm.local',
            employee_code='PBE000002',
            password='ManagerPassword@123!'
        )
        self.mgr_emp = Employee.objects.create(
            user=self.mgr_user,
            first_name='Marketing',
            last_name='Manager',
            department=self.dept,
            position=self.pos,
            role=self.manager_role
        )

        # Employee (reports to Manager)
        self.emp_user = User.objects.create_user(
            email='rahul@pcrm.local',
            employee_code='PBE000003',
            password='EmployeePassword@123!'
        )
        self.emp = Employee.objects.create(
            user=self.emp_user,
            first_name='Rahul',
            last_name='Sharma',
            department=self.dept,
            position=self.pos,
            role=self.staff_role,
            reporting_manager=self.mgr_emp
        )

    def test_manager_creates_task_and_employee_notified(self):
        self.client.force_authenticate(user=self.mgr_user)
        res = self.client.post('/api/v1/tasks/', {
            'title': 'Complete 20 vendor follow-ups',
            'description': 'Call all pending vendors for KYC documents.',
            'department': str(self.dept.id),
            'position': str(self.pos.id),
            'assigned_to': str(self.emp.id),
            'priority': 'HIGH',
            'due_date': str(timezone.localdate()),
            'checklist': ['Call Vendor 1', 'Call Vendor 2', 'Collect GST']
        }, format='json')

        assert res.status_code == status.HTTP_201_CREATED
        task_id = res.data['id']
        task = Task.objects.get(id=task_id)
        assert task.checklist_items.count() == 3
        assert task.status == Task.Status.ASSIGNED

        # Verify notification generated for Rahul
        notif = Notification.objects.filter(recipient=self.emp_user).first()
        assert notif is not None
        assert 'Complete 20 vendor follow-ups' in notif.title
        assert notif.notification_type == Notification.NotificationType.TASK_ASSIGNED

    def test_task_full_lifecycle_accept_start_block_submit_approve(self):
        # 1. Create Task
        task = Task.objects.create(
            title='Venue Inspection',
            description='Inspect venue amenities and seating capacity.',
            department=self.dept,
            assigned_to=self.emp,
            assigned_by=self.mgr_user,
            priority=Task.Priority.URGENT,
            status=Task.Status.ASSIGNED
        )
        check_item = TaskChecklistItem.objects.create(task=task, item_text='Take 5 photos')

        # 2. Employee Accepts Task
        self.client.force_authenticate(user=self.emp_user)
        res_accept = self.client.post(f'/api/v1/tasks/{task.id}/accept/')
        assert res_accept.status_code == status.HTTP_200_OK
        task.refresh_from_db()
        assert task.status == Task.Status.ACCEPTED

        # 3. Employee Starts Task
        res_start = self.client.post(f'/api/v1/tasks/{task.id}/start/')
        assert res_start.status_code == status.HTTP_200_OK
        task.refresh_from_db()
        assert task.status == Task.Status.IN_PROGRESS

        # 4. Employee Blocks Task
        res_block = self.client.post(f'/api/v1/tasks/{task.id}/block/', {
            'reason': 'Venue owner unavailable for inspection',
            'comment': 'Premises locked, owner will return tomorrow at 10 AM.'
        })
        assert res_block.status_code == status.HTTP_200_OK
        task.refresh_from_db()
        assert task.status == Task.Status.BLOCKED
        assert task.blocked_reason == 'Venue owner unavailable for inspection'

        # Manager received blocker alert
        mgr_notif = Notification.objects.filter(recipient=self.mgr_user, notification_type=Notification.NotificationType.TASK_BLOCKED).first()
        assert mgr_notif is not None

        # 5. Employee Unblocks and Completes Checklist
        self.client.post(f'/api/v1/tasks/{task.id}/unblock/')
        task.refresh_from_db()
        assert task.status == Task.Status.IN_PROGRESS

        res_check = self.client.post(f'/api/v1/tasks/{task.id}/toggle-checklist/', {'item_id': str(check_item.id)})
        assert res_check.status_code == status.HTTP_200_OK
        task.refresh_from_db()
        assert task.progress_percentage == 100

        # 6. Employee Submits Task
        res_submit = self.client.post(f'/api/v1/tasks/{task.id}/submit/')
        assert res_submit.status_code == status.HTTP_200_OK
        task.refresh_from_db()
        assert task.status == Task.Status.SUBMITTED

        # 7. Manager Approves Task
        self.client.force_authenticate(user=self.mgr_user)
        res_review = self.client.post(f'/api/v1/tasks/{task.id}/review/', {
            'decision': 'APPROVE',
            'remarks': 'Excellent quality inspection report.'
        })
        assert res_review.status_code == status.HTTP_200_OK
        task.refresh_from_db()
        assert task.status == Task.Status.COMPLETED
        assert task.reviewed_by == self.mgr_user

    def test_daily_work_plan_and_report_review(self):
        # 1. Employee starts day plan
        self.client.force_authenticate(user=self.emp_user)
        res_plan = self.client.post('/api/v1/work/plans/today/', {
            'planned_items': ['Complete vendor calls', 'Update onboarding sheets'],
            'is_started': True,
            'notes': 'On field in Sector 18 today'
        }, format='json')
        assert res_plan.status_code == status.HTTP_200_OK
        assert res_plan.data['is_started'] is True

        # 2. Employee submits end of day report
        today = timezone.localdate()
        res_rep = self.client.post('/api/v1/work/reports/', {
            'report_date': str(today),
            'summary_text': 'Completed all 15 vendor calls and onboarded 2 new partners.',
            'completed_summary': '15 calls made, 2 partners signed',
            'pending_summary': '1 partner pending GST certificate',
            'tomorrow_plan': 'Visit Sector 62 partners'
        })
        assert res_rep.status_code == status.HTTP_201_CREATED
        report_id = res_rep.data['id']

        # 3. Manager reviews report and approves
        self.client.force_authenticate(user=self.mgr_user)
        res_rev = self.client.post(f'/api/v1/work/reports/{report_id}/review/', {
            'decision': 'APPROVE',
            'remarks': 'Good progress today.'
        })
        assert res_rev.status_code == status.HTTP_200_OK
        rep = DailyWorkReport.objects.get(id=report_id)
        assert rep.status == DailyWorkReport.ReportStatus.APPROVED
        assert rep.reviewed_by == self.mgr_user

    def test_notifications_unread_count_and_mark_read(self):
        Notification.objects.create(
            recipient=self.emp_user,
            title='Test Alert 1',
            message='Alert content 1',
            is_read=False
        )
        Notification.objects.create(
            recipient=self.emp_user,
            title='Test Alert 2',
            message='Alert content 2',
            is_read=False
        )

        self.client.force_authenticate(user=self.emp_user)
        res = self.client.get('/api/v1/notifications/unread-count/')
        assert res.status_code == status.HTTP_200_OK
        assert res.data['unread_count'] == 2

        # Mark all as read
        res_all = self.client.post('/api/v1/notifications/read-all/')
        assert res_all.status_code == status.HTTP_200_OK
        assert Notification.objects.filter(recipient=self.emp_user, is_read=False).count() == 0
