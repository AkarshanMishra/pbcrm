from django.utils import timezone
from django.db import transaction
from django.shortcuts import get_object_or_404
from rest_framework import views, viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response

from apps.core.permissions import IsManagerOrAdmin, IsAdminUserOnly
from apps.audit.models import AuditLog
from apps.accounts.views import get_client_ip
from apps.accounts.models import UserDevice
from .models import Attendance, AttendanceCorrection
from .serializers import (
    CheckInSerializer,
    CheckOutSerializer,
    AttendanceSerializer,
    AttendanceCorrectionSerializer,
    AttendanceCorrectionCreateSerializer,
    AttendanceCorrectionReviewSerializer
)

class CheckInView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        if not hasattr(request.user, 'employee_profile'):
            return Response({'success': False, 'message': 'No employee profile associated with this account.'}, status=status.HTTP_400_BAD_REQUEST)

        employee = request.user.employee_profile
        today = timezone.localdate()
        current_time = timezone.localtime().time()

        # Check if already checked in today (Rule #16)
        existing = Attendance.objects.filter(employee=employee, attendance_date=today).first()
        if existing:
            return Response({
                'success': False,
                'message': f'You have already checked in for today ({today}) at {existing.server_check_in_time.strftime("%H:%M:%S")}.'
            }, status=status.HTTP_400_BAD_REQUEST)

        serializer = CheckInSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        device = None
        if data.get('device_id'):
            device = UserDevice.objects.filter(user=request.user, device_id=data['device_id']).first()

        attendance = Attendance.objects.create(
            employee=employee,
            attendance_date=today,
            server_check_in_time=current_time,
            status=Attendance.AttendanceStatus.PRESENT,
            check_in_ip=get_client_ip(request),
            check_in_device=device,
            check_in_latitude=data.get('latitude'),
            check_in_longitude=data.get('longitude'),
            notes=data.get('notes', '')
        )

        AuditLog.log_event(
            actor=request.user,
            event_type=AuditLog.EventType.ATTENDANCE_CHECKIN,
            target_model='Attendance',
            target_id=str(attendance.id),
            request=request,
            metadata={
                'attendance_date': str(today),
                'server_time': current_time.strftime('%H:%M:%S')
            }
        )

        return Response({
            'success': True,
            'message': f'Check-in successful at {current_time.strftime("%I:%M %p")}.',
            'data': AttendanceSerializer(attendance).data
        }, status=status.HTTP_201_CREATED)


class CheckOutView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        if not hasattr(request.user, 'employee_profile'):
            return Response({'success': False, 'message': 'No employee profile associated.'}, status=status.HTTP_400_BAD_REQUEST)

        employee = request.user.employee_profile
        today = timezone.localdate()
        current_time = timezone.localtime().time()

        attendance = Attendance.objects.filter(employee=employee, attendance_date=today).first()
        if not attendance:
            return Response({'success': False, 'message': 'No check-in record found for today. Please check in first.'}, status=status.HTTP_400_BAD_REQUEST)

        if attendance.server_check_out_time:
            return Response({
                'success': False,
                'message': f'You have already checked out for today at {attendance.server_check_out_time.strftime("%H:%M:%S")}.'
            }, status=status.HTTP_400_BAD_REQUEST)

        serializer = CheckOutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        device = None
        if data.get('device_id'):
            device = UserDevice.objects.filter(user=request.user, device_id=data['device_id']).first()

        attendance.server_check_out_time = current_time
        attendance.check_out_ip = get_client_ip(request)
        attendance.check_out_device = device
        attendance.check_out_latitude = data.get('latitude')
        attendance.check_out_longitude = data.get('longitude')
        if data.get('notes'):
            attendance.notes += f"\nCheckout Note: {data['notes']}"
        attendance.save()

        AuditLog.log_event(
            actor=request.user,
            event_type=AuditLog.EventType.ATTENDANCE_CHECKOUT,
            target_model='Attendance',
            target_id=str(attendance.id),
            request=request,
            metadata={
                'attendance_date': str(today),
                'server_time': current_time.strftime('%H:%M:%S')
            }
        )

        return Response({
            'success': True,
            'message': f'Check-out successful at {current_time.strftime("%I:%M %p")}.',
            'data': AttendanceSerializer(attendance).data
        })


class TodayStatusView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if not hasattr(request.user, 'employee_profile'):
            return Response({'success': False, 'message': 'No employee profile associated.'}, status=status.HTTP_400_BAD_REQUEST)

        employee = request.user.employee_profile
        today = timezone.localdate()
        attendance = Attendance.objects.filter(employee=employee, attendance_date=today).first()

        return Response({
            'success': True,
            'today_date': str(today),
            'server_time': timezone.localtime().strftime('%H:%M:%S'),
            'is_checked_in': attendance is not None,
            'is_checked_out': attendance.server_check_out_time is not None if attendance else False,
            'attendance': AttendanceSerializer(attendance).data if attendance else None
        })


class AttendanceViewSet(viewsets.ModelViewSet):
    serializer_class = AttendanceSerializer
    filterset_fields = ['attendance_date', 'status', 'is_corrected']
    search_fields = ['employee__user__employee_code', 'employee__first_name', 'employee__last_name']
    ordering_fields = ['attendance_date', 'server_check_in_time']
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        base_qs = Attendance.objects.select_related('employee__user', 'employee__department')

        if user.is_superuser or user.is_admin_role:
            return base_qs.all()

        if hasattr(user, 'employee_profile'):
            emp = user.employee_profile
            # If manager, can see team records
            if emp.direct_reports.exists():
                team_emp_ids = list(emp.direct_reports.values_list('id', flat=True)) + [emp.id]
                return base_qs.filter(employee_id__in=team_emp_ids)
            # Ordinary employee: own records only
            return base_qs.filter(employee=emp)

        return Attendance.objects.none()

    def perform_create(self, serializer):
        user = self.request.user
        emp = getattr(user, 'employee_profile', None)
        target_emp_id = self.request.data.get('employee') or self.request.data.get('employee_id')
        if (user.is_superuser or user.is_admin_role or (emp and emp.role.code == 'ADMIN')) and target_emp_id:
            target_emp = Employee.objects.filter(id=target_emp_id).first()
            if target_emp:
                serializer.save(employee=target_emp)
                return
        serializer.save(employee=emp)


class AttendanceCorrectionViewSet(viewsets.ModelViewSet):
    serializer_class = AttendanceCorrectionSerializer
    filterset_fields = ['status', 'attendance__attendance_date']
    search_fields = ['employee__user__employee_code', 'employee__first_name', 'employee__last_name']

    def get_queryset(self):
        user = self.request.user
        base_qs = AttendanceCorrection.objects.select_related('employee__user', 'attendance', 'reviewed_by')

        if user.is_superuser or user.is_admin_role:
            return base_qs.all()

        if hasattr(user, 'employee_profile'):
            emp = user.employee_profile
            if emp.direct_reports.exists():
                team_emp_ids = list(emp.direct_reports.values_list('id', flat=True)) + [emp.id]
                return base_qs.filter(employee_id__in=team_emp_ids)
            return base_qs.filter(employee=emp)

        return AttendanceCorrection.objects.none()

    def create(self, request, *args, **kwargs):
        if not hasattr(request.user, 'employee_profile'):
            return Response({'success': False, 'message': 'No employee profile associated.'}, status=status.HTTP_400_BAD_REQUEST)

        serializer = AttendanceCorrectionCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        emp = request.user.employee_profile

        # Find or create target attendance entry
        if data.get('attendance_id'):
            attendance = get_object_or_404(Attendance, id=data['attendance_id'], employee=emp)
        elif data.get('attendance_date'):
            attendance, _ = Attendance.objects.get_or_create(
                employee=emp,
                attendance_date=data['attendance_date'],
                defaults={'status': Attendance.AttendanceStatus.ABSENT}
            )
        else:
            return Response({'success': False, 'message': 'Either attendance_id or attendance_date is required.'}, status=status.HTTP_400_BAD_REQUEST)

        correction = AttendanceCorrection.objects.create(
            attendance=attendance,
            employee=emp,
            requested_check_in_time=data.get('requested_check_in_time'),
            requested_check_out_time=data.get('requested_check_out_time'),
            requested_status=data.get('requested_status', Attendance.AttendanceStatus.PRESENT),
            reason=data['reason'],
            status=AttendanceCorrection.CorrectionStatus.PENDING
        )

        AuditLog.log_event(
            actor=request.user,
            event_type=AuditLog.EventType.ATTENDANCE_CORRECTION_REQ,
            target_model='AttendanceCorrection',
            target_id=str(correction.id),
            request=request,
            metadata={'date': str(attendance.attendance_date), 'reason': data['reason']}
        )

        return Response(AttendanceCorrectionSerializer(correction).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'], permission_classes=[IsManagerOrAdmin], url_path='review')
    @transaction.atomic
    def review(self, request, pk=None):
        correction = self.get_object()
        if correction.status != AttendanceCorrection.CorrectionStatus.PENDING:
            return Response({'success': False, 'message': f'Correction is already {correction.status}.'}, status=status.HTTP_400_BAD_REQUEST)

        serializer = AttendanceCorrectionReviewSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        decision = serializer.validated_data['decision']
        remarks = serializer.validated_data.get('review_remarks', '')

        correction.status = decision
        correction.reviewed_by = request.user
        correction.reviewed_at = timezone.now()
        correction.review_remarks = remarks
        correction.save()

        if decision == 'APPROVED':
            attendance = correction.attendance
            old_vals = {
                'check_in': str(attendance.server_check_in_time),
                'check_out': str(attendance.server_check_out_time),
                'status': attendance.status
            }
            if correction.requested_check_in_time:
                attendance.server_check_in_time = correction.requested_check_in_time
            if correction.requested_check_out_time:
                attendance.server_check_out_time = correction.requested_check_out_time
            if correction.requested_status:
                attendance.status = correction.requested_status
            attendance.is_corrected = True
            attendance.notes += f"\n[Approved Correction by {request.user.employee_code}]: {remarks}"
            attendance.save()

            AuditLog.log_event(
                actor=request.user,
                event_type=AuditLog.EventType.ATTENDANCE_CORRECTION_APPROVED,
                target_model='AttendanceCorrection',
                target_id=str(correction.id),
                request=request,
                metadata={'old': old_vals, 'employee': correction.employee.user.employee_code}
            )
        else:
            AuditLog.log_event(
                actor=request.user,
                event_type=AuditLog.EventType.ATTENDANCE_CORRECTION_REJECTED,
                target_model='AttendanceCorrection',
                target_id=str(correction.id),
                request=request,
                metadata={'employee': correction.employee.user.employee_code, 'reason': remarks}
            )

        return Response({
            'success': True,
            'message': f'Attendance correction has been {decision.lower()}.',
            'data': AttendanceCorrectionSerializer(correction).data
        })
