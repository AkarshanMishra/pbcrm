import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _tickets = [];
  Map<String, dynamic> _metrics = {};
  List<dynamic> _departments = [];
  List<dynamic> _employees = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final tRes = await _api.dio.get('/tickets/');
      _tickets = tRes.data['results'] ?? tRes.data ?? [];
    } catch (_) {}

    try {
      final mRes = await _api.dio.get('/tickets/metrics/');
      _metrics = mRes.data ?? {};
    } catch (_) {}

    try {
      final dRes = await _api.dio.get('/departments/');
      _departments = dRes.data['results'] ?? dRes.data ?? [];
    } catch (_) {}

    try {
      final eRes = await _api.dio.get('/employees/');
      _employees = eRes.data['results'] ?? eRes.data ?? [];
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  List<dynamic> get _filteredTickets {
    switch (_tabController.index) {
      case 0: // All
        return _tickets;
      case 1: // Open
        return _tickets.where((t) => t['status'] == 'OPEN').toList();
      case 2: // In Progress
        return _tickets.where((t) => t['status'] == 'IN_PROGRESS').toList();
      case 3: // Resolved
        return _tickets.where((t) => t['status'] == 'RESOLVED').toList();
      case 4: // Closed
        return _tickets.where((t) => t['status'] == 'CLOSED').toList();
      default:
        return _tickets;
    }
  }

  Color _getPriorityColor(String? p) {
    switch (p) {
      case 'URGENT':
        return Colors.red;
      case 'HIGH':
        return Colors.orange.shade800;
      case 'MEDIUM':
        return Colors.amber.shade700;
      case 'LOW':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String? s) {
    switch (s) {
      case 'OPEN':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.amber.shade800;
      case 'RESOLVED':
        return Colors.green;
      case 'CLOSED':
        return Colors.grey;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showCreateTicketDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'IT_SUPPORT';
    String priority = 'MEDIUM';
    int? selectedDept;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.confirmation_number_outlined, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Raise Support Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Subject / Issue Summary *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'IT_SUPPORT', child: Text('IT & Hardware Support')),
                      DropdownMenuItem(value: 'HR_QUERY', child: Text('HR & Policies')),
                      DropdownMenuItem(value: 'ACCOUNTS_PAYROLL', child: Text('Accounts & Payroll')),
                      DropdownMenuItem(value: 'ASSET_REQUEST', child: Text('Asset / Equipment Request')),
                      DropdownMenuItem(value: 'LEAVE_ATTENDANCE', child: Text('Leave & Attendance')),
                      DropdownMenuItem(value: 'OPERATIONS', child: Text('Operations Support')),
                      DropdownMenuItem(value: 'PURCHASE', child: Text('Procurement & Purchase')),
                      DropdownMenuItem(value: 'GENERAL', child: Text('General Request')),
                    ],
                    onChanged: (val) => setDlgState(() => category = val ?? 'IT_SUPPORT'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.priority_high),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'LOW', child: Text('Low')),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                      DropdownMenuItem(value: 'HIGH', child: Text('High')),
                      DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
                    ],
                    onChanged: (val) => setDlgState(() => priority = val ?? 'MEDIUM'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedDept,
                    decoration: const InputDecoration(
                      labelText: 'Target Department (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.domain),
                    ),
                    items: _departments.map<DropdownMenuItem<int>>((d) {
                      return DropdownMenuItem<int>(
                        value: d['id'],
                        child: Text(d['name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) => setDlgState(() => selectedDept = val),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Detailed Description of Request / Issue *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill subject and description')),
                  );
                  return;
                }
                try {
                  await _api.dio.post('/tickets/', data: {
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'category': category,
                    'priority': priority,
                    'department': selectedDept,
                  });
                  Navigator.pop(ctx);
                  _fetchData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Support ticket raised successfully!')),
                  );
                } catch (err) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to raise ticket: $err')),
                  );
                }
              },
              child: const Text('Submit Ticket'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTicketDetails(Map<String, dynamic> ticket) {
    final commentCtrl = TextEditingController();
    final resNotesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ticket['ticket_number'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(ticket['priority']).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ticket['priority'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getPriorityColor(ticket['priority']),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(ticket['status']).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ticket['status'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(ticket['status']),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  ticket['title'] ?? '',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  ticket['description'] ?? '',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 16),
                const Divider(),
                Row(
                  children: [
                    Icon(Icons.person_pin, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text('Raised by: ${ticket['created_by_name'] ?? 'Staff'}', style: const TextStyle(fontSize: 12)),
                    const Spacer(),
                    Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(ticket['category'] ?? '', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                // Actions (Resolve / Close)
                if (ticket['status'] != 'CLOSED' && ticket['status'] != 'RESOLVED') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final notes = await showDialog<String>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Resolve Ticket'),
                                content: TextField(
                                  controller: resNotesCtrl,
                                  decoration: const InputDecoration(labelText: 'Resolution Summary *', border: OutlineInputBorder()),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(c, resNotesCtrl.text.trim()),
                                    child: const Text('Confirm Resolution'),
                                  ),
                                ],
                              ),
                            );
                            if (notes != null && notes.isNotEmpty) {
                              try {
                                await _api.dio.post('/tickets/${ticket['id']}/resolve/', data: {'resolution_notes': notes});
                                Navigator.pop(ctx);
                                _fetchData();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Resolve Ticket'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          int? selectedEmp;
                          final empId = await showDialog<int>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Assign Ticket to Staff'),
                              content: DropdownButtonFormField<int>(
                                decoration: const InputDecoration(labelText: 'Select Staff Member', border: OutlineInputBorder()),
                                items: _employees.map<DropdownMenuItem<int>>((e) {
                                  return DropdownMenuItem<int>(
                                    value: e['id'],
                                    child: Text('${e['full_name']} (${e['employee_id']})'),
                                  );
                                }).toList(),
                                onChanged: (v) => selectedEmp = v,
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(c, selectedEmp),
                                  child: const Text('Assign'),
                                ),
                              ],
                            ),
                          );
                          if (empId != null) {
                            try {
                              await _api.dio.post('/tickets/${ticket['id']}/assign/', data: {'assigned_to': empId});
                              if (mounted) {
                                Navigator.pop(ctx);
                                _fetchData();
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.person_add_alt),
                        label: const Text('Assign'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await _api.dio.post('/tickets/${ticket['id']}/close/');
                            if (mounted) {
                              Navigator.pop(ctx);
                              _fetchData();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          }
                        },
                        icon: const Icon(Icons.archive_outlined),
                        label: const Text('Close'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: commentCtrl,
                  decoration: InputDecoration(
                    hintText: 'Post a comment/update...',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, color: AppTheme.primary),
                      onPressed: () async {
                        if (commentCtrl.text.trim().isEmpty) return;
                        try {
                          await _api.dio.post('/tickets/${ticket['id']}/comments/', data: {
                            'comment': commentCtrl.text.trim(),
                          });
                          commentCtrl.clear();
                          Navigator.pop(ctx);
                          _fetchData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Comment posted!')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTickets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Internal Helpdesk & Requests'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primary,
          tabs: [
            Tab(text: 'All (${_tickets.length})'),
            Tab(text: 'Open (${_metrics['open'] ?? 0})'),
            Tab(text: 'In Progress (${_metrics['in_progress'] ?? 0})'),
            Tab(text: 'Resolved (${_metrics['resolved'] ?? 0})'),
            Tab(text: 'Closed (${_metrics['closed'] ?? 0})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTicketDialog,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Request / Ticket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.support_agent_rounded, size: 72, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'No Support Tickets in this view',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Raise a ticket for IT, HR, Ops or Equipment requests.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final t = filtered[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          onTap: () => _showTicketDetails(t),
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(t['status']).withOpacity(0.15),
                            child: Icon(Icons.confirmation_num_outlined, color: _getStatusColor(t['status'])),
                          ),
                          title: Row(
                            children: [
                              Text(
                                t['ticket_number'] ?? '',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t['title'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                t['description'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(t['priority']).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      t['priority'] ?? '',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getPriorityColor(t['priority'])),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    t['category'] ?? '',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                  const Spacer(),
                                  Text(
                                    t['created_at'] != null ? t['created_at'].toString().substring(0, 10) : '',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(t['status']).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              t['status'] ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(t['status']),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
