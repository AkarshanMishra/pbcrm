import pytest
from django.contrib.auth import get_user_model
from apps.organization.models import Department, Position
from apps.employees.models import Employee
from apps.core.models import MasterWorkflowProcess, MasterWorkflowStep, CentralEventRecord
from apps.core.workflow_engine import WorkflowEngine

User = get_user_model()

@pytest.mark.django_db
class TestMasterWorkflowEngine:

    def setup_method(self):
        from apps.organization.models import Role
        self.dept = Department.objects.create(name="Information Technology", code="IT")
        self.pos = Position.objects.create(department=self.dept, title="Software Engineer", code="SWE")
        self.role = Role.objects.create(code="IT_DEV", name="Software Developer")
        self.user = User.objects.create_user(
            employee_code="PBE999991",
            email="lead@pcrm.internal",
            password="TestPassword123!"
        )
        self.employee = Employee.objects.create(
            user=self.user,
            first_name="Arjun",
            last_name="Kapoor",
            department=self.dept,
            position=self.pos,
            role=self.role
        )

    def test_employee_onboarding_pipeline_creation(self):
        process = WorkflowEngine.start_employee_onboarding(self.employee, actor=self.user)
        assert process is not None
        assert process.workflow_type == MasterWorkflowProcess.WorkflowType.EMPLOYEE_ONBOARDING
        assert process.entity_id == "PBE999991"
        assert process.steps.count() == 4
        
        # Verify initial step is completed and step 2 is in progress
        step1 = process.steps.get(step_order=1)
        step2 = process.steps.get(step_order=2)
        assert step1.status == MasterWorkflowStep.Status.COMPLETED
        assert step2.status == MasterWorkflowStep.Status.IN_PROGRESS
        assert step2.department == "Information Technology"

    def test_partner_pipeline_creation(self):
        process = WorkflowEngine.start_partner_onboarding(
            partner_code="PBV9999999",
            partner_name="Emerald Luxury Resort",
            partner_type="RESORT_BANQUET",
            actor=self.user
        )
        assert process.workflow_type == MasterWorkflowProcess.WorkflowType.PARTNER_ONBOARDING
        assert process.entity_id == "PBV9999999"
        assert process.steps.count() == 4
        assert process.steps.get(step_order=2).responsible_role == "Super Admin"

    def test_booking_pipeline_creation(self):
        process = WorkflowEngine.start_booking_operations(
            booking_code="BK-999-TEST",
            customer_name="Vikram Malhotra",
            event_date="2026-12-25",
            venue_name="Emerald Luxury Resort",
            actor=self.user
        )
        assert process.workflow_type == MasterWorkflowProcess.WorkflowType.BOOKING_OPERATIONS
        assert process.steps.count() == 4

    def test_it_incident_pipeline_creation(self):
        process = WorkflowEngine.start_it_incident_pipeline(
            issue_code="INC-999-TEST",
            issue_title="Mobile App Geofence Timeout",
            reporter_department="Marketing",
            priority="URGENT",
            actor=self.user
        )
        assert process.workflow_type == MasterWorkflowProcess.WorkflowType.IT_INCIDENT
        assert process.steps.count() == 3

    def test_workflow_step_advancement_and_handoff(self):
        process = WorkflowEngine.start_partner_onboarding(
            partner_code="PBV8888888",
            partner_name="Silver Oak Garden",
            partner_type="BANQUET",
            actor=self.user
        )
        step2 = process.steps.get(step_order=2)
        assert step2.status == MasterWorkflowStep.Status.PENDING_APPROVAL

        # Super Admin approves step 2
        updated_process = WorkflowEngine.advance_step(
            step_id=step2.id,
            action="APPROVE",
            actor=self.user,
            comments="Approved revenue share agreement at 12%."
        )
        step2.refresh_from_db()
        step3 = updated_process.steps.get(step_order=3)
        assert step2.status == MasterWorkflowStep.Status.APPROVED
        assert step3.status == MasterWorkflowStep.Status.IN_PROGRESS
        assert updated_process.current_department == "Operations"

    def test_360_degree_relationship_graph(self):
        WorkflowEngine.start_employee_onboarding(self.employee, actor=self.user)
        graph = WorkflowEngine.get_360_graph('employee', 'PBE999991')
        assert graph['entity_id'] == 'PBE999991'
        assert graph['total_nodes'] >= 5
        assert graph['total_edges'] >= 4
