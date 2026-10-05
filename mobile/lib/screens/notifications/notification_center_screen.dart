import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../tasks/task_detail_screen.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/notifications/');
      setState(() {
        _notifications = res.data['results'] ?? res.data ?? [];
      });
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _markAllAsRead() async {
    try {
      await _api.dio.post('/notifications/read-all/');
      _fetchNotifications();
    } catch (_) {}
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'TASK_ASSIGNED':
        return Icons.add_task;
      case 'TASK_BLOCKED':
        return Icons.warning_amber_rounded;
      case 'TASK_OVERDUE':
        return Icons.timer_off;
      case 'TASK_APPROVED':
      case 'REPORT_APPROVED':
        return Icons.check_circle_outline;
      case 'TASK_REJECTED':
      case 'REPORT_CHANGES_REQUESTED':
        return Icons.rate_review;
      case 'TASK_SUBMITTED':
      case 'REPORT_SUBMITTED':
        return Icons.send;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor(String? priority, String? type) {
    if (type == 'TASK_BLOCKED' || type == 'TASK_OVERDUE' || priority == 'URGENT') {
      return Colors.red;
    }
    if (priority == 'HIGH') return Colors.orange;
    if (type == 'TASK_APPROVED' || type == 'REPORT_APPROVED') return AppTheme.success;
    return AppTheme.primaryLight;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark All as Read',
            onPressed: _markAllAsRead,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('No notifications', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final n = _notifications[i];
                      final isRead = n['is_read'] == true;
                      final type = n['notification_type'];
                      final priority = n['priority'];
                      final linkType = n['link_type'];
                      final linkId = n['link_id'];

                      return Card(
                        color: isRead ? Colors.white : Colors.blue.shade50.withOpacity(0.5),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getColor(priority, type).withOpacity(0.15),
                            child: Icon(_getIcon(type), color: _getColor(priority, type), size: 20),
                          ),
                          title: Text(
                            n['title'] ?? '',
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(n['message'] ?? '', style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                n['created_at'] != null ? n['created_at'].toString().substring(0, 16).replaceAll('T', ' ') : '',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                          trailing: !isRead
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                                )
                              : null,
                          onTap: () async {
                            if (!isRead) {
                              try {
                                await _api.dio.post('/notifications/${n['id']}/read/');
                                setState(() => n['is_read'] = true);
                              } catch (_) {}
                            }
                            if (linkType == 'TASK' && linkId != null && mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: linkId)),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
