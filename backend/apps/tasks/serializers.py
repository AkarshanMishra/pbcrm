from rest_framework import serializers
from apps.organization.serializers import DepartmentSerializer, PositionSerializer
from apps.employees.models import Employee
from apps.organization.models import Department, Position
from .models import (
    Project,
    Task,
    TaskTimeLog,
    TaskChecklistItem,
    TaskDependency,
    TaskComment,
    TaskAttachment,
    TaskActivityLog,
    TaskTemplate
)

class ProjectSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source='department.name', read_only=True)
    manager_name = serializers.CharField(source='manager.get_full_name', read_only=True)
    task_count = serializers.IntegerField(source='tasks.count', read_only=True)
    completed_task_count = serializers.SerializerMethodField()
    member_names = serializers.SerializerMethodField()

    class Meta:
        model = Project
        fields = [
            'id', 'name', 'code', 'description', 'department', 'department_name',
            'manager', 'manager_name', 'members', 'member_names', 'status',
            'start_date', 'due_date', 'budget_hours', 'progress_percentage',
            'task_count', 'completed_task_count', 'created_at'
        ]
        read_only_fields = ['id', 'progress_percentage', 'created_at']

    def get_completed_task_count(self, obj):
        return obj.tasks.filter(status=Task.Status.COMPLETED).count()

    def get_member_names(self, obj):
        return [m.full_name for m in obj.members.all()]


class TaskTimeLogSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    user_code = serializers.CharField(source='user.employee_code', read_only=True)

    class Meta:
        model = TaskTimeLog
        fields = [
            'id', 'task', 'user', 'user_name', 'user_code',
            'start_time', 'end_time', 'duration_minutes', 'notes', 'is_running', 'created_at'
        ]
        read_only_fields = ['id', 'user', 'user_name', 'user_code', 'created_at']


class TaskChecklistItemSerializer(serializers.ModelSerializer):
    completed_by_name = serializers.CharField(source='completed_by.employee_code', read_only=True)

    class Meta:
        model = TaskChecklistItem
        fields = [
            'id',
            'task',
            'item_text',
            'is_completed',
            'completed_by',
            'completed_by_name',
            'completed_at',
            'order'
        ]
        read_only_fields = ['id', 'completed_by', 'completed_at']


class TaskCommentSerializer(serializers.ModelSerializer):
    author_code = serializers.CharField(source='author.employee_code', read_only=True)
    author_name = serializers.CharField(source='author.get_full_name', read_only=True)

    class Meta:
        model = TaskComment
        fields = [
            'id',
            'task',
            'author',
            'author_code',
            'author_name',
            'comment_text',
            'mentions',
            'created_at'
        ]
        read_only_fields = ['id', 'author', 'author_code', 'author_name', 'created_at']


class TaskAttachmentSerializer(serializers.ModelSerializer):
    uploaded_by_code = serializers.CharField(source='uploaded_by.employee_code', read_only=True)

    class Meta:
        model = TaskAttachment
        fields = [
            'id',
            'task',
            'uploaded_by',
            'uploaded_by_code',
            'file',
            'filename',
            'file_size',
            'mime_type',
            'version',
            'created_at'
        ]
        read_only_fields = ['id', 'uploaded_by', 'uploaded_by_code', 'filename', 'file_size', 'mime_type', 'created_at']


class TaskActivityLogSerializer(serializers.ModelSerializer):
    actor_code = serializers.CharField(source='actor.employee_code', read_only=True)

    class Meta:
        model = TaskActivityLog
        fields = [
            'id',
            'task',
            'actor',
            'actor_code',
            'action',
            'description',
            'created_at'
        ]
        read_only_fields = fields


class TaskListSerializer(serializers.ModelSerializer):
    assigned_to_code = serializers.CharField(source='assigned_to.user.employee_code', read_only=True)
    assigned_to_name = serializers.CharField(source='assigned_to.full_name', read_only=True)
    assigned_by_code = serializers.CharField(source='assigned_by.employee_code', read_only=True)
    department_name = serializers.CharField(source='department.name', read_only=True)
    position_title = serializers.CharField(source='position.title', read_only=True)
    project_name = serializers.CharField(source='project.name', read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    checklist_total = serializers.SerializerMethodField()
    checklist_completed = serializers.SerializerMethodField()
    subtask_total = serializers.SerializerMethodField()
    subtask_completed = serializers.SerializerMethodField()

    class Meta:
        model = Task
        fields = [
            'id',
            'title',
            'description',
            'project',
            'project_name',
            'parent_task',
            'department',
            'department_name',
            'position',
            'position_title',
            'assigned_to',
            'assigned_to_code',
            'assigned_to_name',
            'assigned_by_code',
            'priority',
            'status',
            'start_date',
            'due_date',
            'due_time',
            'estimated_hours',
            'actual_hours',
            'is_timer_running',
            'progress_percentage',
            'tags',
            'department_data',
            'is_overdue',
            'checklist_total',
            'checklist_completed',
            'subtask_total',
            'subtask_completed',
            'is_recurring',
            'created_at'
        ]

    def get_checklist_total(self, obj):
        return obj.checklist_items.count()

    def get_checklist_completed(self, obj):
        return obj.checklist_items.filter(is_completed=True).count()

    def get_subtask_total(self, obj):
        return obj.subtasks.count()

    def get_subtask_completed(self, obj):
        return obj.subtasks.filter(status=Task.Status.COMPLETED).count()


class TaskDetailSerializer(serializers.ModelSerializer):
    assigned_to_code = serializers.CharField(source='assigned_to.user.employee_code', read_only=True)
    assigned_to_name = serializers.CharField(source='assigned_to.full_name', read_only=True)
    assigned_by_code = serializers.CharField(source='assigned_by.employee_code', read_only=True)
    assigned_by_name = serializers.CharField(source='assigned_by.get_full_name', read_only=True)
    reviewed_by_code = serializers.CharField(source='reviewed_by.employee_code', read_only=True)
    department_name = serializers.CharField(source='department.name', read_only=True)
    position_title = serializers.CharField(source='position.title', read_only=True)
    project_name = serializers.CharField(source='project.name', read_only=True)
    checklist_items = TaskChecklistItemSerializer(many=True, read_only=True)
    comments = TaskCommentSerializer(many=True, read_only=True)
    attachments = TaskAttachmentSerializer(many=True, read_only=True)
    activity_logs = TaskActivityLogSerializer(many=True, read_only=True)
    time_logs = TaskTimeLogSerializer(many=True, read_only=True)
    subtasks = TaskListSerializer(many=True, read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)

    class Meta:
        model = Task
        fields = [
            'id',
            'title',
            'description',
            'project',
            'project_name',
            'parent_task',
            'department',
            'department_name',
            'position',
            'position_title',
            'assigned_to',
            'assigned_to_code',
            'assigned_to_name',
            'assigned_by',
            'assigned_by_code',
            'assigned_by_name',
            'priority',
            'status',
            'start_date',
            'due_date',
            'due_time',
            'estimated_hours',
            'actual_hours',
            'is_timer_running',
            'progress_percentage',
            'tags',
            'department_data',
            'blocked_reason',
            'blocked_expected_resolution',
            'blocked_comment',
            'completed_at',
            'reviewed_by',
            'reviewed_by_code',
            'reviewed_at',
            'manager_remarks',
            'is_recurring',
            'recurring_pattern',
            'is_overdue',
            'checklist_items',
            'subtasks',
            'comments',
            'attachments',
            'activity_logs',
            'time_logs',
            'created_at',
            'updated_at'
        ]


class TaskCreateSerializer(serializers.ModelSerializer):
    checklist = serializers.ListField(child=serializers.CharField(max_length=255), required=False, write_only=True)

    class Meta:
        model = Task
        fields = [
            'id',
            'title',
            'description',
            'project',
            'parent_task',
            'department',
            'position',
            'assigned_to',
            'priority',
            'status',
            'progress_percentage',
            'start_date',
            'due_date',
            'due_time',
            'estimated_hours',
            'tags',
            'department_data',
            'is_recurring',
            'recurring_pattern',
            'checklist'
        ]
        read_only_fields = ['id', 'status', 'progress_percentage']

    def create(self, validated_data):
        checklist = validated_data.pop('checklist', [])
        task = Task.objects.create(**validated_data)
        for idx, item_text in enumerate(checklist):
            TaskChecklistItem.objects.create(task=task, item_text=item_text, order=idx)
        
        if task.parent_task:
            task.parent_task.recalculate_subtask_progress()
        if task.project:
            task.project.recalculate_progress()
        return task


class TaskBlockSerializer(serializers.Serializer):
    reason = serializers.CharField(max_length=255)
    expected_resolution = serializers.DateField(required=False, allow_null=True)
    comment = serializers.CharField(required=False, allow_blank=True)


class TaskProgressSerializer(serializers.Serializer):
    progress_percentage = serializers.IntegerField(min_value=0, max_value=100)
    comment = serializers.CharField(required=False, allow_blank=True)


class TaskReviewSerializer(serializers.Serializer):
    decision = serializers.ChoiceField(choices=['APPROVE', 'REQUEST_CHANGES', 'REJECT'])
    remarks = serializers.CharField(required=False, allow_blank=True)


class TaskReassignSerializer(serializers.Serializer):
    new_assignee_id = serializers.UUIDField()
    reason = serializers.CharField(max_length=255)


class TaskHandoverSerializer(serializers.Serializer):
    from_employee_id = serializers.UUIDField()
    to_employee_id = serializers.UUIDField()
    task_ids = serializers.ListField(child=serializers.UUIDField(), required=False)
    handover_notes = serializers.CharField()


class TaskBulkUpdateSerializer(serializers.Serializer):
    task_ids = serializers.ListField(child=serializers.UUIDField())
    status = serializers.ChoiceField(choices=Task.Status.choices, required=False)
    priority = serializers.ChoiceField(choices=Task.Priority.choices, required=False)
    assigned_to_id = serializers.UUIDField(required=False)


class TaskTemplateSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source='department.name', read_only=True)

    class Meta:
        model = TaskTemplate
        fields = [
            'id',
            'name',
            'department',
            'department_name',
            'default_priority',
            'description',
            'estimated_hours',
            'checklist_template',
            'department_fields_template',
            'is_active',
            'created_at'
        ]
