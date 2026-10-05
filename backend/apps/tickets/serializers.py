from rest_framework import serializers
from .models import SupportTicket, TicketComment

class TicketCommentSerializer(serializers.ModelSerializer):
    author_name = serializers.SerializerMethodField()
    author_code = serializers.CharField(source='author.employee_code', read_only=True)

    class Meta:
        model = TicketComment
        fields = ['id', 'ticket', 'author', 'author_name', 'author_code', 'comment_text', 'created_at']
        read_only_fields = ['author', 'ticket', 'created_at']

    def get_author_name(self, obj):
        return obj.author.get_full_name() or obj.author.employee_code


class SupportTicketSerializer(serializers.ModelSerializer):
    requester_name = serializers.CharField(source='requester.full_name', read_only=True)
    requester_code = serializers.CharField(source='requester.employee_code', read_only=True)
    department_name = serializers.CharField(source='target_department.name', read_only=True)
    technician_name = serializers.SerializerMethodField()
    comments = TicketCommentSerializer(many=True, read_only=True)

    class Meta:
        model = SupportTicket
        fields = [
            'id', 'ticket_number', 'category', 'title', 'description', 'priority', 'status',
            'requester', 'requester_name', 'requester_code',
            'target_department', 'department_name',
            'assigned_technician', 'technician_name',
            'resolution_notes', 'resolved_at', 'closed_at',
            'comments', 'created_at', 'updated_at'
        ]
        read_only_fields = ['ticket_number', 'requester', 'resolved_at', 'closed_at', 'created_at', 'updated_at']

    def get_technician_name(self, obj):
        if obj.assigned_technician:
            return obj.assigned_technician.get_full_name() or obj.assigned_technician.employee_code
        return None
