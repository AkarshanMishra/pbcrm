import uuid
from datetime import timedelta
from django.utils import timezone
from django.contrib.auth import get_user_model
from apps.operations.models import (
    BookingOperation, EventReadinessChecklist, OperationsIssue,
    QualityInspection, OperationalAsset, OperationsRequest,
    OperationsDailyReport
)

User = get_user_model()


def seed_operations_data():
    print("[SEED] Seeding Operations Hub initial data...")
    today = timezone.now().date()
    
    # Get or find user
    admin_user = User.objects.filter(is_superuser=True).first()
    if not admin_user:
        admin_user = User.objects.first()
    
    # Check if bookings already exist
    if BookingOperation.objects.exists():
        print("[INFO] Operations data already present, skipping.")
        return

    # 1. Seed Bookings
    b1 = BookingOperation.objects.create(
        booking_code='PB-10482',
        customer_name='Rohan Singhania',
        customer_phone='+91 98390 11223',
        customer_email='rohan.s@singhaniagroup.com',
        partner_name='ABC Grand Banquet & Lawn',
        partner_phone='+91 98390 44556',
        partner_type=BookingOperation.PartnerType.BANQUET,
        event_type=BookingOperation.EventType.WEDDING,
        event_date=today,
        event_time_slot='10:00 AM - 04:00 PM',
        guest_count=450,
        package_name='Royal Heritage Wedding & Catering Package',
        amount=385000.00,
        payment_status=BookingOperation.PaymentStatus.PARTIAL,
        partner_confirmation_status=BookingOperation.PartnerConfirmationStatus.CONFIRMED,
        operations_status=BookingOperation.OperationsStatus.READINESS_CHECK,
        readiness_percentage=80,
        special_instructions='VIP Entrance carpet required. Dedicated generator backup for DJ and stage.',
        venue_address='Plot 14, Civil Lines Main Road, Kanpur',
        assigned_executive=admin_user,
        manager=admin_user
    )

    b2 = BookingOperation.objects.create(
        booking_code='PB-10483',
        customer_name='Aarav Mehta',
        customer_phone='+91 94150 99881',
        customer_email='aarav.mehta@fintechcorp.in',
        partner_name='Kuhu Espresso Lounge',
        partner_phone='+91 94150 22334',
        partner_type=BookingOperation.PartnerType.CAFE,
        event_type=BookingOperation.EventType.CORPORATE,
        event_date=today,
        event_time_slot='12:00 PM - 03:00 PM',
        guest_count=35,
        package_name='Corporate High-Tea & Networking Package',
        amount=45000.00,
        payment_status=BookingOperation.PaymentStatus.PAID,
        partner_confirmation_status=BookingOperation.PartnerConfirmationStatus.CONFIRMED,
        operations_status=BookingOperation.OperationsStatus.ISSUE_REPORTED,
        readiness_percentage=50,
        special_instructions='Projector and wireless mic needed. Sound check at 11:30 AM.',
        venue_address='12/480 Swaroop Nagar, Kanpur',
        assigned_executive=admin_user,
        manager=admin_user
    )

    b3 = BookingOperation.objects.create(
        booking_code='PB-10484',
        customer_name='Sunita Aggarwal',
        customer_phone='+91 98890 33445',
        customer_email='sunita.aggarwal@gmail.com',
        partner_name='The Landmark Hotel Ballroom',
        partner_phone='+91 98890 77889',
        partner_type=BookingOperation.PartnerType.RESORT,
        event_type=BookingOperation.EventType.BIRTHDAY,
        event_date=today,
        event_time_slot='02:00 PM - 07:00 PM',
        guest_count=120,
        package_name='Silver Jubilee Celebrations Package',
        amount=125000.00,
        payment_status=BookingOperation.PaymentStatus.PAID,
        partner_confirmation_status=BookingOperation.PartnerConfirmationStatus.CONFIRMED,
        operations_status=BookingOperation.OperationsStatus.COORDINATION,
        readiness_percentage=90,
        special_instructions='Pastel floral theme. Customized cake table with spot lighting.',
        venue_address='The Landmark Towers, The Mall, Kanpur',
        assigned_executive=admin_user,
        manager=admin_user
    )

    b4 = BookingOperation.objects.create(
        booking_code='PB-10485',
        customer_name='Dr. Vikram Malhotra',
        customer_phone='+91 97930 55667',
        customer_email='dr.vikram@medilabs.org',
        partner_name='Regenta Central Krishna',
        partner_phone='+91 97930 11229',
        partner_type=BookingOperation.PartnerType.RESORT,
        event_type=BookingOperation.EventType.SEMINAR,
        event_date=today + timedelta(days=1),
        event_time_slot='09:00 AM - 05:00 PM',
        guest_count=80,
        package_name='Annual Medical Conference Package',
        amount=95000.00,
        payment_status=BookingOperation.PaymentStatus.PARTIAL,
        partner_confirmation_status=BookingOperation.PartnerConfirmationStatus.CONFIRMED,
        operations_status=BookingOperation.OperationsStatus.PREPARATION_PENDING,
        readiness_percentage=60,
        special_instructions='L-shaped podium setup, recording audio feed from PA system.',
        venue_address='GT Road, Shivrajpur Bypass, Kanpur',
        assigned_executive=admin_user,
        manager=admin_user
    )

    # 2. Seed Checklists
    EventReadinessChecklist.objects.create(
        booking=b1,
        hall_confirmed=True,
        seating_confirmed=True,
        decoration_confirmed=True,
        catering_confirmed=True,
        parking_confirmed=True,
        setup_confirmed=True,
        staff_confirmed=False,
        power_backup_confirmed=False,
        notes='Staff arriving at 09:30 AM. Generator connection being tested.',
        verified_by=admin_user,
        verified_at=timezone.now()
    )

    EventReadinessChecklist.objects.create(
        booking=b2,
        hall_confirmed=True,
        seating_confirmed=True,
        decoration_confirmed=False,
        catering_confirmed=True,
        parking_confirmed=False,
        setup_confirmed=False,
        staff_confirmed=False,
        power_backup_confirmed=False,
        notes='Audio mixer cord faulty. Replacement requested from warehouse.',
        verified_by=admin_user,
        verified_at=timezone.now()
    )

    EventReadinessChecklist.objects.create(
        booking=b3,
        hall_confirmed=True,
        seating_confirmed=True,
        decoration_confirmed=True,
        catering_confirmed=True,
        parking_confirmed=True,
        setup_confirmed=True,
        staff_confirmed=True,
        power_backup_confirmed=False,
        notes='All items verified except backup switch.',
        verified_by=admin_user,
        verified_at=timezone.now()
    )

    # 3. Seed Operations Issues & SLA
    OperationsIssue.objects.create(
        issue_code='OP-2481',
        category=OperationsIssue.IssueCategory.EQUIPMENT_FAILURE,
        priority=OperationsIssue.Priority.CRITICAL,
        booking=b2,
        problem_statement='Booking PB-10483 audio mixer output distortion and missing HDMI adapter for corporate presentation.',
        assigned_to=admin_user,
        reported_by=admin_user,
        sla_hours=2,
        sla_deadline=timezone.now() + timedelta(hours=1, minutes=45),
        status=OperationsIssue.Status.IN_PROGRESS,
        escalation_level=OperationsIssue.EscalationLevel.EXECUTIVE
    )

    OperationsIssue.objects.create(
        issue_code='OP-2482',
        category=OperationsIssue.IssueCategory.VENUE_DEFECT,
        priority=OperationsIssue.Priority.HIGH,
        booking=b1,
        problem_statement='Missing venue directional signage and valet parking barricades at ABC Grand Banquet.',
        assigned_to=admin_user,
        reported_by=admin_user,
        sla_hours=4,
        sla_deadline=timezone.now() + timedelta(hours=3),
        status=OperationsIssue.Status.ASSIGNED,
        escalation_level=OperationsIssue.EscalationLevel.EXECUTIVE
    )

    OperationsIssue.objects.create(
        issue_code='OP-2483',
        category=OperationsIssue.IssueCategory.PARTNER_DELAY,
        priority=OperationsIssue.Priority.MEDIUM,
        booking=b4,
        problem_statement='Pending partner menu confirmation for medical conference breakfast session.',
        assigned_to=admin_user,
        reported_by=admin_user,
        sla_hours=6,
        sla_deadline=timezone.now() + timedelta(hours=5),
        status=OperationsIssue.Status.OPEN,
        escalation_level=OperationsIssue.EscalationLevel.EXECUTIVE
    )

    # 4. Seed Quality Inspections
    QualityInspection.objects.create(
        inspection_code='QC-9012',
        partner_name='ABC Grand Banquet & Lawn',
        booking=b1,
        inspector=admin_user,
        inspection_date=today,
        result=QualityInspection.InspectionResult.PASS,
        score=95,
        checklist_data={
            'cleanliness': 'Clean and sanitized',
            'hygiene_audit': 'FSSAI compliant kitchen',
            'staff_uniform': 'All staff in formal PCRM apron/suits',
            'safety': 'Fire extinguishers functional'
        },
        photos=['https://images.unsplash.com/photo-1519167758481-83f550bb49b3'],
        notes='Exceptional ballroom presentation. Kitchen staff passed hygiene inspection.'
    )

    QualityInspection.objects.create(
        inspection_code='QC-9013',
        partner_name='Kuhu Espresso Lounge',
        booking=b2,
        inspector=admin_user,
        inspection_date=today,
        result=QualityInspection.InspectionResult.PASS_WITH_ISSUES,
        score=78,
        checklist_data={
            'cleanliness': 'Good',
            'av_setup': 'Audio mixer cable needs urgent replacement',
            'ac_cooling': 'AC-2 thermostat check needed'
        },
        photos=['https://images.unsplash.com/photo-1554118811-1e0d58224f24'],
        notes='Audio setup has minor hum. Replacement dispatch initiated.'
    )

    # 5. Seed Operational Assets
    OperationalAsset.objects.create(
        asset_code='AST-401',
        name='Sennheiser Wireless Dual Mic Kit',
        category=OperationalAsset.Category.AUDIO_VISUAL,
        status=OperationalAsset.Status.IN_USE,
        condition=OperationalAsset.Condition.EXCELLENT,
        assigned_to=admin_user,
        current_booking=b1,
        location='ABC Grand Banquet',
        serial_number='SN-SENN-8892',
        last_inspected_at=timezone.now()
    )

    OperationalAsset.objects.create(
        asset_code='AST-402',
        name='PA Sound Mixer 16-Channel Yamaha',
        category=OperationalAsset.Category.AUDIO_VISUAL,
        status=OperationalAsset.Status.AVAILABLE,
        condition=OperationalAsset.Condition.EXCELLENT,
        location='Central Operations Warehouse',
        serial_number='SN-YAM-4410',
        last_inspected_at=timezone.now()
    )

    OperationalAsset.objects.create(
        asset_code='AST-403',
        name='Sunmi V2 PRO POS Smart Billing Terminal',
        category=OperationalAsset.Category.POS_DEVICE,
        status=OperationalAsset.Status.IN_USE,
        condition=OperationalAsset.Condition.GOOD,
        assigned_to=admin_user,
        current_booking=b2,
        location='Kuhu Espresso Lounge',
        serial_number='POS-SN-9021',
        last_inspected_at=timezone.now()
    )

    OperationalAsset.objects.create(
        asset_code='AST-404',
        name='Heavy Duty Velvet Stanchion Rope & Barrier Set (10 Pcs)',
        category=OperationalAsset.Category.DECOR_PROP,
        status=OperationalAsset.Status.AVAILABLE,
        condition=OperationalAsset.Condition.EXCELLENT,
        location='Central Operations Warehouse',
        serial_number='BAR-V-10X',
        last_inspected_at=timezone.now()
    )

    # 6. Seed Operations Requests
    OperationsRequest.objects.create(
        request_code='REQ-8821',
        request_type=OperationsRequest.RequestType.ADDITIONAL_STAFF,
        title='2 Extra Service Ushers for ABC Grand Banquet Wedding',
        description='Guest RSVP increased from 350 to 450. Requesting 2 additional field coordinators for parking and guest reception.',
        amount=3000.00,
        status=OperationsRequest.Status.APPROVED,
        requester=admin_user,
        approved_by=admin_user,
        approval_notes='Approved. Coordinating with temp staffing vendor.'
    )

    OperationsRequest.objects.create(
        request_code='REQ-8822',
        request_type=OperationsRequest.RequestType.EQUIPMENT_REQUISITION,
        title='Spare 4K Projector for Landmark Ballroom Seminar',
        description='Client requested dual screen projection for interactive medical diagnostics demo.',
        amount=5500.00,
        status=OperationsRequest.Status.REVIEW,
        requester=admin_user
    )

    # 7. Seed Daily Report
    OperationsDailyReport.objects.create(
        executive=admin_user,
        report_date=today,
        tasks_completed_count=6,
        bookings_handled_count=3,
        issues_resolved_count=2,
        followups_count=8,
        visits_count=2,
        quality_checks_count=2,
        summary_notes='Completed morning service inspection at ABC Grand Banquet and resolved audio connector issue at Kuhu Espresso. All 3 events running on schedule.',
        challenges='Heavy traffic near Civil Lines slowed transport of reserve audio gear by 20 minutes.',
        tomorrow_plan='Attend Regenta Central medical conference setup by 08:00 AM and conduct pre-event QC check.',
        status=OperationsDailyReport.Status.SUBMITTED
    )

    print("[SUCCESS] Successfully seeded Operations data!")
