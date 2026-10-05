from rest_framework import serializers
from .models import DeviceRegistration, SyncQueueRecord, SyncConflict

class DeviceRegistrationSerializer(serializers.ModelSerializer):
    employee_name = serializers.CharField(source='employee.full_name', read_only=True)
    employee_code = serializers.CharField(source='employee.employee_code', read_only=True)
    department_name = serializers.CharField(source='employee.department_name', read_only=True)

    class Meta:
        model = DeviceRegistration
        fields = [
            'id', 'device_id', 'employee', 'employee_name', 'employee_code',
            'department_name', 'device_name', 'device_model', 'os_version',
            'app_version', 'is_online', 'is_revoked', 'last_synced_at',
            'last_heartbeat_at', 'pending_sync_count', 'successful_sync_count',
            'failed_sync_count', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'last_synced_at', 'last_heartbeat_at']


class SyncQueueRecordSerializer(serializers.ModelSerializer):
    employee_name = serializers.CharField(source='employee.full_name', read_only=True)

    class Meta:
        model = SyncQueueRecord
        fields = [
            'id', 'client_id', 'device', 'employee', 'employee_name',
            'action_type', 'client_timestamp', 'server_timestamp',
            'payload', 'status', 'server_version', 'server_entity_id',
            'conflict_details', 'error_message', 'created_at'
        ]
        read_only_fields = ['id', 'server_timestamp', 'created_at']


class SyncConflictSerializer(serializers.ModelSerializer):
    resolver_name = serializers.CharField(source='resolved_by.username', read_only=True)

    class Meta:
        model = SyncConflict
        fields = [
            'id', 'sync_record', 'entity_type', 'entity_id',
            'server_data', 'client_data', 'status', 'resolution_notes',
            'resolved_by', 'resolver_name', 'resolved_at', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class BatchSyncItemSerializer(serializers.Serializer):
    client_id = serializers.CharField(max_length=100)
    action_type = serializers.CharField(max_length=50)
    client_timestamp = serializers.DateTimeField()
    payload = serializers.DictField(default=dict)
    client_version = serializers.IntegerField(default=1, required=False)


class BatchSyncRequestSerializer(serializers.Serializer):
    device_id = serializers.CharField(max_length=100)
    device_name = serializers.CharField(max_length=150, required=False, allow_blank=True)
    device_model = serializers.CharField(max_length=100, required=False, allow_blank=True)
    os_version = serializers.CharField(max_length=50, required=False, allow_blank=True)
    app_version = serializers.CharField(max_length=50, default='1.0.0', required=False)
    items = serializers.ListField(child=BatchSyncItemSerializer(), allow_empty=True)
