from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from apps.core.permissions import IsAdminUserOnly
from .models import Department, Position, Role, Permission, RolePermission
from .serializers import (
    DepartmentSerializer,
    PositionSerializer,
    RoleSerializer,
    PermissionSerializer,
    AssignPermissionsSerializer
)

class DepartmentViewSet(viewsets.ModelViewSet):
    queryset = Department.objects.all()
    serializer_class = DepartmentSerializer
    filterset_fields = ['is_active']
    search_fields = ['name', 'code']
    ordering_fields = ['name', 'created_at']

    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAdminUserOnly()]
        return super().get_permissions()

    def destroy(self, request, *args, **kwargs):
        dept = self.get_object()
        if dept.employees.exists():
            return Response(
                {"error": f"Cannot delete department '{dept.name}' because {dept.employees.count()} employee(s) are assigned to it. Deactivate the department instead."},
                status=status.HTTP_400_BAD_REQUEST
            )
        return super().destroy(request, *args, **kwargs)


class PositionViewSet(viewsets.ModelViewSet):
    queryset = Position.objects.select_related('department').all()
    serializer_class = PositionSerializer
    filterset_fields = ['department', 'is_active']
    search_fields = ['title', 'code', 'department__name']

    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAdminUserOnly()]
        return super().get_permissions()

    def destroy(self, request, *args, **kwargs):
        pos = self.get_object()
        if pos.employees.exists():
            return Response(
                {"error": f"Cannot delete position '{pos.title}' because {pos.employees.count()} employee(s) hold this position. Deactivate the position instead."},
                status=status.HTTP_400_BAD_REQUEST
            )
        return super().destroy(request, *args, **kwargs)


class RoleViewSet(viewsets.ModelViewSet):
    queryset = Role.objects.prefetch_related('role_permissions__permission').all()
    serializer_class = RoleSerializer
    search_fields = ['name', 'code', 'description']

    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy', 'assign_permissions']:
            return [IsAdminUserOnly()]
        return super().get_permissions()

    def destroy(self, request, *args, **kwargs):
        role = self.get_object()
        if role.is_system_reserved:
            return Response(
                {"error": f"Cannot delete system-reserved role '{role.name}'."},
                status=status.HTTP_400_BAD_REQUEST
            )
        if role.employees.exists():
            return Response(
                {"error": f"Cannot delete role '{role.name}' because {role.employees.count()} employee(s) are assigned to it."},
                status=status.HTTP_400_BAD_REQUEST
            )
        return super().destroy(request, *args, **kwargs)

    @action(detail=True, methods=['post'], url_path='assign-permissions')
    def assign_permissions(self, request, pk=None):
        role = self.get_object()
        serializer = AssignPermissionsSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        permission_ids = serializer.validated_data['permission_ids']
        
        # Atomically replace role permissions
        RolePermission.objects.filter(role=role).delete()
        new_permissions = [
            RolePermission(role=role, permission_id=pid)
            for pid in permission_ids
        ]
        RolePermission.objects.bulk_create(new_permissions)

        return Response({
            'success': True,
            'message': f"Permissions successfully updated for role '{role.name}'."
        })


class PermissionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Permission.objects.all()
    serializer_class = PermissionSerializer
    filterset_fields = ['category']
    search_fields = ['name', 'code']
