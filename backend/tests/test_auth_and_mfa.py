import pytest
import pyotp
from rest_framework.test import APIClient
from rest_framework import status
from django.core.exceptions import ValidationError
from apps.accounts.models import User, UserDevice, UserSession, MFASetting
from apps.accounts.validators import ComplexPasswordValidator, PasswordHistoryValidator
from apps.organization.models import Role, Department, Position
from apps.employees.models import Employee

@pytest.mark.django_db
class TestAuthenticationAndSecurity:
    def setup_method(self):
        self.client = APIClient()
        self.dept = Department.objects.create(name='Engineering', code='ENG')
        self.pos = Position.objects.create(department=self.dept, title='Software Engineer', code='SE')
        self.role = Role.objects.create(code=Role.RoleCode.IT, name='IT')
        
        self.user = User.objects.create_user(
            email='test.dev@pcrm.local',
            employee_code='PBE000099',
            password='ComplexPassword@123!'
        )
        self.employee = Employee.objects.create(
            user=self.user,
            first_name='Test',
            last_name='Developer',
            department=self.dept,
            position=self.pos,
            role=self.role
        )

    def test_login_successful_with_employee_code(self):
        response = self.client.post('/api/v1/auth/login/', {
            'identifier': 'PBE000099',
            'password': 'ComplexPassword@123!',
            'device_info': {
                'device_id': 'device-uuid-12345',
                'device_name': 'Samsung Galaxy S24',
                'device_type': 'ANDROID'
            }
        }, format='json')
        assert response.status_code == status.HTTP_200_OK
        assert response.data['success'] is True
        assert 'access_token' in response.data
        assert 'refresh_token' in response.data
        assert response.data['user']['employee_code'] == 'PBE000099'
        
        # Verify device and session registered
        assert UserDevice.objects.filter(user=self.user, device_id='device-uuid-12345').exists()
        assert UserSession.objects.filter(user=self.user, is_active=True).exists()

    def test_login_successful_with_email(self):
        response = self.client.post('/api/v1/auth/login/', {
            'identifier': 'test.dev@pcrm.local',
            'password': 'ComplexPassword@123!'
        })
        assert response.status_code == status.HTTP_200_OK
        assert response.data['success'] is True

    def test_failed_login_throttling_and_lockout(self):
        # 5 consecutive failed login attempts
        for attempt in range(5):
            res = self.client.post('/api/v1/auth/login/', {
                'identifier': 'PBE000099',
                'password': 'WrongPassword123!'
            })
            assert res.status_code == status.HTTP_400_BAD_REQUEST

        self.user.refresh_from_db()
        assert self.user.status == User.AccountStatus.LOCKED
        assert self.user.is_locked is True

        # 6th attempt should be blocked with lockout message
        lockout_res = self.client.post('/api/v1/auth/login/', {
            'identifier': 'PBE000099',
            'password': 'ComplexPassword@123!'
        })
        assert lockout_res.status_code == status.HTTP_400_BAD_REQUEST
        assert 'locked' in lockout_res.data['errors']['non_field_errors'][0].lower() or 'locked' in lockout_res.data['message'].lower()

    def test_mfa_setup_and_verification_flow(self):
        # Authenticate first
        login_res = self.client.post('/api/v1/auth/login/', {
            'identifier': 'PBE000099',
            'password': 'ComplexPassword@123!'
        })
        token = login_res.data['access_token']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')

        # Setup MFA
        setup_res = self.client.get('/api/v1/auth/mfa/setup/')
        assert setup_res.status_code == status.HTTP_200_OK
        secret = setup_res.data['secret']

        # Confirm MFA with valid TOTP code
        totp = pyotp.TOTP(secret)
        current_code = totp.now()

        confirm_res = self.client.post('/api/v1/auth/mfa/confirm/', {'code': current_code})
        assert confirm_res.status_code == status.HTTP_200_OK
        assert confirm_res.data['success'] is True
        assert len(confirm_res.data['recovery_codes']) == 8

        self.user.refresh_from_db()
        assert self.user.is_mfa_enabled is True

        # Next login should challenge for MFA
        self.client.credentials()  # Clear auth
        mfa_login_res = self.client.post('/api/v1/auth/login/', {
            'identifier': 'PBE000099',
            'password': 'ComplexPassword@123!'
        })
        assert mfa_login_res.status_code == status.HTTP_200_OK
        assert mfa_login_res.data['mfa_required'] is True
        mfa_token = mfa_login_res.data['mfa_token']

        # Verify MFA
        verify_res = self.client.post('/api/v1/auth/mfa/verify/', {
            'mfa_token': mfa_token,
            'code': totp.now()
        })
        assert verify_res.status_code == status.HTTP_200_OK
        assert 'access_token' in verify_res.data

    def test_password_complexity_validator(self):
        validator = ComplexPasswordValidator()
        # Missing uppercase
        with pytest.raises(ValidationError):
            validator.validate('alllowercase123!@#')
        # Missing special symbol
        with pytest.raises(ValidationError):
            validator.validate('PasswordWithoutSymbol123')
        # Too short
        with pytest.raises(ValidationError):
            validator.validate('Short1!')
        # Valid
        validator.validate('StrongSecurePassword#2026')
