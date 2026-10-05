from django.core.management.base import BaseCommand
from apps.organization.models import Department
from apps.tasks.models import TaskTemplate, Task

class Command(BaseCommand):
    help = 'Seeds Phase 2 default task templates for Marketing, IT, Operations, and Accounts'

    def handle(self, *args, **kwargs):
        self.stdout.write('Seeding Phase 2 department task templates...')

        mktg_dept = Department.objects.filter(code='MKTG').first()
        it_dept = Department.objects.filter(code='IT').first()
        ops_dept = Department.objects.filter(code='OPS').first()
        acc_dept = Department.objects.filter(code='ACC').first()

        templates_data = [
            # 1. Marketing Templates
            {
                'name': 'Partner / Vendor Onboarding',
                'department': mktg_dept,
                'default_priority': Task.Priority.HIGH,
                'description': 'End-to-end onboarding for marketing partners and vendors.',
                'estimated_hours': 4.0,
                'checklist_template': [
                    'Contact partner and verify primary contact',
                    'Collect firm details and registration certificate',
                    'Collect Owner KYC (Aadhaar / PAN)',
                    'Collect GST certificate',
                    'Collect bank details & cancelled cheque',
                    'Capture high-res venue / shop front photos',
                    'Finalize package pricing and commission structure',
                    'Sign Terms & Conditions contract',
                    'Submit for Admin / Manager activation'
                ]
            },
            {
                'name': 'Market Research & Competitor Analysis',
                'department': mktg_dept,
                'default_priority': Task.Priority.MEDIUM,
                'description': 'Field visit to survey competitors and gather pricing intel.',
                'estimated_hours': 3.0,
                'checklist_template': [
                    'Survey targeted area / market cluster',
                    'Document 5 competitor pricing plans',
                    'Analyze customer traffic and peak hours',
                    'Identify gaps and promotional opportunities',
                    'Upload research summary and photos'
                ]
            },
            # 2. IT Team Templates
            {
                'name': 'Production Bug Resolution',
                'department': it_dept,
                'default_priority': Task.Priority.URGENT,
                'description': 'Investigate, fix, test, and deploy critical bug patch.',
                'estimated_hours': 2.5,
                'checklist_template': [
                    'Review error logs and reproduce issue in local dev',
                    'Isolate root cause in codebase / database',
                    'Implement code fix and unit tests',
                    'Verify regression testing on staging build',
                    'Deploy fix to production',
                    'Monitor error rates in SOC dashboard'
                ]
            },
            {
                'name': 'API Feature Development',
                'department': it_dept,
                'default_priority': Task.Priority.HIGH,
                'description': 'Develop, document, and test new REST endpoint module.',
                'estimated_hours': 6.0,
                'checklist_template': [
                    'Design data models and schema migrations',
                    'Implement REST views with RBAC permissions',
                    'Write pytest test suite with >90% coverage',
                    'Generate OpenAPI schema & Swagger documentation',
                    'Submit PR for code review'
                ]
            },
            # 3. Operations Templates
            {
                'name': 'Physical Venue / Site Verification',
                'department': ops_dept,
                'default_priority': Task.Priority.HIGH,
                'description': 'On-site verification of partner property, amenities, and security.',
                'estimated_hours': 3.5,
                'checklist_template': [
                    'Take exterior and interior property photos',
                    'Inspect listed amenities and equipment',
                    'Verify seating capacity and parking space',
                    'Check safety standards & fire exit compliance',
                    'Verify owner identity documents against premises',
                    'Sign off verification checklist on mobile'
                ]
            },
            # 4. Accounts Templates
            {
                'name': 'Vendor Invoice & Payment Verification',
                'department': acc_dept,
                'default_priority': Task.Priority.HIGH,
                'description': 'Audit invoice against purchase order and initiate bank disbursement.',
                'estimated_hours': 1.5,
                'checklist_template': [
                    'Match invoice items with approved PO / Delivery Receipt',
                    'Verify GST calculations and TDS deduction',
                    'Verify bank account details with vendor master record',
                    'Obtain Finance Head digital approval',
                    'Process payout via banking gateway',
                    'Attach payment confirmation UTR slip'
                ]
            }
        ]

        created_count = 0
        for item in templates_data:
            obj, created = TaskTemplate.objects.update_or_create(
                name=item['name'],
                defaults={
                    'department': item['department'],
                    'default_priority': item['default_priority'],
                    'description': item['description'],
                    'estimated_hours': item['estimated_hours'],
                    'checklist_template': item['checklist_template'],
                    'is_active': True
                }
            )
            if created:
                created_count += 1

        self.stdout.write(self.style.SUCCESS(f'Successfully seeded {len(templates_data)} task templates ({created_count} new).'))
