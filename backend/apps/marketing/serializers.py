from rest_framework import serializers
from .models import Lead, Visit, FollowUp, PartnerOnboarding, MarketingTarget, MarketingDailyReport


class LeadSerializer(serializers.ModelSerializer):
    assigned_to_name = serializers.ReadOnlyField(source='assigned_to.get_full_name')
    created_by_name = serializers.ReadOnlyField(source='created_by.get_full_name')

    class Meta:
        model = Lead
        fields = '__all__'
        read_only_fields = ['id', 'lead_code', 'created_at', 'updated_at', 'created_by']


class VisitSerializer(serializers.ModelSerializer):
    assigned_employee = serializers.PrimaryKeyRelatedField(read_only=True)
    assigned_employee_name = serializers.ReadOnlyField(source='assigned_employee.get_full_name')
    lead_name = serializers.ReadOnlyField(source='lead.business_name')
    lead_phone = serializers.ReadOnlyField(source='lead.phone')

    class Meta:
        model = Visit
        fields = '__all__'
        read_only_fields = ['id', 'visit_code', 'assigned_employee', 'created_at', 'updated_at']


class FollowUpSerializer(serializers.ModelSerializer):
    employee = serializers.PrimaryKeyRelatedField(read_only=True)
    employee_name = serializers.ReadOnlyField(source='employee.get_full_name')
    lead_name = serializers.ReadOnlyField(source='lead.business_name')
    lead_phone = serializers.ReadOnlyField(source='lead.phone')
    lead_type = serializers.ReadOnlyField(source='lead.lead_type')

    class Meta:
        model = FollowUp
        fields = '__all__'
        read_only_fields = ['id', 'employee', 'created_at']


class PartnerOnboardingSerializer(serializers.ModelSerializer):
    assigned_executive = serializers.PrimaryKeyRelatedField(read_only=True)
    assigned_executive_name = serializers.ReadOnlyField(source='assigned_executive.get_full_name')
    manager_approved_by_name = serializers.ReadOnlyField(source='manager_approved_by.get_full_name')
    admin_approved_by_name = serializers.ReadOnlyField(source='admin_approved_by.get_full_name')

    class Meta:
        model = PartnerOnboarding
        fields = '__all__'
        read_only_fields = ['id', 'onboarding_code', 'assigned_executive', 'created_at', 'updated_at']


class MarketingTargetSerializer(serializers.ModelSerializer):
    employee_name = serializers.ReadOnlyField(source='employee.get_full_name')

    class Meta:
        model = MarketingTarget
        fields = '__all__'
        read_only_fields = ['id', 'created_at', 'updated_at']


class MarketingDailyReportSerializer(serializers.ModelSerializer):
    employee_name = serializers.ReadOnlyField(source='employee.get_full_name')
    reviewed_by_name = serializers.ReadOnlyField(source='reviewed_by.get_full_name')

    class Meta:
        model = MarketingDailyReport
        fields = '__all__'
        read_only_fields = ['id', 'submitted_at']
