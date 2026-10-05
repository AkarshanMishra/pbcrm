import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ApiClient _api = ApiClient();
  DateTime _focusedDate = DateTime.now();
  String _selectedView = 'Month'; // 'Day', 'Week', 'Month', 'Agenda'
  String _selectedEventType = 'ALL';

  final List<Map<String, dynamic>> _mockEvents = [
    {
      'id': 'ev-1',
      'title': 'Q4 Executive Leadership Review',
      'type': 'MEETING',
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'time': '10:00 AM - 11:30 AM',
      'dept': 'Management',
      'attendees': 'All Dept Heads',
      'color': Colors.blue,
    },
    {
      'id': 'ev-2',
      'title': 'Grand Heritage Banquet Inspection',
      'type': 'VISIT',
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'time': '02:00 PM - 03:30 PM',
      'dept': 'Marketing',
      'attendees': 'Rahul Verma, Amit Sen',
      'color': Colors.pink,
    },
    {
      'id': 'ev-3',
      'title': 'Royal Palms Wedding Reception Service',
      'type': 'BOOKING',
      'date': DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10),
      'time': '06:00 PM - 11:00 PM',
      'dept': 'Operations',
      'attendees': 'Ops Ground Crew (12 members)',
      'color': Colors.amber.shade900,
    },
    {
      'id': 'ev-4',
      'title': 'Production Staging Deploy v2.5',
      'type': 'DEPLOYMENT',
      'date': DateTime.now().add(const Duration(days: 2)).toIso8601String().substring(0, 10),
      'time': '11:30 PM - 01:00 AM',
      'dept': 'IT Ops',
      'attendees': 'DevOps & Backend Team',
      'color': Colors.purple,
    },
    {
      'id': 'ev-5',
      'title': 'Deepak Joshi (Annual Leave)',
      'type': 'LEAVE',
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'time': 'Full Day',
      'dept': 'HR',
      'attendees': 'Approved by HR Lead',
      'color': Colors.green,
    },
  ];

  void _showAddEventDialog() {
    final titleCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '10:00 AM - 11:00 AM');
    final attendeesCtrl = TextEditingController();
    String type = 'MEETING';
    String dept = 'Management';
    DateTime eventDate = _focusedDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.event_available_rounded, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Schedule Organization Event', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
                    decoration: const InputDecoration(labelText: 'Event Title *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: type,
                          decoration: const InputDecoration(labelText: 'Event Category', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'MEETING', child: Text('Meeting')),
                            DropdownMenuItem(value: 'VISIT', child: Text('Partner Visit')),
                            DropdownMenuItem(value: 'BOOKING', child: Text('Event Booking')),
                            DropdownMenuItem(value: 'DEPLOYMENT', child: Text('Deployment')),
                            DropdownMenuItem(value: 'LEAVE', child: Text('Employee Leave')),
                            DropdownMenuItem(value: 'DEADLINE', child: Text('Project Deadline')),
                          ],
                          onChanged: (val) => setDlgState(() => type = val ?? 'MEETING'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: dept,
                          decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'Management', child: Text('Management')),
                            DropdownMenuItem(value: 'HR', child: Text('HR')),
                            DropdownMenuItem(value: 'IT Ops', child: Text('IT Ops')),
                            DropdownMenuItem(value: 'Marketing', child: Text('Marketing')),
                            DropdownMenuItem(value: 'Operations', child: Text('Operations')),
                            DropdownMenuItem(value: 'Accounts', child: Text('Accounts')),
                          ],
                          onChanged: (val) => setDlgState(() => dept = val ?? 'Management'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Event Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    subtitle: Text(eventDate.toIso8601String().substring(0, 10)),
                    trailing: const Icon(Icons.calendar_month, color: AppTheme.primary),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: eventDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setDlgState(() => eventDate = picked);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: timeCtrl,
                    decoration: const InputDecoration(labelText: 'Time / Duration', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: attendeesCtrl,
                    decoration: const InputDecoration(labelText: 'Assign Attendees / Team Members', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                setState(() {
                  _mockEvents.add({
                    'id': 'ev-${DateTime.now().millisecondsSinceEpoch}',
                    'title': titleCtrl.text.trim(),
                    'type': type,
                    'date': eventDate.toIso8601String().substring(0, 10),
                    'time': timeCtrl.text.trim(),
                    'dept': dept,
                    'attendees': attendeesCtrl.text.trim(),
                    'color': type == 'MEETING'
                        ? Colors.blue
                        : type == 'VISIT'
                            ? Colors.pink
                            : type == 'BOOKING'
                                ? Colors.amber.shade900
                                : Colors.purple,
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Calendar event scheduled & invites dispatched!'), backgroundColor: AppTheme.success),
                );
              },
              child: const Text('Create Event'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _mockEvents.where((e) {
      if (_selectedEventType != 'ALL' && e['type'] != _selectedEventType) return false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization Master Calendar'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.view_agenda_rounded),
            tooltip: 'View Mode',
            onSelected: (v) => setState(() => _selectedView = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Month', child: Text('Month View')),
              PopupMenuItem(value: 'Week', child: Text('Week View')),
              PopupMenuItem(value: 'Day', child: Text('Day View')),
              PopupMenuItem(value: 'Agenda', child: Text('Agenda Timeline')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Event',
            onPressed: _showAddEventDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEventDialog,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Schedule Event'),
      ),
      body: Column(
        children: [
          // Filter Chips & Date Navigator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => setState(() => _focusedDate = _focusedDate.subtract(const Duration(days: 30))),
                        ),
                        Text(
                          '${_getMonthName(_focusedDate.month)} ${_focusedDate.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => setState(() => _focusedDate = _focusedDate.add(const Duration(days: 30))),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                      child: Text('View: $_selectedView', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All Events'),
                      _buildFilterChip('MEETING', 'Meetings'),
                      _buildFilterChip('BOOKING', 'Bookings & Events'),
                      _buildFilterChip('VISIT', 'Partner Visits'),
                      _buildFilterChip('DEPLOYMENT', 'Deployments'),
                      _buildFilterChip('LEAVE', 'Leaves'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Events Timeline / Agenda List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final ev = filtered[i];
                final Color color = ev['color'] ?? Colors.blue;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: color, width: 5)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ev['title'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                ev['type'],
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(ev['date'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 12),
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(ev['time'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Department: ${ev['dept']} • Attendees: ${ev['attendees']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.edit, size: 14),
                              label: const Text('Reschedule', style: TextStyle(fontSize: 11)),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () {
                                setState(() => _mockEvents.remove(ev));
                              },
                              icon: const Icon(Icons.cancel_outlined, size: 14, color: Colors.red),
                              label: const Text('Cancel', style: TextStyle(fontSize: 11, color: Colors.red)),
                            ),
                          ],
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
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedEventType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : Colors.black87)),
        selected: isSelected,
        selectedColor: AppTheme.primary,
        backgroundColor: Colors.grey.shade100,
        onSelected: (val) => setState(() => _selectedEventType = value),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[(month - 1).clamp(0, 11)];
  }
}
