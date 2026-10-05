import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class PositionsManagementScreen extends StatefulWidget {
  const PositionsManagementScreen({super.key});

  @override
  State<PositionsManagementScreen> createState() => _PositionsManagementScreenState();
}

class _PositionsManagementScreenState extends State<PositionsManagementScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _positions = [
    {
      'id': 'pos-1',
      'title': 'Super Admin / Root Architect',
      'department': 'Management / IT',
      'level': 'EXECUTIVE_ROOT',
      'headcount': 1,
      'color': Color(0xFF2563EB),
      'permissions': ['all_access', 'organization_control', 'security_audit', 'finance_approval'],
      'description': 'Full organization governance, configuration, RBAC, and root approvals.',
    },
    {
      'id': 'pos-2',
      'title': 'HR Manager',
      'department': 'Human Resources',
      'level': 'DEPARTMENT_MANAGER',
      'headcount': 2,
      'color': Color(0xFFF43F5E),
      'permissions': ['hr_full', 'employee_crud', 'leave_approval', 'attendance_override'],
      'description': 'Workforce lifecycle, employee onboarding, leaves, and policy compliance.',
    },
    {
      'id': 'pos-3',
      'title': 'Senior Software Engineer',
      'department': 'IT Department',
      'level': 'SENIOR_LEAD',
      'headcount': 4,
      'color': Color(0xFF0284C7),
      'permissions': ['it_tickets', 'code_deployment', 'system_assets', 'sprint_planning'],
      'description': 'Application development, offline-sync algorithms, API pipelines, and platform reliability.',
    },
    {
      'id': 'pos-4',
      'title': 'Marketing & Field Executive',
      'department': 'Marketing',
      'level': 'FIELD_STAFF',
      'headcount': 14,
      'color': Color(0xFF10B981),
      'permissions': ['lead_create', 'partner_visit_gps', 'campaign_view', 'daily_standup'],
      'description': 'Field visits to banquet halls, partner onboarding, and lead conversion.',
    },
    {
      'id': 'pos-5',
      'title': 'Operations Coordinator',
      'department': 'Operations',
      'level': 'FIELD_STAFF',
      'headcount': 18,
      'color': Color(0xFFF59E0B),
      'permissions': ['event_readiness', 'booking_manage', 'inventory_allocate', 'issue_escalation'],
      'description': 'On-ground banquet event execution, checklist verification, and vendor coordination.',
    },
    {
      'id': 'pos-6',
      'title': 'Finance & Accounts Specialist',
      'department': 'Accounts & Finance',
      'level': 'EXECUTIVE_STAFF',
      'headcount': 5,
      'color': Color(0xFF8B5CF6),
      'permissions': ['invoice_posting', 'settlement_12pct', 'expense_verify', 'tds_tax'],
      'description': '12% partner commission settlement, client billing, and ledger maintenance.',
    },
  ];

  void _showAddEditPositionDialog({Map<String, dynamic>? existing}) {
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    String selectedDept = existing?['department'] ?? 'Human Resources';
    String selectedLevel = existing?['level'] ?? 'FIELD_STAFF';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing == null ? 'Add Organization Position' : 'Edit Position Details', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Position Title', hintText: 'e.g. Banquet Operations Lead', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedDept,
                  decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Human Resources', child: Text('Human Resources')),
                    DropdownMenuItem(value: 'IT Department', child: Text('IT & Engineering')),
                    DropdownMenuItem(value: 'Marketing', child: Text('Marketing & Growth')),
                    DropdownMenuItem(value: 'Operations', child: Text('Operations & Logistics')),
                    DropdownMenuItem(value: 'Accounts & Finance', child: Text('Accounts & Finance')),
                    DropdownMenuItem(value: 'Management / IT', child: Text('Executive Management')),
                  ],
                  onChanged: (val) => setDialogState(() => selectedDept = val ?? 'Human Resources'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedLevel,
                  decoration: const InputDecoration(labelText: 'Hierarchy Level', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'EXECUTIVE_ROOT', child: Text('Executive / C-Level (Root)')),
                    DropdownMenuItem(value: 'DEPARTMENT_MANAGER', child: Text('Department Head / Manager')),
                    DropdownMenuItem(value: 'SENIOR_LEAD', child: Text('Team Lead / Senior Specialist')),
                    DropdownMenuItem(value: 'FIELD_STAFF', child: Text('Operational / Field Staff')),
                    DropdownMenuItem(value: 'EXECUTIVE_STAFF', child: Text('Executive Staff')),
                  ],
                  onChanged: (val) => setDialogState(() => selectedLevel = val ?? 'FIELD_STAFF'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Key Responsibilities & Scope', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                setState(() {
                  if (existing != null) {
                    existing['title'] = titleCtrl.text.trim();
                    existing['department'] = selectedDept;
                    existing['level'] = selectedLevel;
                    existing['description'] = descCtrl.text.trim();
                  } else {
                    _positions.add({
                      'id': 'pos-${_positions.length + 1}',
                      'title': titleCtrl.text.trim(),
                      'department': selectedDept,
                      'level': selectedLevel,
                      'headcount': 0,
                      'color': const Color(0xFF2563EB),
                      'permissions': ['view_tasks', 'submit_reports'],
                      'description': descCtrl.text.trim(),
                    });
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ Position "${titleCtrl.text.trim()}" saved successfully')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Position'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.badge_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Positions & Roles Architecture', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showAddEditPositionDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Position', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _positions.length,
        itemBuilder: (context, index) {
          final pos = _positions[index];
          final Color posColor = pos['color'] as Color;

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: posColor.withOpacity(0.12),
                        child: Icon(Icons.badge_rounded, color: posColor, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pos['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                            const SizedBox(height: 2),
                            Text('${pos['department']} · Level: ${pos['level']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                        child: Text('${pos['headcount']} Active Staff', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF1E293B))),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Color(0xFF64748B), size: 20),
                        onSelected: (val) {
                          if (val == 'edit') {
                            _showAddEditPositionDialog(existing: pos);
                          } else if (val == 'delete') {
                            setState(() => _positions.removeAt(index));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('🗑️ Position "${pos['title']}" archived')),
                            );
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit Position Details')),
                          const PopupMenuItem(value: 'delete', child: Text('Archive Position', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(pos['description'], style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.3)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (pos['permissions'] as List<dynamic>)
                        .map((perm) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: posColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: posColor.withOpacity(0.2)),
                              ),
                              child: Text(
                                perm.toString().replaceAll('_', ' '),
                                style: TextStyle(color: posColor, fontSize: 10.5, fontWeight: FontWeight.w600),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
