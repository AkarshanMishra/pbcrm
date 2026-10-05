from rest_framework import serializers
from apps.employees.models import Employee
from .models import (
    JobOpening,
    CandidateApplication,
    OnboardingChecklist,
    EmployeeDocument,
    HRPolicy,
    PolicyAcknowledgement,
    PerformanceReview,
    TrainingProgram,
    TrainingEnrollment,
    HRRequest,
    OffboardingRecord,
    HRAnnouncement,
    HRDailyReport,
)


class JobOpeningSerializer(serializers.ModelSerializer):
    department_name = serializers.ReadOnlyField(source='department.name')
    position_title = serializers.ReadOnlyField(source='position.title')
    applications_count = serializers.IntegerField(source='applications.count', read_only=True)

    class Meta:
        model = JobOpening
        fields = '__all__'


class CandidateApplicationSerializer(serializers.ModelSerializer):
    job_title = serializers.ReadOnlyField(source='job.title')
    interviewer_name = serializers.ReadOnlyField(source='interviewer.get_full_name')

    class Meta:
        model = CandidateApplication
        fields = '__all__'


class OnboardingChecklistSerializer(serializers.ModelSerializer):
    employee_code = serializers.ReadOnlyField(source='employee.user.employee_code')
    employee_name = serializers.ReadOnlyField(source='employee.user.get_full_name')
    department_name = serializers.ReadOnlyField(source='employee.department.name')
    position_title = serializers.ReadOnlyField(source='employee.position.title')

    class Meta:
        model = OnboardingChecklist
        fields = '__all__'


class EmployeeDocumentSerializer(serializers.ModelSerializer):
    employee_code = serializers.ReadOnlyField(source='employee.user.employee_code')
    employee_name = serializers.ReadOnlyField(source='employee.user.get_full_name')
    verified_by_name = serializers.ReadOnlyField(source='verified_by.get_full_name')

    class Meta:
        model = EmployeeDocument
        fields = '__all__'


class PolicyAcknowledgementSerializer(serializers.ModelSerializer):
    employee_code = serializers.ReadOnlyField(source='employee.user.employee_code')
    employee_name = serializers.ReadOnlyField(source='employee.user.get_full_name')

    class Meta:
        model = PolicyAcknowledgement
        fields = '__all__'


class HRPolicySerializer(serializers.ModelSerializer):
    published_by_name = serializers.ReadOnlyField(source='published_by.get_full_name')
    acknowledgements_count = serializers.IntegerField(source='acknowledgements.count', read_only=True)

    class Meta:
        model = HRPolicy
        fields = '__all__'


class PerformanceReviewSerializer(serializers.ModelSerializer):
    employee_code = serializers.ReadOnlyField(source='employee.user.employee_code')
    employee_name = serializers.ReadOnlyField(source='employee.user.get_full_name')
    department_name = serializers.ReadOnlyField(source='employee.department.name')
    position_title = serializers.ReadOnlyField(source='employee.position.title')
    reviewer_name = serializers.ReadOnlyField(source='reviewer.get_full_name')

    class Meta:
        model = PerformanceReview
        fields = '__all__'


class TrainingProgramSerializer(serializers.ModelSerializer):
    enrolled_count = serializers.IntegerField(source='enrollments.count', read_only=True)

    class Meta:
        model = TrainingProgram
        fields = '__all__'


class TrainingEnrollmentSerializer(serializers.ModelSerializer):
    program_title = serializers.ReadOnlyField(source='program.title')
    program_code = serializers.ReadOnlyField(source='program.code')
    is_mandatory = serializers.ReadOnlyField(source='program.is_mandatory')
    deadline = serializers.ReadOnlyField(source='program.deadline')
    employee_code = serializers.ReadOnlyField(source='employee.user.employee_code')
    employee_name = serializers.ReadOnlyField(source='employee.user.get_full_name')

    class Meta:
        model = TrainingEnrollment
        fields = '__all__'


class HRRequestSerializer(serializers.ModelSerializer):
    requester_name = serializers.ReadOnlyField(source='requester.get_full_name')
    requester_code = serializers.ReadOnlyField(source='requester.employee_code')
    reviewed_by_name = serializers.ReadOnlyField(source='reviewed_by.get_full_name')

    class Meta:
        model = HRRequest
        fields = '__all__'
        read_only_fields = ['requester', 'request_code', 'reviewed_by']


class OffboardingRecordSerializer(serializers.ModelSerializer):
    employee_code = serializers.ReadOnlyField(source='employee.user.employee_code')
    employee_name = serializers.ReadOnlyField(source='employee.user.get_full_name')
    department_name = serializers.ReadOnlyField(source='employee.department.name')
    position_title = serializers.ReadOnlyField(source='employee.position.title')

    class Meta:
        model = OffboardingRecord
        fields = '__all__'


class HRAnnouncementSerializer(serializers.ModelSerializer):
    published_by_name = serializers.ReadOnlyField(source='published_by.get_full_name')

    class Meta:
        model = HRAnnouncement
        fields = '__all__'
        read_only_fields = ['published_by']


class HRDailyReportSerializer(serializers.ModelSerializer):
    executive_name = serializers.ReadOnlyField(source='executive.get_full_name')
    executive_code = serializers.ReadOnlyField(source='executive.employee_code')

    class Meta:
        model = HRDailyReport
        fields = '__all__'
        read_only_fields = ['executive']

