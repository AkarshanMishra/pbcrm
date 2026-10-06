import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'booking_detail_screen.dart';
import 'event_readiness_screen.dart';
import 'quality_control_screen.dart';
import 'operations_issues_screen.dart';
import 'operations_inventory_screen.dart';

class AdminOperationsEventsScreen extends StatefulWidget {
  final int initialSectionIndex;
  const AdminOperationsEventsScreen({super.key, this.initialSectionIndex = 0});

  @override
  State<AdminOperationsEventsScreen> createState() => _AdminOperationsEventsScreenState();
}

class _AdminOperationsEventsScreenState extends State<AdminOperationsEventsScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;
  int _currentSection = 0;
  String _searchQuery = '';
  String _bookingFilter = 'ALL';
  String _eventFilter = 'ALL';

  // ---------------------------------------------------------------------------
  // STATE STORE FOR ALL OPERATIONS & EVENTS ENTITIES (FULL CRUD)
  // ---------------------------------------------------------------------------

  // 1. Bookings
  final List<Map<String, dynamic>> _bookings = [
    {
      'id': 'PB-10482',
      'customer': 'Amit Sharma',
      'phone': '+91 98390 11223',
      'email': 'amit.sharma@gmail.com',
      'eventTitle': 'Sharma Grand Wedding Reception',
      'eventType': 'Wedding Reception',
      'date': '18 Oct 2026',
      'time': '06:30 PM - 11:30 PM',
      'venue': 'Grand Heritage Banquet (Crystal Ballroom + Lawn)',
      'guestCount': 650,
      'services': ['Banquet Hall', 'Royal Catering (Package A)', 'Luxury Floral Decor', 'Candid Photography'],
      'package': 'Royal Grand Wedding Platinum',
      'totalAmount': 850000,
      'paidAmount': 850000,
      'paymentStatus': 'PAID',
      'opsStatus': 'CONFIRMED',
      'readiness': 0.88,
      'opsManager': 'Kavita Nair',
      'venueCoordinator': 'Amit Trivedi',
      'cateringCoordinator': 'Priya Saxena',
      'decorCoordinator': 'Neha Sharma',
      'specialRequests': 'VIP stage floral canopy, strict Jain food counter #4, ramp access for elderly guests',
      'issuesCount': 0,
    },
    {
      'id': 'PB-10483',
      'customer': 'Sunil Mittal',
      'phone': '+91 94150 98765',
      'email': 'sunil.mittal@mittalgroup.com',
      'eventTitle': 'Mittal 25th Silver Jubilee Anniversary',
      'eventType': 'Anniversary Gala',
      'date': '19 Oct 2026',
      'time': '07:00 PM - 12:00 AM',
      'venue': 'Royal Palms Resort (Poolside Deck + Banquet)',
      'guestCount': 350,
      'services': ['Poolside Deck', 'Gourmet Barbeque & Buffet', 'Live Fusion Acoustic Band', 'LED Screen Setup'],
      'package': 'Silver Jubilee Premium Gala',
      'totalAmount': 420000,
      'paidAmount': 300000,
      'paymentStatus': 'PARTIAL',
      'opsStatus': 'PREPARATION',
      'readiness': 0.72,
      'opsManager': 'Kavita Nair',
      'venueCoordinator': 'Deepak Verma',
      'cateringCoordinator': 'Suresh Pal',
      'decorCoordinator': 'Akarshan Mishra',
      'specialRequests': 'Live barista coffee counter, customized photo backdrop with 1999-2024 memorabilia',
      'issuesCount': 1,
    },
    {
      'id': 'PB-10484',
      'customer': 'Dr. Alok Srivastava',
      'phone': '+91 98890 44332',
      'email': 'alok.s@medcare.org',
      'eventTitle': 'MedCare National Surgeons Conference',
      'eventType': 'Corporate Conference',
      'date': '20 Oct 2026',
      'time': '09:00 AM - 05:00 PM',
      'venue': 'Kuhu Espresso Banquet (Executive Conference Hall)',
      'guestCount': 200,
      'services': ['Conference Hall', 'AV Projection & Podiums', 'Executive High Tea & Lunch', 'Delegate Kits'],
      'package': 'Corporate Summit Full-Day',
      'totalAmount': 210000,
      'paidAmount': 210000,
      'paymentStatus': 'PAID',
      'opsStatus': 'CONFIRMED',
      'readiness': 0.95,
      'opsManager': 'Kavita Nair',
      'venueCoordinator': 'Amit Trivedi',
      'cateringCoordinator': 'Priya Saxena',
      'decorCoordinator': 'Self-Managed',
      'specialRequests': 'High-speed 100Mbps dedicated WiFi SSID for live surgical video streaming',
      'issuesCount': 0,
    },
    {
      'id': 'PB-10485',
      'customer': 'Pooja Tandon',
      'phone': '+91 97920 66778',
      'email': 'pooja.tandon@yahoo.com',
      'eventTitle': 'Aarav 1st Birthday Wonderland',
      'eventType': 'Birthday Party',
      'date': '21 Oct 2026',
      'time': '05:00 PM - 09:30 PM',
      'venue': 'Grand Heritage Banquet (Mini Party Hall)',
      'guestCount': 120,
      'services': ['Mini Party Hall', 'Jungle Safari Balloon Theme', 'Kids Snack Buffet & Live Waffle Station', 'Magician & Mascot'],
      'package': 'Kids Wonderland Fiesta',
      'totalAmount': 95000,
      'paidAmount': 50000,
      'paymentStatus': 'PARTIAL',
      'opsStatus': 'AT_RISK',
      'readiness': 0.45,
      'opsManager': 'Kavita Nair',
      'venueCoordinator': 'Rahul Verma',
      'cateringCoordinator': 'Pending',
      'decorCoordinator': 'Neha Sharma',
      'specialRequests': 'Eggless customized 3-tier Lion King cake delivery at 06:00 PM sharp',
      'issuesCount': 2,
    },
  ];

  // 2. Events & 360° Lifecycle
  final List<Map<String, dynamic>> _events = [
    {
      'id': 'EVT-000124',
      'bookingId': 'PB-10482',
      'title': 'Sharma Grand Wedding Reception',
      'venue': 'Grand Heritage Banquet',
      'date': 'Tomorrow (18 Oct 2026)',
      'status': 'READY',
      'readiness': 0.96,
      'manager': 'Kavita Nair',
      'guests': 650,
      'qcStatus': 'PASSED',
      'checklistCompleted': '18 / 18 Items',
      'timeline': [
        {'time': '08:00 AM', 'title': 'Venue Access & Power Check', 'owner': 'Amit Trivedi', 'status': 'DONE'},
        {'time': '09:30 AM', 'title': 'Floral Canopy & Stage Decor Setup', 'owner': 'Neha Sharma', 'status': 'DONE'},
        {'time': '11:30 AM', 'title': 'Catering Kitchen Handover & Prep', 'owner': 'Priya Saxena', 'status': 'DONE'},
        {'time': '02:00 PM', 'title': 'Sound, Stage Lighting & Mic QC Check', 'owner': 'Akarshan Mishra', 'status': 'DONE'},
        {'time': '05:00 PM', 'title': 'Buffet Counter Setup & Hygiene Audit', 'owner': 'Priya Saxena', 'status': 'IN_PROGRESS'},
        {'time': '06:30 PM', 'title': 'Guest Arrival & Red Carpet Hostess Entry', 'owner': 'Kavita Nair', 'status': 'UPCOMING'},
        {'time': '08:00 PM', 'title': 'Main Varmala & Stage Ceremony', 'owner': 'Kavita Nair', 'status': 'UPCOMING'},
        {'time': '11:00 PM', 'title': 'Event Breakdown & Security Handover', 'owner': 'Amit Trivedi', 'status': 'UPCOMING'},
      ],
    },
    {
      'id': 'EVT-000125',
      'bookingId': 'PB-10483',
      'title': 'Mittal 25th Silver Jubilee Anniversary',
      'venue': 'Royal Palms Resort',
      'date': '19 Oct 2026',
      'status': 'PREPARATION',
      'readiness': 0.72,
      'manager': 'Kavita Nair',
      'guests': 350,
      'qcStatus': 'IN_PROGRESS',
      'checklistCompleted': '13 / 18 Items',
      'timeline': [
        {'time': '10:00 AM', 'title': 'Poolside Barricading & Setup Access', 'owner': 'Deepak Verma', 'status': 'DONE'},
        {'time': '01:00 PM', 'title': 'Live Acoustic Band Stage & Audio Rig', 'owner': 'SoundTech Vendors', 'status': 'IN_PROGRESS'},
        {'time': '04:00 PM', 'title': 'Barbeque Stations & Charcoal Test', 'owner': 'Suresh Pal', 'status': 'UPCOMING'},
        {'time': '07:00 PM', 'title': 'Guest Arrival & Welcome Mocktails', 'owner': 'Deepak Verma', 'status': 'UPCOMING'},
      ],
    },
    {
      'id': 'EVT-000126',
      'bookingId': 'PB-10485',
      'title': 'Aarav 1st Birthday Wonderland',
      'venue': 'Grand Heritage Banquet',
      'date': '21 Oct 2026',
      'status': 'AT_RISK',
      'readiness': 0.45,
      'manager': 'Kavita Nair',
      'guests': 120,
      'qcStatus': 'ACTION_REQUIRED',
      'checklistCompleted': '8 / 18 Items',
      'timeline': [
        {'time': '01:00 PM', 'title': 'Balloon Arch & Theme Setup', 'owner': 'Neha Sharma', 'status': 'UPCOMING'},
        {'time': '03:30 PM', 'title': 'Kids Play Zone & Mascot Arrival', 'owner': 'Vendor Team', 'status': 'UPCOMING'},
        {'time': '05:00 PM', 'title': 'Party Commencement & Cake Cutting', 'owner': 'Rahul Verma', 'status': 'UPCOMING'},
      ],
    },
  ];

  // 3. Operational Issues & Complaints with SLA
  final List<Map<String, dynamic>> _issues = [
    {
      'id': 'ISS-901',
      'category': 'Catering & Food Safety',
      'title': 'Tasting confirmation delayed for Mittal Silver Jubilee Menu',
      'bookingId': 'PB-10483',
      'eventId': 'EVT-000125',
      'assignedTo': 'Priya Saxena (Catering Lead)',
      'priority': 'HIGH',
      'slaTotal': '4 Hours',
      'slaRemaining': '42 mins remaining',
      'slaElapsed': '3h 18m',
      'status': 'INVESTIGATING',
      'color': Color(0xFFF59E0B),
      'rootCause': 'Client requested chef-special Awadhi Biryani modification; waiting for recipe sign-off',
    },
    {
      'id': 'ISS-902',
      'category': 'Vendor Coordination',
      'title': 'Kids Mascot vendor uncontactable for Aarav 1st Birthday Wonderland',
      'bookingId': 'PB-10485',
      'eventId': 'EVT-000126',
      'assignedTo': 'Rahul Verma (Ops Coordinator)',
      'priority': 'CRITICAL',
      'slaTotal': '2 Hours',
      'slaRemaining': '18 mins remaining (BREACH RISK)',
      'slaElapsed': '1h 42m',
      'status': 'ACTION_REQUIRED',
      'color': Color(0xFFEF4444),
      'rootCause': 'Primary artist phone switched off; activating backup agency roster in Kidwai Nagar',
    },
    {
      'id': 'ISS-903',
      'category': 'Facility & Logistics',
      'title': 'Rooftop AC Unit #3 cooling efficiency dropped to 28°C at Royal Palms',
      'bookingId': 'PB-10483',
      'eventId': 'EVT-000125',
      'assignedTo': 'Akarshan Mishra (Facility IT)',
      'priority': 'HIGH',
      'slaTotal': '3 Hours',
      'slaRemaining': '1h 15m remaining',
      'slaElapsed': '1h 45m',
      'status': 'INVESTIGATING',
      'color': Color(0xFFF59E0B),
      'rootCause': 'Condenser coil dust build-up; technician dispatch underway with spare compressor relay',
    },
  ];

  // 4. Resources & Equipment Inventory
  final List<Map<String, dynamic>> _resources = [
    {
      'id': 'RES-401',
      'name': 'JBL VRX 932LAP Line Array Sound Rig (4 Tops + 2 Subs)',
      'category': 'Audio Equipment',
      'location': 'Central Warehouse Hub A',
      'status': 'IN_USE',
      'assignedEvent': 'EVT-000124 (Grand Heritage)',
      'condition': 'Excellent (QC Checked)',
      'quantity': '2 Sets',
    },
    {
      'id': 'RES-402',
      'name': 'Beam 230 Moving Head Stage Lighting Truss (8 Units)',
      'category': 'Stage Lighting',
      'location': 'Central Warehouse Hub A',
      'status': 'IN_USE',
      'assignedEvent': 'EVT-000124 (Grand Heritage)',
      'condition': 'Good',
      'quantity': '8 Units',
    },
    {
      'id': 'RES-403',
      'name': 'P3.91 Indoor High-Def LED Video Wall (16ft x 10ft)',
      'category': 'Visual Tech',
      'location': 'Transit Vehicle UP78-AT-8821',
      'status': 'RESERVED',
      'assignedEvent': 'EVT-000125 (Royal Palms)',
      'condition': 'Calibrated & Tested',
      'quantity': '1 Rig',
    },
    {
      'id': 'RES-404',
      'name': 'Heavy Duty 62.5 kVA Silent Diesel Generator Rig',
      'category': 'Power Backup',
      'location': 'On-Site Standby (Grand Heritage)',
      'status': 'AVAILABLE',
      'assignedEvent': 'Ready for Dispatch',
      'condition': 'Full Fuel / Inspected',
      'quantity': '1 Mobile Unit',
    },
  ];

  // 5. Logistics & Fleet Dispatch
  final List<Map<String, dynamic>> _logistics = [
    {
      'id': 'LOG-701',
      'vehicle': 'UP-78-BT-4421 (Tata 407 Heavy)',
      'driver': 'Ramesh Yadav (+91 94150 11990)',
      'cargo': 'Sharma Wedding Royal Stage Pillars & Floral Consumables',
      'origin': 'Central Warehouse',
      'destination': 'Grand Heritage Banquet',
      'pickupTime': '08:00 AM',
      'deliveryTime': '09:15 AM',
      'status': 'DELIVERED',
      'notes': 'All 24 floral crates handed over to Neha Sharma',
    },
    {
      'id': 'LOG-702',
      'vehicle': 'UP-78-CT-9912 (Mahindra Bolero MaxiTruck)',
      'driver': 'Satish Pal (+91 98890 22334)',
      'cargo': 'Live Barbeque Grills & Chafing Dish Fleet',
      'origin': 'Royal Flavors Central Commissary',
      'destination': 'Royal Palms Resort',
      'pickupTime': '02:00 PM',
      'deliveryTime': '03:30 PM',
      'status': 'IN_TRANSIT',
      'notes': 'Live GPS Tracking Active on Highway',
    },
  ];

  // 6. Quality Control Checks (Pass / Fail Matrix)
  final List<Map<String, dynamic>> _qcAudits = [
    {
      'id': 'QC-881',
      'eventId': 'EVT-000124',
      'venue': 'Grand Heritage Banquet',
      'auditor': 'Kavita Nair (Ops Head)',
      'time': 'Today, 02:30 PM',
      'result': 'PASS',
      'score': '98/100',
      'breakdown': {
        'Hall Cleanliness & Restrooms': '10/10',
        'AC Temperature & Odor Control': '10/10',
        'Stage Stability & Lighting': '10/10',
        'Catering Hygiene & Hairnets': '10/10',
        'Fire Extinguishers & First Aid': '9/10',
      },
      'photosAttached': 8,
      'notes': 'Exemplary banquet floor readiness. All catering staff verified with health badges.',
    },
    {
      'id': 'QC-882',
      'eventId': 'EVT-000125',
      'venue': 'Royal Palms Resort',
      'auditor': 'Deepak Verma',
      'time': 'Today, 11:00 AM',
      'result': 'PASS_WITH_ISSUE',
      'score': '84/100',
      'breakdown': {
        'Poolside Barrier Safety': '9/10',
        'AC Cooling Performance': '6/10 (ISSUE-903 Logged)',
        'Barbeque Smoke Exhaust': '9/10',
        'Stage Audio Wiring & Cable Ramps': '9/10',
      },
      'photosAttached': 5,
      'notes': 'AC cooling issue flagged to IT/facility technician for immediate relay replacement.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentSection = widget.initialSectionIndex;
    _tabController = TabController(length: 11, vsync: this, initialIndex: _currentSection);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentSection = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // CRUD MODALS & ACTIONS
  // ---------------------------------------------------------------------------

  void _showCreateBookingDialog({Map<String, dynamic>? editBooking}) {
    final customerCtrl = TextEditingController(text: editBooking?['customer'] ?? '');
    final phoneCtrl = TextEditingController(text: editBooking?['phone'] ?? '');
    final eventTitleCtrl = TextEditingController(text: editBooking?['eventTitle'] ?? '');
    final venueCtrl = TextEditingController(text: editBooking?['venue'] ?? 'Grand Heritage Banquet');
    final dateCtrl = TextEditingController(text: editBooking?['date'] ?? '25 Oct 2026');
    final timeCtrl = TextEditingController(text: editBooking?['time'] ?? '06:30 PM - 11:30 PM');
    final guestsCtrl = TextEditingController(text: editBooking != null ? editBooking['guestCount'].toString() : '500');
    final amountCtrl = TextEditingController(text: editBooking != null ? editBooking['totalAmount'].toString() : '650000');
    final requestsCtrl = TextEditingController(text: editBooking?['specialRequests'] ?? '');
    String eventType = editBooking?['eventType'] ?? 'Wedding Reception';
    String opsStatus = editBooking?['opsStatus'] ?? 'CONFIRMED';
    String opsManager = editBooking?['opsManager'] ?? 'Kavita Nair';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.celebration_rounded, color: Color(0xFFF59E0B), size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                editBooking != null ? 'Edit Operations Booking' : 'Create Enterprise Booking',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: eventTitleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Event Title / Name *',
                      prefixIcon: const Icon(Icons.event_seat_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customerCtrl,
                          decoration: InputDecoration(
                            labelText: 'Customer / Host Name *',
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Customer Phone *',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: eventType,
                          decoration: InputDecoration(labelText: 'Event Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          items: const [
                            DropdownMenuItem(value: 'Wedding Reception', child: Text('💍 Wedding Reception')),
                            DropdownMenuItem(value: 'Anniversary Gala', child: Text('🥂 Anniversary Gala')),
                            DropdownMenuItem(value: 'Corporate Conference', child: Text('💼 Corporate Summit')),
                            DropdownMenuItem(value: 'Birthday Party', child: Text('🎂 Birthday Party')),
                            DropdownMenuItem(value: 'Cultural Night', child: Text('🎭 Cultural / Musical Night')),
                          ],
                          onChanged: (v) => setDialogState(() => eventType = v ?? 'Wedding Reception'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: guestsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Guest Count *',
                            prefixIcon: const Icon(Icons.groups_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: venueCtrl,
                    decoration: InputDecoration(
                      labelText: 'Partner Venue & Space *',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dateCtrl,
                          decoration: InputDecoration(
                            labelText: 'Event Date *',
                            prefixIcon: const Icon(Icons.calendar_today_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: timeCtrl,
                          decoration: InputDecoration(
                            labelText: 'Event Timing *',
                            prefixIcon: const Icon(Icons.access_time_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Booking Amount (₹) *',
                            prefixIcon: const Icon(Icons.currency_rupee_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: opsStatus,
                          decoration: InputDecoration(labelText: 'Operations Status', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          items: const [
                            DropdownMenuItem(value: 'CONFIRMED', child: Text('Confirmed')),
                            DropdownMenuItem(value: 'PREPARATION', child: Text('Preparation')),
                            DropdownMenuItem(value: 'READY', child: Text('Ready for Execution')),
                            DropdownMenuItem(value: 'LIVE', child: Text('Live Event Today')),
                            DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                            DropdownMenuItem(value: 'AT_RISK', child: Text('At Risk / Escalation')),
                          ],
                          onChanged: (v) => setDialogState(() => opsStatus = v ?? 'CONFIRMED'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: requestsCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Special Dietary, VIP & Decor Requirements',
                      prefixIcon: const Icon(Icons.note_alt_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white),
              onPressed: () {
                final amt = int.tryParse(amountCtrl.text.trim()) ?? 0;
                final gCount = int.tryParse(guestsCtrl.text.trim()) ?? 100;
                if (customerCtrl.text.trim().isEmpty || eventTitleCtrl.text.trim().isEmpty || amt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required booking fields.')));
                  return;
                }
                setState(() {
                  if (editBooking != null) {
                    editBooking['customer'] = customerCtrl.text.trim();
                    editBooking['phone'] = phoneCtrl.text.trim();
                    editBooking['eventTitle'] = eventTitleCtrl.text.trim();
                    editBooking['venue'] = venueCtrl.text.trim();
                    editBooking['date'] = dateCtrl.text.trim();
                    editBooking['time'] = timeCtrl.text.trim();
                    editBooking['eventType'] = eventType;
                    editBooking['guestCount'] = gCount;
                    editBooking['totalAmount'] = amt;
                    editBooking['opsStatus'] = opsStatus;
                    editBooking['specialRequests'] = requestsCtrl.text.trim();
                  } else {
                    final newBookingId = 'PB-${_bookings.length + 10486}';
                    _bookings.insert(0, {
                      'id': newBookingId,
                      'customer': customerCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'email': 'customer@partybala.in',
                      'eventTitle': eventTitleCtrl.text.trim(),
                      'eventType': eventType,
                      'date': dateCtrl.text.trim(),
                      'time': timeCtrl.text.trim(),
                      'venue': venueCtrl.text.trim(),
                      'guestCount': gCount,
                      'services': ['Banquet Space', 'Turnkey Catering', 'Theme Decor'],
                      'package': 'Enterprise Custom Package',
                      'totalAmount': amt,
                      'paidAmount': (amt * 0.5).round(),
                      'paymentStatus': 'PARTIAL',
                      'opsStatus': opsStatus,
                      'readiness': 0.80,
                      'opsManager': opsManager,
                      'venueCoordinator': 'Amit Trivedi',
                      'cateringCoordinator': 'Priya Saxena',
                      'decorCoordinator': 'Neha Sharma',
                      'specialRequests': requestsCtrl.text.trim(),
                      'issuesCount': 0,
                    });
                    // Also auto-generate the connected Event 360° record
                    _events.insert(0, {
                      'id': 'EVT-000${_events.length + 127}',
                      'bookingId': newBookingId,
                      'title': eventTitleCtrl.text.trim(),
                      'venue': venueCtrl.text.trim(),
                      'date': dateCtrl.text.trim(),
                      'status': 'PLANNING',
                      'readiness': 0.80,
                      'manager': opsManager,
                      'guests': gCount,
                      'qcStatus': 'SCHEDULED',
                      'checklistCompleted': '12 / 18 Items',
                      'timeline': [
                        {'time': '08:00 AM', 'title': 'Venue Setup Access', 'owner': 'Amit Trivedi', 'status': 'UPCOMING'},
                        {'time': '11:00 AM', 'title': 'Catering & Decor Arrival', 'owner': 'Priya Saxena', 'status': 'UPCOMING'},
                        {'time': '05:00 PM', 'title': 'Quality & Cleanliness Audit', 'owner': 'Kavita Nair', 'status': 'UPCOMING'},
                        {'time': '07:00 PM', 'title': 'Event Execution', 'owner': 'Kavita Nair', 'status': 'UPCOMING'},
                      ],
                    });
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(editBooking != null ? '✓ Booking updated!' : '✓ Booking & Event 360° generated across Operations!'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              },
              child: Text(editBooking != null ? 'Save Changes' : 'Create & Generate Event'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportIssueDialog() {
    final titleCtrl = TextEditingController();
    final bookingCtrl = TextEditingController(text: 'PB-10482');
    final causeCtrl = TextEditingController();
    String cat = 'Catering & Food Safety';
    String priority = 'HIGH';
    String sla = '2 Hours';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.report_problem_rounded, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text('Log Operational Incident / SLA Issue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Incident Description / Summary *',
                      prefixIcon: const Icon(Icons.description_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: cat,
                          decoration: InputDecoration(labelText: 'Issue Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          items: const [
                            DropdownMenuItem(value: 'Catering & Food Safety', child: Text('🍽️ Catering & Food Safety')),
                            DropdownMenuItem(value: 'Venue & Facilities', child: Text('🏢 Venue & Facilities')),
                            DropdownMenuItem(value: 'Vendor Coordination', child: Text('🤝 Vendor Coordination')),
                            DropdownMenuItem(value: 'Audio / Visual & IT', child: Text('🔊 Audio / Visual & IT')),
                            DropdownMenuItem(value: 'Customer Complaint', child: Text('👤 Customer Complaint')),
                            DropdownMenuItem(value: 'Emergency / Safety', child: Text('🚨 Emergency / Safety')),
                          ],
                          onChanged: (v) => setDialogState(() => cat = v ?? 'Catering & Food Safety'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: priority,
                          decoration: InputDecoration(labelText: 'Severity Level', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          items: const [
                            DropdownMenuItem(value: 'CRITICAL', child: Text('🔴 Critical (1h SLA)')),
                            DropdownMenuItem(value: 'HIGH', child: Text('🟠 High (2h SLA)')),
                            DropdownMenuItem(value: 'MEDIUM', child: Text('🟡 Medium (4h SLA)')),
                            DropdownMenuItem(value: 'LOW', child: Text('🟢 Low (8h SLA)')),
                          ],
                          onChanged: (v) => setDialogState(() => priority = v ?? 'HIGH'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bookingCtrl,
                    decoration: InputDecoration(
                      labelText: 'Booking Ref ID *',
                      prefixIcon: const Icon(Icons.tag_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: causeCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Root Cause & Immediate Action Plan *',
                      prefixIcon: const Icon(Icons.notes_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                setState(() {
                  _issues.insert(0, {
                    'id': 'ISS-${_issues.length + 904}',
                    'category': cat,
                    'title': titleCtrl.text.trim(),
                    'bookingId': bookingCtrl.text.trim(),
                    'eventId': 'EVT-000124',
                    'assignedTo': 'Kavita Nair (Ops Head)',
                    'priority': priority,
                    'slaTotal': priority == 'CRITICAL' ? '1 Hour' : '2 Hours',
                    'slaRemaining': priority == 'CRITICAL' ? '58 mins remaining' : '1h 58m remaining',
                    'slaElapsed': 'Just now',
                    'status': 'INVESTIGATING',
                    'color': priority == 'CRITICAL' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                    'rootCause': causeCtrl.text.trim(),
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⚠️ Incident logged with active SLA timer countdown!'), backgroundColor: Colors.redAccent),
                );
              },
              child: const Text('Log Issue & Start SLA Timer'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN BUILD METHOD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.precision_manufacturing_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text(
              'Operations & Event Execution Engine',
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF334155)),
            tooltip: 'Refresh Execution Engine',
            onPressed: () => setState(() {}),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFFF59E0B),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFFF59E0B),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_customize_rounded, size: 18), text: '📊 Operations Dashboard'),
            Tab(icon: Icon(Icons.event_seat_rounded, size: 18), text: '📅 Bookings (360°)'),
            Tab(icon: Icon(Icons.celebration_rounded, size: 18), text: '🎉 Events & Timelines'),
            Tab(icon: Icon(Icons.location_city_rounded, size: 18), text: '🏢 Venues & Vendors'),
            Tab(icon: Icon(Icons.fact_check_rounded, size: 18), text: '🛠️ Checklists & QC'),
            Tab(icon: Icon(Icons.groups_rounded, size: 18), text: '👥 Staff Allocation'),
            Tab(icon: Icon(Icons.inventory_2_rounded, size: 18), text: '📦 Logistics & Inventory'),
            Tab(icon: Icon(Icons.place_rounded, size: 18), text: '📍 Field Operations'),
            Tab(icon: Icon(Icons.warning_amber_rounded, size: 18), text: '⚠️ Issues & SLA'),
            Tab(icon: Icon(Icons.favorite_rounded, size: 18), text: '❤️ Customer Experience'),
            Tab(icon: Icon(Icons.analytics_rounded, size: 18), text: '📈 Funnel & Bottlenecks'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_currentSection == 8) {
            _showReportIssueDialog();
          } else {
            _showCreateBookingDialog();
          }
        },
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        icon: Icon(_currentSection == 8 ? Icons.report_problem_rounded : Icons.add_rounded),
        label: Text(
          _currentSection == 8 ? '+ Log Incident' : '+ Create Booking / Event',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOperationsDashboardTab(),
          _buildBookingsTab(),
          _buildEventsTimelineTab(),
          _buildVenuesVendorsTab(),
          _buildChecklistsQcTab(),
          _buildStaffAllocationTab(),
          _buildLogisticsInventoryTab(),
          _buildFieldOperationsTab(),
          _buildIssuesSlaTab(),
          _buildCustomerExperienceTab(),
          _buildFunnelBottlenecksTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. 📊 OPERATIONS DASHBOARD
  // ===========================================================================
  Widget _buildOperationsDashboardTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Bottleneck Intelligence Alert
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.psychology_alt_rounded, color: Color(0xFF2563EB), size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OPERATIONAL BOTTLENECK INSIGHT', style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                    SizedBox(height: 3),
                    Text(
                      'Catering menu confirmation is causing 42% of event readiness delays. Automated tasting reminders dispatched.',
                      style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Live Operational KPIs
        const Text('TODAY\'S LIVE OPERATIONS MATRIX', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Total Bookings', '48', '41 Confirmed • 2 At Risk', Icons.event_available_rounded, const Color(0xFF10B981))),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Live Events Today', '18', '7 In Progress • 9 Done', Icons.celebration_rounded, const Color(0xFFF59E0B))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Active Issues', '9', '1 Critical • 3 SLA Alerts', Icons.warning_rounded, const Color(0xFFEF4444))),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Event Readiness', '92.4%', 'Tomorrow: 12 Events Ready', Icons.verified_rounded, const Color(0xFF2563EB))),
          ],
        ),
        const SizedBox(height: 20),

        // Tomorrow's Event Readiness Breakdown
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOMORROW\'S EVENT READINESS (12 EVENTS)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A))),
                  Text('8 Ready • 3 Prep • 1 At Risk', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w800, fontSize: 11.5)),
                ],
              ),
              const SizedBox(height: 14),
              _buildEventReadinessRow('EVT-000124 (Sharma Wedding)', 'Grand Heritage Banquet', 0.96, const Color(0xFF10B981)),
              _buildEventReadinessRow('EVT-000125 (Mittal 25th Gala)', 'Royal Palms Resort', 0.72, const Color(0xFFF59E0B)),
              _buildEventReadinessRow('EVT-000126 (Aarav 1st Birthday)', 'Grand Heritage Mini Hall', 0.45, const Color(0xFFEF4444)),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. 📅 BOOKINGS (360°)
  // ===========================================================================
  Widget _buildBookingsTab() {
    final filtered = _bookings.where((b) {
      if (_bookingFilter != 'ALL' && b['opsStatus'] != _bookingFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return b['customer'].toString().toLowerCase().contains(q) ||
            b['eventTitle'].toString().toLowerCase().contains(q) ||
            b['venue'].toString().toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Filter & Search bar
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Search bookings by customer, event, venue...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _showCreateBookingDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('+ New Booking'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        const Text('ENTERPRISE BOOKINGS (CROSS-DEPARTMENT 360°)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),

        ...filtered.map((b) {
          final readiness = (b['readiness'] as double);
          final status = b['opsStatus'];
          Color statusColor = const Color(0xFF10B981);
          if (status == 'AT_RISK') statusColor = const Color(0xFFEF4444);
          if (status == 'PREPARATION') statusColor = const Color(0xFFF59E0B);

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                            child: Text(b['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFD97706))),
                          ),
                          const SizedBox(width: 8),
                          Text(b['eventType'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          status.toString().replaceAll('_', ' '),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(b['eventTitle'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text('Customer: ${b['customer']} (${b['phone']}) • ${b['guestCount']} Guests', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  Text('Venue: ${b['venue']}', style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount: ₹ ${(b['totalAmount'] as int).toString()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                      Text('Ops Lead: ${b['opsManager']}', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('Date: ${b['date']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFF59E0B))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: readiness,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _showCreateBookingDialog(editBooking: b)),
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                            tooltip: 'Initiate Cancellation Workflow',
                            onPressed: () {
                              setState(() => b['opsStatus'] = 'CANCELLED');
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cancellation workflow initiated with Accounts & Partner notifications.')));
                            },
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingDetailScreen(
                                bookingId: b['id'],
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility_rounded, size: 14),
                        label: const Text('Open Booking 360°', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // 3. 🎉 EVENTS & TIMELINES
  // ===========================================================================
  Widget _buildEventsTimelineTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('LIVE EVENT EXECUTION & MINUTE-BY-MINUTE TIMELINES', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),

        ..._events.map((evt) {
          final timeline = (evt['timeline'] as List<dynamic>?) ?? [];

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(evt['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2563EB))),
                          ),
                          const SizedBox(width: 8),
                          Text(evt['date'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFD97706))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text(evt['status'], style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(evt['title'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
                  Text('Venue: ${evt['venue']} • Guests: ${evt['guests']} • Manager: ${evt['manager']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 14),
                  const Text('OPERATIONAL TIMELINE & RUN SHEET', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  ...timeline.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 75,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                          child: Text(item['time'], style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(item['title'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                        Text(item['owner'], style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        const SizedBox(width: 6),
                        Icon(item['status'] == 'DONE' ? Icons.check_circle_rounded : Icons.schedule_rounded, size: 16, color: item['status'] == 'DONE' ? Colors.green : Colors.orange),
                      ],
                    ),
                  )),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventReadinessScreen(bookingId: evt['id'] ?? 'PB-10482'))),
                        icon: const Icon(Icons.fact_check_rounded, size: 14),
                        label: const Text('Readiness Check', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QualityControlScreen())),
                        icon: const Icon(Icons.verified_rounded, size: 14),
                        label: const Text('Perform QC Audit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // 4. 🏢 VENUES & VENDORS
  // ===========================================================================
  Widget _buildVenuesVendorsTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MULTI-SPACE VENUE ARCHITECTURE & BUNDLE LOGIC', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              const Text(
                'Grand Heritage Banquet (Spaces: Crystal Ballroom, Grand Lawn, Poolside Deck, Conference Suite).\n'
                'Auto-Bundle Logic: Prevents duplicate billing when Venue already contains mandatory In-House Catering.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. 🛠️ CHECKLISTS & QC
  // ===========================================================================
  Widget _buildChecklistsQcTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('QUALITY CONTROL AUDITS & PASS/FAIL LOGS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),

        ..._qcAudits.map((qc) => Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(qc['id'], style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text(qc['result'], style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('${qc['venue']} (Score: ${qc['score']})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
                Text('Audited by: ${qc['auditor']} • ${qc['time']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                Text(qc['notes'], style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
              ],
            ),
          ),
        )),
      ],
    );
  }

  // ===========================================================================
  // 6. 👥 STAFF ALLOCATION
  // ===========================================================================
  Widget _buildStaffAllocationTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('STAFF CONFLICT & DOUBLE-BOOKING PREVENTION', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
              SizedBox(height: 8),
              Text(
                'Automated shift roster sync with HR. If an Operations Coordinator is already assigned to a live banquet or marked on leave in HR, the system flags scheduling conflicts.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 7. 📦 LOGISTICS & INVENTORY
  // ===========================================================================
  Widget _buildLogisticsInventoryTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('CENTRAL ASSETS & EQUIPMENT INVENTORY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),

        ..._resources.map((res) => Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
          color: Colors.white,
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.speaker_group_rounded, color: Color(0xFF2563EB))),
            title: Text(res['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
            subtitle: Text('Category: ${res['category']} • Status: ${res['status']}\nAssigned: ${res['assignedEvent']}'),
            isThreeLine: true,
          ),
        )),

        const SizedBox(height: 16),
        const Text('FLEET LOGISTICS & VEHICLE TRANSIT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),
        ..._logistics.map((log) => Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
          color: Colors.white,
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFECFDF5), child: Icon(Icons.local_shipping_rounded, color: Color(0xFF10B981))),
            title: Text('${log['vehicle']} (${log['status']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
            subtitle: Text('Cargo: ${log['cargo']}\nFrom: ${log['origin']} → To: ${log['destination']}'),
            isThreeLine: true,
          ),
        )),
      ],
    );
  }

  // ===========================================================================
  // 8. 📍 FIELD OPERATIONS
  // ===========================================================================
  Widget _buildFieldOperationsTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FIELD AUDITS & OFFLINE CAPTURE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
              SizedBox(height: 8),
              Text(
                'Field supervisors can execute on-site banquet inspections, capture geotagged photos, and log checklist responses completely offline. Syncs instantly when network is restored.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 9. ⚠️ ISSUES & SLA COMMAND
  // ===========================================================================
  Widget _buildIssuesSlaTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('LIVE INCIDENT QUEUE & COUNTDOWN SLA TIMERS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
              onPressed: _showReportIssueDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+ Log Incident'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ..._issues.map((iss) {
          final Color color = iss['color'] as Color;

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text('${iss['priority']} SLA', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
                      ),
                      Text(iss['slaRemaining'], style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11.5)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(iss['title'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                  Text('Category: ${iss['category']} • Assignee: ${iss['assignedTo']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Text('Root Cause: ${iss['rootCause']}', style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                        onPressed: () {
                          setState(() => _issues.remove(iss));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Incident marked resolved & SLA closed!'), backgroundColor: AppTheme.success));
                        },
                        child: const Text('Resolve Incident', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // 10. ❤️ CUSTOMER EXPERIENCE
  // ===========================================================================
  Widget _buildCustomerExperienceTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('POST-EVENT CLOSURE & CUSTOMER FEEDBACK WORKFLOW', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
              SizedBox(height: 8),
              Text(
                'Event Completed → Operations Summary Report → Customer Review Request (Automated WhatsApp) → Accounts Financial Reconciliation → Partner Performance Score Updated.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 11. 📈 FUNNEL & BOTTLENECKS
  // ===========================================================================
  Widget _buildFunnelBottlenecksTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OPERATIONS EVENT EXECUTION FUNNEL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
              const SizedBox(height: 14),
              _buildFunnelRow('Bookings Received', '100', '100%', 1.0, const Color(0xFF2563EB)),
              _buildFunnelRow('Partner Confirmed', '94', '94.0%', 0.94, const Color(0xFF38BDF8)),
              _buildFunnelRow('Operationally Ready', '91', '91.0%', 0.91, const Color(0xFF10B981)),
              _buildFunnelRow('Successfully Executed', '89', '89.0%', 0.89, const Color(0xFFF59E0B)),
              _buildFunnelRow('Post-Event Closed & Reconciled', '87', '87.0%', 0.87, const Color(0xFF059669)),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildMetricCard(String label, String val, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(val, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEventReadinessRow(String title, String venue, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
              Text('${(progress * 100).toInt()}% Ready', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 2),
          Text(venue, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelRow(String label, String count, String pct, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0F172A))),
              Text('$count ($pct)', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
