import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'task_detail_screen.dart';
import 'create_task_screen.dart';

class KanbanBoardScreen extends StatefulWidget {
  const KanbanBoardScreen({super.key});

  @override
  State<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends State<KanbanBoardScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  Map<String, List<dynamic>> _kanbanData = {
    'TODO': [],
    'IN_PROGRESS': [],
    'BLOCKED': [],
    'REVIEW': [],
    'COMPLETED': [],
  };

  final List<Map<String, dynamic>> _columns = [
    {'key': 'TODO', 'title': 'To Do / Assigned', 'color': Colors.blue, 'icon': Icons.assignment_outlined},
    {'key': 'IN_PROGRESS', 'title': 'In Progress', 'color': Colors.amber.shade800, 'icon': Icons.pending_actions},
    {'key': 'BLOCKED', 'title': 'Blocked ⚠️', 'color': Colors.red, 'icon': Icons.block_rounded},
    {'key': 'REVIEW', 'title': 'Under Review', 'color': Colors.purple, 'icon': Icons.rate_review_outlined},
    {'key': 'COMPLETED', 'title': 'Completed', 'color': Colors.teal, 'icon': Icons.check_circle_outline},
  ];

  @override
  void initState() {
    super.initState();
    _fetchKanban();
  }

  Future<void> _fetchKanban() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/tasks/kanban/');
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _kanbanData = {
          'TODO': List.from(data['TODO'] ?? []),
          'IN_PROGRESS': List.from(data['IN_PROGRESS'] ?? []),
          'BLOCKED': List.from(data['BLOCKED'] ?? []),
          'REVIEW': List.from(data['REVIEW'] ?? []),
          'COMPLETED': List.from(data['COMPLETED'] ?? []),
        };
      });
    } catch (_) {}
    setState(() => _isLoading = false);
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

  Future<void> _moveTask(int taskId, String newStatus) async {
    try {
      if (newStatus == 'IN_PROGRESS') {
        await _api.dio.post('/tasks/$taskId/start/');
      } else if (newStatus == 'COMPLETED') {
        await _api.dio.post('/tasks/$taskId/review/', data: {'action': 'APPROVE'});
      } else if (newStatus == 'REVIEW') {
        await _api.dio.post('/tasks/$taskId/submit/', data: {'submission_notes': 'Submitted via Kanban Board'});
      } else if (newStatus == 'BLOCKED') {
        await _api.dio.post('/tasks/$taskId/block/', data: {'reason': 'Marked blocked from Kanban board'});
      } else {
        await _api.dio.patch('/tasks/$taskId/', data: {'status': newStatus});
      }
      _fetchKanban();
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task: $err')),
      );
    }
  }

  Widget _buildKanbanCard(Map<String, dynamic> task) {
    final priorityColor = _getPriorityColor(task['priority']);
    final progress = (task['progress'] ?? 0) as int;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(taskId: task['id']),
            ),
          );
          _fetchKanban();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task['priority'] ?? 'MEDIUM',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor),
                    ),
                  ),
                  const Spacer(),
                  if (task['is_timer_running'] == true) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, size: 12, color: Colors.green),
                          SizedBox(width: 2),
                          Text('LIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task['title'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task['assigned_to_name'] ?? 'Unassigned',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.event_outlined, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    task['due_date'] ?? 'No deadline',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Text(
                    '$progress%',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress / 100.0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 100 ? Colors.green : AppTheme.primary,
                  ),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumn(Map<String, dynamic> col) {
    final String key = col['key'];
    final List<dynamic> items = _kanbanData[key] ?? [];
    final Color colColor = col['color'];

    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: colColor.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Icon(col['icon'], color: colColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    col['title'],
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colColor),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No tasks',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: items.length,
                    itemBuilder: (ctx, idx) => _buildKanbanCard(items[idx]),
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
        title: const Text('Interactive Kanban Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchKanban,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
          );
          if (res == true) _fetchKanban();
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _columns.map((c) => _buildColumn(c)).toList(),
              ),
            ),
    );
  }
}
