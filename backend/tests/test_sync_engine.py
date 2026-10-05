import pytest
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from apps.accounts.models import User
from apps.organization.models import Department, Position, Role
from apps.employees.models import Employee
from apps.sync_engine.models import DeviceRegistration, SyncQueueRecord, SyncConflict
from apps.attendance.models import Attendance
from apps.tasks.models import Task
from apps.work_management.models import DailyWorkReport

@pytest.mark.django_db
class TestSyncEngine:

    def setup_method(self):
        self.client = APIClient()
        self.dept = Department.objects.create(name='IT Ops', code='ITO')
        self.pos = Position.objects.create(department=self.dept, title='SysAdmin', code='SA')
        self.role = Role.objects.create(code=Role.RoleCode.IT, name='IT')

        self.admin_user = User.objects.create_superuser(
            email='admin_sync@pcrm.local',
            employee_code='PBE000001',
            password='AdminPassword@123!'
        )
        self.admin_emp = Employee.objects.create(
            user=self.admin_user,
            first_name='Admin',
            last_name='User',
            department=self.dept,
            position=self.pos,
            role=self.role
        )

        self.emp_user = User.objects.create_user(
            email='emp_sync@pcrm.local',
            employee_code='PBE000004',
            password='EmpPassword@123!'
        )
        self.employee = Employee.objects.create(
            user=self.emp_user,
            first_name='Ankit',
            last_name='Verma',
            department=self.dept,
            position=self.pos,
            role=self.role,
            reporting_manager=self.admin_emp
        )

    def test_heartbeat_and_device_registration(self):
        self.client.force_authenticate(user=self.emp_user)
        response = self.client.post('/api/v1/sync/heartbeat/', {
            'device_id': 'test-mobile-device-001',
            'pending_count': 3
        })
        assert response.status_code == status.HTTP_200_OK
        assert response.data['status'] == 'ONLINE'
        assert response.data['is_revoked'] is False

        device = DeviceRegistration.objects.get(device_id='test-mobile-device-001')
        assert device.is_online is True
        assert device.pending_sync_count == 3

    def test_batch_sync_offline_attendance(self):
        self.client.force_authenticate(user=self.emp_user)
        payload_data = {
            'device_id': 'test-mobile-device-002',
            'device_name': 'Samsung Galaxy S24',
            'app_version': '1.0.0',
            'items': [
                {
                    'client_id': 'client-punch-001',
                    'action_type': 'ATTENDANCE_PUNCH',
                    'client_timestamp': timezone.now().isoformat(),
                    'payload': {
                        'punch_type': 'CHECK_IN',
                        'attendance_date': timezone.now().date().isoformat()
                    }
                }
            ]
        }

        response = self.client.post('/api/v1/sync/batch/', payload_data, format='json')
        assert response.status_code == status.HTTP_200_OK
        assert response.data['synced_count'] == 1
        assert response.data['results'][0]['status'] == 'SYNCED'

        # Verify Attendance record was created on server
        att = Attendance.objects.filter(employee=self.employee).first()
        assert att is not None
        assert att.server_check_in_time is not None

    def test_batch_sync_offline_task_and_report(self):
        self.client.force_authenticate(user=self.emp_user)
        payload_data = {
            'device_id': 'test-mobile-device-003',
            'items': [
                {
                    'client_id': 'client-task-001',
                    'action_type': 'TASK_CREATE',
                    'client_timestamp': timezone.now().isoformat(),
                    'payload': {
                        'title': 'Offline Created Dev Task',
                        'description': 'Built offline during flight',
                        'priority': 'HIGH'
                    }
                },
                {
                    'client_id': 'client-report-001',
                    'action_type': 'DAILY_REPORT',
                    'client_timestamp': timezone.now().isoformat(),
                    'payload': {
                        'report_date': timezone.now().date().isoformat(),
                        'summary_text': 'Completed offline modules',
                        'completed_summary': 'Engine tests & sync schemas',
                        'status': 'SUBMITTED'
                    }
                }
            ]
        }

        response = self.client.post('/api/v1/sync/batch/', payload_data, format='json')
        assert response.status_code == status.HTTP_200_OK
        assert response.data['synced_count'] == 2

        # Verify Task created
        task = Task.objects.filter(title='Offline Created Dev Task').first()
        assert task is not None

        # Verify Daily Report created
        report = DailyWorkReport.objects.filter(employee=self.employee).first()
        assert report is not None
        assert report.summary_text == 'Completed offline modules'

    def test_sync_idempotency(self):
        self.client.force_authenticate(user=self.emp_user)
        payload_data = {
            'device_id': 'test-mobile-device-004',
            'items': [
                {
                    'client_id': 'client-idempotent-001',
                    'action_type': 'TASK_CREATE',
                    'client_timestamp': timezone.now().isoformat(),
                    'payload': {'title': 'Idempotent Task'}
                }
            ]
        }

        # First sync
        res1 = self.client.post('/api/v1/sync/batch/', payload_data, format='json')
        assert res1.status_code == status.HTTP_200_OK

        # Duplicate sync with same client_id
        res2 = self.client.post('/api/v1/sync/batch/', payload_data, format='json')
        assert res2.status_code == status.HTTP_200_OK
        assert res2.data['results'][0]['status'] == 'SYNCED'
        assert 'idempotent' in res2.data['results'][0]['message'].lower()

    def test_device_revocation_blocks_sync(self):
        # Register device
        device = DeviceRegistration.objects.create(
            device_id='compromised-device-999',
            employee=self.employee,
            is_revoked=True
        )

        self.client.force_authenticate(user=self.emp_user)
        payload_data = {
            'device_id': 'compromised-device-999',
            'items': [
                {
                    'client_id': 'client-blocked-001',
                    'action_type': 'TASK_CREATE',
                    'client_timestamp': timezone.now().isoformat(),
                    'payload': {'title': 'Should not sync'}
                }
            ]
        }

        response = self.client.post('/api/v1/sync/batch/', payload_data, format='json')
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_admin_sync_health_dashboard(self):
        DeviceRegistration.objects.create(device_id='dev-1', is_online=True)
        DeviceRegistration.objects.create(device_id='dev-2', is_online=False)

        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get('/api/v1/sync/admin/health/')
        assert response.status_code == status.HTTP_200_OK
        assert 'total_devices' in response.data
        assert response.data['total_devices'] >= 2
