import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../tasks/task_detail_screen.dart';
import '../work/daily_work_screen.dart';

class ManagerCommandCenterScreen extends StatefulWidget {
  const ManagerCommandCenterScreen({super.key});

  @override
  State<ManagerCommandCenterScreen> createState() => _ManagerCommandCenterScreenState();
}

class _ManagerCommandCenterScreenState extends State<ManagerCommandCenterScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _employees = [];
  List<dynamic> _blockedTasks = [];
  List<dynamic> _overdueTasks = [];
  List<dynamic> _pendingReports = [];
  Map<String, dynamic> _metrics = {};

  @override
  void initState() {
    super.initState();
    _fetchCommandCenterData();
  }

  Future<void> _fetchCommandCenterData() async {
    setState(() => _isLoading = true);
    try {
      final e = await _api.dio.get('/employees/');
      _employees = e.data['results'] ?? e.data ?? [];
    } catch (_) {}

    try {
      final t = await _api.dio.get('/tasks/');
      final allTasks = (t.data['results'] ?? t.data ?? []) as List<dynamic>;
      _blockedTasks = allTasks.where((task) => task['status'] == 'BLOCKED').toList();
      _overdueTasks = allTasks.where((task) => task['is_overdue'] == true || task['status'] == 'OVERDUE').toList();
    } catch (_) {}

    try {
      final m = await _api.dio.get('/tasks/metrics/');
      _metrics = m.data ?? {};
    } catch (_) {}

    try {
      final r = await _api.dio.get('/reports/');
      final allReports = (r.data['results'] ?? r.data ?? []) as List<dynamic>;
      _pendingReports = allReports.where((rep) => rep['status'] == 'SUBMITTED').toList();
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Command Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCommandCenterData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchCommandCenterData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Team Status Card
                  const Text('TEAM STATUS TODAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.green.shade200)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_employees.length}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                              const Text('Total Roster', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.blue.shade200)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_metrics['in_progress'] ?? 0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                              const Text('Active Tasks', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.amber.shade200)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_pendingReports.length}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                              const Text('Reports Due', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Exceptions / Needs Action Section
                  const Text('NEEDS YOUR ACTION & REVIEW ⚠️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
                  const SizedBox(height: 8),

                  if (_blockedTasks.isEmpty && _overdueTasks.isEmpty && _pendingReports.isEmpty)
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 28),
                            SizedBox(width: 12),
                            Text('All team operations are healthy! No blockers.', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Blocked Tasks
                    if (_blockedTasks.isNotEmpty) ...[
                      ..._blockedTasks.map((t) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.red.shade300),
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: Color(0xFFFEE2E2), child: Icon(Icons.block, color: Colors.red)),
                              title: Text(t['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Blocked reason: ${t['block_reason'] ?? 'Action Required'} • Assignee: ${t['assigned_to_name']}'),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: t['id'])),
                                  );
                                  _fetchCommandCenterData();
                                },
                                child: const Text('Resolve'),
                              ),
                            ),
                          )),
                    ],

                    // Pending Reports
                    if (_pendingReports.isNotEmpty) ...[
                      ..._pendingReports.map((r) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.amber.shade300),
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: Color(0xFFFEF3C7), child: Icon(Icons.rate_review, color: Colors.amber)),
                              title: Text('${r['employee_name']} — Daily Report', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Date: ${r['date']} • ${r['today_tasks_count'] ?? 0} tasks completed'),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const DailyWorkScreen()),
                                  );
                                  _fetchCommandCenterData();
                                },
                                child: const Text('Review'),
                              ),
                            ),
                          )),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}
