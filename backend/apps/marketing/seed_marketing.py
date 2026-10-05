import os
import sys
import django
from django.utils import timezone
from datetime import timedelta

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, BASE_DIR)

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
os.environ.setdefault('DB_ENGINE', 'sqlite')
django.setup()

from django.contrib.auth import get_user_model
from apps.organization.models import Department, Position, Role
from apps.marketing.models import Lead, Visit, FollowUp, PartnerOnboarding, MarketingTarget

User = get_user_model()

# Ensure Marketing Department & Positions exist
mkt_dept, _ = Department.objects.get_or_create(
    code='MKT',
    defaults={'name': 'Marketing & Field Operations', 'description': 'Field marketing, vendor acquisition & partner onboarding'}
)

mkt_pos, _ = Position.objects.get_or_create(
    department=mkt_dept,
    title='Marketing Executive',
    defaults={'code': 'MKT-EXEC', 'description': 'Field sales & partner acquisition'}
)

mkt_mgr_pos, _ = Position.objects.get_or_create(
    department=mkt_dept,
    title='Marketing Manager',
    defaults={'code': 'MKT-MGR', 'description': 'Marketing department leader'}
)

# Marketing Role
mkt_role, _ = Role.objects.get_or_create(
    code=Role.RoleCode.MARKETING,
    defaults={'name': 'Marketing & Field Operations', 'description': 'Marketing workforce & Field executives'}
)

# Marketing Executive User: Rahul Sharma
rahul, _ = User.objects.get_or_create(
    employee_code='PBE000003',
    defaults={
        'email': 'dev.rahul@pcrm.local',
        'phone': '9876543210',
        'is_active': True,
    }
)
rahul.set_password('12345678')
rahul.save()

from apps.employees.models import Employee

Employee.objects.update_or_create(
    user=rahul,
    defaults={
        'first_name': 'Rahul',
        'last_name': 'Sharma',
        'department': mkt_dept,
        'position': mkt_pos,
        'role': mkt_role,
        'hire_date': timezone.now().date(),
    }
)

# Marketing Manager User: Neha Kapoor
neha, _ = User.objects.get_or_create(
    employee_code='PBE000002',
    defaults={
        'email': 'lead.dev@pcrm.local',
        'phone': '9876543211',
        'is_active': True,
    }
)
neha.set_password('12345678')
neha.save()

Employee.objects.update_or_create(
    user=neha,
    defaults={
        'first_name': 'Neha',
        'last_name': 'Kapoor',
        'department': mkt_dept,
        'position': mkt_mgr_pos,
        'role': mkt_role,
        'hire_date': timezone.now().date(),
    }
)

# Target for October 2026
MarketingTarget.objects.get_or_create(
    employee=rahul,
    month='2026-10',
    defaults={
        'target_visits': 10,
        'completed_visits': 7,
        'target_followups': 10,
        'completed_followups': 8,
        'target_leads': 10,
        'completed_leads': 5,
        'target_onboardings': 4,
        'completed_onboardings': 2,
    }
)

# Seed Leads
lead1, _ = Lead.objects.get_or_create(
    business_name='ABC Banquet & Resort',
    defaults={
        'lead_type': Lead.LeadType.VENUE,
        'contact_person': 'Rahul Sharma (Owner)',
        'phone': '9988776655',
        'email': 'contact@abcbanquet.com',
        'city': 'Kanpur',
        'area': 'Civil Lines',
        'address': 'Plot 45, Mall Road, Civil Lines, Kanpur',
        'status': Lead.LeadStatus.INTERESTED,
        'priority': Lead.Priority.HIGH,
        'interest_level': Lead.InterestLevel.HIGH,
        'assigned_to': rahul,
        'created_by': rahul,
        'estimated_deal_value': 150000.00,
        'next_follow_up_at': timezone.now() + timedelta(hours=2),
        'notes': 'Large venue with 2 banquet halls (500 pax capacity). Very eager for online bookings.',
        'activity_timeline': [
            {'type': 'lead_created', 'timestamp': (timezone.now() - timedelta(days=2)).isoformat(), 'by': 'Rahul Sharma', 'note': 'Lead created via field scouting'},
            {'type': 'call', 'timestamp': (timezone.now() - timedelta(days=1)).isoformat(), 'by': 'Rahul Sharma', 'note': 'Spoke with owner, scheduled onboarding visit.'},
        ]
    }
)

lead2, _ = Lead.objects.get_or_create(
    business_name='Kuhu Espresso & Cafe',
    defaults={
        'lead_type': Lead.LeadType.VENDOR,
        'contact_person': 'Aman Gupta',
        'phone': '9811223344',
        'email': 'aman@kuhuespresso.in',
        'city': 'Kanpur',
        'area': 'Swaroop Nagar',
        'address': 'Shop 12, Main Market, Swaroop Nagar',
        'status': Lead.LeadStatus.VISITED,
        'priority': Lead.Priority.MEDIUM,
        'interest_level': Lead.InterestLevel.HIGH,
        'assigned_to': rahul,
        'created_by': rahul,
        'estimated_deal_value': 45000.00,
        'next_follow_up_at': timezone.now() + timedelta(days=1),
        'notes': 'Premium beverage & espresso live stall caterer for weddings and corporate parties.',
        'activity_timeline': [
            {'type': 'lead_created', 'timestamp': (timezone.now() - timedelta(days=3)).isoformat(), 'by': 'Rahul Sharma', 'note': 'Lead identified'},
            {'type': 'visit_completed', 'timestamp': (timezone.now() - timedelta(days=1)).isoformat(), 'by': 'Rahul Sharma', 'note': 'Site visit complete. Menu samples received.'},
        ]
    }
)

lead3, _ = Lead.objects.get_or_create(
    business_name='XYZ Grand Convention',
    defaults={
        'lead_type': Lead.LeadType.VENUE,
        'contact_person': 'Vikram Mehra',
        'phone': '9123456780',
        'email': 'vikram@xyzgrand.com',
        'city': 'Kanpur',
        'area': 'Kakadeo',
        'address': 'Near Metro Pillar 18, Kakadeo',
        'status': Lead.LeadStatus.NEW,
        'priority': Lead.Priority.URGENT,
        'interest_level': Lead.InterestLevel.UNDECIDED,
        'assigned_to': rahul,
        'created_by': rahul,
        'estimated_deal_value': 220000.00,
        'next_follow_up_at': timezone.now() + timedelta(hours=4),
        'notes': 'New multi-purpose convention hall opening next month. Requires complete onboarding.',
        'activity_timeline': [
            {'type': 'lead_created', 'timestamp': timezone.now().isoformat(), 'by': 'Rahul Sharma', 'note': 'New inbound referral lead'},
        ]
    }
)

# Today's Visits for Rahul
now = timezone.now()
today_10am = now.replace(hour=10, minute=0, second=0, microsecond=0)
today_12pm = now.replace(hour=12, minute=30, second=0, microsecond=0)
today_4pm = now.replace(hour=16, minute=0, second=0, microsecond=0)

Visit.objects.get_or_create(
    partner_name='ABC Banquet & Resort',
    scheduled_start=today_10am,
    defaults={
        'lead': lead1,
        'purpose': Visit.VisitPurpose.VENUE_ONBOARDING,
        'assigned_employee': rahul,
        'status': Visit.VisitStatus.SCHEDULED,
        'location_name': 'Mall Road, Civil Lines, Kanpur',
        'partner_interest': 'high',
        'checklist': {
            'owner_details': True,
            'aadhaar': True,
            'pan': True,
            'gst': False,
            'exterior_photos': False,
            'interior_photos': False,
            'amenities': ['AC', 'Wi-Fi', 'Parking', 'Power Backup'],
        },
        'photos': [],
        'discussion_notes': 'Collect property photos, GST certificate, and agree on package pricing.',
    }
)

Visit.objects.get_or_create(
    partner_name='Kuhu Espresso & Cafe',
    scheduled_start=today_12pm,
    defaults={
        'lead': lead2,
        'purpose': Visit.VisitPurpose.VENDOR_MEETING,
        'assigned_employee': rahul,
        'status': Visit.VisitStatus.SCHEDULED,
        'location_name': 'Swaroop Nagar, Kanpur',
        'partner_interest': 'high',
        'checklist': {
            'owner_details': True,
            'aadhaar': True,
            'pan': True,
            'gst': True,
        },
        'photos': [],
        'discussion_notes': 'Verify beverage pricing card and package commissions.',
    }
)

Visit.objects.get_or_create(
    partner_name='XYZ Grand Convention',
    scheduled_start=today_4pm,
    defaults={
        'lead': lead3,
        'purpose': Visit.VisitPurpose.LEAD_FOLLOWUP,
        'assigned_employee': rahul,
        'status': Visit.VisitStatus.SCHEDULED,
        'location_name': 'Kakadeo, Kanpur',
        'partner_interest': 'medium',
        'discussion_notes': 'Initial meetup with Vikram Mehra regarding launching on PartyBala platform.',
    }
)

# Follow-ups
FollowUp.objects.get_or_create(
    lead=lead1,
    scheduled_at=now + timedelta(hours=1),
    defaults={
        'employee': rahul,
        'type': FollowUp.FollowUpType.CALL,
        'status': FollowUp.FollowUpStatus.PENDING,
        'notes': 'Confirm arrival time with owner Rahul Sharma before heading to Mall Road.',
    }
)

FollowUp.objects.get_or_create(
    lead=lead2,
    scheduled_at=now + timedelta(hours=3),
    defaults={
        'employee': rahul,
        'type': FollowUp.FollowUpType.WHATSAPP,
        'status': FollowUp.FollowUpStatus.PENDING,
        'notes': 'Send PartyBala standard vendor agreement draft PDF via WhatsApp.',
    }
)

# Partner Onboarding Entry for ABC Banquet
PartnerOnboarding.objects.get_or_create(
    partner_name='ABC Banquet & Resort',
    defaults={
        'lead': lead1,
        'partner_type': PartnerOnboarding.PartnerType.VENUE,
        'assigned_executive': rahul,
        'workflow_step': PartnerOnboarding.WorkflowStep.DOCUMENTS,
        'status': PartnerOnboarding.OnboardingStatus.DRAFT,
        'progress_percentage': 35,
        'info_data': {
            'owner_name': 'Rahul Sharma',
            'contact_phone': '9988776655',
            'capacity_indoor': 500,
            'capacity_outdoor': 300,
            'city': 'Kanpur',
            'area': 'Civil Lines',
        },
        'documents_data': {
            'pan_card': 'ABCDE1234F',
            'gst_number': '09ABCDE1234F1Z5',
        },
        'amenities_data': ['AC Banquet Hall', 'Valet Parking', 'Power Backup Generator', 'Bridal Dressing Rooms', 'Wi-Fi'],
        'packages_data': [
            {'name': 'Silver Package (Veg Only)', 'price_per_plate': 1200},
            {'name': 'Gold Royal Package (Veg + Non-Veg + Live Stalls)', 'price_per_plate': 1850},
        ],
    }
)

print("Marketing seed data loaded successfully!")
