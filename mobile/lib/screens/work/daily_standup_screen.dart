import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class DailyStandupScreen extends StatefulWidget {
  const DailyStandupScreen({super.key});

  @override
  State<DailyStandupScreen> createState() => _DailyStandupScreenState();
}

class _DailyStandupScreenState extends State<DailyStandupScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _standups = [];
  List<dynamic> _diaryEntries = [];

  final _yesterdayCtrl = TextEditingController();
  final _todayCtrl = TextEditingController();
  final _blockersCtrl = TextEditingController();
  final _diaryActivityCtrl = TextEditingController();
  String _diaryCategory = 'DEVELOPMENT';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _yesterdayCtrl.dispose();
    _todayCtrl.dispose();
    _blockersCtrl.dispose();
    _diaryActivityCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final sRes = await _api.dio.get('/standups/');
      _standups = sRes.data['results'] ?? sRes.data ?? [];
    } catch (_) {}

    try {
      final dRes = await _api.dio.get('/diary/');
      _diaryEntries = dRes.data['results'] ?? dRes.data ?? [];
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  Future<void> _submitStandup() async {
    if (_yesterdayCtrl.text.trim().isEmpty || _todayCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete Yesterday and Today sections')),
      );
      return;
    }

    try {
      await _api.dio.post('/standups/', data: {
        'yesterday_completed': _yesterdayCtrl.text.trim(),
        'today_planned': _todayCtrl.text.trim(),
        'blockers_encountered': _blockersCtrl.text.trim(),
      });
      _yesterdayCtrl.clear();
      _todayCtrl.clear();
      _blockersCtrl.clear();
      _fetchData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily Standup submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
    }
  }

  Future<void> _addDiaryEntry() async {
    if (_diaryActivityCtrl.text.trim().isEmpty) return;

    try {
      await _api.dio.post('/diary/', data: {
        'activity': _diaryActivityCtrl.text.trim(),
        'category': _diaryCategory,
      });
      _diaryActivityCtrl.clear();
      _fetchData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diary entry logged!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to log entry: $e')));
    }
  }

  Widget _buildStandupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.wb_sunny_outlined, color: Colors.orange, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Submit Today\'s Standup',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('1. What did you complete yesterday? *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _yesterdayCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Completed vendor onboarding API, fixed 2 bugs...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('2. What will you work on today? *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _todayCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Integrate payment webhook, attend marketing sync...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('3. Any blockers or dependencies stopping you?', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _blockersCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Waiting for GST credentials from partner, API token approval...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _submitStandup,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Post Standup Update', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Team Standup Feed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_standups.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No standups posted today yet.', style: TextStyle(color: Colors.grey.shade600)),
              ),
            )
          else
            ..._standups.map((s) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primary.withOpacity(0.15),
                              child: Text(
                                (s['employee_name'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s['employee_name'] ?? 'Team Member', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text(
                                    '${s['department_name'] ?? ''} • ${s['date'] ?? ''}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Yesterday:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                              Text(s['yesterday_completed'] ?? '', style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 6),
                              const Text('Today:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                              Text(s['today_planned'] ?? '', style: const TextStyle(fontSize: 13)),
                              if ((s['blockers_encountered'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                const Text('Blockers:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red)),
                                Text(s['blockers_encountered'], style: const TextStyle(fontSize: 13, color: Colors.red)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildDiaryTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _diaryActivityCtrl,
                          decoration: const InputDecoration(
                            hintText: 'What are you working on right now?',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _diaryCategory,
                        items: const [
                          DropdownMenuItem(value: 'DEVELOPMENT', child: Text('Dev')),
                          DropdownMenuItem(value: 'MEETING', child: Text('Meeting')),
                          DropdownMenuItem(value: 'SUPPORT', child: Text('Support')),
                          DropdownMenuItem(value: 'RESEARCH', child: Text('Research')),
                          DropdownMenuItem(value: 'DOCUMENTATION', child: Text('Docs')),
                          DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                        ],
                        onChanged: (v) => setState(() => _diaryCategory = v ?? 'DEVELOPMENT'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addDiaryEntry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Text('Log'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Today\'s Work Diary Log', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: _diaryEntries.isEmpty
                ? Center(
                    child: Text('No diary logs recorded yet today.', style: TextStyle(color: Colors.grey.shade600)),
                  )
                : ListView.builder(
                    itemCount: _diaryEntries.length,
                    itemBuilder: (ctx, idx) {
                      final item = _diaryEntries[idx];
                      final timeStr = item['timestamp'] != null
                          ? item['timestamp'].toString().substring(11, 16)
                          : '--:--';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              timeStr,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
                            ),
                          ),
                          title: Text(item['activity'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['category'] ?? '',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Standup & Work Diary'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Daily Standup', icon: Icon(Icons.groups_outlined)),
            Tab(text: 'Work Diary', icon: Icon(Icons.menu_book_outlined)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStandupTab(),
                _buildDiaryTab(),
              ],
            ),
    );
  }
}
