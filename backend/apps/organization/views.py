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
        if self.action in ['create', 'update', 'partial_update', 'destroy', 'transfer_employees']:
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

    @action(detail=True, methods=['get'])
    def details(self, request, pk=None):
        dept = self.get_object()
        employees_qs = dept.employees.select_related('user', 'position', 'role').all()
        
        employees_data = []
        for emp in employees_qs:
            employees_data.append({
                'id': str(emp.id),
                'user_id': str(emp.user.id),
                'name': emp.user.get_full_name() or f"{emp.first_name} {emp.last_name}",
                'employee_code': emp.user.employee_code,
                'email': emp.user.email,
                'phone': emp.user.phone or '',
                'position_title': emp.position.title if emp.position else 'N/A',
                'position_id': str(emp.position.id) if emp.position else None,
                'role_name': emp.role.name if emp.role else 'Staff',
                'is_active': emp.user.is_active,
                'employment_type': emp.employment_type,
                'joining_date': str(emp.date_of_joining) if hasattr(emp, 'date_of_joining') and emp.date_of_joining else None,
            })

        positions_qs = dept.positions.all()
        positions_data = [
            {
                'id': str(p.id),
                'title': p.title,
                'code': p.code,
                'description': p.description,
                'is_active': p.is_active,
                'employee_count': p.employees.count(),
            }
            for p in positions_qs
        ]

        jobs_data = []
        if hasattr(dept, 'job_openings'):
            jobs_data = [
                {
                    'id': str(j.id),
                    'code': j.code,
                    'title': j.title,
                    'status': j.status,
                    'openings_count': j.openings_count,
                    'experience_required': j.experience_required,
                    'applications_count': j.applications.count() if hasattr(j, 'applications') else 0,
                }
                for j in dept.job_openings.all()
            ]

        return Response({
            'department': DepartmentSerializer(dept).data,
            'employees': employees_data,
            'positions': positions_data,
            'jobs': jobs_data,
            'stats': {
                'total_employees': len(employees_data),
                'active_employees': sum(1 for e in employees_data if e['is_active']),
                'total_positions': len(positions_data),
                'active_jobs': sum(1 for j in jobs_data if j['status'] == 'OPEN'),
            }
        })

    @action(detail=True, methods=['post'], url_path='transfer-employees')
    def transfer_employees(self, request, pk=None):
        source_dept = self.get_object()
        target_dept_id = request.data.get('target_department_id')
        target_pos_id = request.data.get('target_position_id')
        employee_ids = request.data.get('employee_ids', [])

        if not target_dept_id:
            return Response({'error': 'target_department_id is required.'}, status=status.HTTP_400_BAD_REQUEST)
        if not employee_ids:
            return Response({'error': 'employee_ids list cannot be empty.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            target_dept = Department.objects.get(id=target_dept_id)
        except Department.DoesNotExist:
            return Response({'error': 'Target department not found.'}, status=status.HTTP_404_NOT_FOUND)

        target_pos = None
        if target_pos_id:
            target_pos = target_dept.positions.filter(id=target_pos_id).first()

        from apps.employees.models import Employee
        updated_count = 0
        for emp_id in employee_ids:
            emp = Employee.objects.filter(id=emp_id, department=source_dept).first()
            if emp:
                emp.department = target_dept
                if target_pos:
                    emp.position = target_pos
                emp.save(update_fields=['department', 'position'] if target_pos else ['department'])
                updated_count += 1

        return Response({
            'success': True,
            'message': f"Successfully transferred {updated_count} employee(s) to '{target_dept.name}'.",
            'transferred_count': updated_count,
        })



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
