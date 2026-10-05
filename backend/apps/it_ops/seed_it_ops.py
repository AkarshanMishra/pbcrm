import os
import sys
from pathlib import Path

# Add backend directory to sys.path
BASE_DIR = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(BASE_DIR))

import django
from django.utils import timezone
from datetime import timedelta
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

from apps.accounts.models import User
from apps.employees.models import Employee, Role
from apps.organization.models import Department, Position
from apps.it_ops.models import (
    SystemComponent, ITIncident, ITIncidentComment,
    PullRequest, DeploymentRecord, ITAsset, ITAccessRequest,
    KnowledgeArticle, ITDailyReport
)
from apps.tasks.models import Task, Project

def seed():
    print("Seeding IT Operations Data...")

    # Ensure IT Department & Positions
    it_dept, _ = Department.objects.get_or_create(
        code="IT_ENG",
        defaults={
            "name": "Information Technology & Engineering",
            "description": "Software Development, DevOps, Security, Cloud, IT Support"
        }
    )

    dev_role, _ = Role.objects.get_or_create(
        code="SOFTWARE_ENGINEER",
        defaults={"name": "Software Engineer", "description": "Full-stack developer"}
    )
    mgr_role, _ = Role.objects.get_or_create(
        code="IT_MANAGER",
        defaults={"name": "IT Engineering Lead", "description": "Lead and manage IT systems & sprint work"}
    )

    dev_pos, _ = Position.objects.get_or_create(
        code="DEV_SDE2",
        defaults={"title": "Software Developer", "department": it_dept}
    )
    mgr_pos, _ = Position.objects.get_or_create(
        code="ENG_LEAD",
        defaults={"title": "IT Engineering Manager", "department": it_dept}
    )

    # IT Dev User (Akarshan)
    akarshan_emp = Employee.objects.filter(user__employee_code="PBE000003").first()
    if akarshan_emp:
        akarshan_emp.first_name = "Akarshan"
        akarshan_emp.last_name = "Mishra"
        akarshan_emp.department = it_dept
        akarshan_emp.position = dev_pos
        akarshan_emp.role = dev_role
        akarshan_emp.save()

    # IT Manager User
    it_mgr_emp = Employee.objects.filter(user__employee_code="PBE000002").first()
    if it_mgr_emp:
        it_mgr_emp.department = it_dept
        it_mgr_emp.position = mgr_pos
        it_mgr_emp.role = mgr_role
        it_mgr_emp.save()

    # Create additional team devs for workload visualization if needed
    for i, code in enumerate(["PBE000004", "PBE000005", "PBE000006"], start=4):
        emp_user, _ = User.objects.get_or_create(
            employee_code=code,
            defaults={
                "email": f"dev{i}@pcrm.local",
                "status": User.AccountStatus.ACTIVE,
            }
        )
        if not emp_user.has_usable_password():
            emp_user.set_password("12345678")
            emp_user.save()
        Employee.objects.get_or_create(
            user=emp_user,
            defaults={
                "first_name": f"Developer {chr(64+i)}",
                "last_name": "Team",
                "department": it_dept,
                "position": dev_pos,
                "role": dev_role,
                "joining_date": timezone.now().date()
            }
        )

    # 1. System Components
    systems_data = [
        {
            "name": "Payment API & Webhook Service",
            "slug": "payment-api-service",
            "component_type": SystemComponent.ComponentType.API,
            "status": SystemComponent.HealthStatus.DOWN,
            "endpoint_or_host": "https://api.partybala.com/v1/payments/",
            "uptime_percentage": 94.20,
            "responsible_team": "Payments & Core Backend",
            "dependencies_info": "PostgreSQL, Razorpay Gateway, Redis",
            "description": "Handles payment gateway callbacks, customer checkout and partner payouts."
        },
        {
            "name": "API Gateway & Edge Router",
            "slug": "api-gateway",
            "component_type": SystemComponent.ComponentType.API,
            "status": SystemComponent.HealthStatus.OPERATIONAL,
            "endpoint_or_host": "https://gateway.partybala.com",
            "uptime_percentage": 99.99,
            "responsible_team": "DevOps / Infrastructure",
            "dependencies_info": "Cloudflare Edge, Nginx Ingress",
            "description": "Reverse proxy, rate limiting, JWT validation and SSL termination."
        },
        {
            "name": "PostgreSQL Primary Cluster",
            "slug": "postgres-primary-db",
            "component_type": SystemComponent.ComponentType.DATABASE,
            "status": SystemComponent.HealthStatus.OPERATIONAL,
            "endpoint_or_host": "db-prod.partybala.internal:5432",
            "uptime_percentage": 99.98,
            "responsible_team": "DBA / Backend",
            "dependencies_info": "AWS RDS Multi-AZ, Read Replica 1, Read Replica 2",
            "description": "Primary transactional relational database cluster with automated failover."
        },
        {
            "name": "PartyBala Customer Mobile & Web App",
            "slug": "customer-app",
            "component_type": SystemComponent.ComponentType.APPLICATION,
            "status": SystemComponent.HealthStatus.OPERATIONAL,
            "endpoint_or_host": "https://partybala.com",
            "uptime_percentage": 99.95,
            "responsible_team": "Frontend & Mobile Team",
            "dependencies_info": "API Gateway, CDN, Firebase Notifications",
            "description": "Customer facing venue booking, event packages and ticketing experience."
        },
        {
            "name": "Automated Backup Service",
            "slug": "backup-service",
            "component_type": SystemComponent.ComponentType.BACKUP,
            "status": SystemComponent.HealthStatus.WARNING,
            "endpoint_or_host": "backup-runner.prod.partybala.internal",
            "uptime_percentage": 98.40,
            "responsible_team": "DevOps / Site Reliability",
            "dependencies_info": "AWS S3 Glacier, GCS Archive",
            "description": "Nightly differential and weekly full DB snapshots with cross-region replication."
        },
        {
            "name": "SSL Wildcard Certificate (*.partybala.com)",
            "slug": "ssl-wildcard-cert",
            "component_type": SystemComponent.ComponentType.SSL_CERT,
            "status": SystemComponent.HealthStatus.WARNING,
            "endpoint_or_host": "*.partybala.com",
            "uptime_percentage": 100.0,
            "ssl_expiry_date": (timezone.now() + timedelta(days=12)).date(),
            "responsible_team": "Security & SecOps",
            "dependencies_info": "Let's Encrypt / DigiCert ACME",
            "description": "Production edge wildcard certificate (renewal window active)."
        }
    ]

    created_systems = {}
    for data in systems_data:
        sys_obj, _ = SystemComponent.objects.update_or_create(slug=data["slug"], defaults=data)
        created_systems[data["slug"]] = sys_obj

    # 2. IT Incidents / Tickets
    pay_sys = created_systems.get("payment-api-service")
    inc1, _ = ITIncident.objects.update_or_create(
        incident_number="INC-10248",
        defaults={
            "title": "Production Payment API 502 High Latency",
            "description": "Payment webhook timeouts causing 502 Bad Gateway during peak checkout volume.",
            "category": ITIncident.Category.APPLICATION_BUG,
            "priority": ITIncident.Priority.CRITICAL,
            "status": ITIncident.Status.INVESTIGATING,
            "impact": "Customer payments affected. Gateway callback queue accumulating in Redis.",
            "affected_system": pay_sys,
            "reporter": Employee.objects.filter(user__employee_code="PBE000001").first(),
            "assignee": akarshan_emp,
            "root_cause": "Database connection pool exhaustion on payment webhook listener worker.",
            "escalated": True
        }
    )
    if akarshan_emp and akarshan_emp.user:
        ITIncidentComment.objects.get_or_create(
            incident=inc1,
            author=akarshan_emp.user,
            comment_text="Identified thread exhaustion in Gunicorn async worker. Increasing pool size and deploying patch.",
            is_internal_log=True
        )

    ITIncident.objects.update_or_create(
        incident_number="INC-10249",
        defaults={
            "title": "Staging Redis Cluster Memory Alert (>85%)",
            "description": "Redis memory consumption peaked due to unevicted session tokens.",
            "category": ITIncident.Category.SERVER,
            "priority": ITIncident.Priority.HIGH,
            "status": ITIncident.Status.IN_PROGRESS,
            "impact": "Staging test suites experiencing slower token verification.",
            "reporter": it_mgr_emp,
            "assignee": akarshan_emp
        }
    )

    ITIncident.objects.update_or_create(
        incident_number="INC-10250",
        defaults={
            "title": "SSL Certificate Expiry Warning (*.partybala.com)",
            "description": "Production wildcard SSL expires in 12 days. ACME auto-renewal bot failed DNS challenge.",
            "category": ITIncident.Category.SECURITY,
            "priority": ITIncident.Priority.HIGH,
            "status": ITIncident.Status.OPEN,
            "impact": "Will disrupt HTTPS customer traffic if not renewed by 16 Oct 2026.",
            "affected_system": created_systems.get("ssl-wildcard-cert"),
            "reporter": it_mgr_emp
        }
    )

    # 3. Pull Requests / Code Reviews
    if akarshan_emp:
        PullRequest.objects.update_or_create(
            pr_number=248,
            defaults={
                "title": "Payment Gateway Fix & Webhook Connection Pooling",
                "repository": "partybala/backend-core",
                "source_branch": "feat/payment-gateway-fix",
                "target_branch": "main",
                "author": akarshan_emp,
                "reviewer": it_mgr_emp,
                "build_status": PullRequest.BuildStatus.PASSED,
                "test_status": PullRequest.BuildStatus.PASSED,
                "review_status": PullRequest.ReviewStatus.PENDING,
                "state": PullRequest.PRState.OPEN,
                "commit_hash": "e4a7b19",
                "summary": "Increases DB pool size from 10 to 40 for payment webhooks, adds exponential backoff retry."
            }
        )

        PullRequest.objects.update_or_create(
            pr_number=247,
            defaults={
                "title": "Auth MFA Token Refresh & Biometric Validation",
                "repository": "partybala/backend-core",
                "source_branch": "feat/mfa-jwt-refresh",
                "target_branch": "main",
                "author": akarshan_emp,
                "reviewer": it_mgr_emp,
                "build_status": PullRequest.BuildStatus.PASSED,
                "test_status": PullRequest.BuildStatus.PASSED,
                "review_status": PullRequest.ReviewStatus.APPROVED,
                "state": PullRequest.PRState.OPEN,
                "commit_hash": "c91a02d",
                "summary": "Implements secure refresh token rotation and biometric hardware key fallback."
            }
        )

    # 4. Deployments
    if akarshan_emp:
        DeploymentRecord.objects.update_or_create(
            version_tag="v2.8.4-rc1",
            environment=DeploymentRecord.Environment.STAGING,
            defaults={
                "application": "PartyBala Enterprise CRM",
                "commit_hash": "e4a7b19",
                "build_passed": True,
                "tests_passed": True,
                "triggered_by": akarshan_emp,
                "approved_by": it_mgr_emp,
                "status": DeploymentRecord.DeployStatus.SUCCESS,
                "logs_output": "Docker image partybala/crm:v2.8.4 built. Kubernetes rolling update complete.",
                "release_notes": "Added IT role view, dynamic ticketing, and marketing telemetry."
            }
        )

        DeploymentRecord.objects.update_or_create(
            version_tag="v2.8.3",
            environment=DeploymentRecord.Environment.PRODUCTION,
            defaults={
                "application": "PartyBala Enterprise CRM",
                "commit_hash": "a8f9c12",
                "build_passed": True,
                "tests_passed": True,
                "triggered_by": akarshan_emp,
                "approved_by": it_mgr_emp,
                "status": DeploymentRecord.DeployStatus.SUCCESS,
                "logs_output": "Production canary deployment succeeded. 0 errors observed in 24h.",
                "release_notes": "Phase 2 workforce execution & marketing hub launch."
            }
        )

    # 5. IT Assets
    if akarshan_emp:
        ITAsset.objects.update_or_create(
            asset_tag="IT-LAP-00248",
            defaults={
                "asset_type": ITAsset.AssetType.LAPTOP,
                "name": "Dell Latitude 7420 Developer Workstation",
                "brand": "Dell",
                "model_name": "Latitude 7420 (Intel Core i7-1185G7)",
                "serial_number": "DL-7420-99410A",
                "assigned_to": akarshan_emp,
                "status": ITAsset.AssetStatus.ACTIVE,
                "purchase_date": (timezone.now() - timedelta(days=200)).date(),
                "warranty_expiry": (timezone.now() + timedelta(days=530)).date(),
                "specs": {"RAM": "32 GB DDR4", "Storage": "1 TB NVMe SSD", "OS": "Ubuntu 24.04 LTS / Windows 11 Dual"},
                "installed_software": "VS Code, Docker Desktop, Postman, Git, Flutter SDK, Python 3.12, DBeaver",
                "maintenance_history": "04-May-2026: Battery diagnostic passed. Software patches verified."
            }
        )

        ITAsset.objects.update_or_create(
            asset_tag="IT-MON-00109",
            defaults={
                "asset_type": ITAsset.AssetType.MONITOR,
                "name": "Dell UltraSharp 27\" 4K USB-C Hub Monitor (U2723QE)",
                "brand": "Dell",
                "model_name": "U2723QE 4K IPS",
                "serial_number": "MON-U27-33120B",
                "assigned_to": akarshan_emp,
                "status": ITAsset.AssetStatus.ACTIVE,
                "purchase_date": (timezone.now() - timedelta(days=180)).date(),
                "warranty_expiry": (timezone.now() + timedelta(days=550)).date(),
                "specs": {"Resolution": "3840 x 2160", "RefreshRate": "60Hz", "Port": "USB-C 90W PD"}
            }
        )

    # 6. IT Access Requests
    if akarshan_emp:
        ITAccessRequest.objects.update_or_create(
            request_number="REQ-IT-2026-0014",
            defaults={
                "request_type": ITAccessRequest.RequestType.DATABASE,
                "title": "Staging Database Read/Write Access for Incident Debugging",
                "justification": "Required to test payment webhook idempotency keys on staging PostgreSQL.",
                "status": ITAccessRequest.Status.RESOLVED,
                "requester": akarshan_emp,
                "approved_by": it_mgr_emp,
                "provisioned_details": "Granted temporary RDS staging IAM credentials (valid for 30 days)."
            }
        )

    # 7. Knowledge Base & SOPs
    KnowledgeArticle.objects.update_or_create(
        slug="troubleshoot-production-api-502-error",
        defaults={
            "title": "How to Troubleshoot Production API 502 Bad Gateway Errors",
            "category": KnowledgeArticle.Category.TROUBLESHOOTING,
            "summary": "Standard operational runbook for diagnosing and restoring backend API 502/504 errors in production.",
            "content": """### Production API 502 Runbook

Follow these sequential steps whenever an alert triggers for elevated 502 errors:

1. **Verify Ingress & Gateway Health**: Check Cloudflare / Nginx ingress latency and error rate.
2. **Inspect Backend Application Logs**: Run `kubectl logs -n prod -l app=pcrm-backend --tail=200` to check for Gunicorn worker crashes.
3. **Check Database Connection Pool**: Verify active PostgreSQL client connections via `SELECT count(*) FROM pg_stat_activity;`.
4. **Inspect Redis Cache / Worker Queues**: Ensure Celery and Redis message queues are not starved.
5. **Execute Controlled Pod Restart**: Run `kubectl rollout restart deployment/pcrm-backend -n prod` if deadlock is observed.
6. **Escalation Protocol**: If error rate remains > 2% after 5 minutes, escalate to Lead DevOps on PagerDuty.
""",
            "steps_checklist": [
                {"step": 1, "action": "Verify Ingress & Edge Gateway status"},
                {"step": 2, "action": "Inspect Kubernetes Gunicorn pod container logs"},
                {"step": 3, "action": "Check PostgreSQL active connection saturation"},
                {"step": 4, "action": "Verify Redis queue throughput & memory limit"},
                {"step": 5, "action": "Execute graceful rolling restart if required"},
                {"step": 6, "action": "Notify incident channel & page DevOps Lead"}
            ],
            "tags": ["production", "runbook", "api", "502", "troubleshooting", "kubernetes", "postgres"],
            "view_count": 84
        }
    )

    KnowledgeArticle.objects.update_or_create(
        slug="staging-and-production-zero-downtime-deployment-sop",
        defaults={
            "title": "Zero-Downtime Deployment SOP for Microservices & APIs",
            "category": KnowledgeArticle.Category.DEPLOYMENT,
            "summary": "Detailed guidelines on CI/CD pipelines, semantic tagging, database migrations, and canary deployments.",
            "content": """### Deployment SOP

- **Staging**: Triggered automatically on merge to `develop` or manual tag `v*.*.*-rc*`.
- **Production**: Requires PR approval from IT Manager + green test suite + manual approval in Deployment Center.
- **Database Migrations**: Must be backward-compatible (expand-and-contract pattern).
""",
            "steps_checklist": [
                {"step": 1, "action": "Ensure all unit and integration tests pass"},
                {"step": 2, "action": "Verify database migrations are non-locking"},
                {"step": 3, "action": "Obtain IT Engineering Manager signoff"},
                {"step": 4, "action": "Trigger deployment from Deployment Center"},
                {"step": 5, "action": "Monitor APM dashboard for 15 minutes post-release"}
            ],
            "tags": ["deployment", "sop", "ci-cd", "kubernetes", "release"],
            "view_count": 52
        }
    )

    # 8. IT Daily Report
    if akarshan_emp:
        ITDailyReport.objects.update_or_create(
            developer=akarshan_emp,
            report_date=timezone.now().date(),
            defaults={
                "tasks_completed_count": 5,
                "bugs_fixed_count": 2,
                "tickets_resolved_count": 4,
                "deployments_count": 1,
                "code_reviews_count": 2,
                "incidents_handled": "Investigated Production Payment API 502 latency and tuned Gunicorn pool size.",
                "blockers": "Waiting for staging AWS CloudWatch IAM policy approval.",
                "tomorrow_plan": "Complete payment gateway retry logic and merge PR #248.",
                "summary_notes": "All critical systems stable. Production API patch ready for canary release."
            }
        )

    print("IT Operations Seeding Completed Successfully!")

if __name__ == '__main__':
    seed()
