import pytest
from django.utils import timezone
from datetime import timedelta
from rest_framework.test import APIClient
from django.contrib.auth import get_user_model
from apps.organization.models import Department, Position, Role
from apps.employees.models import Employee
from apps.marketing.models import Lead, Visit, FollowUp, PartnerOnboarding, MarketingTarget

User = get_user_model()


@pytest.mark.django_db
def test_marketing_lead_pipeline_and_activity():
    dept, _ = Department.objects.get_or_create(code='MKT_TEST', defaults={'name': 'Marketing Test'})
    pos, _ = Position.objects.get_or_create(department=dept, title='Field Executive', defaults={'code': 'FE-1'})
    role, _ = Role.objects.get_or_create(code='MARKETING_TEST', defaults={'name': 'Marketing Role'})

    user = User.objects.create_user(email='test.marketing@pcrm.local', employee_code='PBETEST01', password='Password@123!')
    Employee.objects.create(user=user, first_name='Test', last_name='Marketer', department=dept, position=pos, role=role)

    client = APIClient()
    client.force_authenticate(user=user)

    # 1. Create Lead
    payload = {
        'business_name': 'Grand Royal Banquet',
        'lead_type': 'venue',
        'contact_person': 'Suresh Kumar',
        'phone': '9876500000',
        'city': 'Kanpur',
        'area': 'Swaroop Nagar',
        'priority': 'high',
        'status': 'new',
    }
    res = client.post('/api/v1/marketing/leads/', payload, format='json')
    assert res.status_code == 201
    lead_id = res.data['id']
    assert res.data['lead_code'].startswith('PBL')

    # 2. Get Pipeline
    pipeline_res = client.get('/api/v1/marketing/leads/pipeline/')
    assert pipeline_res.status_code == 200
    assert 'new' in pipeline_res.data
    assert pipeline_res.data['new']['count'] >= 1

    # 3. Add Activity Note
    act_res = client.post(f'/api/v1/marketing/leads/{lead_id}/add-activity/', {'type': 'call', 'note': 'First call positive'}, format='json')
    assert act_res.status_code == 200
    assert len(act_res.data['activity_timeline']) >= 2

    # 4. Quick Status Change
    stat_res = client.post(f'/api/v1/marketing/leads/{lead_id}/quick-status/', {'status': 'interested'}, format='json')
    assert stat_res.status_code == 200
    assert stat_res.data['status'] == 'interested'


@pytest.mark.django_db
def test_marketing_visit_workflow_and_telemetry():
    dept, _ = Department.objects.get_or_create(code='MKT_TEST2', defaults={'name': 'Marketing Test 2'})
    pos, _ = Position.objects.get_or_create(department=dept, title='Field Executive', defaults={'code': 'FE-2'})
    role, _ = Role.objects.get_or_create(code='MARKETING_TEST2', defaults={'name': 'Marketing Role 2'})

    user = User.objects.create_user(email='test.visiting@pcrm.local', employee_code='PBETEST02', password='Password@123!')
    Employee.objects.create(user=user, first_name='Vis', last_name='Exec', department=dept, position=pos, role=role)

    lead = Lead.objects.create(
        business_name='Kuhu Bakery & Cafe',
        lead_type=Lead.LeadType.VENDOR,
        contact_person='Aman',
        phone='9876511111',
        status=Lead.LeadStatus.INTERESTED,
        assigned_to=user,
        created_by=user,
    )

    client = APIClient()
    client.force_authenticate(user=user)

    # 1. Schedule Visit
    now = timezone.now()
    visit_res = client.post('/api/v1/marketing/visits/', {
        'lead': str(lead.id),
        'partner_name': lead.business_name,
        'purpose': 'venue_onboarding',
        'scheduled_start': now.isoformat(),
        'location_name': 'Civil Lines, Kanpur',
    }, format='json')
    assert visit_res.status_code == 201
    visit_id = visit_res.data['id']

    # 2. Start Visit
    start_res = client.post(f'/api/v1/marketing/visits/{visit_id}/start-visit/', {
        'latitude': 26.4499,
        'longitude': 80.3319
    }, format='json')
    assert start_res.status_code == 200
    assert start_res.data['status'] == 'in_progress'

    # 3. Complete Visit with checklist and photos
    comp_res = client.post(f'/api/v1/marketing/visits/{visit_id}/complete-visit/', {
        'checklist': {'aadhaar': True, 'gst': True, 'photos': True},
        'photos': [{'category': 'exterior', 'url': 'http://storage.local/photo1.jpg'}],
        'partner_interest': 'high',
        'discussion_notes': 'Agreed on 10% commission model',
        'next_action': 'Send contract draft',
        'next_follow_up_date': (now + timedelta(days=1)).isoformat(),
    }, format='json')
    assert comp_res.status_code == 200
    assert comp_res.data['status'] == 'completed'

    # Auto follow-up should have been created
    assert FollowUp.objects.filter(lead=lead).exists()

    # 4. Check Telemetry
    tele_res = client.get('/api/v1/marketing/telemetry/')
    assert tele_res.status_code == 200
    assert tele_res.data['today']['visits_total'] >= 1
    assert tele_res.data['today']['visits_completed'] >= 1
    assert 'funnel' in tele_res.data
    assert 'conversion' in tele_res.data
