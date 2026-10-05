import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../tasks/task_detail_screen.dart';

class UniversalSearchScreen extends StatefulWidget {
  const UniversalSearchScreen({super.key});

  @override
  State<UniversalSearchScreen> createState() => _UniversalSearchScreenState();
}

class _UniversalSearchScreenState extends State<UniversalSearchScreen> {
  final ApiClient _api = ApiClient();
  final _searchCtrl = TextEditingController();
  bool _isLoading = false;
  String _query = '';
  List<dynamic> _tasks = [];
  List<dynamic> _projects = [];
  List<dynamic> _tickets = [];
  List<dynamic> _employees = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final t = await _api.dio.get('/tasks/');
      _tasks = t.data['results'] ?? t.data ?? [];
    } catch (_) {}
    try {
      final p = await _api.dio.get('/projects/');
      _projects = p.data['results'] ?? p.data ?? [];
    } catch (_) {}
    try {
      final tk = await _api.dio.get('/tickets/');
      _tickets = tk.data['results'] ?? tk.data ?? [];
    } catch (_) {}
    try {
      final e = await _api.dio.get('/employees/');
      _employees = e.data['results'] ?? e.data ?? [];
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  List<dynamic> get _matchedTasks {
    if (_query.isEmpty) return [];
    return _tasks.where((t) {
      final title = (t['title'] ?? '').toString().toLowerCase();
      final desc = (t['description'] ?? '').toString().toLowerCase();
      return title.contains(_query) || desc.contains(_query);
    }).toList();
  }

  List<dynamic> get _matchedProjects {
    if (_query.isEmpty) return [];
    return _projects.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final code = (p['code'] ?? '').toString().toLowerCase();
      return name.contains(_query) || code.contains(_query);
    }).toList();
  }

  List<dynamic> get _matchedTickets {
    if (_query.isEmpty) return [];
    return _tickets.where((tk) {
      final num = (tk['ticket_number'] ?? '').toString().toLowerCase();
      final title = (tk['title'] ?? '').toString().toLowerCase();
      return num.contains(_query) || title.contains(_query);
    }).toList();
  }

  List<dynamic> get _matchedEmployees {
    if (_query.isEmpty) return [];
    return _employees.where((e) {
      final name = (e['full_name'] ?? '').toString().toLowerCase();
      final code = (e['employee_id'] ?? '').toString().toLowerCase();
      return name.contains(_query) || code.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final matchedT = _matchedTasks;
    final matchedP = _matchedProjects;
    final matchedTk = _matchedTickets;
    final matchedE = _matchedEmployees;
    final totalMatches = matchedT.length + matchedP.length + matchedTk.length + matchedE.length;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search tasks, projects, tickets, people...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _query.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'Universal Enterprise Search',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Type to search across all tasks, projects, tickets, and team members.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : totalMatches == 0
                  ? Center(
                      child: Text('No matches found for "$_query"', style: TextStyle(color: Colors.grey.shade600)),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (matchedT.isNotEmpty) ...[
                          Text('Tasks (${matchedT.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary)),
                          const SizedBox(height: 6),
                          ...matchedT.map((t) => Card(
                                margin: const EdgeInsets.only(bottom: 6),
                                child: ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.task_alt, color: AppTheme.primary),
                                  title: Text(t['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Due: ${t['due_date'] ?? 'N/A'} • Priority: ${t['priority'] ?? 'MEDIUM'}'),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: t['id'])),
                                  ),
                                ),
                              )),
                          const SizedBox(height: 14),
                        ],
                        if (matchedP.isNotEmpty) ...[
                          Text('Projects (${matchedP.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
                          const SizedBox(height: 6),
                          ...matchedP.map((p) => Card(
                                margin: const EdgeInsets.only(bottom: 6),
                                child: ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.folder_special, color: Colors.blue),
                                  title: Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Code: ${p['code']} • Status: ${p['status']}'),
                                ),
                              )),
                          const SizedBox(height: 14),
                        ],
                        if (matchedTk.isNotEmpty) ...[
                          Text('Tickets (${matchedTk.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.deepPurple)),
                          const SizedBox(height: 6),
                          ...matchedTk.map((tk) => Card(
                                margin: const EdgeInsets.only(bottom: 6),
                                child: ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.confirmation_number, color: Colors.deepPurple),
                                  title: Text(tk['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${tk['ticket_number']} • ${tk['category']}'),
                                ),
                              )),
                          const SizedBox(height: 14),
                        ],
                        if (matchedE.isNotEmpty) ...[
                          Text('Team Members (${matchedE.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal)),
                          const SizedBox(height: 6),
                          ...matchedE.map((e) => Card(
                                margin: const EdgeInsets.only(bottom: 6),
                                child: ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.person, color: Colors.teal),
                                  title: Text(e['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${e['employee_id']} • ${e['department_name'] ?? ''} - ${e['position_name'] ?? ''}'),
                                ),
                              )),
                        ],
                      ],
                    ),
    );
  }
}
