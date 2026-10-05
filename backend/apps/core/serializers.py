from rest_framework import serializers
from apps.core.models import MasterWorkflowProcess, MasterWorkflowStep, CentralEventRecord

class MasterWorkflowStepSerializer(serializers.ModelSerializer):
    completed_by_name = serializers.CharField(source='completed_by.get_full_name', read_only=True)

    class Meta:
        model = MasterWorkflowStep
        fields = [
            'id', 'step_order', 'title', 'description',
            'department', 'responsible_role', 'action_type',
            'assignee', 'status', 'sla_hours', 'due_date',
            'linked_task_id', 'completed_at', 'completed_by',
            'completed_by_name', 'comments'
        ]


class MasterWorkflowProcessSerializer(serializers.ModelSerializer):
    steps = MasterWorkflowStepSerializer(many=True, read_only=True)
    initiator_name = serializers.CharField(source='initiator.get_full_name', read_only=True)

    class Meta:
        model = MasterWorkflowProcess
        fields = [
            'id', 'process_code', 'title', 'workflow_type',
            'entity_type', 'entity_id', 'status', 'current_stage_name',
            'current_department', 'current_role', 'initiator',
            'initiator_name', 'current_assignee', 'sla_hours',
            'sla_deadline', 'is_escalated', 'progress_percentage',
            'metadata', 'steps', 'created_at', 'updated_at'
        ]


class CentralEventRecordSerializer(serializers.ModelSerializer):
    actor_name = serializers.CharField(source='actor.get_full_name', read_only=True)

    class Meta:
        model = CentralEventRecord
        fields = [
            'id', 'event_type', 'entity_type', 'entity_id',
            'actor', 'actor_name', 'payload', 'processed', 'created_at'
        ]
