from rest_framework import serializers
from .models import DailyWorkPlan, DailyWorkReport, DailyStandup, WorkDiaryEntry, Announcement

class DailyWorkPlanSerializer(serializers.ModelSerializer):
    employee_code = serializers.CharField(source='employee.user.employee_code', read_only=True)
    employee_name = serializers.CharField(source='employee.full_name', read_only=True)

    class Meta:
        model = DailyWorkPlan
        fields = [
            'id',
            'employee',
            'employee_code',
            'employee_name',
            'plan_date',
            'planned_items',
            'is_started',
            'started_at',
            'notes',
            'created_at'
        ]
        read_only_fields = ['id', 'employee', 'employee_code', 'employee_name', 'created_at']


class DailyWorkReportSerializer(serializers.ModelSerializer):
    employee_code = serializers.CharField(source='employee.user.employee_code', read_only=True)
    employee_name = serializers.CharField(source='employee.full_name', read_only=True)
    department_name = serializers.CharField(source='employee.department.name', read_only=True)
    reviewed_by_code = serializers.CharField(source='reviewed_by.employee_code', read_only=True)

    class Meta:
        model = DailyWorkReport
        fields = [
            'id',
            'employee',
            'employee_code',
            'employee_name',
            'department_name',
            'report_date',
            'summary_text',
            'completed_summary',
            'pending_summary',
            'blocked_summary',
            'tomorrow_plan',
            'status',
            'submitted_at',
            'reviewed_by',
            'reviewed_by_code',
            'reviewed_at',
            'manager_remarks',
            'created_at',
            'updated_at'
        ]
        read_only_fields = ['id', 'employee', 'employee_code', 'employee_name', 'department_name', 'reviewed_by', 'reviewed_by_code', 'reviewed_at', 'created_at', 'updated_at']


class ReportReviewSerializer(serializers.Serializer):
    decision = serializers.ChoiceField(choices=['APPROVE', 'REQUEST_CHANGES'])
    remarks = serializers.CharField(required=False, allow_blank=True)


class DailyStandupSerializer(serializers.ModelSerializer):
    employee_code = serializers.CharField(source='employee.user.employee_code', read_only=True)
    employee_name = serializers.CharField(source='employee.full_name', read_only=True)
    department_name = serializers.CharField(source='employee.department.name', read_only=True)
    reviewed_by_name = serializers.CharField(source='reviewed_by.get_full_name', read_only=True)

    class Meta:
        model = DailyStandup
        fields = [
            'id', 'employee', 'employee_code', 'employee_name', 'department_name',
            'standup_date', 'yesterday_completed', 'today_planned', 'blockers_encountered',
            'submitted_at', 'reviewed_by', 'reviewed_by_name', 'manager_feedback', 'created_at'
        ]
        read_only_fields = ['id', 'employee', 'employee_code', 'employee_name', 'department_name', 'submitted_at', 'reviewed_by', 'created_at']


class WorkDiaryEntrySerializer(serializers.ModelSerializer):
    employee_code = serializers.CharField(source='employee.user.employee_code', read_only=True)
    task_title = serializers.CharField(source='task.title', read_only=True)

    class Meta:
        model = WorkDiaryEntry
        fields = [
            'id', 'employee', 'employee_code', 'task', 'task_title',
            'logged_at', 'activity_text', 'duration_minutes', 'category', 'created_at'
        ]
        read_only_fields = ['id', 'employee', 'employee_code', 'created_at']


class AnnouncementSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source='author.get_full_name', read_only=True)
    author_code = serializers.CharField(source='author.employee_code', read_only=True)
    department_name = serializers.CharField(source='target_department.name', read_only=True)

    class Meta:
        model = Announcement
        fields = [
            'id', 'title', 'content', 'author', 'author_name', 'author_code',
            'target_type', 'target_department', 'department_name',
            'priority', 'is_pinned', 'valid_until', 'created_at'
        ]
        read_only_fields = ['id', 'author', 'author_name', 'author_code', 'created_at']
