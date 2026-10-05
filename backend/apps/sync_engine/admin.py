from django.contrib import admin
from .models import DeviceRegistration, SyncQueueRecord, SyncConflict

@admin.register(DeviceRegistration)
class DeviceRegistrationAdmin(admin.ModelAdmin):
    list_display = ('device_id', 'device_name', 'employee', 'is_online', 'is_revoked', 'last_synced_at', 'pending_sync_count')
    list_filter = ('is_online', 'is_revoked')
    search_fields = ('device_id', 'device_name', 'employee__user__username')


@admin.register(SyncQueueRecord)
class SyncQueueRecordAdmin(admin.ModelAdmin):
    list_display = ('client_id', 'action_type', 'employee', 'status', 'client_timestamp', 'server_timestamp')
    list_filter = ('action_type', 'status')
    search_fields = ('client_id', 'employee__user__username')


@admin.register(SyncConflict)
class SyncConflictAdmin(admin.ModelAdmin):
    list_display = ('entity_type', 'entity_id', 'status', 'resolved_by', 'resolved_at')
    list_filter = ('status', 'entity_type')
    search_fields = ('entity_id', 'entity_type')
