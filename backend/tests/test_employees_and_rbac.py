import pytest
from rest_framework.test import APIClient
from rest_framework import status
from apps.accounts.models import User, UserSession
from apps.organization.models import Department, Position, Role, Permission, RolePermission
from apps.employees.models import Employee, generate_next_employee_code

@pytest.mark.django_db
class TestEmployeeAndRBAC:
    def setup_method(self):
        self.client = APIClient()
        self.dept = Department.objects.create(name='Marketing Group', code='MKTG')
        self.pos = Position.objects.create(department=self.dept, title='Growth Specialist', code='GS')
        self.admin_role = Role.objects.create(code=Role.RoleCode.ADMIN, name='Admin')
        self.mkt_role = Role.objects.create(code=Role.RoleCode.MARKETING, name='Marketing')

        # Admin
        self.admin_user = User.objects.create_superuser(
            email='admin@pcrm.local',
            employee_code='PBE000001',
            password='AdminPassword@123!'
        )
        self.admin_emp = Employee.objects.create(
            user=self.admin_user,
            first_name='System',
            last_name='Admin',
            department=self.dept,
            position=self.pos,
            role=self.admin_role
        )

    def test_sequential_pbe_id_generation(self):
        code1 = generate_next_employee_code()
        assert code1.startswith('PBE')
        assert len(code1) == 9  # PBE + 6 digits

    def test_admin_creates_new_employee(self):
        self.client.force_authenticate(user=self.admin_user)
        res = self.client.post('/api/v1/employees/', {
            'first_name': 'Sneha',
            'last_name': 'Gupta',
            'email': 'sneha.gupta@pcrm.local',
            'phone': '+919876543210',
            'department_id': str(self.dept.id),
            'position_id': str(self.pos.id),
            'role_id': str(self.mkt_role.id),
            'employment_type': 'FULL_TIME'
        })
        assert res.status_code == status.HTTP_201_CREATED
        assert res.data['employee_code'].startswith('PBE')
        assert res.data['email'] == 'sneha.gupta@pcrm.local'

    def test_employee_deactivation_revokes_sessions(self):
        # Create an employee
        user = User.objects.create_user(
            email='target@pcrm.local',
            employee_code='PBE000007',
            password='TargetPassword@123!'
        )
        emp = Employee.objects.create(
            user=user,
            first_name='Target',
            last_name='User',
            department=self.dept,
            position=self.pos,
            role=self.mkt_role
        )
        # Create active session
        session = UserSession.objects.create(
            user=user,
            refresh_token_jti='test-jti-session',
            ip_address='127.0.0.1',
            expires_at='2030-01-01T00:00:00Z',
            is_active=True
        )

        # Admin deactivates employee
        self.client.force_authenticate(user=self.admin_user)
        res = self.client.post(f'/api/v1/employees/{emp.id}/change-status/', {
            'status': 'DEACTIVATED',
            'reason': 'Employee resigned and offboarding completed.'
        })
        assert res.status_code == status.HTTP_200_OK
        user.refresh_from_db()
        session.refresh_from_db()
        assert user.status == User.AccountStatus.DEACTIVATED
        assert user.is_active is False
        assert session.is_active is False

    def test_admin_creates_employee_with_custom_id_and_password(self):
        self.client.force_authenticate(user=self.admin_user)
        res = self.client.post('/api/v1/employees/', {
            'employee_code': 'PBE999999',
            'first_name': 'Vikram',
            'last_name': 'Singh',
            'email': 'vikram.singh@pcrm.local',
            'phone': '+919811122233',
            'password': 'CustomSecretPassword@123!',
            'department_id': str(self.dept.id),
            'position_id': str(self.pos.id),
            'role_id': str(self.mkt_role.id),
            'employment_type': 'FULL_TIME'
        })
        assert res.status_code == status.HTTP_201_CREATED
        assert res.data['employee_code'] == 'PBE999999'
        assert res.data['email'] == 'vikram.singh@pcrm.local'

        # Verify password works
        user = User.objects.get(employee_code='PBE999999')
        assert user.check_password('CustomSecretPassword@123!') is True

    def test_admin_updates_employee(self):
        self.client.force_authenticate(user=self.admin_user)
        # Create an employee
        user = User.objects.create_user(
            email='edit.target@pcrm.local',
            employee_code='PBE000088',
            password='TargetPassword@123!'
        )
        emp = Employee.objects.create(
            user=user,
            first_name='Original',
            last_name='Name',
            department=self.dept,
            position=self.pos,
            role=self.mkt_role
        )

        res = self.client.patch(f'/api/v1/employees/{emp.id}/', {
            'first_name': 'UpdatedFirst',
            'last_name': 'UpdatedLast',
            'phone': '+919999888877'
        })
        assert res.status_code == status.HTTP_200_OK
        emp.refresh_from_db()
        assert emp.first_name == 'UpdatedFirst'
        assert emp.last_name == 'UpdatedLast'
        assert emp.user.phone == '+919999888877'

    def test_admin_resets_employee_password(self):
        self.client.force_authenticate(user=self.admin_user)
        user = User.objects.create_user(
            email='pw.reset@pcrm.local',
            employee_code='PBE000077',
            password='OldPassword@123!'
        )
        emp = Employee.objects.create(
            user=user,
            first_name='PW',
            last_name='Reset',
            department=self.dept,
            position=self.pos,
            role=self.mkt_role
        )

        res = self.client.post(f'/api/v1/employees/{emp.id}/reset-password/', {
            'new_password': 'BrandNewAdminPassword@999!'
        })
        assert res.status_code == status.HTTP_200_OK
        user.refresh_from_db()
        assert user.check_password('BrandNewAdminPassword@999!') is True

    def test_admin_deletes_employee(self):
        self.client.force_authenticate(user=self.admin_user)
        user = User.objects.create_user(
            email='delete.me@pcrm.local',
            employee_code='PBE000066',
            password='DeletePassword@123!'
        )
        emp = Employee.objects.create(
            user=user,
            first_name='To',
            last_name='Delete',
            department=self.dept,
            position=self.pos,
            role=self.mkt_role
        )
        emp_id = str(emp.id)

        res = self.client.delete(f'/api/v1/employees/{emp_id}/')
        assert res.status_code == status.HTTP_200_OK
        assert not Employee.objects.filter(id=emp_id).exists()
        assert not User.objects.filter(employee_code='PBE000066').exists()

