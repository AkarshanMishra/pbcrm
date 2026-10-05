from rest_framework import serializers
from .models import Attendance, AttendanceCorrection

class CheckInSerializer(serializers.Serializer):
    device_id = serializers.CharField(max_length=255, required=False, allow_blank=True)
    latitude = serializers.DecimalField(max_digits=9, decimal_places=6, required=False, allow_null=True)
    longitude = serializers.DecimalField(max_digits=9, decimal_places=6, required=False, allow_null=True)
    notes = serializers.CharField(required=False, allow_blank=True)


class CheckOutSerializer(serializers.Serializer):
    device_id = serializers.CharField(max_length=255, required=False, allow_blank=True)
    latitude = serializers.DecimalField(max_digits=9, decimal_places=6, required=False, allow_null=True)
    longitude = serializers.DecimalField(max_digits=9, decimal_places=6, required=False, allow_null=True)
    notes = serializers.CharField(required=False, allow_blank=True)


class AttendanceSerializer(serializers.ModelSerializer):
    employee_code = serializers.CharField(source='employee.user.employee_code', read_only=True)
    employee_name = serializers.CharField(source='employee.full_name', read_only=True)
    department_name = serializers.CharField(source='employee.department.name', read_only=True)

    class Meta:
        model = Attendance
        fields = [
            'id',
            'employee',
            'employee_code',
            'employee_name',
            'department_name',
            'attendance_date',
            'server_check_in_time',
            'server_check_out_time',
            'status',
            'check_in_ip',
            'check_out_ip',
            'check_in_latitude',
            'check_in_longitude',
            'check_out_latitude',
            'check_out_longitude',
            'notes',
            'is_corrected',
            'created_at'
        ]
        read_only_fields = ['id', 'employee_code', 'employee_name', 'department_name', 'is_corrected', 'created_at']


class AttendanceCorrectionSerializer(serializers.ModelSerializer):
    employee_code = serializers.CharField(source='employee.user.employee_code', read_only=True)
    employee_name = serializers.CharField(source='employee.full_name', read_only=True)
    attendance_date = serializers.DateField(source='attendance.attendance_date', read_only=True)
    reviewed_by_name = serializers.CharField(source='reviewed_by.employee_code', read_only=True)

    class Meta:
        model = AttendanceCorrection
        fields = [
            'id',
            'attendance',
            'attendance_date',
            'employee',
            'employee_code',
            'employee_name',
            'requested_check_in_time',
            'requested_check_out_time',
            'requested_status',
            'reason',
            'status',
            'reviewed_by',
            'reviewed_by_name',
            'reviewed_at',
            'review_remarks',
            'created_at'
        ]
        read_only_fields = ['id', 'status', 'reviewed_by', 'reviewed_at', 'created_at']


class AttendanceCorrectionCreateSerializer(serializers.Serializer):
    attendance_id = serializers.UUIDField(required=False, allow_null=True)
    attendance_date = serializers.DateField(required=False, allow_null=True)
    requested_check_in_time = serializers.TimeField(required=False, allow_null=True)
    requested_check_out_time = serializers.TimeField(required=False, allow_null=True)
    requested_status = serializers.ChoiceField(choices=Attendance.AttendanceStatus.choices, default=Attendance.AttendanceStatus.PRESENT)
    reason = serializers.CharField(required=True, allow_blank=False)


class AttendanceCorrectionReviewSerializer(serializers.Serializer):
    decision = serializers.ChoiceField(choices=['APPROVED', 'REJECTED'])
    review_remarks = serializers.CharField(required=False, allow_blank=True)
