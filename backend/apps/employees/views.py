from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db import transaction
from django.shortcuts import get_object_or_404
from apps.core.permissions import IsAdminUserOnly, IsManagerOrAdmin
from apps.audit.models import AuditLog
from apps.accounts.models import User, UserSession
from .models import Employee, EmployeeLifecycleHistory
from .serializers import (
    EmployeeListSerializer,
    EmployeeDetailSerializer,
    EmployeeCreateSerializer,
    EmployeeUpdateSerializer,
    AdminResetPasswordSerializer,
    ChangePositionSerializer,
    ChangeStatusSerializer
)

class EmployeeViewSet(viewsets.ModelViewSet):
    serializer_class = EmployeeListSerializer
    filterset_fields = ['department', 'position', 'role', 'user__status', 'employment_type']
    search_fields = ['user__employee_code', 'first_name', 'last_name', 'user__email', 'user__phone']
    ordering_fields = ['user__employee_code', 'first_name', 'joining_date', 'created_at']

    def get_queryset(self):
        user = self.request.user
        base_qs = Employee.objects.select_related(
            'user', 'department', 'position', 'role', 'reporting_manager__user'
        )

        if user.is_superuser or user.is_admin_role:
            return base_qs.all()

        if hasattr(user, 'employee_profile'):
            emp = user.employee_profile
            # Managers can view themselves + their direct and indirect subordinates
            return base_qs.filter(id__in=self._get_team_ids(emp))

        return Employee.objects.none()

    def _get_team_ids(self, manager_emp):
        team_ids = {manager_emp.id}
        direct_reports = list(manager_emp.direct_reports.values_list('id', flat=True))
        team_ids.update(direct_reports)
        return list(team_ids)

    def get_serializer_class(self):
        if self.action == 'create':
            return EmployeeCreateSerializer
        if self.action in ['update', 'partial_update']:
            return EmployeeUpdateSerializer
        if self.action in ['retrieve']:
            return EmployeeDetailSerializer
        return EmployeeListSerializer

    def get_permissions(self):
        if self.action in ['create', 'destroy', 'update', 'partial_update', 'change_position', 'change_status', 'reset_password']:
            return [IsAdminUserOnly()]
        return [permissions.IsAuthenticated()]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        employee = serializer.save()

        AuditLog.log_event(
            actor=request.user,
            event_type=AuditLog.EventType.EMPLOYEE_CREATED,
            target_model='Employee',
            target_id=str(employee.id),
            request=request,
            metadata={
                'employee_code': employee.user.employee_code,
                'email': employee.user.email,
                'department': employee.department.name,
                'position': employee.position.title,
                'role': employee.role.code
            }
        )

        detail_serializer = EmployeeDetailSerializer(employee)
        return Response(detail_serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['get'], url_path='me')
    def me(self, request):
        if not hasattr(request.user, 'employee_profile'):
            return Response({'success': False, 'message': 'No employee profile associated.'}, status=status.HTTP_404_NOT_FOUND)
        serializer = EmployeeDetailSerializer(request.user.employee_profile)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='team')
    def team(self, request):
        if not hasattr(request.user, 'employee_profile'):
            return Response({'success': False, 'message': 'No employee profile associated.'}, status=status.HTTP_404_NOT_FOUND)
        emp = request.user.employee_profile
        direct_reports = emp.direct_reports.select_related('user', 'department', 'position', 'role')
        serializer = EmployeeListSerializer(direct_reports, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'], url_path='change-position')
    def change_position(self, request, pk=None):
        employee = self.get_object()
        serializer = ChangePositionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        old_dept = employee.department.name
        old_pos = employee.position.title
        old_role = employee.role.code

        new_dept = serializer.validated_data['department_id']
        new_pos = serializer.validated_data['position_id']
        new_role = serializer.validated_data.get('role_id')
        reason = serializer.validated_data.get('reason', '')

        employee.department = new_dept
        employee.position = new_pos
        if new_role:
            employee.role = new_role
        employee.save()

        AuditLog.log_event(
            actor=request.user,
            event_type=AuditLog.EventType.POSITION_CHANGED,
            target_model='Employee',
            target_id=str(employee.id),
            request=request,
            metadata={
                'employee_code': employee.user.employee_code,
                'from': f"{old_dept} / {old_pos} ({old_role})",
                'to': f"{new_dept.name} / {new_pos.title} ({employee.role.code})",
                'reason': reason
            }
        )

        return Response({
            'success': True,
            'message': f"Position updated successfully for {employee.full_name}."
        })

    @action(detail=True, methods=['post'], url_path='change-status')
    @transaction.atomic
    def change_status(self, request, pk=None):
        employee = self.get_object()
        serializer = ChangeStatusSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        new_status = serializer.validated_data['status']
        reason = serializer.validated_data.get('reason', '')
        old_status = employee.user.status

        employee.user.status = new_status
        if new_status == User.AccountStatus.DEACTIVATED:
            employee.user.is_active = False
            # Revoke all active sessions and devices
            UserSession.objects.filter(user=employee.user).update(is_active=False)
            employee.user.devices.update(is_revoked=True)
        elif new_status == User.AccountStatus.ACTIVE:
            employee.user.is_active = True
            employee.user.failed_login_attempts = 0
            employee.user.locked_until = None

        employee.user.save()

        EmployeeLifecycleHistory.objects.create(
            employee=employee,
            previous_status=old_status,
            new_status=new_status,
            reason=reason,
            changed_by=request.user
        )

        AuditLog.log_event(
            actor=request.user,
            event_type=AuditLog.EventType.EMPLOYEE_STATUS_CHANGED,
            target_model='Employee',
            target_id=str(employee.id),
            request=request,
            metadata={
                'employee_code': employee.user.employee_code,
                'old_status': old_status,
                'new_status': new_status,
                'reason': reason
            }
        )

        return Response({
            'success': True,
            'message': f"Status changed from {old_status} to {new_status} for {employee.full_name}."
        })

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        employee = self.get_object()
        serializer = EmployeeUpdateSerializer(employee, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        updated_emp = serializer.save()

        AuditLog.log_event(
            actor=request.user,
            event_type=AuditLog.EventType.ADMIN_ACTION,
            target_model='Employee',
            target_id=str(updated_emp.id),
            request=request,
            metadata={
                'action': 'EMPLOYEE_UPDATED',
                'employee_code': updated_emp.user.employee_code,
                'updated_fields': list(request.data.keys())
            }
        )

        return Response(EmployeeDetailSerializer(updated_emp).data)

    def partial_update(self, request, *args, **kwargs):
        kwargs['partial'] = True
        return self.update(request, *args, **kwargs)

    @action(detail=True, methods=['post'], url_path='reset-password')
    @transaction.atomic
    def reset_password(self, request, pk=None):
        employee = self.get_object()
        serializer = AdminResetPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        new_password = serializer.validated_data['new_password']
        target_user = employee.user
        target_user.set_password(new_password)
        target_user.failed_login_attempts = 0
        target_user.locked_until = None
        target_user.save()

        # Invalidate all active sessions of this user
        UserSession.objects.filter(user=target_user).update(is_active=False)

        AuditLog.log_event(
            actor=request.user,
            event_type=AuditLog.EventType.ADMIN_ACTION,
            target_model='User',
            target_id=str(target_user.id),
            request=request,
            metadata={
                'action': 'ADMIN_PASSWORD_RESET',
                'target_employee_code': target_user.employee_code,
                'target_email': target_user.email
            }
        )

        return Response({
            'success': True,
            'message': f"Password for {employee.full_name} ({target_user.employee_code}) has been reset successfully."
        })

    @transaction.atomic
    def destroy(self, request, *args, **kwargs):
        employee = self.get_object()
        target_user = employee.user
        emp_code = target_user.employee_code
        emp_name = employee.full_name
        emp_id = str(employee.id)

        AuditLog.log_event(
            actor=request.user,
            event_type=AuditLog.EventType.ADMIN_ACTION,
            target_model='Employee',
            target_id=emp_id,
            request=request,
            metadata={
                'action': 'EMPLOYEE_DELETED',
                'employee_code': emp_code,
                'name': emp_name
            }
        )

        # Deleting the user will cascade delete the employee and related models
        target_user.delete()

        return Response({
            'success': True,
            'message': f"Employee {emp_name} ({emp_code}) deleted successfully."
        }, status=status.HTTP_200_OK)

