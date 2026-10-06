import '../../models/auth_user.dart';

class OfflineFallbackData {
  // ==========================================
  // PRESET DEMO PERSONAS FOR 1-TAP OFFLINE LOGIN
  // ==========================================
  static final AuthUser adminUser = AuthUser(
    id: 'pbe-admin-001',
    employeeCode: 'PBE000001',
    email: 'admin@partybala.com',
    name: 'System Admin (Executive)',
    status: 'ACTIVE',
    isMfaEnabled: false,
    isAdmin: true,
    isManager: true,
    role: 'SUPER_ADMIN',
    department: 'EXECUTIVE',
    position: 'Chief Operating Officer',
    permissions: ['*'],
  );

  static final AuthUser marketingManagerUser = AuthUser(
    id: 'pbe-mkt-001',
    employeeCode: 'PBE000003',
    email: 'rahul.mkt@partybala.com',
    name: 'Rahul Sharma (Marketing Mgr)',
    status: 'ACTIVE',
    isMfaEnabled: false,
    isAdmin: false,
    isManager: true,
    role: 'MARKETING_MANAGER',
    department: 'MARKETING',
    position: 'Head of Growth & Partnerships',
    permissions: ['MARKETING_READ', 'MARKETING_WRITE', 'MARKETING_APPROVE'],
  );

  static final AuthUser marketingExecutiveUser = AuthUser(
    id: 'pbe-mkt-002',
    employeeCode: 'PBE000007',
    email: 'amit.mkt@partybala.com',
    name: 'Amit Verma (Field Growth)',
    status: 'ACTIVE',
    isMfaEnabled: false,
    isAdmin: false,
    isManager: false,
    role: 'MARKETING_EXECUTIVE',
    department: 'MARKETING',
    position: 'Field Acquisition Executive',
    permissions: ['MARKETING_READ', 'MARKETING_WRITE'],
  );

  static final AuthUser operationsManagerUser = AuthUser(
    id: 'pbe-ops-001',
    employeeCode: 'PBE000004',
    email: 'priya.ops@partybala.com',
    name: 'Priya Patel (Operations Mgr)',
    status: 'ACTIVE',
    isMfaEnabled: false,
    isAdmin: false,
    isManager: true,
    role: 'OPERATIONS_MANAGER',
    department: 'OPERATIONS',
    position: 'VP of Event Operations',
    permissions: ['OPERATIONS_READ', 'OPERATIONS_WRITE', 'OPERATIONS_APPROVE'],
  );

  static final AuthUser operationsExecutiveUser = AuthUser(
    id: 'pbe-ops-002',
    employeeCode: 'PBE000008',
    email: 'rohan.ops@partybala.com',
    name: 'Rohan Joshi (Ops Lead)',
    status: 'ACTIVE',
    isMfaEnabled: false,
    isAdmin: false,
    isManager: false,
    role: 'OPERATIONS_EXECUTIVE',
    department: 'OPERATIONS',
    position: 'Field Event Coordinator',
    permissions: ['OPERATIONS_READ', 'OPERATIONS_WRITE'],
  );

  static final AuthUser itManagerUser = AuthUser(
    id: 'pbe-it-001',
    employeeCode: 'PBE000002',
    email: 'akarshan.it@partybala.com',
    name: 'Akarshan Mishra (IT Lead)',
    status: 'ACTIVE',
    isMfaEnabled: false,
    isAdmin: false,
    isManager: true,
    role: 'IT_MANAGER',
    department: 'IT',
    position: 'Chief Technology & Systems Lead',
    permissions: ['IT_READ', 'IT_WRITE', 'IT_ADMIN'],
  );

  static final AuthUser hrManagerUser = AuthUser(
    id: 'pbe-hr-001',
    employeeCode: 'PBE000005',
    email: 'anita.hr@partybala.com',
    name: 'Anita Roy (People Lead)',
    status: 'ACTIVE',
    isMfaEnabled: false,
    isAdmin: false,
    isManager: true,
    role: 'HR_MANAGER',
    department: 'HUMAN RESOURCES',
    position: 'Director of People Operations',
    permissions: ['HR_READ', 'HR_WRITE', 'HR_APPROVE'],
  );

  static final AuthUser staffUser = AuthUser(
    id: 'pbe-emp-001',
    employeeCode: 'PBE000006',
    email: 'suresh.emp@partybala.com',
    name: 'Suresh Kumar (Operations)',
    status: 'ACTIVE',
    isMfaEnabled: false,
    isAdmin: false,
    isManager: false,
    role: 'STAFF',
    department: 'OPERATIONS',
    position: 'Event Coordinator',
    permissions: ['EMPLOYEE_READ', 'EMPLOYEE_WRITE'],
  );

  static List<AuthUser> get allDemoUsers => [
    adminUser,
    marketingManagerUser,
    marketingExecutiveUser,
    operationsManagerUser,
    operationsExecutiveUser,
    itManagerUser,
    hrManagerUser,
    staffUser,
  ];

  static AuthUser findMatchingDemoUser(String identifier) {
    final clean = identifier.trim().toLowerCase();
    if (clean.contains('admin') || clean == 'pbe000001') return adminUser;
    if (clean.contains('rahul') || clean.contains('mkt.mgr') || clean == 'pbe000003') return marketingManagerUser;
    if (clean.contains('amit') || clean.contains('mkt') || clean.contains('marketing') || clean == 'pbe000007') return marketingExecutiveUser;
    if (clean.contains('priya') || clean.contains('ops.mgr') || clean == 'pbe000004') return operationsManagerUser;
    if (clean.contains('rohan') || clean.contains('ops') || clean.contains('operations') || clean == 'pbe000008') return operationsExecutiveUser;
    if (clean.contains('akarshan') || clean.contains('it') || clean.contains('tech') || clean.contains('dev') || clean == 'pbe000002') return itManagerUser;
    if (clean.contains('anita') || clean.contains('hr') || clean.contains('people') || clean == 'pbe000005') return hrManagerUser;
    return staffUser;
  }

  // ==========================================
  // FALLBACK EMPLOYEES
  // ==========================================
  static List<Map<String, dynamic>> get fallbackEmployees => [
    {
      'id': 'pbe-admin-001',
      'employee_code': 'PBE000001',
      'first_name': 'System',
      'last_name': 'Admin',
      'email': 'admin@partybala.com',
      'phone_number': '+91 98100 11000',
      'department': 'EXECUTIVE',
      'position': 'Chief Operating Officer',
      'role': 'SUPER_ADMIN',
      'status': 'ACTIVE',
      'is_staff': true,
      'is_admin': true,
      'date_of_joining': '2024-01-01',
    },
    {
      'id': 'pbe-it-001',
      'employee_code': 'PBE000002',
      'first_name': 'Akarshan',
      'last_name': 'Mishra',
      'email': 'akarshan.it@partybala.com',
      'phone_number': '+91 98765 43210',
      'department': 'IT',
      'position': 'Chief Technology Lead',
      'role': 'IT_MANAGER',
      'status': 'ACTIVE',
      'is_staff': true,
      'date_of_joining': '2024-02-01',
    },
    {
      'id': 'pbe-mkt-001',
      'employee_code': 'PBE000003',
      'first_name': 'Rahul',
      'last_name': 'Sharma',
      'email': 'rahul.mkt@partybala.com',
      'phone_number': '+91 98234 56789',
      'department': 'MARKETING',
      'position': 'Head of Growth & Partnerships',
      'role': 'MARKETING_MANAGER',
      'status': 'ACTIVE',
      'is_staff': true,
      'date_of_joining': '2024-03-15',
    },
    {
      'id': 'pbe-ops-001',
      'employee_code': 'PBE000004',
      'first_name': 'Priya',
      'last_name': 'Patel',
      'email': 'priya.ops@partybala.com',
      'phone_number': '+91 98345 67890',
      'department': 'OPERATIONS',
      'position': 'VP of Event Operations',
      'role': 'OPERATIONS_MANAGER',
      'status': 'ACTIVE',
      'is_staff': true,
      'date_of_joining': '2024-04-10',
    },
    {
      'id': 'pbe-hr-001',
      'employee_code': 'PBE000005',
      'first_name': 'Anita',
      'last_name': 'Roy',
      'email': 'anita.hr@partybala.com',
      'phone_number': '+91 98456 78901',
      'department': 'HUMAN RESOURCES',
      'position': 'Director of People Operations',
      'role': 'HR_MANAGER',
      'status': 'ACTIVE',
      'is_staff': true,
      'date_of_joining': '2024-05-01',
    },
    {
      'id': 'pbe-emp-001',
      'employee_code': 'PBE000006',
      'first_name': 'Suresh',
      'last_name': 'Kumar',
      'email': 'suresh.emp@partybala.com',
      'phone_number': '+91 98567 89012',
      'department': 'OPERATIONS',
      'position': 'Event Coordinator',
      'role': 'STAFF',
      'status': 'ACTIVE',
      'is_staff': false,
      'date_of_joining': '2024-06-15',
    },
    {
      'id': 'pbe-mkt-002',
      'employee_code': 'PBE000007',
      'first_name': 'Amit',
      'last_name': 'Verma',
      'email': 'amit.mkt@partybala.com',
      'phone_number': '+91 98678 90123',
      'department': 'MARKETING',
      'position': 'Field Acquisition Executive',
      'role': 'MARKETING_EXECUTIVE',
      'status': 'ACTIVE',
      'is_staff': false,
      'date_of_joining': '2024-07-01',
    },
    {
      'id': 'pbe-ops-002',
      'employee_code': 'PBE000008',
      'first_name': 'Rohan',
      'last_name': 'Joshi',
      'email': 'rohan.ops@partybala.com',
      'phone_number': '+91 98789 01234',
      'department': 'OPERATIONS',
      'position': 'Field Event Coordinator',
      'role': 'OPERATIONS_EXECUTIVE',
      'status': 'ACTIVE',
      'is_staff': false,
      'date_of_joining': '2024-08-10',
    },
  ];

  // ==========================================
  // FALLBACK TASKS
  // ==========================================
  static List<Map<String, dynamic>> get fallbackTasks => [
    {
      'id': 'task-offline-001',
      'title': 'Grand Ballroom Sound & Lighting QC Inspection',
      'description': 'Conduct 20-point audio-visual checklist before the 500-guest Royal Wedding reception.',
      'priority': 'URGENT',
      'status': 'IN_PROGRESS',
      'due_date': DateTime.now().toIso8601String().substring(0, 10),
      'department': 'OPERATIONS',
      'assigned_to_name': 'Priya Patel',
      'progress_percent': 65,
    },
    {
      'id': 'task-offline-002',
      'title': 'Deploy Offline Sync Engine v2.4 Hotfix',
      'description': 'Verify bidirectional local cache and conflict resolution on weak 4G networks.',
      'priority': 'HIGH',
      'status': 'IN_PROGRESS',
      'due_date': DateTime.now().toIso8601String().substring(0, 10),
      'department': 'IT',
      'assigned_to_name': 'Akarshan Mishra',
      'progress_percent': 85,
    },
    {
      'id': 'task-offline-003',
      'title': 'Taj Vivanta Partnership Quotation & Contract Review',
      'description': 'Review 15% revenue share clause and complete KYC document verification.',
      'priority': 'HIGH',
      'status': 'ASSIGNED',
      'due_date': DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10),
      'department': 'MARKETING',
      'assigned_to_name': 'Rahul Sharma',
      'progress_percent': 30,
    },
    {
      'id': 'task-offline-004',
      'title': 'Q4 High-Performer Incentive & Appraisal Audit',
      'description': 'Process quarterly rewards for field marketing and operations stars.',
      'priority': 'MEDIUM',
      'status': 'ASSIGNED',
      'due_date': DateTime.now().add(const Duration(days: 3)).toIso8601String().substring(0, 10),
      'department': 'HUMAN RESOURCES',
      'assigned_to_name': 'Anita Roy',
      'progress_percent': 10,
    },
    {
      'id': 'task-offline-005',
      'title': 'Heritage Palace Outdoor Lawn Power Backup Setup',
      'description': 'Emergency generator testing with dual 125kVA sync panels.',
      'priority': 'URGENT',
      'status': 'BLOCKED',
      'due_date': DateTime.now().toIso8601String().substring(0, 10),
      'department': 'OPERATIONS',
      'assigned_to_name': 'Rohan Joshi',
      'progress_percent': 40,
    },
    {
      'id': 'task-offline-006',
      'title': 'Monthly ISO 27001 Security Audit Log Review',
      'description': 'Review all role escalation events and sensitive permission grants.',
      'priority': 'MEDIUM',
      'status': 'COMPLETED',
      'due_date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10),
      'department': 'IT',
      'assigned_to_name': 'Akarshan Mishra',
      'progress_percent': 100,
    },
  ];

  // ==========================================
  // FALLBACK LEADS & CRM PIPELINE
  // ==========================================
  static List<Map<String, dynamic>> get fallbackLeads => [
    {
      'id': 'lead-off-001',
      'name': 'Adani Global Leadership Gala 2026',
      'contact_name': 'Vikram Mehta',
      'phone': '+91 98200 44556',
      'email': 'vmehta@adani.com',
      'stage': 'NEGOTIATION',
      'score': 94,
      'estimated_budget': '₹18,50,000',
      'guests': 450,
      'date': '2026-11-20',
      'venue_preference': 'Grand Horizon Luxury Ballroom',
      'assigned_to': 'Rahul Sharma',
    },
    {
      'id': 'lead-off-002',
      'name': 'Singhania & Kapoor Destination Wedding',
      'contact_name': 'Sunita Singhania',
      'phone': '+91 99112 33445',
      'email': 'sunita@singhania.org',
      'stage': 'PROPOSAL_SENT',
      'score': 88,
      'estimated_budget': '₹34,00,000',
      'guests': 600,
      'date': '2026-12-14',
      'venue_preference': 'The Imperial Palace & Royal Lawn',
      'assigned_to': 'Amit Verma',
    },
    {
      'id': 'lead-off-003',
      'name': 'Google Cloud Developers Summit Delhi',
      'contact_name': 'Pooja Iyer',
      'phone': '+91 97170 88990',
      'email': 'pooja.i@google.com',
      'stage': 'QUALIFIED',
      'score': 96,
      'estimated_budget': '₹22,00,000',
      'guests': 350,
      'date': '2026-11-05',
      'venue_preference': 'Metropolitan Convention Center',
      'assigned_to': 'Rahul Sharma',
    },
  ];

  // ==========================================
  // FALLBACK VENUES & SPACES
  // ==========================================
  static List<Map<String, dynamic>> get fallbackVenues => [
    {
      'id': 'venue-off-001',
      'code': 'PBV-00892',
      'name': 'The Royal Grandeur Palace & Lawns',
      'category': 'Luxury Heritage Estate',
      'location': 'MG Road, South Delhi',
      'spaces_count': 4,
      'spaces': [
        {'name': 'Imperial Crystal Ballroom', 'sqft': 12000, 'banquet_cap': 600, 'floating_cap': 1000, 'tariff': '₹3,50,000'},
        {'name': 'Mughal Royal Lawns', 'sqft': 25000, 'banquet_cap': 1200, 'floating_cap': 2000, 'tariff': '₹5,00,000'},
        {'name': 'Sunset Rooftop Lounge', 'sqft': 6000, 'banquet_cap': 200, 'floating_cap': 350, 'tariff': '₹1,75,000'},
        {'name': 'Poolside Oasis Deck', 'sqft': 4500, 'banquet_cap': 150, 'floating_cap': 250, 'tariff': '₹1,20,000'},
      ],
      'rating': 4.9,
      'reviews_count': 142,
      'status': 'ACTIVE',
      'kyc_status': 'VERIFIED',
      'amenities': ['Central AC', 'Valet (150 cars)', 'Bridal Suite', '300kVA DG', 'DJ Sound 10pm', 'In-house Chef'],
    },
    {
      'id': 'venue-off-002',
      'code': 'PBV-00431',
      'name': 'Novotel Skyview Convention Suites',
      'category': '5-Star Corporate Arena',
      'location': 'Aerocity, New Delhi',
      'spaces_count': 3,
      'spaces': [
        {'name': 'Summit Plenary Hall', 'sqft': 9500, 'banquet_cap': 450, 'floating_cap': 800, 'tariff': '₹2,80,000'},
        {'name': 'Executive Boardroom Pavilion', 'sqft': 3200, 'banquet_cap': 100, 'floating_cap': 150, 'tariff': '₹90,000'},
        {'name': 'Terrace Banquet Deck', 'sqft': 5000, 'banquet_cap': 220, 'floating_cap': 400, 'tariff': '₹1,50,000'},
      ],
      'rating': 4.8,
      'reviews_count': 98,
      'status': 'ACTIVE',
      'kyc_status': 'VERIFIED',
      'amenities': ['High-Speed Fiber Wi-Fi', 'Audio-Visual Rig', 'Valet Parking', 'Green Room', 'Liquor License'],
    },
  ];

  // ==========================================
  // FALLBACK BOOKINGS & EVENTS
  // ==========================================
  static List<Map<String, dynamic>> get fallbackBookings => [
    {
      'id': 'book-off-001',
      'code': 'PBB-89201',
      'client_name': 'Rakesh Mehra',
      'event_type': 'Wedding Reception',
      'event_date': DateTime.now().add(const Duration(days: 2)).toIso8601String().substring(0, 10),
      'venue_name': 'The Royal Grandeur Palace',
      'space_name': 'Imperial Crystal Ballroom',
      'guests': 550,
      'status': 'CONFIRMED',
      'readiness_percent': 90,
      'amount': '₹8,50,000',
      'paid_amount': '₹5,00,000',
      'manager': 'Priya Patel',
    },
    {
      'id': 'book-off-002',
      'code': 'PBB-89202',
      'client_name': 'Tata Consultancy Services',
      'event_type': 'Annual Awards & Gala',
      'event_date': DateTime.now().add(const Duration(days: 5)).toIso8601String().substring(0, 10),
      'venue_name': 'Novotel Skyview Convention Suites',
      'space_name': 'Summit Plenary Hall',
      'guests': 400,
      'status': 'CONFIRMED',
      'readiness_percent': 75,
      'amount': '₹6,20,000',
      'paid_amount': '₹6,20,000',
      'manager': 'Priya Patel',
    },
    {
      'id': 'book-off-003',
      'code': 'PBB-89203',
      'client_name': 'Dr. Alok Verma',
      'event_type': 'Silver Jubilee Anniversary',
      'event_date': DateTime.now().toIso8601String().substring(0, 10),
      'venue_name': 'The Royal Grandeur Palace',
      'space_name': 'Sunset Rooftop Lounge',
      'guests': 180,
      'status': 'IN_PROGRESS',
      'readiness_percent': 100,
      'amount': '₹3,40,000',
      'paid_amount': '₹3,40,000',
      'manager': 'Rohan Joshi',
    },
  ];
}
