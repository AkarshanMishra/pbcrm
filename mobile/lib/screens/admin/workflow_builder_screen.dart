import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class WorkflowBuilderScreen extends StatefulWidget {
  const WorkflowBuilderScreen({super.key});

  @override
  State<WorkflowBuilderScreen> createState() => _WorkflowBuilderScreenState();
}

class _WorkflowBuilderScreenState extends State<WorkflowBuilderScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _workflows = [
    {
      'id': 'WF-001',
      'title': 'Vendor & Partner Onboarding',
      'department': 'Operations',
      'description': 'End-to-end verification and approval pipeline for new company vendors.',
      'steps': [
        {'step_no': 1, 'title': 'Document Collection', 'assignee': 'Operations Executive', 'required': true},
        {'step_no': 2, 'title': 'KYC & GST Verification', 'assignee': 'Compliance Team', 'required': true},
        {'step_no': 3, 'title': 'Manager Approval', 'assignee': 'Operations Manager', 'required': true},
        {'step_no': 4, 'title': 'Admin Approval & Secret Key Gen', 'assignee': 'Admin', 'required': true},
        {'step_no': 5, 'title': 'Publish to Marketplace', 'assignee': 'Marketing Lead', 'required': false},
      ],
    },
    {
      'id': 'WF-002',
      'title': 'Production Code Release',
      'department': 'IT',
      'description': 'Mandatory security audit and sign-off before deploying to live servers.',
      'steps': [
        {'step_no': 1, 'title': 'Unit Tests & Static Analysis', 'assignee': 'Developer', 'required': true},
        {'step_no': 2, 'title': 'Peer Code Review', 'assignee': 'Senior Engineer', 'required': true},
        {'step_no': 3, 'title': 'QA Staging Verification', 'assignee': 'QA Lead', 'required': true},
        {'step_no': 4, 'title': 'Deploy to Production', 'assignee': 'DevOps / Admin', 'required': true},
      ],
    },
  ];

  void _showAddWorkflowDialog() {
    final titleCtrl = TextEditingController();
    final deptCtrl = TextEditingController(text: 'Operations');
    final descCtrl = TextEditingController();
    List<Map<String, dynamic>> steps = [
      {'step_no': 1, 'title': 'Step 1: Initiation', 'assignee': 'Lead', 'required': true},
      {'step_no': 2, 'title': 'Step 2: Admin Approval', 'assignee': 'Admin', 'required': true},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Create New Workflow Template'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Workflow Title *')),
                  const SizedBox(height: 12),
                  TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'Department')),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Workflow Steps', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Step'),
                        onPressed: () {
                          setDlgState(() {
                            steps.add({
                              'step_no': steps.length + 1,
                              'title': 'Step ${steps.length + 1}',
                              'assignee': 'Reviewer',
                              'required': true,
                            });
                          });
                        },
                      ),
                    ],
                  ),
                  ...steps.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final s = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            CircleAvatar(radius: 12, child: Text('${idx + 1}', style: const TextStyle(fontSize: 11))),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: s['title'],
                                decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                                onChanged: (val) => s['title'] = val,
                              ),
                            ),
                            if (steps.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                onPressed: () => setDlgState(() => steps.removeAt(idx)),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
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
                  _workflows.add({
                    'id': 'WF-00${_workflows.length + 1}',
                    'title': titleCtrl.text.trim(),
                    'department': deptCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'steps': steps,
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Workflow template created!'), backgroundColor: AppTheme.success),
                );
              },
              child: const Text('Save Workflow'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workflow & Process Orchestrator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Workflow',
            onPressed: _showAddWorkflowDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primary, Colors.blue.shade900]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enterprise Workflows', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(
                  'Automate department hand-offs, KYC verification pipelines, and multi-tier approval chains.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          ..._workflows.map((wf) {
            final steps = (wf['steps'] as List<dynamic>);
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(wf['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('${wf['department']} • ${wf['id']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                          child: Text('${steps.length} Steps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green.shade800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(wf['description'], style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 16),

                    // Visual Step Pipeline
                    Column(
                      children: steps.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final s = entry.value;
                        final isLast = idx == steps.length - 1;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppTheme.primary,
                                  child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                if (!isLast)
                                  Container(
                                    width: 2,
                                    height: 24,
                                    color: Colors.grey.shade300,
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2, bottom: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(s['title'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    Text(s['assignee'], style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
