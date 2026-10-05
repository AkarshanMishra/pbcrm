from rest_framework import serializers
from .models import Notification

class NotificationSerializer(serializers.ModelSerializer):
    recipient_code = serializers.CharField(source='recipient.employee_code', read_only=True)

    class Meta:
        model = Notification
        fields = [
            'id',
            'recipient',
            'recipient_code',
            'title',
            'message',
            'notification_type',
            'priority',
            'link_type',
            'link_id',
            'is_read',
            'read_at',
            'created_at'
        ]
        read_only_fields = fields
