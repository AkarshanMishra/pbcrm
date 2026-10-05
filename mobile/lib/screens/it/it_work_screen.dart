import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class ITWorkScreen extends StatefulWidget {
  const ITWorkScreen({super.key});

  @override
  State<ITWorkScreen> createState() => _ITWorkScreenState();
}

class _ITWorkScreenState extends State<ITWorkScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _api = ApiClient();
  bool _isLoading = false;
  
  List<Map<String, dynamic>> _myTasks = [];
  List<Map<String, dynamic>> _bugs = [];
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _sprints = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadWorkData();
  }

  void _loadWorkData() {
    setState(() {
      _myTasks = [
        {
          'id': '1',
          'title': 'Fix Payment Webhook Idempotency & DB Connection Pool',
          'type': 'Development',
          'priority': 'URGENT',
          'status': 'In Progress',
          'project': 'PartyBala Core Platform',
          'sprint': 'Sprint 18 (Backend Stability)',
          'due_date': 'Today, 06:00 PM',
          'environment': 'Production',
          'git_ref': 'feat/payment-gateway-fix (PR #248)',
          'related_ticket': 'INC-10248',
          'assignee': 'Akarshan Mishra',
          'dependencies': 'PostgreSQL Pool Config, Redis Webhook Queue',
        },
        {
          'id': '2',
          'title': 'Review Auth MFA Token Refresh PR',
          'type': 'Code Review',
          'priority': 'HIGH',
          'status': 'Code Review',
          'project': 'PartyBala Auth & Security',
          'sprint': 'Sprint 18',
          'due_date': 'Today, 11:30 AM',
          'environment': 'Staging',
          'git_ref': 'feat/mfa-jwt-refresh (PR #247)',
          'related_ticket': 'REQ-IT-2026-0014',
          'assignee': 'Akarshan Mishra',
          'dependencies': 'None',
        },
        {
          'id': '3',
          'title': 'Deploy Staging Release Candidate v2.8.4-rc1',
          'type': 'Deployment',
          'priority': 'HIGH',
          'status': 'Ready for Deploy',
          'project': 'PartyBala Enterprise CRM',
          'sprint': 'Sprint 18',
          'due_date': 'Today, 02:00 PM',
          'environment': 'Staging',
          'git_ref': 'release/v2.8.4',
          'related_ticket': '-',
          'assignee': 'Akarshan Mishra',
          'dependencies': 'Automated test suite passing',
        },
        {
          'id': '4',
          'title': 'PostgreSQL Backup Consistency Verification & Test Restore',
          'type': 'Database',
          'priority': 'MEDIUM',
          'status': 'Assigned',
          'project': 'Infrastructure & DevOps',
          'sprint': 'Sprint 18',
          'due_date': 'Tomorrow',
          'environment': 'Production',
          'git_ref': '-',
          'related_ticket': 'INC-10250',
          'assignee': 'Akarshan Mishra',
          'dependencies': 'S3 Snapshot Available',
        },
        {
          'id': '5',
          'title': 'Update API Gateway Rate Limiting SOP in Knowledge Base',
          'type': 'Documentation',
          'priority': 'LOW',
          'status': 'Done',
          'project': 'DevOps Docs',
          'sprint': 'Sprint 17',
          'due_date': 'Yesterday',
          'environment': 'All',
          'git_ref': 'docs/gateway-sop',
          'related_ticket': '-',
          'assignee': 'Akarshan Mishra',
          'dependencies': 'None',
        },
      ];

      _bugs = [
        {
          'id': 'b1',
          'title': 'Webhook 502 Timeout on peak concurrent checkouts',
          'priority': 'URGENT',
          'status': 'In Progress',
          'environment': 'Production',
          'affected_component': 'Payment API Gateway',
          'reported_by': 'Accounts Department',
          'git_ref': 'PR #248',
        },
        {
          'id': 'b2',
          'title': 'Redis memory leak warning on session store cluster',
          'priority': 'HIGH',
          'status': 'Testing',
          'environment': 'Staging',
          'affected_component': 'Redis Cache Cluster',
          'reported_by': 'DevOps Monitoring Bot',
          'git_ref': 'hotfix/redis-eviction',
        },
        {
          'id': 'b3',
          'title': 'JWT Token refresh failure on slow mobile 3G networks',
          'priority': 'MEDIUM',
          'status': 'Done',
          'environment': 'Production',
          'affected_component': 'Auth Service',
          'reported_by': 'Customer Mobile App QA',
          'git_ref': 'PR #247',
        },
      ];

      _projects = [
        {
          'name': 'PartyBala Core Platform',
          'code': 'PBC-01',
          'status': 'Active',
          'sprint': 'Sprint 18',
          'progress': 78,
          'open_tasks': 14,
          'open_bugs': 2,
          'lead': 'IT Engineering Manager',
        },
        {
          'name': 'PartyBala Enterprise CRM (Phase 2)',
          'code': 'CRM-02',
          'status': 'Active',
          'sprint': 'Sprint 18',
          'progress': 92,
          'open_tasks': 4,
          'open_bugs': 1,
          'lead': 'Akarshan Mishra',
        },
        {
          'name': 'Security & Compliance (ISO 27001)',
          'code': 'SEC-04',
          'status': 'In Progress',
          'sprint': 'Sprint 18',
          'progress': 65,
          'open_tasks': 8,
          'open_bugs': 0,
          'lead': 'SecOps Team',
        },
      ];

      _sprints = [
        {
          'name': 'Sprint 18 (Q4 Platform Reliability)',
          'dates': '01 Oct - 14 Oct 2026',
          'status': 'Active (Day 4 of 14)',
          'velocity': '42 Story Points',
          'completed_points': 28,
          'total_tasks': 32,
          'completed_tasks': 18,
          'blocked_tasks': 2,
        },
        {
          'name': 'Sprint 17 (Marketing & Field Operations)',
          'dates': '16 Sep - 30 Sep 2026',
          'status': 'Completed',
          'velocity': '38 Story Points',
          'completed_points': 38,
          'total_tasks': 26,
          'completed_tasks': 26,
          'blocked_tasks': 0,
        },
      ];
    });
  }

  void _showTaskDetailSheet(Map<String, dynamic> task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                  ),
                  child: Text(
                    task['type'] ?? 'Task',
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                _buildPriorityBadge(task['priority'] ?? 'MEDIUM'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task['title'] ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _buildDetailRow("Lifecycle Status", task['status'] ?? 'Assigned', Icons.sync_rounded),
            _buildDetailRow("Project", task['project'] ?? '-', Icons.folder_rounded),
            _buildDetailRow("Sprint", task['sprint'] ?? '-', Icons.run_circle_outlined),
            _buildDetailRow("Environment", task['environment'] ?? 'Staging', Icons.cloud_done_rounded),
            _buildDetailRow("Git / PR Reference", task['git_ref'] ?? '-', Icons.merge_type_rounded),
            _buildDetailRow("Related Ticket", task['related_ticket'] ?? '-', Icons.confirmation_number_outlined),
            _buildDetailRow("Assignee", task['assignee'] ?? 'Akarshan', Icons.person_rounded),
            _buildDetailRow("Dependencies", task['dependencies'] ?? 'None', Icons.account_tree_rounded),
            const SizedBox(height: 24),
            const Text(
              "UPDATE TASK STATUS",
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.1),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'In Progress',
                'Code Review',
                'Testing',
                'Ready for Deploy',
                'Done',
                'Blocked'
              ].map((st) => ActionChip(
                label: Text(st),
                backgroundColor: task['status'] == st ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
                labelStyle: TextStyle(
                  color: task['status'] == st ? const Color(0xFF0F172A) : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                side: BorderSide(color: const Color(0xFF334155)),
                onPressed: () {
                  setState(() {
                    task['status'] = st;
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Task updated to $st"),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    if (priority == 'URGENT') {
      color = const Color(0xFFEF4444);
    } else if (priority == 'HIGH') {
      color = const Color(0xFFF97316);
    } else if (priority == 'MEDIUM') {
      color = const Color(0xFFEAB308);
    } else {
      color = const Color(0xFF10B981);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        priority,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
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
        title: const Text(
          "IT Work & Engineering Hub",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF38BDF8),
          indicatorWeight: 3,
          labelColor: const Color(0xFF38BDF8),
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: "My Tasks"),
            Tab(text: "Bugs"),
            Tab(text: "Projects"),
            Tab(text: "Sprints"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF38BDF8),
        onPressed: _showCreateTaskDialog,
        child: const Icon(Icons.add, color: Color(0xFF0F172A)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyTasksTab(),
          _buildBugsTab(),
          _buildProjectsTab(),
          _buildSprintsTab(),
        ],
      ),
    );
  }

  Widget _buildMyTasksTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myTasks.length,
      itemBuilder: (ctx, i) {
        final t = _myTasks[i];
        return InkWell(
          onTap: () => _showTaskDetailSheet(t),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t['type'] ?? '',
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    _buildPriorityBadge(t['priority'] ?? 'MEDIUM'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  t['title'] ?? '',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.sync_rounded, color: const Color(0xFF94A3B8), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      t['status'] ?? '',
                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.calendar_today_rounded, color: const Color(0xFF94A3B8), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      t['due_date'] ?? '',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
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

  Widget _buildBugsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bugs.length,
      itemBuilder: (ctx, i) {
        final b = _bugs[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bug_report_rounded, color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        b['affected_component'] ?? '',
                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  _buildPriorityBadge(b['priority'] ?? 'HIGH'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                b['title'] ?? '',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Env: ${b['environment']}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      b['status'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProjectsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _projects.length,
      itemBuilder: (ctx, i) {
        final p = _projects[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    p['code'] ?? '',
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p['status'] ?? 'Active',
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                p['name'] ?? '',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Progress", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  Text("${p['progress']}%", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (p['progress'] as int) / 100,
                  backgroundColor: const Color(0xFF0F172A),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF38BDF8)),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Tasks: ${p['open_tasks']}", style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                  Text("Bugs: ${p['open_bugs']}", style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
                  Text("Lead: ${p['lead']}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSprintsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sprints.length,
      itemBuilder: (ctx, i) {
        final sp = _sprints[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFA78BFA).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sp['dates'] ?? '',
                    style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA78BFA).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sp['status'] ?? '',
                      style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                sp['name'] ?? '',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Story Points: ${sp['completed_points']} / ${sp['velocity']}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text("Tasks: ${sp['completed_tasks']}/${sp['total_tasks']} ✓", style: const TextStyle(color: Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateTaskDialog() {
    final titleCtrl = TextEditingController();
    String type = "Development";
    String priority = "HIGH";
    String env = "Staging";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text("Create IT Engineering Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Task Title",
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF475569))),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: type,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Task Type", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                  items: [
                    'Development',
                    'Bug Fix',
                    'Code Review',
                    'Testing',
                    'Deployment',
                    'Database',
                    'API',
                    'UI/UX',
                    'Documentation',
                    'Maintenance',
                    'Research',
                    'Technical Support'
                  ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setDState(() => type = v ?? type),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: priority,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Priority", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                  items: ['URGENT', 'HIGH', 'MEDIUM', 'LOW'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setDState(() => priority = v ?? priority),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.isNotEmpty) {
                  setState(() {
                    _myTasks.insert(0, {
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': titleCtrl.text,
                      'type': type,
                      'priority': priority,
                      'status': 'Assigned',
                      'project': 'PartyBala Core Platform',
                      'sprint': 'Sprint 18',
                      'due_date': 'Today',
                      'environment': env,
                      'git_ref': '-',
                      'related_ticket': '-',
                      'assignee': 'Akarshan Mishra',
                    });
                  });
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), foregroundColor: const Color(0xFF0F172A)),
              child: const Text("Create Task", style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
