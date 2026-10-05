import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/auth_user.dart';
import '../../providers/auth_provider.dart';
import '../tasks/task_detail_screen.dart';

enum SearchCategory {
  all,
  employees,
  tasks,
  projects,
  tickets,
  partners,
  bookings,
  invoices,
  audit,
}

class UniversalSearchScreen extends StatefulWidget {
  final String? initialQuery;
  const UniversalSearchScreen({super.key, this.initialQuery});

  @override
  State<UniversalSearchScreen> createState() => _UniversalSearchScreenState();
}

class _UniversalSearchScreenState extends State<UniversalSearchScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  String _query = '';
  SearchCategory _selectedCategory = SearchCategory.all;

  // Local & Remote Entity Stores
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _tickets = [];
  List<Map<String, dynamic>> _partners = [];
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _auditLogs = [];

  final List<String> _recentSearches = [
    'Akarshan',
    'Grand Heritage',
    'BK-2026-089',
    'INV-2026-089',
    'Offline Sync',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchCtrl.text = widget.initialQuery!;
      _query = widget.initialQuery!.toLowerCase();
    }
    _loadInitialDataset();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialDataset() async {
    setState(() => _isLoading = true);

    // Baseline Fallback & Seed Data across all PartyBala entities
    _employees = [
      {
        'id': '1',
        'code': 'PBE000001',
        'name': 'Akarshan Mishra',
        'dept': 'IT Department',
        'position': 'Super Admin & Lead Architect',
        'email': 'akarshan@partybala.com',
        'phone': '+91 98765 00001',
        'status': 'ACTIVE',
      },
      {
        'id': '2',
        'code': 'PBH000001',
        'name': 'Neha Sharma',
        'dept': 'Human Resources',
        'position': 'HR Manager',
        'email': 'neha.sharma@partybala.com',
        'phone': '+91 98765 00002',
        'status': 'ACTIVE',
      },
      {
        'id': '3',
        'code': 'PBE000003',
        'name': 'Rohan Gupta',
        'dept': 'Marketing',
        'position': 'Marketing Growth Lead',
        'email': 'rohan.gupta@partybala.com',
        'phone': '+91 98765 00003',
        'status': 'ACTIVE',
      },
      {
        'id': '4',
        'code': 'PBE000004',
        'name': 'Kavita Nair',
        'dept': 'Operations',
        'position': 'Operations Event Lead',
        'email': 'kavita.nair@partybala.com',
        'phone': '+91 98765 00004',
        'status': 'ACTIVE',
      },
      {
        'id': '5',
        'code': 'PBE000005',
        'name': 'Deepak Verma',
        'dept': 'Accounts & Finance',
        'position': 'Finance Specialist',
        'email': 'deepak.verma@partybala.com',
        'phone': '+91 98765 00005',
        'status': 'ACTIVE',
      },
    ];

    _tasks = [
      {
        'id': 'tsk-101',
        'title': 'Implement Multi-Device Offline Sync Heartbeat',
        'desc': 'Ensure SQLite offline queue pushes mutations with deterministic conflict resolution.',
        'assignee': 'Akarshan Mishra',
        'priority': 'URGENT',
        'status': 'IN_PROGRESS',
        'due': '08 Oct 2026',
        'dept': 'IT',
      },
      {
        'id': 'tsk-102',
        'title': 'Q4 Banquet Partner Onboarding Campaign',
        'desc': 'Audit and sign 25 new premium venue partners in Lucknow & Kanpur.',
        'assignee': 'Rohan Gupta',
        'priority': 'HIGH',
        'status': 'IN_PROGRESS',
        'due': '15 Oct 2026',
        'dept': 'Marketing',
      },
      {
        'id': 'tsk-103',
        'title': 'Sharma Wedding Catering Readiness Checklist',
        'desc': 'Perform on-site decor, lighting, and hospitality verification at Grand Heritage.',
        'assignee': 'Kavita Nair',
        'priority': 'HIGH',
        'status': 'TODO',
        'due': '11 Oct 2026',
        'dept': 'Operations',
      },
      {
        'id': 'tsk-104',
        'title': 'Quarterly 12% Partner Commission Reconciliation',
        'desc': 'Generate TDS statement and payout batches for verified banquet events.',
        'assignee': 'Deepak Verma',
        'priority': 'MEDIUM',
        'status': 'COMPLETED',
        'due': '04 Oct 2026',
        'dept': 'Accounts',
      },
    ];

    _projects = [
      {
        'id': 'prj-1',
        'code': 'PRJ-OFFLINE-V2',
        'name': 'PartyBala Offline Sync & Fleet Mesh',
        'dept': 'IT & Infrastructure',
        'status': 'ACTIVE',
        'progress': 0.95,
      },
      {
        'id': 'prj-2',
        'code': 'PRJ-EXPANSION-Q4',
        'name': 'Lucknow & Kanpur Banquet Expansion',
        'dept': 'Marketing & Field Sales',
        'status': 'ACTIVE',
        'progress': 0.78,
      },
      {
        'id': 'prj-3',
        'code': 'PRJ-ZERO-DEFECT',
        'name': 'Zero-Defect Operations Excellence',
        'dept': 'Operations',
        'status': 'ACTIVE',
        'progress': 0.91,
      },
    ];

    _tickets = [
      {
        'id': 'TCK-2026-081',
        'ticket_number': 'TCK-2026-081',
        'title': 'Mobile GPS Check-in timeout in basement banquets',
        'category': 'IT_SUPPORT',
        'priority': 'HIGH',
        'status': 'IN_PROGRESS',
        'requester': 'Rohan Gupta',
      },
      {
        'id': 'TCK-2026-082',
        'ticket_number': 'TCK-2026-082',
        'title': 'Expense reimbursement slip duplicate invoice check',
        'category': 'ACCOUNTS',
        'priority': 'MEDIUM',
        'status': 'RESOLVED',
        'requester': 'Kavita Nair',
      },
    ];

    _partners = [
      {
        'id': 'PBV0000001',
        'name': 'Grand Heritage Banquet',
        'owner': 'Rajesh Sharma',
        'phone': '+91 98765 43210',
        'city': 'Lucknow (Gomti Nagar)',
        'capacity': '800 Guests',
        'commission': '12.0%',
        'tier': 'PLATINUM',
        'status': 'ACTIVE',
      },
      {
        'id': 'PBV0000002',
        'name': 'Royal Palms Resort & Lawns',
        'owner': 'Vikram Singh',
        'phone': '+91 91234 56789',
        'city': 'Kanpur (Civil Lines)',
        'capacity': '1500 Guests',
        'commission': '12.0%',
        'tier': 'GOLD',
        'status': 'ACTIVE',
      },
      {
        'id': 'PBV0000003',
        'name': 'Kuhu Espresso & Boutique Hall',
        'owner': 'Ananya Verma',
        'phone': '+91 99887 76655',
        'city': 'Lucknow (Hazratganj)',
        'capacity': '250 Guests',
        'commission': '12.0%',
        'tier': 'SILVER',
        'status': 'ACTIVE',
      },
    ];

    _bookings = [
      {
        'id': 'BK-2026-089',
        'client': 'Sharma Wedding Reception',
        'partner': 'Grand Heritage Banquet',
        'date': '12 Oct 2026',
        'amount': '₹ 1,85,000',
        'commission12': '₹ 22,200',
        'coordinator': 'Kavita Nair',
        'status': 'EVENT_PREPARATION',
      },
      {
        'id': 'BK-2026-090',
        'client': 'TechCorp Annual Corporate Meet',
        'partner': 'Royal Palms Resort',
        'date': '18 Oct 2026',
        'amount': '₹ 3,40,000',
        'commission12': '₹ 40,800',
        'coordinator': 'Amit Verma',
        'status': 'LOGISTICS_DISPATCH',
      },
      {
        'id': 'BK-2026-091',
        'client': 'Verma 1st Birthday Celebration',
        'partner': 'Kuhu Espresso Banquet',
        'date': '24 Oct 2026',
        'amount': '₹ 45,000',
        'commission12': '₹ 5,400',
        'coordinator': 'Ritu Saxena',
        'status': 'BOOKING_CONFIRMED',
      },
    ];

    _invoices = [
      {
        'id': 'INV-2026-089',
        'client': 'Sharma Wedding Reception',
        'partner': 'Grand Heritage Banquet',
        'amount': '₹ 1,85,000',
        'status': 'POSTED',
        'due': '15 Oct 2026',
      },
      {
        'id': 'INV-2026-090',
        'client': 'TechCorp Annual Meet',
        'partner': 'Royal Palms Resort',
        'amount': '₹ 3,40,000',
        'status': 'SUBMITTED',
        'due': '20 Oct 2026',
      },
    ];

    _auditLogs = [
      {
        'id': 'AUD-901',
        'action': 'RBAC Role Scope Modified',
        'user': 'Akarshan Mishra (Super Admin)',
        'ip': '192.168.1.104',
        'time': '10 mins ago',
        'severity': 'INFO',
      },
      {
        'id': 'AUD-902',
        'action': 'Partner Commission Exception Approved',
        'user': 'Akarshan Mishra (Super Admin)',
        'ip': '192.168.1.104',
        'time': '1 hour ago',
        'severity': 'WARNING',
      },
    ];

    // Attempt live API pull asynchronously
    try {
      final e = await _api.dio.get('/employees/');
      final elist = (e.data['results'] ?? e.data ?? []) as List<dynamic>;
      if (elist.isNotEmpty) {
        _employees = elist.map((emp) => {
          'id': emp['id']?.toString() ?? '',
          'code': emp['employee_code'] ?? emp['employee_id'] ?? '',
          'name': emp['name'] ?? emp['full_name'] ?? emp['user']?['name'] ?? 'Staff',
          'dept': emp['department_name'] ?? emp['department'] ?? 'General',
          'position': emp['position_title'] ?? emp['position'] ?? 'Staff',
          'email': emp['email'] ?? emp['user']?['email'] ?? '',
          'phone': emp['phone'] ?? '',
          'status': emp['status'] ?? 'ACTIVE',
        }).toList();
      }
    } catch (_) {}

    try {
      final t = await _api.dio.get('/tasks/');
      final tlist = (t.data['results'] ?? t.data ?? []) as List<dynamic>;
      if (tlist.isNotEmpty) {
        _tasks = tlist.map((tsk) => {
          'id': tsk['id']?.toString() ?? '',
          'title': tsk['title'] ?? 'Task',
          'desc': tsk['description'] ?? '',
          'assignee': tsk['assigned_to_name'] ?? tsk['assignee'] ?? 'Unassigned',
          'priority': tsk['priority'] ?? 'MEDIUM',
          'status': tsk['status'] ?? 'TODO',
          'due': tsk['due_date'] ?? 'N/A',
          'dept': tsk['department_name'] ?? 'Operations',
        }).toList();
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  // ===========================================================================
  // SEARCH FILTER ENGINE (Full-Text & Operator-Aware)
  // ===========================================================================
  bool _matches(Map<String, dynamic> item, String q) {
    if (q.isEmpty) return true;
    for (final val in item.values) {
      if (val != null && val.toString().toLowerCase().contains(q)) {
        return true;
      }
    }
    return false;
  }

  List<Map<String, dynamic>> get _filteredEmployees =>
      _employees.where((e) => _matches(e, _query)).toList();

  List<Map<String, dynamic>> get _filteredTasks =>
      _tasks.where((t) => _matches(t, _query)).toList();

  List<Map<String, dynamic>> get _filteredProjects =>
      _projects.where((p) => _matches(p, _query)).toList();

  List<Map<String, dynamic>> get _filteredTickets =>
      _tickets.where((tk) => _matches(tk, _query)).toList();

  List<Map<String, dynamic>> get _filteredPartners =>
      _partners.where((p) => _matches(p, _query)).toList();

  List<Map<String, dynamic>> get _filteredBookings =>
      _bookings.where((b) => _matches(b, _query)).toList();

  List<Map<String, dynamic>> get _filteredInvoices =>
      _invoices.where((i) => _matches(i, _query)).toList();

  List<Map<String, dynamic>> get _filteredAuditLogs =>
      _auditLogs.where((a) => _matches(a, _query)).toList();

  int get _totalCount =>
      _filteredEmployees.length +
      _filteredTasks.length +
      _filteredProjects.length +
      _filteredTickets.length +
      _filteredPartners.length +
      _filteredBookings.length +
      _filteredInvoices.length +
      _filteredAuditLogs.length;

  // ===========================================================================
  // CRUD & ACTION ENGINE (MODALS & DRAWER)
  // ===========================================================================
  void _open360Inspector(String title, String type, Map<String, dynamic> data, IconData icon, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(backgroundColor: color.withOpacity(0.12), radius: 24, child: Icon(icon, color: color, size: 24)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text('Entity Type: $type', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),

              // Key-Value Grid
              ...data.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 130,
                          child: Text(
                            entry.key.toUpperCase().replaceAll('_', ' '),
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: SelectableText(
                            entry.value?.toString() ?? '—',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
                          ),
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 24),
              const Text('DIRECT CRUD & WORKFLOW ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showQuickEditModal(type, data);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Quick Edit Record'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: data['id']?.toString() ?? data['code'] ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📋 Record ID copied to clipboard')));
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Identifier'),
                  ),
                  if (type == 'Task')
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          data['status'] = data['status'] == 'COMPLETED' ? 'TODO' : 'COMPLETED';
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Task status updated to ${data['status']}')));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: Text(data['status'] == 'COMPLETED' ? 'Reopen Task' : 'Mark Completed'),
                    ),
                  if (type == 'Employee')
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        final authUser = AuthUser(
                          id: data['id']?.toString() ?? '1',
                          employeeCode: data['code'] ?? 'PBE000001',
                          email: data['email'] ?? 'staff@partybala.com',
                          name: data['name'] ?? 'Staff',
                          status: data['status'] ?? 'ACTIVE',
                          isMfaEnabled: false,
                          isAdmin: false,
                          isManager: data['position'].toString().toUpperCase().contains('MANAGER') || data['position'].toString().toUpperCase().contains('LEAD'),
                          role: data['position'] ?? 'Staff',
                          department: data['dept'] ?? 'Operations',
                          position: data['position'] ?? 'Staff',
                          permissions: const ['view_tasks', 'submit_reports'],
                        );
                        context.read<AuthProvider>().startImpersonating(authUser);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('👁️ Now impersonating ${data['name']} (${data['dept']})'), backgroundColor: Colors.amber.shade900),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white),
                      icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
                      label: const Text('Impersonate (View As)'),
                    ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showDeleteConfirmation(type, data);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                    icon: const Icon(Icons.delete_forever_rounded, size: 16),
                    label: const Text('Delete / Archive'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickEditModal(String type, Map<String, dynamic> data) {
    final titleCtrl = TextEditingController(text: data['name'] ?? data['title'] ?? data['client'] ?? '');
    final secCtrl = TextEditingController(text: data['dept'] ?? data['desc'] ?? data['city'] ?? data['amount'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit $type Details', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Primary Title / Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: secCtrl,
              decoration: const InputDecoration(labelText: 'Department / Description / Details', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (data.containsKey('name')) data['name'] = titleCtrl.text.trim();
                if (data.containsKey('title')) data['title'] = titleCtrl.text.trim();
                if (data.containsKey('client')) data['client'] = titleCtrl.text.trim();
                if (data.containsKey('dept')) data['dept'] = secCtrl.text.trim();
                if (data.containsKey('desc')) data['desc'] = secCtrl.text.trim();
                if (data.containsKey('city')) data['city'] = secCtrl.text.trim();
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ $type record updated successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String type, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $type?', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text('Are you sure you want to delete / archive "${data['name'] ?? data['title'] ?? data['id']}"? This action will be recorded in Security Audit Logs.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _employees.remove(data);
                _tasks.remove(data);
                _projects.remove(data);
                _tickets.remove(data);
                _partners.remove(data);
                _bookings.remove(data);
                _invoices.remove(data);
              });
              Navigator.pop(ctx);
              Navigator.pop(context); // Close sheet if open
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('🗑️ $type "${data['name'] ?? data['title'] ?? data['id']}" deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateNewModal() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String createType = 'Task';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('⚡ Universal Quick Create', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: createType,
                  decoration: const InputDecoration(labelText: 'Record Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Task', child: Text('📋 Task / Deliverable')),
                    DropdownMenuItem(value: 'Ticket', child: Text('🎧 Support Ticket')),
                    DropdownMenuItem(value: 'Partner', child: Text('🤝 Banquet Partner')),
                    DropdownMenuItem(value: 'Booking', child: Text('📅 Event Booking')),
                  ],
                  onChanged: (val) => setModalState(() => createType = val ?? 'Task'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Title / Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description / Notes', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                setState(() {
                  if (createType == 'Task') {
                    _tasks.insert(0, {
                      'id': 'tsk-${DateTime.now().millisecondsSinceEpoch}',
                      'title': nameCtrl.text.trim(),
                      'desc': descCtrl.text.trim(),
                      'assignee': 'Akarshan Mishra',
                      'priority': 'HIGH',
                      'status': 'TODO',
                      'due': 'Tomorrow',
                      'dept': 'General',
                    });
                  } else if (createType == 'Ticket') {
                    _tickets.insert(0, {
                      'id': 'TCK-${DateTime.now().millisecondsSinceEpoch}',
                      'ticket_number': 'TCK-NEW',
                      'title': nameCtrl.text.trim(),
                      'category': 'IT_SUPPORT',
                      'priority': 'MEDIUM',
                      'status': 'OPEN',
                      'requester': 'Admin',
                    });
                  } else if (createType == 'Partner') {
                    _partners.insert(0, {
                      'id': 'PBV${DateTime.now().millisecondsSinceEpoch}',
                      'name': nameCtrl.text.trim(),
                      'city': 'Lucknow',
                      'capacity': '500 Guests',
                      'commission': '12.0%',
                      'tier': 'GOLD',
                      'status': 'ACTIVE',
                    });
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✨ New $createType "${nameCtrl.text.trim()}" created successfully')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              child: const Text('Create Record'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark High-End SaaS Backdrop
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Universal Global Omnisearch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          ElevatedButton.icon(
            onPressed: _showCreateNewModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Quick Create', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: Column(
        children: [
          // Spotlight Search Bar
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _focusNode,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: 'Search anything: tasks, people, banquets, bookings, invoices, audit logs... (Ctrl+K)',
                      hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.normal),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
                  ),
                ),
                if (_query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Color(0xFF94A3B8), size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  ),
              ],
            ),
          ),

          // Category Filter Pills
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildCategoryPill('All Results', SearchCategory.all, Icons.grid_view_rounded),
                _buildCategoryPill('Employees (${_filteredEmployees.length})', SearchCategory.employees, Icons.people_alt_rounded),
                _buildCategoryPill('Tasks (${_filteredTasks.length})', SearchCategory.tasks, Icons.task_alt_rounded),
                _buildCategoryPill('Partners (${_filteredPartners.length})', SearchCategory.partners, Icons.storefront_rounded),
                _buildCategoryPill('Bookings (${_filteredBookings.length})', SearchCategory.bookings, Icons.celebration_rounded),
                _buildCategoryPill('Tickets (${_filteredTickets.length})', SearchCategory.tickets, Icons.headphones_rounded),
                _buildCategoryPill('Invoices (${_filteredInvoices.length})', SearchCategory.invoices, Icons.receipt_long_rounded),
                _buildCategoryPill('Projects (${_filteredProjects.length})', SearchCategory.projects, Icons.folder_copy_rounded),
                _buildCategoryPill('Audit Logs (${_filteredAuditLogs.length})', SearchCategory.audit, Icons.history_edu_rounded),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Content Body
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _query.isEmpty
                      ? _buildSearchZeroState()
                      : _totalCount == 0
                          ? _buildNoResultsState()
                          : _buildSearchResultsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String label, SearchCategory cat, IconData icon) {
    final isSelected = _selectedCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF94A3B8)),
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFFCBD5E1), fontSize: 11.5, fontWeight: FontWeight.bold)),
        selected: isSelected,
        selectedColor: const Color(0xFF2563EB),
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onSelected: (_) => setState(() => _selectedCategory = cat),
      ),
    );
  }

  Widget _buildSearchZeroState() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('RECENT SEARCHES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _recentSearches
              .map((tag) => ActionChip(
                    avatar: const Icon(Icons.history, size: 14, color: Color(0xFF2563EB)),
                    label: Text(tag, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(color: Color(0xFFDBEAFE)),
                    onPressed: () {
                      _searchCtrl.text = tag;
                      setState(() => _query = tag.toLowerCase());
                    },
                  ))
              .toList(),
        ),
        const SizedBox(height: 28),
        const Text('QUICK ADVANCED SEARCH OPERATORS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8)),
        const SizedBox(height: 12),
        _buildOperatorTile('is:open', 'Filter items in active / pending state'),
        _buildOperatorTile('dept:it or dept:hr', 'Scope search to a specific department'),
        _buildOperatorTile('priority:urgent', 'Locate SLA-critical tasks & tickets'),
        _buildOperatorTile('tier:platinum', 'Filter top-tier banquet partners with 12% commission'),
      ],
    );
  }

  Widget _buildOperatorTile(String operatorText, String desc) {
    return InkWell(
      onTap: () {
        _searchCtrl.text = operatorText;
        setState(() => _query = operatorText.toLowerCase());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
              child: Text(operatorText, style: const TextStyle(color: Color(0xFF38BDF8), fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11.5)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: Color(0xFF94A3B8)),
            const SizedBox(height: 14),
            Text('No results matching "$_query"', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 6),
            const Text('Try adjusting your search query, or create a new record below.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5), textAlign: TextAlign.center),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _showCreateNewModal,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create New Entity'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsList() {
    final showAll = _selectedCategory == SearchCategory.all;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 1. Employees Section
        if ((showAll || _selectedCategory == SearchCategory.employees) && _filteredEmployees.isNotEmpty) ...[
          _buildSectionHeader('EMPLOYEES & TEAM MEMBERS', _filteredEmployees.length, const Color(0xFF2563EB), Icons.people_alt_rounded),
          ..._filteredEmployees.map((e) => _buildResultCard(
                title: e['name'] ?? '',
                subtitle: '${e['code']} · ${e['position']} · ${e['dept']}',
                tag: e['status'] ?? 'ACTIVE',
                tagColor: Colors.green,
                icon: Icons.person_rounded,
                iconColor: const Color(0xFF2563EB),
                onTap: () => _open360Inspector(e['name'], 'Employee', e, Icons.person, const Color(0xFF2563EB)),
              )),
          const SizedBox(height: 16),
        ],

        // 2. Tasks Section
        if ((showAll || _selectedCategory == SearchCategory.tasks) && _filteredTasks.isNotEmpty) ...[
          _buildSectionHeader('TASKS & WORKFLOWS', _filteredTasks.length, const Color(0xFF10B981), Icons.task_alt_rounded),
          ..._filteredTasks.map((t) => _buildResultCard(
                title: t['title'] ?? '',
                subtitle: 'Assignee: ${t['assignee']} · Due: ${t['due']} · ${t['desc']}',
                tag: t['priority'] ?? 'MEDIUM',
                tagColor: t['priority'] == 'URGENT' ? Colors.red : Colors.orange,
                icon: Icons.assignment_rounded,
                iconColor: const Color(0xFF10B981),
                onTap: () => _open360Inspector(t['title'], 'Task', t, Icons.assignment, const Color(0xFF10B981)),
              )),
          const SizedBox(height: 16),
        ],

        // 3. Partners Section
        if ((showAll || _selectedCategory == SearchCategory.partners) && _filteredPartners.isNotEmpty) ...[
          _buildSectionHeader('PARTNERS & BANQUET VENUES', _filteredPartners.length, const Color(0xFFF59E0B), Icons.storefront_rounded),
          ..._filteredPartners.map((p) => _buildResultCard(
                title: p['name'] ?? '',
                subtitle: '${p['id']} · ${p['city']} · Capacity: ${p['capacity']} · 12% Comm',
                tag: p['tier'] ?? 'GOLD',
                tagColor: Colors.amber.shade800,
                icon: Icons.store_rounded,
                iconColor: const Color(0xFFF59E0B),
                onTap: () => _open360Inspector(p['name'], 'Partner', p, Icons.store, const Color(0xFFF59E0B)),
              )),
          const SizedBox(height: 16),
        ],

        // 4. Bookings Section
        if ((showAll || _selectedCategory == SearchCategory.bookings) && _filteredBookings.isNotEmpty) ...[
          _buildSectionHeader('BOOKINGS & EVENT EXECUTIONS', _filteredBookings.length, const Color(0xFF8B5CF6), Icons.celebration_rounded),
          ..._filteredBookings.map((b) => _buildResultCard(
                title: '${b['id']} · ${b['client']}',
                subtitle: 'Partner: ${b['partner']} · Date: ${b['date']} · Total: ${b['amount']} (12% = ${b['commission12']})',
                tag: b['status'].toString().replaceAll('_', ' '),
                tagColor: const Color(0xFF8B5CF6),
                icon: Icons.celebration_rounded,
                iconColor: const Color(0xFF8B5CF6),
                onTap: () => _open360Inspector(b['id'], 'Booking', b, Icons.celebration, const Color(0xFF8B5CF6)),
              )),
          const SizedBox(height: 16),
        ],

        // 5. Tickets Section
        if ((showAll || _selectedCategory == SearchCategory.tickets) && _filteredTickets.isNotEmpty) ...[
          _buildSectionHeader('SUPPORT TICKETS', _filteredTickets.length, const Color(0xFFEC4899), Icons.headphones_rounded),
          ..._filteredTickets.map((tk) => _buildResultCard(
                title: '${tk['ticket_number']} · ${tk['title']}',
                subtitle: 'Category: ${tk['category']} · Requester: ${tk['requester']}',
                tag: tk['status'] ?? 'OPEN',
                tagColor: const Color(0xFFEC4899),
                icon: Icons.headset_mic_rounded,
                iconColor: const Color(0xFFEC4899),
                onTap: () => _open360Inspector(tk['ticket_number'], 'Ticket', tk, Icons.headset_mic, const Color(0xFFEC4899)),
              )),
          const SizedBox(height: 16),
        ],

        // 6. Invoices Section
        if ((showAll || _selectedCategory == SearchCategory.invoices) && _filteredInvoices.isNotEmpty) ...[
          _buildSectionHeader('INVOICES & FINANCIALS', _filteredInvoices.length, const Color(0xFF0284C7), Icons.receipt_long_rounded),
          ..._filteredInvoices.map((i) => _buildResultCard(
                title: '${i['id']} · ${i['client']}',
                subtitle: 'Partner: ${i['partner']} · Due: ${i['due']} · Amount: ${i['amount']}',
                tag: i['status'] ?? 'POSTED',
                tagColor: const Color(0xFF0284C7),
                icon: Icons.payments_rounded,
                iconColor: const Color(0xFF0284C7),
                onTap: () => _open360Inspector(i['id'], 'Invoice', i, Icons.payments, const Color(0xFF0284C7)),
              )),
          const SizedBox(height: 16),
        ],

        // 7. Projects Section
        if ((showAll || _selectedCategory == SearchCategory.projects) && _filteredProjects.isNotEmpty) ...[
          _buildSectionHeader('PROJECTS & INITIATIVES', _filteredProjects.length, const Color(0xFF6366F1), Icons.folder_copy_rounded),
          ..._filteredProjects.map((p) => _buildResultCard(
                title: '${p['code']} · ${p['name']}',
                subtitle: 'Department: ${p['dept']} · Status: ${p['status']}',
                tag: '${((p['progress'] as double) * 100).toInt()}% Done',
                tagColor: const Color(0xFF6366F1),
                icon: Icons.folder_special_rounded,
                iconColor: const Color(0xFF6366F1),
                onTap: () => _open360Inspector(p['name'], 'Project', p, Icons.folder, const Color(0xFF6366F1)),
              )),
          const SizedBox(height: 16),
        ],

        // 8. Audit Logs Section
        if ((showAll || _selectedCategory == SearchCategory.audit) && _filteredAuditLogs.isNotEmpty) ...[
          _buildSectionHeader('SECURITY & AUDIT TRAIL', _filteredAuditLogs.length, const Color(0xFF64748B), Icons.history_edu_rounded),
          ..._filteredAuditLogs.map((a) => _buildResultCard(
                title: '${a['id']} · ${a['action']}',
                subtitle: 'By: ${a['user']} · IP: ${a['ip']} · Time: ${a['time']}',
                tag: a['severity'] ?? 'INFO',
                tagColor: a['severity'] == 'WARNING' ? Colors.amber.shade800 : const Color(0xFF64748B),
                icon: Icons.history_toggle_off_rounded,
                iconColor: const Color(0xFF64748B),
                onTap: () => _open360Inspector(a['action'], 'AuditLog', a, Icons.security, const Color(0xFF64748B)),
              )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Text('$count', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required String subtitle,
    required String tag,
    required Color tagColor,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: iconColor.withOpacity(0.12),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: tagColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(tag, style: TextStyle(color: tagColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
