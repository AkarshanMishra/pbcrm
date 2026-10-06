from rest_framework import serializers
from .models import Department, Position, Role, Permission, RolePermission

class DepartmentSerializer(serializers.ModelSerializer):
    position_count = serializers.IntegerField(source='positions.count', read_only=True)
    employee_count = serializers.IntegerField(source='employees.count', read_only=True)
    active_employee_count = serializers.SerializerMethodField()
    open_jobs_count = serializers.SerializerMethodField()
    positions_list = serializers.SerializerMethodField()

    class Meta:
        model = Department
        fields = [
            'id', 'name', 'code', 'description', 'is_active',
            'position_count', 'employee_count', 'active_employee_count',
            'open_jobs_count', 'positions_list', 'created_at'
        ]

    def validate_code(self, value):
        return value.strip().upper()

    def get_active_employee_count(self, obj):
        return obj.employees.filter(user__is_active=True).count()

    def get_open_jobs_count(self, obj):
        if hasattr(obj, 'job_openings'):
            return obj.job_openings.filter(status='OPEN').count()
        return 0

    def get_positions_list(self, obj):
        return [
            {
                'id': str(p.id),
                'title': p.title,
                'code': p.code,
                'is_active': p.is_active,
                'employee_count': p.employees.count(),
            }
            for p in obj.positions.all()[:10]
        ]



class PositionSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source='department.name', read_only=True)
    employee_count = serializers.IntegerField(source='employees.count', read_only=True)

    class Meta:
        model = Position
        fields = ['id', 'department', 'department_name', 'title', 'code', 'description', 'is_active', 'employee_count', 'created_at']

    def validate_code(self, value):
        if value:
            return value.strip().upper()
        return value


class PermissionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Permission
        fields = ['id', 'code', 'name', 'category', 'description']


class RoleSerializer(serializers.ModelSerializer):
    permissions = serializers.SerializerMethodField()
    employee_count = serializers.IntegerField(source='employees.count', read_only=True)
    permission_ids = serializers.ListField(
        child=serializers.UUIDField(),
        write_only=True,
        required=False,
        allow_empty=True,
        help_text="List of Permission UUIDs to assign to the role"
    )

    class Meta:
        model = Role
        fields = ['id', 'code', 'name', 'description', 'is_system_reserved', 'permissions', 'permission_ids', 'employee_count', 'created_at']

    def validate_code(self, value):
        return value.strip().upper()

    def get_permissions(self, obj):
        perms = Permission.objects.filter(permission_roles__role=obj)
        return PermissionSerializer(perms, many=True).data

    def create(self, validated_data):
        permission_ids = validated_data.pop('permission_ids', None)
        role = super().create(validated_data)
        if permission_ids is not None:
            new_permissions = [
                RolePermission(role=role, permission_id=pid)
                for pid in permission_ids
            ]
            RolePermission.objects.bulk_create(new_permissions)
        return role

    def update(self, instance, validated_data):
        permission_ids = validated_data.pop('permission_ids', None)
        role = super().update(instance, validated_data)
        if permission_ids is not None:
            RolePermission.objects.filter(role=role).delete()
            new_permissions = [
                RolePermission(role=role, permission_id=pid)
                for pid in permission_ids
            ]
            RolePermission.objects.bulk_create(new_permissions)
        return role


class AssignPermissionsSerializer(serializers.Serializer):
    permission_ids = serializers.ListField(
        child=serializers.UUIDField(),
        allow_empty=True,
        help_text="List of Permission UUIDs to assign to the role"
    )
