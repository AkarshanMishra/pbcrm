import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _task;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTaskDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchTaskDetails() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/tasks/${widget.taskId}/');
      setState(() {
        _task = res.data;
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

  Color _getStatusColor(String? s) {
    switch (s) {
      case 'COMPLETED':
        return AppTheme.success;
      case 'IN_PROGRESS':
        return AppTheme.primaryLight;
      case 'BLOCKED':
        return Colors.red.shade700;
      case 'SUBMITTED':
        return Colors.purple;
      case 'ACCEPTED':
        return Colors.teal;
      case 'OVERDUE':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleAction(String endpoint, [Map<String, dynamic>? body]) async {
    try {
      final res = await _api.dio.post('/tasks/${widget.taskId}/$endpoint/', data: body ?? {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.data['message'] ?? 'Action completed.'), backgroundColor: AppTheme.success),
        );
        _fetchTaskDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _showBlockDialog() {
    final reasonCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('Block Task'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Explain why this task cannot proceed. Your manager will be alerted.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Blocker Reason *', hintText: 'e.g. Awaiting client documents'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Detailed Comment', hintText: 'Specific issue or person to contact'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              _handleAction('block', {'reason': reasonCtrl.text.trim(), 'comment': noteCtrl.text.trim()});
            },
            child: const Text('Confirm Blocker'),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog() {
    final remarksCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Review Task Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Verify employee work and approve completion or request revisions.'),
            const SizedBox(height: 12),
            TextField(
              controller: remarksCtrl,
              decoration: const InputDecoration(labelText: 'Manager Remarks / Feedback'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.orange.shade800),
            onPressed: () {
              Navigator.pop(ctx);
              _handleAction('review', {'decision': 'REQUEST_CHANGES', 'remarks': remarksCtrl.text.trim()});
            },
            child: const Text('Request Changes'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () {
              Navigator.pop(ctx);
              _handleAction('review', {'decision': 'APPROVE', 'remarks': remarksCtrl.text.trim()});
            },
            child: const Text('Approve & Complete'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    _commentController.clear();

    try {
      await _api.dio.post('/tasks/${widget.taskId}/comments/', data: {'comment_text': text});
      _fetchTaskDetails();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Details')),
        body: const Center(child: Text('Task not found.')),
      );
    }

    final t = _task!;
    final priority = t['priority'] ?? 'MEDIUM';
    final status = t['status'] ?? 'ASSIGNED';
    final progress = (t['progress_percentage'] ?? 0) as int;
    final checklist = (t['checklist_items'] ?? []) as List<dynamic>;
    final comments = (t['comments'] ?? []) as List<dynamic>;
    final history = (t['activity_logs'] ?? []) as List<dynamic>;
    final isBlocked = status == 'BLOCKED';

    return Scaffold(
      appBar: AppBar(
        title: Text(t['title'] ?? 'Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTaskDetails,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(priority).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$priority PRIORITY',
                        style: TextStyle(color: _getPriorityColor(priority), fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const Spacer(),
                    if (t['due_date'] != null)
                      Text(
                        'Due: ${t['due_date']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: t['is_overdue'] == true ? AppTheme.error : Colors.grey.shade700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  t['title'] ?? '',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  t['description'] ?? '',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Assigned to: ${t['assigned_to_name']} (${t['assigned_to_code']})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text('$progress% Complete', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress / 100.0,
                  backgroundColor: Colors.grey.shade200,
                  color: isBlocked ? Colors.red : AppTheme.primary,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                if (isBlocked && (t['blocked_reason'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Blocker: ${t['blocked_reason']}', style: const TextStyle(color: Colors.red, fontSize: 12))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action Buttons Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.grey.shade100, border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
            child: Row(
              children: [
                if (status == 'ASSIGNED')
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      onPressed: () => _handleAction('accept'),
                    ),
                  ),
                if (status == 'ACCEPTED')
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Start Work'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                      onPressed: () => _handleAction('start'),
                    ),
                  ),
                if (status == 'IN_PROGRESS' || status == 'ACCEPTED') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.block, size: 16, color: Colors.red),
                      label: const Text('Block', style: TextStyle(color: Colors.red)),
                      onPressed: _showBlockDialog,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('Submit'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                      onPressed: () => _handleAction('submit'),
                    ),
                  ),
                ],
                if (isBlocked)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_circle_outline, size: 18),
                      label: const Text('Unblock & Resume'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () => _handleAction('unblock'),
                    ),
                  ),
                if (status == 'SUBMITTED')
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.rate_review, size: 18),
                      label: const Text('Manager Review'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                      onPressed: _showReviewDialog,
                    ),
                  ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Checklist (${checklist.length})'),
              Tab(text: 'Comments (${comments.length})'),
              Tab(text: 'Activity (${history.length})'),
            ],
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Checklist Tab
                checklist.isEmpty
                    ? const Center(child: Text('No checklist items for this task.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: checklist.length,
                        itemBuilder: (ctx, i) {
                          final item = checklist[i];
                          final isDone = item['is_completed'] == true;
                          return Card(
                            child: CheckboxListTile(
                              value: isDone,
                              title: Text(
                                item['item_text'] ?? '',
                                style: TextStyle(
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                  color: isDone ? Colors.grey : Colors.black87,
                                ),
                              ),
                              subtitle: isDone && item['completed_by_name'] != null
                                  ? Text('Completed by ${item['completed_by_name']}', style: const TextStyle(fontSize: 11))
                                  : null,
                              onChanged: (val) async {
                                try {
                                  await _api.dio.post('/tasks/${widget.taskId}/toggle-checklist/', data: {'item_id': item['id']});
                                  _fetchTaskDetails();
                                } catch (_) {}
                              },
                            ),
                          );
                        },
                      ),

                // 2. Comments Tab
                Column(
                  children: [
                    Expanded(
                      child: comments.isEmpty
                          ? const Center(child: Text('No comments yet. Start the conversation!'))
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: comments.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (ctx, i) {
                                final c = comments[i];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(c['author_name'] ?? c['author_code'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          Text(
                                            c['created_at'] != null ? c['created_at'].toString().substring(0, 16).replaceAll('T', ' ') : '',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(c['comment_text'] ?? '', style: const TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: const InputDecoration(hintText: 'Type task comment...', border: InputBorder.none),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: AppTheme.primary),
                            onPressed: _sendComment,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 3. Activity History Tab
                history.isEmpty
                    ? const Center(child: Text('No activity recorded.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: history.length,
                        itemBuilder: (ctx, i) {
                          final h = history[i];
                          return ListTile(
                            leading: const CircleAvatar(
                              radius: 14,
                              backgroundColor: AppTheme.primaryLight,
                              child: Icon(Icons.history, size: 16, color: Colors.white),
                            ),
                            title: Text(h['action'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(h['description'] ?? '', style: const TextStyle(fontSize: 12)),
                            trailing: Text(
                              h['created_at'] != null ? h['created_at'].toString().substring(11, 16) : '',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
