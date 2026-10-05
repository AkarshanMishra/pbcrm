from rest_framework import serializers
from .models import (
    SystemComponent, ITIncident, ITIncidentComment,
    PullRequest, DeploymentRecord, ITAsset, ITAccessRequest,
    KnowledgeArticle, ITDailyReport
)
from apps.employees.serializers import EmployeeListSerializer


class SystemComponentSerializer(serializers.ModelSerializer):
    class Meta:
        model = SystemComponent
        fields = '__all__'


class ITIncidentCommentSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source='author.get_full_name', read_only=True)
    author_code = serializers.CharField(source='author.employee_code', read_only=True)

    class Meta:
        model = ITIncidentComment
        fields = ['id', 'incident', 'author', 'author_name', 'author_code', 'comment_text', 'is_internal_log', 'created_at']
        read_only_fields = ['author', 'created_at']


class ITIncidentSerializer(serializers.ModelSerializer):
    reporter_detail = EmployeeListSerializer(source='reporter', read_only=True)
    assignee_detail = EmployeeListSerializer(source='assignee', read_only=True)
    system_detail = SystemComponentSerializer(source='affected_system', read_only=True)
    comments = ITIncidentCommentSerializer(many=True, read_only=True)

    class Meta:
        model = ITIncident
        fields = '__all__'
        read_only_fields = ['incident_number', 'created_at', 'updated_at']


class PullRequestSerializer(serializers.ModelSerializer):
    author_detail = EmployeeListSerializer(source='author', read_only=True)
    reviewer_detail = EmployeeListSerializer(source='reviewer', read_only=True)

    class Meta:
        model = PullRequest
        fields = '__all__'


class DeploymentRecordSerializer(serializers.ModelSerializer):
    triggered_by_detail = EmployeeListSerializer(source='triggered_by', read_only=True)
    approved_by_detail = EmployeeListSerializer(source='approved_by', read_only=True)

    class Meta:
        model = DeploymentRecord
        fields = '__all__'
        read_only_fields = ['triggered_by', 'deployed_at', 'created_at', 'updated_at']


class ITAssetSerializer(serializers.ModelSerializer):
    assigned_to_detail = EmployeeListSerializer(source='assigned_to', read_only=True)

    class Meta:
        model = ITAsset
        fields = '__all__'


class ITAccessRequestSerializer(serializers.ModelSerializer):
    requester_detail = EmployeeListSerializer(source='requester', read_only=True)
    assigned_engineer_detail = EmployeeListSerializer(source='assigned_engineer', read_only=True)
    approved_by_detail = EmployeeListSerializer(source='approved_by', read_only=True)

    class Meta:
        model = ITAccessRequest
        fields = '__all__'


class KnowledgeArticleSerializer(serializers.ModelSerializer):
    author_detail = EmployeeListSerializer(source='author', read_only=True)

    class Meta:
        model = KnowledgeArticle
        fields = '__all__'


class ITDailyReportSerializer(serializers.ModelSerializer):
    developer_detail = EmployeeListSerializer(source='developer', read_only=True)

    class Meta:
        model = ITDailyReport
        fields = '__all__'
        read_only_fields = ['developer', 'created_at', 'updated_at']
