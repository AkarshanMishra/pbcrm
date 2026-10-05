import secrets
from django.db import transaction
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from apps.accounts.models import User
from apps.organization.models import Department, Position, Role
from apps.organization.serializers import DepartmentSerializer, PositionSerializer, RoleSerializer
from .models import Employee, EmployeeLifecycleHistory, generate_next_employee_code

class EmployeeListSerializer(serializers.ModelSerializer):
    employee_code = serializers.CharField(source='user.employee_code', read_only=True)
    email = serializers.CharField(source='user.email', read_only=True)
    phone = serializers.CharField(source='user.phone', read_only=True)
    status = serializers.CharField(source='user.status', read_only=True)
    department_name = serializers.CharField(source='department.name', read_only=True)
    position_title = serializers.CharField(source='position.title', read_only=True)
    role_name = serializers.CharField(source='role.name', read_only=True)
    manager_name = serializers.CharField(source='reporting_manager.full_name', read_only=True)

    class Meta:
        model = Employee
        fields = [
            'id',
            'employee_code',
            'first_name',
            'last_name',
            'full_name',
            'email',
            'phone',
            'status',
            'department',
            'department_name',
            'position',
            'position_title',
            'role',
            'role_name',
            'reporting_manager',
            'manager_name',
            'employment_type',
            'joining_date',
            'created_at'
        ]


class EmployeeDetailSerializer(serializers.ModelSerializer):
    employee_code = serializers.CharField(source='user.employee_code', read_only=True)
    email = serializers.CharField(source='user.email', read_only=True)
    phone = serializers.CharField(source='user.phone', read_only=True)
    status = serializers.CharField(source='user.status', read_only=True)
    department_details = DepartmentSerializer(source='department', read_only=True)
    position_details = PositionSerializer(source='position', read_only=True)
    role_details = RoleSerializer(source='role', read_only=True)
    manager_name = serializers.CharField(source='reporting_manager.full_name', read_only=True)

    class Meta:
        model = Employee
        fields = [
            'id',
            'employee_code',
            'first_name',
            'last_name',
            'full_name',
            'email',
            'phone',
            'gender',
            'date_of_birth',
            'status',
            'department',
            'department_details',
            'position',
            'position_details',
            'role',
            'role_details',
            'reporting_manager',
            'manager_name',
            'employment_type',
            'emergency_contact_name',
            'emergency_contact_phone',
            'address',
            'joining_date',
            'created_at',
            'updated_at'
        ]


class EmployeeCreateSerializer(serializers.Serializer):
    employee_code = serializers.CharField(max_length=30, required=False, allow_blank=True, help_text="Custom Employee ID (optional; auto-generated if omitted)")
    first_name = serializers.CharField(max_length=100)
    last_name = serializers.CharField(max_length=100)
    email = serializers.EmailField()
    phone = serializers.CharField(max_length=25, required=False, allow_blank=True)
    password = serializers.CharField(write_only=True, required=False, allow_blank=True, help_text="Initial password for employee")
    department_id = serializers.PrimaryKeyRelatedField(queryset=Department.objects.filter(is_active=True), source='department')
    position_id = serializers.PrimaryKeyRelatedField(queryset=Position.objects.filter(is_active=True), source='position')
    role_id = serializers.PrimaryKeyRelatedField(queryset=Role.objects.all(), source='role')
    reporting_manager_id = serializers.PrimaryKeyRelatedField(queryset=Employee.objects.all(), required=False, allow_null=True, source='reporting_manager')
    joining_date = serializers.DateField(required=False)
    employment_type = serializers.ChoiceField(choices=Employee.EmploymentType.choices, default=Employee.EmploymentType.FULL_TIME)

    def validate_email(self, value):
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("A user with this email address already exists.")
        return value.lower()

    def validate_employee_code(self, value):
        if value and value.strip():
            if User.objects.filter(employee_code__iexact=value.strip()).exists():
                raise serializers.ValidationError("An employee with this Employee ID already exists.")
            return value.strip().upper()
        return None

    @transaction.atomic
    def create(self, validated_data):
        email = validated_data['email']
        phone = validated_data.get('phone', '')
        password = validated_data.get('password')
        custom_code = validated_data.get('employee_code')
        
        # If no password provided, generate a secure initial password
        if not password or not password.strip():
            password = f"Pcrm@{secrets.token_urlsafe(8)}!"

        # Use custom Employee ID or generate next sequential PBE ID
        employee_code = custom_code if (custom_code and custom_code.strip()) else generate_next_employee_code()

        # Create User
        user = User.objects.create_user(
            email=email,
            employee_code=employee_code,
            phone=phone,
            password=password.strip(),
            status=User.AccountStatus.ACTIVE
        )

        # Create Employee
        employee = Employee.objects.create(
            user=user,
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name'],
            department=validated_data['department'],
            position=validated_data['position'],
            role=validated_data['role'],
            reporting_manager=validated_data.get('reporting_manager'),
            joining_date=validated_data.get('joining_date', user.created_at.date()),
            employment_type=validated_data.get('employment_type', Employee.EmploymentType.FULL_TIME)
        )

        return employee


class EmployeeUpdateSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(source='user.email', required=False)
    phone = serializers.CharField(source='user.phone', required=False, allow_blank=True)
    first_name = serializers.CharField(required=False)
    last_name = serializers.CharField(required=False)
    department_id = serializers.PrimaryKeyRelatedField(queryset=Department.objects.all(), source='department', required=False)
    position_id = serializers.PrimaryKeyRelatedField(queryset=Position.objects.all(), source='position', required=False)
    role_id = serializers.PrimaryKeyRelatedField(queryset=Role.objects.all(), source='role', required=False)
    reporting_manager_id = serializers.PrimaryKeyRelatedField(queryset=Employee.objects.all(), source='reporting_manager', required=False, allow_null=True)
    employment_type = serializers.ChoiceField(choices=Employee.EmploymentType.choices, required=False)

    class Meta:
        model = Employee
        fields = [
            'first_name',
            'last_name',
            'email',
            'phone',
            'department_id',
            'position_id',
            'role_id',
            'reporting_manager_id',
            'employment_type',
            'emergency_contact_name',
            'emergency_contact_phone',
            'address'
        ]

    @transaction.atomic
    def update(self, instance, validated_data):
        user_data = validated_data.pop('user', {})
        if 'email' in user_data:
            instance.user.email = user_data['email'].lower()
        if 'phone' in user_data:
            instance.user.phone = user_data['phone']
        instance.user.save()

        for attr, val in validated_data.items():
            setattr(instance, attr, val)
        instance.save()
        return instance


class AdminResetPasswordSerializer(serializers.Serializer):
    new_password = serializers.CharField(min_length=8, help_text="New password set by administrator")


class ChangePositionSerializer(serializers.Serializer):
    department_id = serializers.PrimaryKeyRelatedField(queryset=Department.objects.filter(is_active=True))
    position_id = serializers.PrimaryKeyRelatedField(queryset=Position.objects.filter(is_active=True))
    role_id = serializers.PrimaryKeyRelatedField(queryset=Role.objects.all(), required=False)
    reason = serializers.CharField(required=False, allow_blank=True)


class ChangeStatusSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=User.AccountStatus.choices)
    reason = serializers.CharField(required=False, allow_blank=True)
