import pytest
from datetime import date
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from apps.accounts.models import User
from apps.organization.models import Department, Position, Role
from apps.employees.models import Employee
from apps.attendance.models import Attendance, AttendanceCorrection

@pytest.mark.django_db
class TestAttendanceWorkflow:
    def setup_method(self):
        self.client = APIClient()
        self.dept = Department.objects.create(name='IT Ops', code='ITO')
        self.pos = Position.objects.create(department=self.dept, title='SysAdmin', code='SA')
        self.role = Role.objects.create(code=Role.RoleCode.IT, name='IT')
        
        # Admin / Manager
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
            role=self.role
        )

        # Regular Employee
        self.emp_user = User.objects.create_user(
            email='emp@pcrm.local',
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

    def test_check_in_and_check_out_flow(self):
        self.client.force_authenticate(user=self.emp_user)

        # 1. Check in
        check_in_res = self.client.post('/api/v1/attendance/check-in/', {
            'latitude': 28.6139,
            'longitude': 77.2090,
            'notes': 'Working from office'
        })
        assert check_in_res.status_code == status.HTTP_201_CREATED
        assert check_in_res.data['success'] is True

        today = timezone.localdate()
        att = Attendance.objects.get(employee=self.employee, attendance_date=today)
        assert att.server_check_in_time is not None
        assert att.status == Attendance.AttendanceStatus.PRESENT

        # 2. Duplicate check-in on same day should be prevented (Rule #16)
        duplicate_res = self.client.post('/api/v1/attendance/check-in/')
        assert duplicate_res.status_code == status.HTTP_400_BAD_REQUEST
        assert 'already checked in' in duplicate_res.data['message'].lower()

        # 3. Check out
        check_out_res = self.client.post('/api/v1/attendance/check-out/', {
            'notes': 'Completed daily tasks'
        })
        assert check_out_res.status_code == status.HTTP_200_OK
        att.refresh_from_db()
        assert att.server_check_out_time is not None

        # 4. Duplicate check out should fail
        dup_checkout_res = self.client.post('/api/v1/attendance/check-out/')
        assert dup_checkout_res.status_code == status.HTTP_400_BAD_REQUEST

    def test_attendance_correction_approval_workflow(self):
        # Create an existing past attendance record with missing checkout
        past_date = date(2026, 10, 1)
        att = Attendance.objects.create(
            employee=self.employee,
            attendance_date=past_date,
            server_check_in_time='09:00:00',
            status=Attendance.AttendanceStatus.PRESENT
        )

        # Employee requests correction
        self.client.force_authenticate(user=self.emp_user)
        req_res = self.client.post('/api/v1/attendance/corrections/', {
            'attendance_id': str(att.id),
            'requested_check_out_time': '18:30:00',
            'reason': 'Forgot to punch out due to client meeting.'
        })
        assert req_res.status_code == status.HTTP_201_CREATED
        correction_id = req_res.data['id']

        # Manager / Admin reviews and approves
        self.client.force_authenticate(user=self.admin_user)
        review_res = self.client.post(f'/api/v1/attendance/corrections/{correction_id}/review/', {
            'decision': 'APPROVED',
            'review_remarks': 'Verified with client meeting logs.'
        })
        assert review_res.status_code == status.HTTP_200_OK
        assert review_res.data['success'] is True

        att.refresh_from_db()
        assert att.is_corrected is True
        assert str(att.server_check_out_time) == '18:30:00'
