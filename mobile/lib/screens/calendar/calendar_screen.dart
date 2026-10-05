import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

enum CalendarViewMode {
  month,
  week,
  day,
  agenda,
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  DateTime _focusedDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  CalendarViewMode _viewMode = CalendarViewMode.month;
  String _selectedCategoryFilter = 'ALL';
  String _selectedDeptFilter = 'ALL';

  // Master Organization Events Store (Full Admin CRUD)
  final List<Map<String, dynamic>> _events = [
    {
      'id': 'EV-2026-001',
      'title': 'Q4 Executive Leadership Strategy Review',
      'category': 'MEETING',
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'startTime': '10:00 AM',
      'endTime': '11:30 AM',
      'location': 'Boardroom A / Zoom Bridge',
      'dept': 'Management',
      'organizer': 'Akarshan Mishra (Super Admin)',
      'attendees': ['Akarshan Mishra', 'Neha Sharma', 'Rohan Gupta', 'Kavita Nair', 'Deepak Verma'],
      'color': Color(0xFF2563EB),
      'priority': 'HIGH',
      'description': 'Quarterly growth review, revenue velocity vs 50L target, and departmental scorecards.',
    },
    {
      'id': 'EV-2026-002',
      'title': 'Grand Heritage Banquet Setup & Inspection',
      'category': 'VISIT',
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'startTime': '02:00 PM',
      'endTime': '03:30 PM',
      'location': 'Grand Heritage Banquet, Gomti Nagar',
      'dept': 'Marketing',
      'organizer': 'Rohan Gupta',
      'attendees': ['Rohan Gupta', 'Amit Sen (Field Agent)'],
      'color': Color(0xFF10B981),
      'priority': 'NORMAL',
      'description': 'On-ground banquet hall audit and 12% commission partner onboarding agreement sign-off.',
    },
    {
      'id': 'EV-2026-003',
      'title': 'Sharma Wedding Reception Execution (BK-2026-089)',
      'category': 'BOOKING',
      'date': DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10),
      'startTime': '06:00 PM',
      'endTime': '11:00 PM',
      'location': 'Grand Heritage Lawn & Banquet',
      'dept': 'Operations',
      'organizer': 'Kavita Nair',
      'attendees': ['Kavita Nair', 'Ops Crew #1 (8 Staff)'],
      'color': Color(0xFFF59E0B),
      'priority': 'URGENT',
      'description': 'Live event coordination, stage decor readiness, catering checklist, and sound setup.',
    },
    {
      'id': 'EV-2026-004',
      'title': 'Platform Release: Offline Sync Engine V2 Staging',
      'category': 'DEPLOYMENT',
      'date': DateTime.now().add(const Duration(days: 2)).toIso8601String().substring(0, 10),
      'startTime': '11:30 PM',
      'endTime': '01:00 AM',
      'location': 'IT Server Cluster (Node #1 & #2)',
      'dept': 'IT Ops',
      'organizer': 'Akarshan Mishra',
      'attendees': ['DevOps Team', 'Backend Engineers'],
      'color': Color(0xFF8B5CF6),
      'priority': 'HIGH',
      'description': 'Database migration, deterministic conflict resolver rollout, and multi-device push queue.',
    },
    {
      'id': 'EV-2026-005',
      'title': 'Deepak Joshi (Annual Leave)',
      'category': 'LEAVE',
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'startTime': 'Full Day',
      'endTime': 'Full Day',
      'location': 'Out of Office',
      'dept': 'Human Resources',
      'organizer': 'Neha Sharma',
      'attendees': ['Deepak Joshi'],
      'color': Color(0xFFF43F5E),
      'priority': 'NORMAL',
      'description': 'Approved paid annual leave.',
    },
    {
      'id': 'EV-2026-006',
      'title': 'TechCorp Annual Meet Event Fulfillment',
      'category': 'BOOKING',
      'date': DateTime.now().add(const Duration(days: 4)).toIso8601String().substring(0, 10),
      'startTime': '09:00 AM',
      'endTime': '05:00 PM',
      'location': 'Royal Palms Resort & Lawns, Kanpur',
      'dept': 'Operations',
      'organizer': 'Amit Verma',
      'attendees': ['Amit Verma', 'Ops Crew #2'],
      'color': Color(0xFFF59E0B),
      'priority': 'HIGH',
      'description': '₹ 3,40,000 Corporate conference with 500 delegates and stage projection.',
    },
  ];

  // ===========================================================================
  // ADMIN EVENT CRUD & MODALS
  // ===========================================================================
  void _showAddEditEventModal({Map<String, dynamic>? existing, DateTime? initialDate}) {
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    final locCtrl = TextEditingController(text: existing?['location'] ?? 'PartyBala HQ / Virtual Bridge');
    final startCtrl = TextEditingController(text: existing?['startTime'] ?? '10:00 AM');
    final endCtrl = TextEditingController(text: existing?['endTime'] ?? '11:30 AM');
    final attendeesCtrl = TextEditingController(text: (existing?['attendees'] as List<dynamic>?)?.join(', ') ?? 'All Dept Heads');

    String category = existing?['category'] ?? 'MEETING';
    String dept = existing?['dept'] ?? 'Management';
    String priority = existing?['priority'] ?? 'HIGH';
    DateTime eventDate = existing != null ? DateTime.parse(existing['date']) : (initialDate ?? _selectedDate);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.event_available_rounded, color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 10),
              Text(existing == null ? 'Schedule Organization Event' : 'Edit Event Details', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Event Title *', hintText: 'e.g. Q4 Executive Strategy or Banquet Setup', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: category,
                          decoration: const InputDecoration(labelText: 'Event Category', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'MEETING', child: Text('👥 Leadership Meeting')),
                            DropdownMenuItem(value: 'BOOKING', child: Text('📅 Banquet Booking Event')),
                            DropdownMenuItem(value: 'VISIT', child: Text('🚗 Partner Field Visit')),
                            DropdownMenuItem(value: 'DEPLOYMENT', child: Text('💻 IT Sprint / Deployment')),
                            DropdownMenuItem(value: 'LEAVE', child: Text('🏖️ Employee Leave')),
                            DropdownMenuItem(value: 'MILESTONE', child: Text('🎯 Project Milestone')),
                          ],
                          onChanged: (val) => setModalState(() => category = val ?? 'MEETING'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: dept,
                          decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'Management', child: Text('Management')),
                            DropdownMenuItem(value: 'Operations', child: Text('Operations')),
                            DropdownMenuItem(value: 'Marketing', child: Text('Marketing')),
                            DropdownMenuItem(value: 'IT Ops', child: Text('IT & DevOps')),
                            DropdownMenuItem(value: 'Human Resources', child: Text('Human Resources')),
                            DropdownMenuItem(value: 'Accounts', child: Text('Accounts & Finance')),
                          ],
                          onChanged: (val) => setModalState(() => dept = val ?? 'Management'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: eventDate,
                              firstDate: DateTime(2025),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setModalState(() => eventDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Event Date', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    Text(eventDate.toIso8601String().substring(0, 10), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                                const Icon(Icons.calendar_month, color: Color(0xFF2563EB), size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: priority,
                          decoration: const InputDecoration(labelText: 'Priority / Urgency', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'URGENT', child: Text('🔴 Urgent')),
                            DropdownMenuItem(value: 'HIGH', child: Text('🟠 High')),
                            DropdownMenuItem(value: 'NORMAL', child: Text('🟡 Normal')),
                          ],
                          onChanged: (val) => setModalState(() => priority = val ?? 'HIGH'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Time', hintText: '10:00 AM', border: OutlineInputBorder()))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End Time', hintText: '11:30 AM', border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Location / Venue / Zoom Room', border: OutlineInputBorder())),
                  const SizedBox(height: 14),
                  TextField(controller: attendeesCtrl, decoration: const InputDecoration(labelText: 'Attendees / Team Members (comma-separated)', border: OutlineInputBorder())),
                  const SizedBox(height: 14),
                  TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Event Agenda & Description', border: OutlineInputBorder())),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                setState(() {
                  final attList = attendeesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  final Color c = category == 'MEETING'
                      ? const Color(0xFF2563EB)
                      : category == 'BOOKING'
                          ? const Color(0xFFF59E0B)
                          : category == 'VISIT'
                              ? const Color(0xFF10B981)
                              : category == 'DEPLOYMENT'
                                  ? const Color(0xFF8B5CF6)
                                  : const Color(0xFFF43F5E);

                  if (existing != null) {
                    existing['title'] = titleCtrl.text.trim();
                    existing['category'] = category;
                    existing['dept'] = dept;
                    existing['date'] = eventDate.toIso8601String().substring(0, 10);
                    existing['startTime'] = startCtrl.text.trim();
                    existing['endTime'] = endCtrl.text.trim();
                    existing['location'] = locCtrl.text.trim();
                    existing['priority'] = priority;
                    existing['description'] = descCtrl.text.trim();
                    existing['attendees'] = attList;
                    existing['color'] = c;
                  } else {
                    _events.insert(0, {
                      'id': 'EV-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                      'title': titleCtrl.text.trim(),
                      'category': category,
                      'dept': dept,
                      'date': eventDate.toIso8601String().substring(0, 10),
                      'startTime': startCtrl.text.trim(),
                      'endTime': endCtrl.text.trim(),
                      'location': locCtrl.text.trim(),
                      'organizer': 'Akarshan Mishra (Super Admin)',
                      'priority': priority,
                      'description': descCtrl.text.trim(),
                      'attendees': attList,
                      'color': c,
                    });
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('📅 Event "${titleCtrl.text.trim()}" saved & calendar updated')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              child: Text(existing == null ? 'Schedule Event' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _openEvent360Inspector(Map<String, dynamic> ev) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final Color color = ev['color'] as Color;
          final attendees = (ev['attendees'] as List<dynamic>?) ?? [];

          return Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  children: [
                    CircleAvatar(backgroundColor: color.withOpacity(0.12), radius: 24, child: Icon(Icons.calendar_today_rounded, color: color, size: 22)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ev['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A))),
                          Text('${ev['category']} · ${ev['dept']} Department', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE2E8F0)),
                const SizedBox(height: 12),

                _buildInspectorDetailRow('DATE & TIME', '${ev['date']} (${ev['startTime']} - ${ev['endTime']})', Icons.access_time_filled_rounded),
                _buildInspectorDetailRow('LOCATION / ROOM', ev['location'], Icons.location_on_rounded),
                _buildInspectorDetailRow('ORGANIZER', ev['organizer'], Icons.person_rounded),
                _buildInspectorDetailRow('PRIORITY', ev['priority'], Icons.flag_rounded),
                _buildInspectorDetailRow('DESCRIPTION', ev['description'], Icons.notes_rounded),

                const SizedBox(height: 16),
                const Text('INVITED ATTENDEES & PARTICIPANTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: attendees
                      .map((att) => Chip(
                            avatar: CircleAvatar(backgroundColor: color, child: Text(att.toString()[0], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                            label: Text(att.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            backgroundColor: const Color(0xFFF1F5F9),
                          ))
                      .toList(),
                ),

                const SizedBox(height: 24),
                const Text('ADMIN ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAddEditEventModal(existing: ev);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit / Reschedule'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _events.remove(ev));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ Event cancelled and attendees notified')));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Cancel Event'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInspectorDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF1E293B))),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FILTERING LOGIC
  // ===========================================================================
  List<Map<String, dynamic>> get _filteredEvents {
    return _events.where((e) {
      if (_selectedCategoryFilter != 'ALL' && e['category'] != _selectedCategoryFilter) return false;
      if (_selectedDeptFilter != 'ALL' && e['dept'] != _selectedDeptFilter) return false;
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> get _eventsForSelectedDate {
    final dateStr = _selectedDate.toIso8601String().substring(0, 10);
    return _filteredEvents.where((e) => e['date'] == dateStr).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark High-End SaaS Backdrop
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: Color(0xFF38BDF8), size: 22),
            const SizedBox(width: 8),
            const Text('Master Organization Calendar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
          ],
        ),
        actions: [
          // View Switcher Segment
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                _buildViewModeButton('Month', CalendarViewMode.month),
                _buildViewModeButton('Week', CalendarViewMode.week),
                _buildViewModeButton('Day', CalendarViewMode.day),
                _buildViewModeButton('Agenda', CalendarViewMode.agenda),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showAddEditEventModal(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Schedule Event', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Calendar Navigation & Filter Controls Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded, size: 24),
                            onPressed: () => setState(() {
                              _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
                            }),
                          ),
                          Text(
                            '${_getMonthName(_focusedDate.month)} ${_focusedDate.year}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, size: 24),
                            onPressed: () => setState(() {
                              _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
                            }),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => setState(() {
                              _focusedDate = DateTime.now();
                              _selectedDate = DateTime.now();
                            }),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                            child: const Text('Today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          DropdownButton<String>(
                            value: _selectedCategoryFilter,
                            dropdownColor: Colors.white,
                            items: const [
                              DropdownMenuItem(value: 'ALL', child: Text('All Categories')),
                              DropdownMenuItem(value: 'MEETING', child: Text('👥 Meetings')),
                              DropdownMenuItem(value: 'BOOKING', child: Text('📅 Banquet Bookings')),
                              DropdownMenuItem(value: 'VISIT', child: Text('🚗 Partner Visits')),
                              DropdownMenuItem(value: 'DEPLOYMENT', child: Text('💻 IT Deployments')),
                              DropdownMenuItem(value: 'LEAVE', child: Text('🏖️ Staff Leaves')),
                            ],
                            onChanged: (v) => setState(() => _selectedCategoryFilter = v ?? 'ALL'),
                          ),
                          const SizedBox(width: 12),
                          DropdownButton<String>(
                            value: _selectedDeptFilter,
                            dropdownColor: Colors.white,
                            items: const [
                              DropdownMenuItem(value: 'ALL', child: Text('All Departments')),
                              DropdownMenuItem(value: 'Management', child: Text('Management')),
                              DropdownMenuItem(value: 'Operations', child: Text('Operations')),
                              DropdownMenuItem(value: 'Marketing', child: Text('Marketing')),
                              DropdownMenuItem(value: 'IT Ops', child: Text('IT & DevOps')),
                              DropdownMenuItem(value: 'Human Resources', child: Text('HR')),
                              DropdownMenuItem(value: 'Accounts', child: Text('Accounts')),
                            ],
                            onChanged: (v) => setState(() => _selectedDeptFilter = v ?? 'ALL'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Active View Mode Rendering
            Expanded(
              child: _buildActiveViewContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeButton(String label, CalendarViewMode mode) {
    final isSelected = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildActiveViewContent() {
    switch (_viewMode) {
      case CalendarViewMode.month:
        return _buildMonthGridView();
      case CalendarViewMode.week:
        return _buildWeekTimelineView();
      case CalendarViewMode.day:
        return _buildDayHourlyView();
      case CalendarViewMode.agenda:
      default:
        return _buildAgendaTimelineView();
    }
  }

  // ===========================================================================
  // 1. MONTH GRID VIEW (Interactive Matrix with Dots + Day Panel)
  // ===========================================================================
  Widget _buildMonthGridView() {
    final daysInMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    final firstDayWeekday = DateTime(_focusedDate.year, _focusedDate.month, 1).weekday; // 1 = Mon, 7 = Sun

    return Row(
      children: [
        // Left Calendar Grid (7 columns)
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Weekday headers
                Row(
                  children: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                      .map((d) => Expanded(
                            child: Center(
                              child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B))),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),

                // Grid Days
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.3),
                    itemCount: (firstDayWeekday - 1) + daysInMonth,
                    itemBuilder: (context, index) {
                      if (index < firstDayWeekday - 1) {
                        return const SizedBox.shrink(); // Empty slot before 1st of month
                      }
                      final dayNumber = index - (firstDayWeekday - 1) + 1;
                      final currentDay = DateTime(_focusedDate.year, _focusedDate.month, dayNumber);
                      final dateStr = currentDay.toIso8601String().substring(0, 10);
                      final dayEvents = _filteredEvents.where((e) => e['date'] == dateStr).toList();

                      final isSelected = _selectedDate.year == currentDay.year && _selectedDate.month == currentDay.month && _selectedDate.day == currentDay.day;
                      final isToday = DateTime.now().year == currentDay.year && DateTime.now().month == currentDay.month && DateTime.now().day == currentDay.day;

                      return InkWell(
                        onTap: () => setState(() => _selectedDate = currentDay),
                        onDoubleTap: () => _showAddEditEventModal(initialDate: currentDay),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? const Color(0xFF2563EB) : (isToday ? const Color(0xFF38BDF8) : const Color(0xFFE2E8F0)), width: isSelected ? 2 : 1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '$dayNumber',
                                  style: TextStyle(
                                    fontWeight: isToday || isSelected ? FontWeight.w900 : FontWeight.w500,
                                    fontSize: 12,
                                    color: isToday ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (dayEvents.isNotEmpty)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: dayEvents.take(3).map((e) {
                                    final Color c = e['color'] as Color;
                                    return Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 4),
                                      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Selected Day Schedule & Action Panel
        Container(
          width: 360,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getMonthName(_selectedDate.month)} ${_selectedDate.day}, ${_selectedDate.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                        Text('${_eventsForSelectedDate.length} Scheduled Events', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Color(0xFF2563EB)),
                      tooltip: 'Add event to this date',
                      onPressed: () => _showAddEditEventModal(initialDate: _selectedDate),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _eventsForSelectedDate.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.event_busy_rounded, size: 42, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 8),
                            const Text('No events scheduled for this day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                            const SizedBox(height: 4),
                            TextButton.icon(
                              onPressed: () => _showAddEditEventModal(initialDate: _selectedDate),
                              icon: const Icon(Icons.add, size: 14),
                              label: const Text('Schedule on this date', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _eventsForSelectedDate.length,
                        itemBuilder: (ctx, i) {
                          final ev = _eventsForSelectedDate[i];
                          final Color color = ev['color'] as Color;

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withOpacity(0.3))),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _openEvent360Inspector(ev),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                                          child: Text(ev['category'], style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 9.5)),
                                        ),
                                        const Spacer(),
                                        Text('${ev['startTime']} - ${ev['endTime']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(ev['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A))),
                                    const SizedBox(height: 2),
                                    Text(ev['location'], style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. AGENDA & TIMELINE STREAM VIEW
  // ===========================================================================
  Widget _buildAgendaTimelineView() {
    final list = _filteredEvents;

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final ev = list[index];
        final Color color = ev['color'] as Color;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openEvent360Inspector(ev),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 55,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        Text(ev['date'].substring(8), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
                        Text(ev['date'].substring(5, 7), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(ev['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F172A))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                              child: Text(ev['category'], style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 13, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text('${ev['startTime']} - ${ev['endTime']}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                            const SizedBox(width: 12),
                            const Icon(Icons.location_on, size: 13, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Expanded(child: Text(ev['location'], style: const TextStyle(fontSize: 12, color: Color(0xFF475569)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Dept: ${ev['dept']} · Organizer: ${ev['organizer']}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 3. WEEK & DAY VIEWS
  // ===========================================================================
  Widget _buildWeekTimelineView() {
    return _buildAgendaTimelineView(); // Streamlined adaptive layout
  }

  Widget _buildDayHourlyView() {
    return _buildAgendaTimelineView();
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[(month - 1).clamp(0, 11)];
  }
}
