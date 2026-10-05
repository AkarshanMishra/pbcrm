import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class DailyWorkScreen extends StatefulWidget {
  const DailyWorkScreen({super.key});

  @override
  State<DailyWorkScreen> createState() => _DailyWorkScreenState();
}

class _DailyWorkScreenState extends State<DailyWorkScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;

  // Plan state
  bool _isPlanLoading = true;
  bool _isDayStarted = false;
  List<String> _plannedItems = [];
  final TextEditingController _newGoalController = TextEditingController();
  final TextEditingController _planNotesController = TextEditingController();

  // Report state
  final TextEditingController _summaryCtrl = TextEditingController();
  final TextEditingController _completedCtrl = TextEditingController();
  final TextEditingController _pendingCtrl = TextEditingController();
  final TextEditingController _blockedCtrl = TextEditingController();
  final TextEditingController _tomorrowCtrl = TextEditingController();
  String _reportStatus = 'NOT_SUBMITTED';
  String? _managerRemarks;

  // Team Reports (Manager/Admin)
  List<dynamic> _teamReports = [];
  bool _isTeamLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTodayPlan();
    _fetchTodayReport();
    _fetchTeamReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _newGoalController.dispose();
    _planNotesController.dispose();
    _summaryCtrl.dispose();
    _completedCtrl.dispose();
    _pendingCtrl.dispose();
    _blockedCtrl.dispose();
    _tomorrowCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchTodayPlan() async {
    setState(() => _isPlanLoading = true);
    try {
      final res = await _api.dio.get('/work/plans/today/');
      final data = res.data;
      setState(() {
        _isDayStarted = data['is_started'] ?? false;
        _plannedItems = List<String>.from(data['planned_items'] ?? []);
        _planNotesController.text = data['notes'] ?? '';
      });
    } catch (_) {}
    setState(() => _isPlanLoading = false);
  }

  Future<void> _savePlan({bool? startDay}) async {
    try {
      await _api.dio.post('/work/plans/today/', data: {
        'planned_items': _plannedItems,
        'notes': _planNotesController.text.trim(),
        'is_started': startDay ?? _isDayStarted,
      });
      _fetchTodayPlan();
      if (mounted && startDay == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Have a productive day! 🚀'), backgroundColor: AppTheme.success),
        );
      }
    } catch (_) {}
  }

  Future<void> _fetchTodayReport() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      final res = await _api.dio.get('/work/reports/', queryParameters: {'report_date': today});
      final results = (res.data['results'] ?? res.data) as List<dynamic>;
      if (results.isNotEmpty) {
        final r = results.first;
        setState(() {
          _summaryCtrl.text = r['summary_text'] ?? '';
          _completedCtrl.text = r['completed_summary'] ?? '';
          _pendingCtrl.text = r['pending_summary'] ?? '';
          _blockedCtrl.text = r['blocked_summary'] ?? '';
          _tomorrowCtrl.text = r['tomorrow_plan'] ?? '';
          _reportStatus = r['status'] ?? 'SUBMITTED';
          _managerRemarks = r['manager_remarks'];
        });
      }
    } catch (_) {}
  }

  Future<void> _submitDailyReport() async {
    if (_summaryCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a summary of your day.'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      await _api.dio.post('/work/reports/', data: {
        'report_date': today,
        'summary_text': _summaryCtrl.text.trim(),
        'completed_summary': _completedCtrl.text.trim(),
        'pending_summary': _pendingCtrl.text.trim(),
        'blocked_summary': _blockedCtrl.text.trim(),
        'tomorrow_plan': _tomorrowCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily report submitted for review!'), backgroundColor: AppTheme.success),
        );
        _fetchTodayReport();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _fetchTeamReports() async {
    setState(() => _isTeamLoading = true);
    try {
      final res = await _api.dio.get('/work/reports/team-summary/');
      setState(() {
        _teamReports = res.data ?? [];
      });
    } catch (_) {}
    setState(() => _isTeamLoading = false);
  }

  void _showReviewDialog(Map<String, dynamic> item) {
    final remarksCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Review: ${item['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Employee: ${item['name']} (${item['employee_code']})'),
            const SizedBox(height: 12),
            TextField(
              controller: remarksCtrl,
              decoration: const InputDecoration(labelText: 'Manager Feedback / Remarks'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.orange.shade800),
            onPressed: () async {
              if (item['report_id'] == null) return;
              await _api.dio.post('/work/reports/${item['report_id']}/review/', data: {
                'decision': 'REQUEST_CHANGES',
                'remarks': remarksCtrl.text.trim(),
              });
              Navigator.pop(ctx);
              _fetchTeamReports();
            },
            child: const Text('Request Changes'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () async {
              if (item['report_id'] == null) return;
              await _api.dio.post('/work/reports/${item['report_id']}/review/', data: {
                'decision': 'APPROVE',
                'remarks': remarksCtrl.text.trim(),
              });
              Navigator.pop(ctx);
              _fetchTeamReports();
            },
            child: const Text('Approve Report'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Work Management'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Work Plan'),
            Tab(text: 'Daily Report'),
            Tab(text: 'Team Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. WORK PLAN TAB
          _isPlanLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header greeting
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Good Day, ${user?.employeeCode ?? "Team"} 👋',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            if (!_isDayStarted)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, minimumSize: const Size(110, 40)),
                                onPressed: () => _savePlan(startDay: true),
                                child: const Text('Start Day'),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle, size: 14, color: AppTheme.success),
                                    SizedBox(width: 4),
                                    Text('Day Started', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Goals section
                      const Text("Today's Key Goals", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newGoalController,
                              decoration: const InputDecoration(hintText: 'Add a planned goal / task...'),
                              onSubmitted: (_) {
                                if (_newGoalController.text.trim().isNotEmpty) {
                                  setState(() {
                                    _plannedItems.add(_newGoalController.text.trim());
                                    _newGoalController.clear();
                                  });
                                  _savePlan();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              if (_newGoalController.text.trim().isNotEmpty) {
                                setState(() {
                                  _plannedItems.add(_newGoalController.text.trim());
                                  _newGoalController.clear();
                                });
                                _savePlan();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._plannedItems.asMap().entries.map((e) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.arrow_right_alt, color: AppTheme.primary),
                            title: Text(e.value),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                              onPressed: () {
                                setState(() => _plannedItems.removeAt(e.key));
                                _savePlan();
                              },
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),

                      // Plan Notes
                      TextField(
                        controller: _planNotesController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Daily Notes & Focus Area'),
                        onChanged: (_) => _savePlan(),
                      ),
                    ],
                  ),
                ),

          // 2. DAILY WORK REPORT TAB
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Banner
                if (_reportStatus != 'NOT_SUBMITTED') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _reportStatus == 'APPROVED' ? Colors.green.shade50 : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _reportStatus == 'APPROVED' ? AppTheme.success : AppTheme.warning),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _reportStatus == 'APPROVED' ? Icons.check_circle : Icons.pending_actions,
                              color: _reportStatus == 'APPROVED' ? AppTheme.success : AppTheme.warning,
                            ),
                            const SizedBox(width: 8),
                            Text('Status: $_reportStatus', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (_managerRemarks != null && _managerRemarks!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('Manager Feedback: $_managerRemarks', style: const TextStyle(fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: _summaryCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Day's Summary *", hintText: 'What did you accomplish today?'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _completedCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Completed Highlights', hintText: 'Key deliverables finished'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pendingCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Pending Items', hintText: 'Tasks in progress'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _blockedCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Blockers Encountered', hintText: 'Any issues needing manager attention'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tomorrowCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: "Tomorrow's Action Plan", hintText: 'Top priorities for tomorrow'),
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Daily Work Report'),
                  onPressed: _submitDailyReport,
                ),
              ],
            ),
          ),

          // 3. TEAM REPORTS TAB
          _isTeamLoading
              ? const Center(child: CircularProgressIndicator())
              : _teamReports.isEmpty
                  ? const Center(child: Text('No team reports submitted for today.'))
                  : RefreshIndicator(
                      onRefresh: _fetchTeamReports,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _teamReports.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final item = _teamReports[i];
                          final status = item['report_status'] ?? 'NOT_SUBMITTED';
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text((item['name'] ?? 'E').substring(0, 1)),
                              ),
                              title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${item['employee_code']} • ${item['department']}'),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: status == 'APPROVED' ? Colors.grey : AppTheme.primary,
                                  minimumSize: const Size(90, 36),
                                ),
                                onPressed: status == 'NOT_SUBMITTED' ? null : () => _showReviewDialog(item),
                                child: Text(status == 'APPROVED' ? 'Approved' : 'Review'),
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
}
