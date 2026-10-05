import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'task_detail_screen.dart';
import 'create_task_screen.dart';
import 'kanban_board_screen.dart';
import '../projects/projects_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;
  bool _isLoading = true;
  String _searchQuery = '';
  String? _priorityFilter;
  List<dynamic> _tasks = [];
  Map<String, dynamic> _metrics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _fetchTasks();
    _fetchMetrics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/tasks/');
      setState(() {
        _tasks = res.data['results'] ?? res.data ?? [];
      });
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _fetchMetrics() async {
    try {
      final res = await _api.dio.get('/tasks/metrics/');
      setState(() {
        _metrics = res.data ?? {};
      });
    } catch (_) {}
  }

  List<dynamic> get _filteredTasks {
    List<dynamic> current = List.from(_tasks);

    // Tab filter
    switch (_tabController.index) {
      case 0: // Today
        final today = DateTime.now().toIso8601String().substring(0, 10);
        current = current.where((t) => t['due_date'] == today && t['status'] != 'COMPLETED').toList();
        break;
      case 1: // Upcoming
        current = current.where((t) => t['status'] != 'COMPLETED' && t['status'] != 'OVERDUE').toList();
        break;
      case 2: // Overdue
        current = current.where((t) => t['is_overdue'] == true || t['status'] == 'OVERDUE').toList();
        break;
      case 3: // Blocked
        current = current.where((t) => t['status'] == 'BLOCKED').toList();
        break;
      case 4: // Completed
        current = current.where((t) => t['status'] == 'COMPLETED').toList();
        break;
      case 5: // All
      default:
        break;
    }

    // Priority filter
    if (_priorityFilter != null) {
      current = current.where((t) => t['priority'] == _priorityFilter).toList();
    }

    // Search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      current = current.where((t) {
        final title = (t['title'] ?? '').toString().toLowerCase();
        final desc = (t['description'] ?? '').toString().toLowerCase();
        final assignee = (t['assigned_to_name'] ?? '').toString().toLowerCase();
        return title.contains(q) || desc.contains(q) || assignee.contains(q);
      }).toList();
    }

    return current;
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Work & Task Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_kanban_outlined),
            tooltip: 'Kanban Board',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KanbanBoardScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.folder_special_outlined),
            tooltip: 'Projects & Workspaces',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProjectsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _fetchTasks();
              _fetchMetrics();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primary,
          tabs: [
            Tab(text: 'Today (${_metrics['today_due'] ?? 0})'),
            Tab(text: 'Upcoming (${_metrics['upcoming'] ?? 0})'),
            Tab(text: 'Overdue (${_metrics['overdue'] ?? 0})'),
            Tab(text: 'Blocked (${_metrics['blocked'] ?? 0})'),
            Tab(text: 'Completed (${_metrics['completed'] ?? 0})'),
            Tab(text: 'All (${_tasks.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
          );
          if (res == true) {
            _fetchTasks();
            _fetchMetrics();
          }
        },
        icon: const Icon(Icons.add_task),
        label: const Text('Create Task'),
      ),
      body: Column(
        children: [
          // Search and Priority Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String?>(
                  icon: Icon(Icons.filter_list, color: _priorityFilter != null ? AppTheme.primary : Colors.grey),
                  onSelected: (val) => setState(() => _priorityFilter = val),
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: null, child: Text('All Priorities')),
                    PopupMenuItem(value: 'URGENT', child: Text('🔴 Urgent Only')),
                    PopupMenuItem(value: 'HIGH', child: Text('🟠 High Only')),
                    PopupMenuItem(value: 'MEDIUM', child: Text('🟡 Medium Only')),
                    PopupMenuItem(value: 'LOW', child: Text('🟢 Low Only')),
                  ],
                ),
              ],
            ),
          ),

          // Main List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('No tasks in this view', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _fetchTasks();
                          await _fetchMetrics();
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final t = filtered[idx];
                            final priority = t['priority'] ?? 'MEDIUM';
                            final status = t['status'] ?? 'ASSIGNED';
                            final progress = (t['progress_percentage'] ?? 0) as int;
                            final isOverdue = t['is_overdue'] == true || status == 'OVERDUE';
                            final isBlocked = status == 'BLOCKED';

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: t['id'])),
                                  );
                                  _fetchTasks();
                                  _fetchMetrics();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top row: Priority & Status
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getPriorityColor(priority).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              priority,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: _getPriorityColor(priority),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          if (isBlocked)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                                              child: const Text('BLOCKED', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                                            )
                                          else if (isOverdue)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: Colors.deepOrange.shade100, borderRadius: BorderRadius.circular(4)),
                                              child: const Text('OVERDUE', style: TextStyle(fontSize: 10, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                                            )
                                          else
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                              child: Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                                            ),
                                          const Spacer(),
                                          if (t['due_date'] != null)
                                            Text(
                                              'Due: ${t['due_date']}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isOverdue ? AppTheme.error : Colors.grey.shade600,
                                                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Task Title & Desc
                                      Text(
                                        t['title'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      if ((t['description'] ?? '').isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          t['description'],
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                        ),
                                      ],
                                      const SizedBox(height: 12),

                                      // Assignee & Checklist counts
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            t['assigned_to_name'] ?? 'Assignee',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                          const Spacer(),
                                          if ((t['checklist_total'] ?? 0) > 0) ...[
                                            const Icon(Icons.checklist, size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${t['checklist_completed']}/${t['checklist_total']}',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                            const SizedBox(width: 12),
                                          ],
                                          Text('$progress%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
