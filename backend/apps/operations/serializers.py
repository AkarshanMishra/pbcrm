from rest_framework import serializers
from .models import (
    BookingOperation, EventReadinessChecklist, OperationsIssue,
    QualityInspection, OperationalAsset, OperationsRequest,
    OperationsDailyReport
)


class EventReadinessChecklistSerializer(serializers.ModelSerializer):
    verified_by_name = serializers.ReadOnlyField(source='verified_by.get_full_name')

    class Meta:
        model = EventReadinessChecklist
        fields = '__all__'
        read_only_fields = ['score_percentage', 'created_at', 'updated_at']


class BookingOperationSerializer(serializers.ModelSerializer):
    assigned_executive_name = serializers.ReadOnlyField(source='assigned_executive.get_full_name')
    manager_name = serializers.ReadOnlyField(source='manager.get_full_name')
    readiness_checklist = EventReadinessChecklistSerializer(read_only=True)

    class Meta:
        model = BookingOperation
        fields = '__all__'
        read_only_fields = ['booking_code', 'created_at', 'updated_at']


class OperationsIssueSerializer(serializers.ModelSerializer):
    assigned_to_name = serializers.ReadOnlyField(source='assigned_to.get_full_name')
    reported_by_name = serializers.ReadOnlyField(source='reported_by.get_full_name')
    booking_code = serializers.ReadOnlyField(source='booking.booking_code')
    booking_customer_name = serializers.ReadOnlyField(source='booking.customer_name')
    partner_name = serializers.ReadOnlyField(source='booking.partner_name')

    class Meta:
        model = OperationsIssue
        fields = '__all__'
        read_only_fields = ['issue_code', 'reported_by', 'sla_deadline', 'created_at', 'updated_at']


class QualityInspectionSerializer(serializers.ModelSerializer):
    inspector_name = serializers.ReadOnlyField(source='inspector.get_full_name')
    booking_code = serializers.ReadOnlyField(source='booking.booking_code')

    class Meta:
        model = QualityInspection
        fields = '__all__'
        read_only_fields = ['inspection_code', 'inspector', 'auto_generated_issue', 'created_at', 'updated_at']


class OperationalAssetSerializer(serializers.ModelSerializer):
    assigned_to_name = serializers.ReadOnlyField(source='assigned_to.get_full_name')
    current_booking_code = serializers.ReadOnlyField(source='current_booking.booking_code')

    class Meta:
        model = OperationalAsset
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']


class OperationsRequestSerializer(serializers.ModelSerializer):
    requester_name = serializers.ReadOnlyField(source='requester.get_full_name')
    approved_by_name = serializers.ReadOnlyField(source='approved_by.get_full_name')

    class Meta:
        model = OperationsRequest
        fields = '__all__'
        read_only_fields = ['request_code', 'requester', 'approved_by', 'created_at', 'updated_at']


class OperationsDailyReportSerializer(serializers.ModelSerializer):
    executive_name = serializers.ReadOnlyField(source='executive.get_full_name')

    class Meta:
        model = OperationsDailyReport
        fields = '__all__'
        read_only_fields = ['executive', 'created_at', 'updated_at']
