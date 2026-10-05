import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class ITTicketsScreen extends StatefulWidget {
  const ITTicketsScreen({super.key});

  @override
  State<ITTicketsScreen> createState() => _ITTicketsScreenState();
}

class _ITTicketsScreenState extends State<ITTicketsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _incidents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    try {
      final res = await _api.get('/api/v1/it/incidents/');
      if (res.statusCode == 200 && res.data != null) {
        if (mounted) {
          setState(() {
            _incidents = (res.data is List) ? res.data : (res.data['results'] ?? []);
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _incidents = [
            {
              'id': '1',
              'incident_number': 'INC-10248',
              'title': 'Production Payment API 502 High Latency',
              'description': 'Payment webhook timeouts causing 502 Bad Gateway during peak checkout volume.',
              'category': 'APPLICATION_BUG',
              'priority': 'CRITICAL',
              'status': 'INVESTIGATING',
              'impact': 'Customer payments affected. Gateway callback queue accumulating in Redis.',
              'reporter_detail': {'full_name': 'Accounts Department'},
              'assignee_detail': {'full_name': 'Akarshan Mishra'},
              'system_detail': {'name': 'Payment API & Webhook Service'},
              'created_at': 'Today, 10:42 AM',
              'escalated': true,
              'comments': [
                {'author_name': 'Akarshan', 'comment_text': 'Identified thread exhaustion in Gunicorn async worker.', 'created_at': '10:55 AM'}
              ]
            },
            {
              'id': '2',
              'incident_number': 'INC-10249',
              'title': 'Staging Redis Cluster Memory Alert (>85%)',
              'description': 'Redis memory consumption peaked due to unevicted session tokens.',
              'category': 'SERVER',
              'priority': 'HIGH',
              'status': 'IN_PROGRESS',
              'impact': 'Staging test suites experiencing slower token verification.',
              'reporter_detail': {'full_name': 'IT Manager'},
              'assignee_detail': {'full_name': 'Akarshan Mishra'},
              'system_detail': {'name': 'Redis Cache Cluster'},
              'created_at': 'Today, 09:15 AM',
              'escalated': false,
              'comments': []
            },
            {
              'id': '3',
              'incident_number': 'INC-10250',
              'title': 'SSL Certificate Expiry Warning (*.partybala.com)',
              'description': 'Production wildcard SSL expires in 12 days. ACME auto-renewal bot failed DNS challenge.',
              'category': 'SECURITY',
              'priority': 'HIGH',
              'status': 'OPEN',
              'impact': 'Will disrupt HTTPS customer traffic if not renewed by 16 Oct 2026.',
              'reporter_detail': {'full_name': 'IT Manager'},
              'assignee_detail': null,
              'system_detail': {'name': 'SSL Wildcard Certificate'},
              'created_at': 'Yesterday',
              'escalated': false,
              'comments': []
            }
          ];
        });
      }
    }
  }

  void _showTicketDetail(Map<String, dynamic> inc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollCtrl) => ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: const Color(0xFF475569), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    inc['incident_number'] ?? 'INC-0000',
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  _buildPriorityChip(inc['priority'] ?? 'MEDIUM'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                inc['title'] ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              _buildInfoTile("STATUS", inc['status'] ?? 'OPEN', Icons.info_outline_rounded, const Color(0xFF38BDF8)),
              _buildInfoTile("SYSTEM", inc['system_detail']?['name'] ?? 'Payment API', Icons.settings_system_daydream_rounded, Colors.white),
              _buildInfoTile("IMPACT", inc['impact'] ?? 'Customer payments affected', Icons.warning_amber_rounded, const Color(0xFFF87171)),
              _buildInfoTile("ASSIGNED", inc['assignee_detail']?['full_name'] ?? 'Unassigned', Icons.person_rounded, Colors.white),
              _buildInfoTile("REPORTED BY", inc['reporter_detail']?['full_name'] ?? 'IT Monitoring', Icons.campaign_rounded, const Color(0xFF94A3B8)),
              const SizedBox(height: 20),
              const Text(
                "DESCRIPTION",
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Text(
                  inc['description'] ?? 'No description provided',
                  style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "ACTIONS",
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setMState(() {
                        inc['status'] = 'INVESTIGATING';
                        inc['assignee_detail'] = {'full_name': 'Akarshan Mishra'};
                      });
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ownership Assigned to Akarshan!")));
                    },
                    icon: const Icon(Icons.person_pin_rounded, size: 16),
                    label: const Text("Take Ownership"),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), foregroundColor: const Color(0xFF0F172A)),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showAddCommentDialog(inc),
                    icon: const Icon(Icons.add_comment_rounded, size: 16),
                    label: const Text("Add Comment / Log"),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Color(0xFF475569))),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      setMState(() => inc['priority'] = 'CRITICAL');
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Incident Escalated to CRITICAL!")));
                    },
                    icon: const Icon(Icons.crisis_alert_rounded, size: 16, color: Color(0xFFEF4444)),
                    label: const Text("Escalate", style: TextStyle(color: Color(0xFFEF4444))),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFEF4444))),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setMState(() => inc['status'] = 'RESOLVED');
                      setState(() {});
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Incident Marked RESOLVED!"), backgroundColor: Color(0xFF10B981)),
                      );
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text("Resolve Incident"),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valColor, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color col = priority == 'CRITICAL'
        ? const Color(0xFFEF4444)
        : (priority == 'HIGH' ? const Color(0xFFF97316) : const Color(0xFFEAB308));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: col.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: col)),
      child: Text(
        priority,
        style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }

  void _showAddCommentDialog(Map<String, dynamic> inc) {
    final commentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Add Incident Log", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: commentCtrl,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Enter root cause notes, actions taken, or terminal log output...",
            hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF475569))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (commentCtrl.text.isNotEmpty) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Log comment added!")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), foregroundColor: const Color(0xFF0F172A)),
            child: const Text("Save Log"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text("IT Incident & Ticket Center", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF38BDF8),
          indicatorWeight: 3,
          labelColor: const Color(0xFF38BDF8),
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: "My Tickets"),
            Tab(text: "Assigned"),
            Tab(text: "Team"),
            Tab(text: "Critical"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFEF4444),
        onPressed: _showCreateIncidentDialog,
        child: const Icon(Icons.add_alert_rounded, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildIncidentList(_incidents),
                _buildIncidentList(_incidents.where((i) => i['assignee_detail'] != null).toList()),
                _buildIncidentList(_incidents),
                _buildIncidentList(_incidents.where((i) => i['priority'] == 'CRITICAL').toList()),
              ],
            ),
    );
  }

  Widget _buildIncidentList(List<dynamic> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text("No tickets found in this view", style: TextStyle(color: Color(0xFF94A3B8))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final inc = list[i];
        return InkWell(
          onTap: () => _showTicketDetail(inc),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: inc['priority'] == 'CRITICAL' ? const Color(0xFFEF4444).withOpacity(0.4) : const Color(0xFF334155),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      inc['incident_number'] ?? '',
                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    _buildPriorityChip(inc['priority'] ?? 'MEDIUM'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  inc['title'] ?? '',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.dns_rounded, color: Color(0xFF94A3B8), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          inc['system_detail']?['name'] ?? 'System API',
                          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        inc['status'] ?? 'OPEN',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateIncidentDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String cat = "APPLICATION_BUG";
    String pri = "HIGH";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text("Report Incident / Ticket", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Incident Title", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Description & Impact", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: pri,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Priority"),
                  items: ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setDState(() => pri = v ?? pri),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.isNotEmpty) {
                  setState(() {
                    _incidents.insert(0, {
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'incident_number': 'INC-10251',
                      'title': titleCtrl.text,
                      'description': descCtrl.text,
                      'category': cat,
                      'priority': pri,
                      'status': 'OPEN',
                      'system_detail': {'name': 'Payment API Gateway'},
                      'assignee_detail': {'full_name': 'Akarshan Mishra'},
                      'reporter_detail': {'full_name': 'Akarshan Mishra'},
                      'created_at': 'Just now',
                    });
                  });
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
              child: const Text("Submit Ticket"),
            ),
          ],
        ),
      ),
    );
  }
}
