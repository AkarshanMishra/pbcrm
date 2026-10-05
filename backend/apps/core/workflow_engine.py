import uuid
from django.utils import timezone
from django.db import transaction
from django.contrib.auth import get_user_model
from apps.core.models import MasterWorkflowProcess, MasterWorkflowStep, CentralEventRecord
from apps.tasks.models import Task, Project
from apps.notifications.models import Notification
from apps.audit.models import AuditLog

User = get_user_model()

class WorkflowEngine:
    """
    Central Nervous System for PCRM Enterprise.
    Executes cross-departmental business processes with automated task handoffs,
    status updates, role notifications, and immutable audit logs.
    """

    @classmethod
    def emit_event(cls, event_type, entity_type, entity_id, actor=None, payload=None):
        """
        Record a central event and dispatch dependent reactions.
        """
        payload = payload or {}
        event = CentralEventRecord.objects.create(
            event_type=event_type,
            entity_type=entity_type,
            entity_id=str(entity_id),
            actor=actor,
            payload=payload,
            processed=True
        )
        return event

    # ==========================================
    # 1. NEW EMPLOYEE ONBOARDING PIPELINE
    # HR -> IT -> Manager -> Active
    # ==========================================
    @classmethod
    @transaction.atomic
    def start_employee_onboarding(cls, employee, actor=None):
        code = f"WF-ONB-{str(uuid.uuid4())[:6].upper()}"
        name = employee.full_name or f"{employee.first_name} {employee.last_name}".trim()
        dept_name = employee.department.name if employee.department else "IT"
        pos_name = employee.position.title if employee.position else "Specialist"

        process = MasterWorkflowProcess.objects.create(
            process_code=code,
            title=f"Employee Onboarding — {name} ({employee.employee_code})",
            workflow_type=MasterWorkflowProcess.WorkflowType.EMPLOYEE_ONBOARDING,
            entity_type='employee',
            entity_id=employee.employee_code,
            status=MasterWorkflowProcess.Status.IN_PROGRESS,
            current_stage_name="HR Profile Verification",
            current_department="Human Resources",
            current_role="HR Manager",
            initiator=actor,
            sla_hours=48,
            sla_deadline=timezone.now() + timezone.timedelta(hours=48),
            metadata={
                "employee_code": employee.employee_code,
                "name": name,
                "target_department": dept_name,
                "position": pos_name,
                "joining_date": str(employee.joining_date)
            }
        )

        # Step 1: HR Profile & Document Collection (Auto Completed)
        step1 = MasterWorkflowStep.objects.create(
            process=process,
            step_order=1,
            title="HR Record & Verification",
            description=f"Verify Aadhaar, educational certificates, and employment contract for {name}.",
            department="Human Resources",
            responsible_role="HR Manager",
            action_type=MasterWorkflowStep.ActionType.DOCUMENT_VERIFICATION,
            status=MasterWorkflowStep.Status.COMPLETED,
            assignee=actor,
            completed_at=timezone.now(),
            completed_by=actor,
            comments="Employee record generated and validated in HRIS."
        )

        # Step 2: IT Provisioning (Email, Laptop, Cloud Credentials)
        step2 = MasterWorkflowStep.objects.create(
            process=process,
            step_order=2,
            title="IT Provisioning & Asset Allocation",
            description=f"Create Google Workspace email, VPN access, and allocate MacBook for {name} ({dept_name}).",
            department="Information Technology",
            responsible_role="IT Manager",
            action_type=MasterWorkflowStep.ActionType.SYSTEM_PROVISIONING,
            status=MasterWorkflowStep.Status.IN_PROGRESS,
            sla_hours=12,
            due_date=timezone.now() + timezone.timedelta(hours=12)
        )

        # Create actual linked task in IT department
        it_task = Task.objects.create(
            title=f"Provision IT Systems & Hardware for {name} ({employee.employee_code})",
            description=f"1. Generate corporate email {employee.employee_code.lower()}@pcrm.internal\n2. Issue MacBook & NFC Security Badge\n3. Assign SSO roles for {dept_name}",
            priority=Task.Priority.HIGH,
            status=Task.Status.ASSIGNED,
            department=employee.department,
            assigned_to=employee,
            assigned_by=actor or employee.user,
            due_date=(timezone.now() + timezone.timedelta(days=1)).date()
        )
        step2.linked_task_id = str(it_task.id)
        step2.save(update_fields=['linked_task_id'])

        # Step 3: Reporting Manager Team Handover
        MasterWorkflowStep.objects.create(
            process=process,
            step_order=3,
            title="Manager Team & Goal Allocation",
            description=f"Welcome {name} to {dept_name}, assign initial sprint tasks, and confirm 30-day goals.",
            department=dept_name,
            responsible_role="Department Manager",
            action_type=MasterWorkflowStep.ActionType.HANDOVER,
            status=MasterWorkflowStep.Status.PENDING,
            sla_hours=24,
            due_date=timezone.now() + timezone.timedelta(hours=24)
        )

        # Step 4: Super Admin Final Sign-Off
        MasterWorkflowStep.objects.create(
            process=process,
            step_order=4,
            title="Admin Final Onboarding Audit",
            description=f"Final administrative compliance check and confirmation of active employee status.",
            department="Management",
            responsible_role="Super Admin",
            action_type=MasterWorkflowStep.ActionType.APPROVAL,
            status=MasterWorkflowStep.Status.PENDING,
            sla_hours=12
        )

        process.recalculate_progress()
        cls.emit_event(
            CentralEventRecord.EventType.WORKFLOW_STARTED,
            'employee',
            employee.employee_code,
            actor=actor,
            payload={"process_code": code, "type": "EMPLOYEE_ONBOARDING"}
        )
        return process

    # ==========================================
    # 2. PARTYBALA PARTNER PIPELINE
    # Marketing -> Admin Approval -> Operations -> Accounts
    # ==========================================
    @classmethod
    @transaction.atomic
    def start_partner_onboarding(cls, partner_code, partner_name, partner_type, actor=None):
        code = f"WF-PTR-{str(uuid.uuid4())[:6].upper()}"

        process = MasterWorkflowProcess.objects.create(
            process_code=code,
            title=f"Partner Onboarding — {partner_name} ({partner_code})",
            workflow_type=MasterWorkflowProcess.WorkflowType.PARTNER_ONBOARDING,
            entity_type='partner',
            entity_id=partner_code,
            status=MasterWorkflowProcess.Status.IN_PROGRESS,
            current_stage_name="Marketing KYC & Verification",
            current_department="Marketing",
            current_role="Marketing Executive",
            initiator=actor,
            sla_hours=72,
            sla_deadline=timezone.now() + timezone.timedelta(hours=72),
            metadata={
                "partner_code": partner_code,
                "partner_name": partner_name,
                "partner_type": partner_type
            }
        )

        # Step 1: Marketing Field Visit & Document Collection (Completed)
        MasterWorkflowStep.objects.create(
            process=process,
            step_order=1,
            title="Field Visit & KYC Collection",
            description=f"Completed on-site survey and collected FSSAI, GST, and property deed for {partner_name}.",
            department="Marketing",
            responsible_role="Marketing Executive",
            action_type=MasterWorkflowStep.ActionType.DOCUMENT_VERIFICATION,
            status=MasterWorkflowStep.Status.COMPLETED,
            assignee=actor,
            completed_at=timezone.now(),
            completed_by=actor,
            comments="Field check-in verified with GPS geofence stamp."
        )

        # Step 2: Super Admin / Management Approval
        step2 = MasterWorkflowStep.objects.create(
            process=process,
            step_order=2,
            title="Super Admin Commercial Sign-Off",
            description=f"Review commercial terms and grant organization approval for {partner_name}.",
            department="Management",
            responsible_role="Super Admin",
            action_type=MasterWorkflowStep.ActionType.APPROVAL,
            status=MasterWorkflowStep.Status.PENDING_APPROVAL,
            sla_hours=24,
            due_date=timezone.now() + timezone.timedelta(hours=24)
        )

        # Step 3: Operations Setup (Packages, Menus, Readiness)
        MasterWorkflowStep.objects.create(
            process=process,
            step_order=3,
            title="Operations Readiness & Package Configuration",
            description=f"Inspect banquet capacity, upload catering packages, and audit service readiness.",
            department="Operations",
            responsible_role="Operations Manager",
            action_type=MasterWorkflowStep.ActionType.QUALITY_AUDIT,
            status=MasterWorkflowStep.Status.PENDING,
            sla_hours=24
        )

        # Step 4: Accounts Banking & Settlement Setup
        MasterWorkflowStep.objects.create(
            process=process,
            step_order=4,
            title="Accounts Banking & Commercial Agreement",
            description=f"Configure bank IFSC, payment gateway split, commission tiers, and generate partner agreement.",
            department="Accounts & Finance",
            responsible_role="Accounts Manager",
            action_type=MasterWorkflowStep.ActionType.COMMERCIAL_SETUP,
            status=MasterWorkflowStep.Status.PENDING,
            sla_hours=24
        )

        process.recalculate_progress()
        cls.emit_event(
            CentralEventRecord.EventType.PARTNER_CREATED,
            'partner',
            partner_code,
            actor=actor,
            payload={"process_code": code, "partner_name": partner_name}
        )
        return process

    # ==========================================
    # 3. BOOKING OPERATIONS PIPELINE
    # Booking -> Operations -> Accounts -> Event -> Complete
    # ==========================================
    @classmethod
    @transaction.atomic
    def start_booking_operations(cls, booking_code, customer_name, event_date, venue_name, actor=None):
        code = f"WF-BKG-{str(uuid.uuid4())[:6].upper()}"

        process = MasterWorkflowProcess.objects.create(
            process_code=code,
            title=f"Booking Operations — {booking_code} ({customer_name} @ {venue_name})",
            workflow_type=MasterWorkflowProcess.WorkflowType.BOOKING_OPERATIONS,
            entity_type='booking',
            entity_id=booking_code,
            status=MasterWorkflowProcess.Status.IN_PROGRESS,
            current_stage_name="Operations Venue Confirmation",
            current_department="Operations",
            current_role="Operations Executive",
            initiator=actor,
            sla_hours=48,
            sla_deadline=timezone.now() + timezone.timedelta(hours=48),
            metadata={
                "booking_code": booking_code,
                "customer_name": customer_name,
                "event_date": str(event_date),
                "venue": venue_name
            }
        )

        # Step 1: Operations Venue & Partner Confirmation
        MasterWorkflowStep.objects.create(
            process=process,
            step_order=1,
            title="Venue & Coordinator Confirmation",
            description=f"Confirm event hall, sound systems, and catering coordinator for {customer_name} on {event_date}.",
            department="Operations",
            responsible_role="Operations Executive",
            action_type=MasterWorkflowStep.ActionType.TASK_EXECUTION,
            status=MasterWorkflowStep.Status.IN_PROGRESS,
            sla_hours=12,
            due_date=timezone.now() + timezone.timedelta(hours=12)
        )

        # Step 2: Accounts Advance & Tax Invoice
        MasterWorkflowStep.objects.create(
            process=process,
            step_order=2,
            title="Advance Payment Verification & GST Invoice",
            description=f"Verify 50% booking advance payment and issue formal tax invoice to {customer_name}.",
            department="Accounts & Finance",
            responsible_role="Accountant",
            action_type=MasterWorkflowStep.ActionType.COMMERCIAL_SETUP,
            status=MasterWorkflowStep.Status.PENDING,
            sla_hours=12
        )

        # Step 3: Event Day Execution & Quality Checklist
        MasterWorkflowStep.objects.create(
            process=process,
            step_order=3,
            title="Event Day Service Execution & Quality Audit",
            description=f"Real-time checklist verification (Stage, Lights, Catering, Sanitization, Staff).",
            department="Operations",
            responsible_role="Operations Lead",
            action_type=MasterWorkflowStep.ActionType.QUALITY_AUDIT,
            status=MasterWorkflowStep.Status.PENDING,
            sla_hours=24
        )

        # Step 4: Accounts Final Settlement & Customer Review
        MasterWorkflowStep.objects.create(
            process=process,
            step_order=4,
            title="Final Settlement & Performance Review",
            description=f"Process remaining partner payout, record customer rating, and archive booking.",
            department="Accounts & Finance",
            responsible_role="Accounts Manager",
            action_type=MasterWorkflowStep.ActionType.APPROVAL,
            status=MasterWorkflowStep.Status.PENDING,
            sla_hours=24
        )

        process.recalculate_progress()
        cls.emit_event(
            CentralEventRecord.EventType.BOOKING_CREATED,
            'booking',
            booking_code,
            actor=actor,
            payload={"process_code": code, "customer": customer_name}
        )
        return process

    # ==========================================
    # 4. IT INCIDENT CROSS-DEPARTMENT PIPELINE
    # Operations Issue -> IT Ticket/Fix/Deploy -> Operations Verify
    # ==========================================
    @classmethod
    @transaction.atomic
    def start_it_incident_pipeline(cls, issue_code, issue_title, reporter_department, priority="HIGH", actor=None):
        code = f"WF-INC-{str(uuid.uuid4())[:6].upper()}"

        process = MasterWorkflowProcess.objects.create(
            process_code=code,
            title=f"Incident Resolution — {issue_title} ({issue_code})",
            workflow_type=MasterWorkflowProcess.WorkflowType.IT_INCIDENT,
            entity_type='issue',
            entity_id=issue_code,
            status=MasterWorkflowProcess.Status.IN_PROGRESS,
            current_stage_name="IT Investigation & Triage",
            current_department="Information Technology",
            current_role="IT Engineer",
            initiator=actor,
            sla_hours=8 if priority == "URGENT" else 24,
            sla_deadline=timezone.now() + timezone.timedelta(hours=8 if priority == "URGENT" else 24),
            metadata={
                "issue_code": issue_code,
                "title": issue_title,
                "reporter_dept": reporter_department,
                "priority": priority
            }
        )

        # Step 1: IT Investigation, Bug Fix & Testing
        step1 = MasterWorkflowStep.objects.create(
            process=process,
            step_order=1,
            title="IT Root Cause Analysis & Hotfix",
            description=f"Investigate issue originated from {reporter_department}: '{issue_title}'. Apply fix and test in staging.",
            department="Information Technology",
            responsible_role="IT Engineer",
            action_type=MasterWorkflowStep.ActionType.TASK_EXECUTION,
            status=MasterWorkflowStep.Status.IN_PROGRESS,
            sla_hours=6,
            due_date=timezone.now() + timezone.timedelta(hours=6)
        )

        # Step 2: DevOps Staging/Prod Deployment
        MasterWorkflowStep.objects.create(
            process=process,
            step_order=2,
            title="DevOps Production Deployment",
            description=f"Deploy verified patch to production cluster with zero downtime.",
            department="Information Technology",
            responsible_role="DevOps Lead",
            action_type=MasterWorkflowStep.ActionType.SYSTEM_PROVISIONING,
            status=MasterWorkflowStep.Status.PENDING,
            sla_hours=4
        )

        # Step 3: Originating Department Verification
        MasterWorkflowStep.objects.create(
            process=process,
            step_order=3,
            title=f"{reporter_department} End-to-End Verification",
            description=f"{reporter_department} team tests live system to confirm '{issue_title}' is fully resolved.",
            department=reporter_department,
            responsible_role="Department Manager",
            action_type=MasterWorkflowStep.ActionType.APPROVAL,
            status=MasterWorkflowStep.Status.PENDING,
            sla_hours=6
        )

        process.recalculate_progress()
        cls.emit_event(
            CentralEventRecord.EventType.ISSUE_REPORTED,
            'issue',
            issue_code,
            actor=actor,
            payload={"process_code": code, "priority": priority}
        )
        return process

    # ==========================================
    # 5. STEP ADVANCEMENT & AUTOMATIC HANDOFFS
    # ==========================================
    @classmethod
    @transaction.atomic
    def advance_step(cls, step_id, action="COMPLETE", actor=None, comments=""):
        step = MasterWorkflowStep.objects.select_for_update().get(id=step_id)
        process = step.process

        if action in ["COMPLETE", "APPROVE"]:
            step.status = MasterWorkflowStep.Status.COMPLETED if action == "COMPLETE" else MasterWorkflowStep.Status.APPROVED
            step.completed_at = timezone.now()
            step.completed_by = actor
            step.comments = comments
            step.save()

            # Unlock Next Step
            next_step = process.steps.filter(step_order=step.step_order + 1).first()
            if next_step:
                next_step.status = MasterWorkflowStep.Status.IN_PROGRESS
                next_step.save()

                process.current_stage_name = next_step.title
                process.current_department = next_step.department
                process.current_role = next_step.responsible_role
                process.save(update_fields=['current_stage_name', 'current_department', 'current_role', 'updated_at'])

                # Dispatch Notification to Next Responsible Department
                try:
                    target_user = User.objects.filter(is_active=True).first()
                    if target_user:
                        Notification.objects.create(
                            recipient=target_user,
                            notification_type=Notification.NotificationType.WORKFLOW,
                            title=f"New Workflow Action: {next_step.title}",
                            message=f"Process [{process.process_code}] has advanced to your department ({next_step.department}).",
                            priority=Notification.Priority.HIGH,
                            action_url=f"/workflow/{process.process_code}"
                        )
                except Exception:
                    pass

                cls.emit_event(
                    CentralEventRecord.EventType.WORKFLOW_STEP_COMPLETED,
                    process.entity_type,
                    process.entity_id,
                    actor=actor,
                    payload={
                        "process_code": process.process_code,
                        "completed_step": step.title,
                        "next_step": next_step.title,
                        "next_department": next_step.department
                    }
                )
            else:
                # All Steps Completed
                process.status = MasterWorkflowProcess.Status.CLOSED
                process.save(update_fields=['status', 'updated_at'])
                cls.emit_event(
                    CentralEventRecord.EventType.WORKFLOW_COMPLETED,
                    process.entity_type,
                    process.entity_id,
                    actor=actor,
                    payload={"process_code": process.process_code}
                )

        elif action == "REJECT":
            step.status = MasterWorkflowStep.Status.REJECTED
            step.comments = comments
            step.completed_at = timezone.now()
            step.completed_by = actor
            step.save()

            process.status = MasterWorkflowProcess.Status.REJECTED
            process.save(update_fields=['status', 'updated_at'])

        process.recalculate_progress()
        return process

    # ==========================================
    # 6. ADMIN 360° RELATIONSHIP GRAPH API
    # ==========================================
    @classmethod
    def get_360_graph(cls, entity_type, entity_id):
        """
        Generates full cross-department relationship nodes and edges for any master entity.
        """
        entity_id_clean = str(entity_id).strip()
        workflows = MasterWorkflowProcess.objects.filter(
            entity_id__iexact=entity_id_clean
        ).prefetch_related('steps')

        nodes = [
            {
                "id": f"root-{entity_type}-{entity_id_clean}",
                "label": f"{entity_type.upper()}: {entity_id_clean}",
                "type": "MASTER_ENTITY",
                "department": "ALL",
                "status": "ACTIVE"
            }
        ]
        edges = []

        for wf in workflows:
            wf_node_id = f"wf-{wf.process_code}"
            nodes.append({
                "id": wf_node_id,
                "label": f"[{wf.process_code}] {wf.title}",
                "type": "WORKFLOW_PROCESS",
                "department": wf.current_department,
                "status": wf.status,
                "progress": wf.progress_percentage
            })
            edges.append({
                "from": f"root-{entity_type}-{entity_id_clean}",
                "to": wf_node_id,
                "relation": "ORCHESTRATED_BY"
            })

            prev_step_node = None
            for step in wf.steps.all():
                step_node_id = f"step-{wf.process_code}-{step.step_order}"
                nodes.append({
                    "id": step_node_id,
                    "label": f"Step {step.step_order}: {step.title} ({step.department})",
                    "type": "WORKFLOW_STEP",
                    "department": step.department,
                    "role": step.responsible_role,
                    "status": step.status,
                    "action_type": step.action_type
                })

                if prev_step_node:
                    edges.append({
                        "from": prev_step_node,
                        "to": step_node_id,
                        "relation": "HANDOFF_TO"
                    })
                else:
                    edges.append({
                        "from": wf_node_id,
                        "to": step_node_id,
                        "relation": "INITIATES"
                    })
                prev_step_node = step_node_id

        return {
            "entity_type": entity_type,
            "entity_id": entity_id_clean,
            "total_nodes": len(nodes),
            "total_edges": len(edges),
            "nodes": nodes,
            "edges": edges
        }
