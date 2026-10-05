from rest_framework import serializers
from .models import AuditLog

class AuditLogSerializer(serializers.ModelSerializer):
    actor_employee_code = serializers.CharField(source='actor.employee_code', read_only=True)
    actor_email = serializers.CharField(source='actor.email', read_only=True)

    class Meta:
        model = AuditLog
        fields = [
            'id',
            'actor',
            'actor_employee_code',
            'actor_email',
            'event_type',
            'target_model',
            'target_id',
            'ip_address',
            'user_agent',
            'metadata',
            'created_at'
        ]
        read_only_fields = fields
