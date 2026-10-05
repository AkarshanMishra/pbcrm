from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils import timezone
from apps.core.models import MasterWorkflowProcess, MasterWorkflowStep, CentralEventRecord
from apps.core.workflow_engine import WorkflowEngine
from apps.employees.models import Employee

User = get_user_model()

class Command(BaseCommand):
    help = "Seed cross-department master workflows across HR, IT, Marketing, Operations, and Accounts."

    def handle(self, *args, **kwargs):
        self.stdout.write("Seeding Master Workflow Processes and Event Trails...")
        admin_user = User.objects.filter(is_superuser=True).first() or User.objects.first()

        MasterWorkflowStep.objects.all().delete()
        MasterWorkflowProcess.objects.all().delete()
        CentralEventRecord.objects.all().delete()

        # 1. Employee Onboarding Workflow (PBE000003 - Rahul Verma)
        wf1 = MasterWorkflowProcess.objects.create(
            process_code="WF-ONB-00124",
            title="Employee Onboarding — Rahul Verma (PBE000003)",
            workflow_type=MasterWorkflowProcess.WorkflowType.EMPLOYEE_ONBOARDING,
            entity_type='employee',
            entity_id='PBE000003',
            status=MasterWorkflowProcess.Status.IN_PROGRESS,
            current_stage_name="IT Provisioning & Asset Allocation",
            current_department="Information Technology",
            current_role="IT Manager",
            initiator=admin_user,
            sla_hours=48,
            sla_deadline=timezone.now() + timezone.timedelta(hours=36),
            progress_percentage=25,
            metadata={"employee_code": "PBE000003", "name": "Rahul Verma", "department": "Marketing", "position": "Marketing Executive"}
        )
        MasterWorkflowStep.objects.create(
            process=wf1, step_order=1, title="HR Record & KYC Verification",
            description="Verified government Aadhaar ID, education certificates, and contract.",
            department="Human Resources", responsible_role="HR Manager",
            action_type=MasterWorkflowStep.ActionType.DOCUMENT_VERIFICATION,
            status=MasterWorkflowStep.Status.COMPLETED, completed_at=timezone.now(), completed_by=admin_user
        )
        MasterWorkflowStep.objects.create(
            process=wf1, step_order=2, title="IT Provisioning & Hardware Setup",
            description="Provision email rahul.verma@pcrm.internal, issue corporate SIM, and allocate laptop.",
            department="Information Technology", responsible_role="IT Manager",
            action_type=MasterWorkflowStep.ActionType.SYSTEM_PROVISIONING,
            status=MasterWorkflowStep.Status.IN_PROGRESS, sla_hours=12
        )
        MasterWorkflowStep.objects.create(
            process=wf1, step_order=3, title="Marketing Manager Team Handover",
            description="Assign field sales territory, introduce to team, and set Q4 targets.",
            department="Marketing", responsible_role="Marketing Manager",
            action_type=MasterWorkflowStep.ActionType.HANDOVER,
            status=MasterWorkflowStep.Status.PENDING, sla_hours=24
        )
        MasterWorkflowStep.objects.create(
            process=wf1, step_order=4, title="Super Admin Final Confirmation",
            description="Final sign-off and activation into organizational payroll.",
            department="Management", responsible_role="Super Admin",
            action_type=MasterWorkflowStep.ActionType.APPROVAL,
            status=MasterWorkflowStep.Status.PENDING, sla_hours=12
        )

        # 2. PartyBala Partner Onboarding Pipeline (PBV0000001 - Grand Imperial Banquet)
        wf2 = MasterWorkflowProcess.objects.create(
            process_code="WF-PTR-00891",
            title="PartyBala Partner Onboarding — Grand Imperial Banquet (PBV0000001)",
            workflow_type=MasterWorkflowProcess.WorkflowType.PARTNER_ONBOARDING,
            entity_type='partner',
            entity_id='PBV0000001',
            status=MasterWorkflowProcess.Status.IN_PROGRESS,
            current_stage_name="Operations Readiness & Package Configuration",
            current_department="Operations",
            current_role="Operations Manager",
            initiator=admin_user,
            sla_hours=72,
            sla_deadline=timezone.now() + timezone.timedelta(hours=24),
            progress_percentage=50,
            metadata={"partner_code": "PBV0000001", "name": "Grand Imperial Banquet", "city": "Lucknow"}
        )
        MasterWorkflowStep.objects.create(
            process=wf2, step_order=1, title="Marketing Field Survey & KYC",
            description="Completed site inspection, photos, and gathered GST & FSSAI docs.",
            department="Marketing", responsible_role="Marketing Executive",
            action_type=MasterWorkflowStep.ActionType.DOCUMENT_VERIFICATION,
            status=MasterWorkflowStep.Status.COMPLETED, completed_at=timezone.now(), completed_by=admin_user
        )
        MasterWorkflowStep.objects.create(
            process=wf2, step_order=2, title="Super Admin Commercial Sign-Off",
            description="Verified 15% revenue share agreement and signed digital contract.",
            department="Management", responsible_role="Super Admin",
            action_type=MasterWorkflowStep.ActionType.APPROVAL,
            status=MasterWorkflowStep.Status.APPROVED, completed_at=timezone.now(), completed_by=admin_user
        )
        MasterWorkflowStep.objects.create(
            process=wf2, step_order=3, title="Operations Readiness & Package Configuration",
            description="Set up banquet hall capacity (800 pax), sound systems, and dinner menu templates.",
            department="Operations", responsible_role="Operations Manager",
            action_type=MasterWorkflowStep.ActionType.QUALITY_AUDIT,
            status=MasterWorkflowStep.Status.IN_PROGRESS, sla_hours=24
        )
        MasterWorkflowStep.objects.create(
            process=wf2, step_order=4, title="Accounts Banking & Payout Agreement",
            description="Configure HDFC Escrow account, auto-split payment rule, and invoice template.",
            department="Accounts & Finance", responsible_role="Accounts Manager",
            action_type=MasterWorkflowStep.ActionType.COMMERCIAL_SETUP,
            status=MasterWorkflowStep.Status.PENDING, sla_hours=24
        )

        # 3. Customer Booking Operations Pipeline (BK-2026-001)
        wf3 = MasterWorkflowProcess.objects.create(
            process_code="WF-BKG-00452",
            title="Booking Operations — BK-2026-001 (Aarav Sharma Wedding @ Grand Imperial)",
            workflow_type=MasterWorkflowProcess.WorkflowType.BOOKING_OPERATIONS,
            entity_type='booking',
            entity_id='BK-2026-001',
            status=MasterWorkflowProcess.Status.IN_PROGRESS,
            current_stage_name="Operations Service Readiness & Catering Check",
            current_department="Operations",
            current_role="Operations Executive",
            initiator=admin_user,
            sla_hours=48,
            sla_deadline=timezone.now() + timezone.timedelta(hours=18),
            progress_percentage=25,
            metadata={"booking_code": "BK-2026-001", "guest_count": 650, "date": "2026-10-15"}
        )
        MasterWorkflowStep.objects.create(
            process=wf3, step_order=1, title="Customer Booking & Advance Payment",
            description="Advance payment of ₹1,50,000 received via Razorpay. GST invoice generated.",
            department="Accounts & Finance", responsible_role="Accountant",
            action_type=MasterWorkflowStep.ActionType.COMMERCIAL_SETUP,
            status=MasterWorkflowStep.Status.COMPLETED, completed_at=timezone.now(), completed_by=admin_user
        )
        MasterWorkflowStep.objects.create(
            process=wf3, step_order=2, title="Operations Service Readiness & Catering Check",
            description="Verify banquet hall allocation, lighting, DJ setup, and 4-course North Indian menu.",
            department="Operations", responsible_role="Operations Executive",
            action_type=MasterWorkflowStep.ActionType.QUALITY_AUDIT,
            status=MasterWorkflowStep.Status.IN_PROGRESS, sla_hours=12
        )
        MasterWorkflowStep.objects.create(
            process=wf3, step_order=3, title="Event Day Execution & Live Coordination",
            description="Real-time coordinator on-site checklist and vendor management.",
            department="Operations", responsible_role="Operations Lead",
            action_type=MasterWorkflowStep.ActionType.TASK_EXECUTION,
            status=MasterWorkflowStep.Status.PENDING, sla_hours=24
        )
        MasterWorkflowStep.objects.create(
            process=wf3, step_order=4, title="Final Payout Settlement & Customer Review",
            description="Release remaining 50% vendor payout, record client NPS rating.",
            department="Accounts & Finance", responsible_role="Accounts Manager",
            action_type=MasterWorkflowStep.ActionType.APPROVAL,
            status=MasterWorkflowStep.Status.PENDING, sla_hours=24
        )

        # 4. IT Incident Pipeline (INC-2026-042)
        wf4 = MasterWorkflowProcess.objects.create(
            process_code="WF-INC-00042",
            title="Incident Resolution — Payment Gateway Timeout on Booking Portal (INC-2026-042)",
            workflow_type=MasterWorkflowProcess.WorkflowType.IT_INCIDENT,
            entity_type='issue',
            entity_id='INC-2026-042',
            status=MasterWorkflowProcess.Status.IN_PROGRESS,
            current_stage_name="IT Investigation & Hotfix",
            current_department="Information Technology",
            current_role="IT Engineer",
            initiator=admin_user,
            sla_hours=8,
            sla_deadline=timezone.now() + timezone.timedelta(hours=4),
            progress_percentage=33,
            metadata={"originating_department": "Operations", "priority": "URGENT"}
        )
        MasterWorkflowStep.objects.create(
            process=wf4, step_order=1, title="IT Investigation & RCA",
            description="Investigate gateway timeout reported by Operations during high traffic.",
            department="Information Technology", responsible_role="IT Engineer",
            action_type=MasterWorkflowStep.ActionType.TASK_EXECUTION,
            status=MasterWorkflowStep.Status.IN_PROGRESS, sla_hours=4
        )
        MasterWorkflowStep.objects.create(
            process=wf4, step_order=2, title="DevOps Cluster Deployment",
            description="Deploy optimized connection pool patch to staging & production.",
            department="Information Technology", responsible_role="DevOps Lead",
            action_type=MasterWorkflowStep.ActionType.SYSTEM_PROVISIONING,
            status=MasterWorkflowStep.Status.PENDING, sla_hours=2
        )
        MasterWorkflowStep.objects.create(
            process=wf4, step_order=3, title="Operations Live Verification",
            description="Operations tests booking confirmation live with test transaction.",
            department="Operations", responsible_role="Operations Manager",
            action_type=MasterWorkflowStep.ActionType.APPROVAL,
            status=MasterWorkflowStep.Status.PENDING, sla_hours=2
        )

        self.stdout.write(self.style.SUCCESS("[SUCCESS] Successfully seeded 4 cross-department master workflows with 15 connected stages!"))
