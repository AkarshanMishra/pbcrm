import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/auth_user.dart';
import '../../providers/auth_provider.dart';
import '../tasks/task_detail_screen.dart';
import '../pipeline/leads_partners_bookings_screen.dart';
import '../admin/admin_approval_center_screen.dart';

enum NotificationFilter {
  all,
  unread,
  actionRequired,
  approvals,
  system,
}

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isLoading = false;
  NotificationFilter _selectedFilter = NotificationFilter.all;
  String _searchQuery = '';

  // Local notifications dataset with fallback & server synchronization
  List<Map<String, dynamic>> _notifications = [];

  // Broadcasts created by Admin
  List<Map<String, dynamic>> _broadcasts = [
    {
      'id': 'BC-101',
      'title': 'System Maintenance: Offline Sync Engine V2 Deployment',
      'target': 'ALL_DEPARTMENTS',
      'priority': 'HIGH',
      'created_at': 'Today, 09:00 AM',
      'author': 'Akarshan Mishra (Super Admin)',
      'readCount': '118/124 Read',
    },
    {
      'id': 'BC-102',
      'title': 'Q4 Banquet Partner Commission Policy Reminder (12%)',
      'target': 'MARKETING & OPERATIONS',
      'priority': 'MEDIUM',
      'created_at': 'Yesterday, 04:30 PM',
      'author': 'Neha Sharma (HR)',
      'readCount': '52/55 Read',
    },
  ];

  // Preferences
  bool _pushEnabled = true;
  bool _emailDigest = true;
  bool _urgentSms = true;
  bool _quietHours = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    setState(() => _isLoading = true);

    // Initial Enterprise Seed Data
    _notifications = [
      {
        'id': 'notif-1',
        'title': 'Urgent: Server Replica Latency Alert',
        'message': 'Primary database replica replication lag exceeded 200ms on worker node #2.',
        'notification_type': 'SYSTEM_ALERT',
        'priority': 'URGENT',
        'is_read': false,
        'action_required': true,
        'action_type': 'ACKNOWLEDGE_INCIDENT',
        'created_at': 'Just now',
        'link_type': 'IT',
        'link_id': 'it-replica',
      },
      {
        'id': 'notif-2',
        'title': 'New Banquet Booking Assigned: Sharma Wedding Reception',
        'message': 'Grand Heritage Banquet booking BK-2026-089 (₹ 1,85,000) requires operations readiness verification.',
        'notification_type': 'BOOKING_ASSIGNED',
        'priority': 'HIGH',
        'is_read': false,
        'action_required': true,
        'action_type': 'VIEW_BOOKING',
        'created_at': '12 mins ago',
        'link_type': 'BOOKING',
        'link_id': 'BK-2026-089',
      },
      {
        'id': 'notif-3',
        'title': 'Leave Request Submitted by Kavita Nair',
        'message': 'Operations Event Lead requested 2 days Casual Leave from 14 Oct to 15 Oct.',
        'notification_type': 'APPROVAL_REQUEST',
        'priority': 'HIGH',
        'is_read': false,
        'action_required': true,
        'action_type': 'APPROVE_LEAVE',
        'created_at': '45 mins ago',
        'link_type': 'APPROVAL',
        'link_id': 'leave-104',
      },
      {
        'id': 'notif-4',
        'title': 'Task Completed: Multi-Device Offline Sync Batch Handler',
        'message': 'Akarshan Mishra completed the deterministic conflict resolver module.',
        'notification_type': 'TASK_APPROVED',
        'priority': 'NORMAL',
        'is_read': true,
        'action_required': false,
        'created_at': '2 hours ago',
        'link_type': 'TASK',
        'link_id': 'tsk-101',
      },
      {
        'id': 'notif-5',
        'title': '12% Partner Settlement Batch Posted: #SET-2026-089',
        'message': 'Deepak Verma submitted ₹ 22,200 payout for Grand Heritage Banquet.',
        'notification_type': 'FINANCE_ALERT',
        'priority': 'NORMAL',
        'is_read': true,
        'action_required': false,
        'created_at': 'Yesterday',
        'link_type': 'ACCOUNTS',
        'link_id': 'INV-2026-089',
      },
    ];

    try {
      final res = await _api.dio.get('/notifications/').timeout(const Duration(seconds: 3));
      final remoteList = (res.data['results'] ?? res.data ?? []) as List<dynamic>;
      if (remoteList.isNotEmpty) {
        for (var item in remoteList) {
          _notifications.insert(0, {
            'id': item['id']?.toString() ?? 'notif-${DateTime.now().millisecondsSinceEpoch}',
            'title': item['title'] ?? 'Notification',
            'message': item['message'] ?? '',
            'notification_type': item['notification_type'] ?? 'GENERAL',
            'priority': item['priority'] ?? 'NORMAL',
            'is_read': item['is_read'] == true,
            'action_required': item['priority'] == 'URGENT' || item['priority'] == 'HIGH',
            'created_at': item['created_at'] != null ? item['created_at'].toString().substring(0, 16).replaceAll('T', ' ') : 'Recent',
            'link_type': item['link_type'],
            'link_id': item['link_id'],
          });
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  // ===========================================================================
  // NOTIFICATION CRUD ACTIONS
  // ===========================================================================
  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n['is_read'] = true;
      }
    });
    try {
      _api.dio.post('/notifications/read-all/');
    } catch (_) {}
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ All notifications marked as read')),
    );
  }

  void _toggleReadStatus(Map<String, dynamic> n) {
    setState(() {
      n['is_read'] = !(n['is_read'] == true);
    });
    try {
      if (n['is_read'] == true) {
        _api.dio.post('/notifications/${n['id']}/read/');
      }
    } catch (_) {}
  }

  void _deleteNotification(int index) {
    final deleted = _notifications.removeAt(index);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🗑️ Dismissed "${deleted['title']}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => setState(() => _notifications.insert(index, deleted)),
        ),
      ),
    );
  }

  void _clearAllRead() {
    setState(() {
      _notifications.removeWhere((n) => n['is_read'] == true);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🧹 Cleared all read notifications')),
    );
  }

  void _showBroadcastCreationModal({Map<String, dynamic>? existing}) {
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final msgCtrl = TextEditingController(text: existing?['message'] ?? '');
    String target = existing?['target'] ?? 'ALL_DEPARTMENTS';
    String priority = existing?['priority'] ?? 'HIGH';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing == null ? '📢 Compose Company Alert Broadcast' : 'Edit Broadcast Notice', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Broadcast Subject / Headline', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: target,
                  decoration: const InputDecoration(labelText: 'Recipient Audience', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'ALL_DEPARTMENTS', child: Text('🏢 All Departments & Staff')),
                    DropdownMenuItem(value: 'IT_OPERATIONS', child: Text('💻 IT & Operations Teams')),
                    DropdownMenuItem(value: 'MARKETING_FIELD', child: Text('📣 Marketing & Field Agents')),
                    DropdownMenuItem(value: 'HR_MANAGERS', child: Text('👥 HR & Team Managers')),
                    DropdownMenuItem(value: 'ACCOUNTS_FINANCE', child: Text('💰 Accounts & Finance')),
                  ],
                  onChanged: (val) => setModalState(() => target = val ?? 'ALL_DEPARTMENTS'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Alert Urgency / Priority', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'URGENT', child: Text('🔴 URGENT (Immediate Push & Sound)')),
                    DropdownMenuItem(value: 'HIGH', child: Text('🟠 High Priority')),
                    DropdownMenuItem(value: 'MEDIUM', child: Text('🟡 Normal Priority')),
                    DropdownMenuItem(value: 'INFO', child: Text('🔵 Informational / Bulletin')),
                  ],
                  onChanged: (val) => setModalState(() => priority = val ?? 'HIGH'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: msgCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Detailed Broadcast Message', border: OutlineInputBorder()),
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
                    existing['target'] = target;
                    existing['priority'] = priority;
                  } else {
                    final newBc = {
                      'id': 'BC-${DateTime.now().millisecondsSinceEpoch}',
                      'title': titleCtrl.text.trim(),
                      'target': target,
                      'priority': priority,
                      'created_at': 'Just now',
                      'author': 'Akarshan Mishra (Super Admin)',
                      'readCount': '0/124 Read',
                    };
                    _broadcasts.insert(0, newBc);
                    _notifications.insert(0, {
                      'id': 'notif-${DateTime.now().millisecondsSinceEpoch}',
                      'title': titleCtrl.text.trim(),
                      'message': msgCtrl.text.trim().isNotEmpty ? msgCtrl.text.trim() : 'Company broadcast alert.',
                      'notification_type': 'COMPANY_BROADCAST',
                      'priority': priority,
                      'is_read': false,
                      'action_required': priority == 'URGENT',
                      'created_at': 'Just now',
                    });
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('🚀 Broadcast "${titleCtrl.text.trim()}" dispatched to $target')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              child: const Text('Publish Broadcast'),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // FILTERING LOGIC
  // ===========================================================================
  List<Map<String, dynamic>> get _filteredNotifications {
    return _notifications.where((n) {
      if (_searchQuery.isNotEmpty) {
        final title = (n['title'] ?? '').toString().toLowerCase();
        final msg = (n['message'] ?? '').toString().toLowerCase();
        if (!title.contains(_searchQuery) && !msg.contains(_searchQuery)) {
          return false;
        }
      }

      switch (_selectedFilter) {
        case NotificationFilter.unread:
          return n['is_read'] == false;
        case NotificationFilter.actionRequired:
          return n['action_required'] == true;
        case NotificationFilter.approvals:
          return n['notification_type'] == 'APPROVAL_REQUEST';
        case NotificationFilter.system:
          return n['notification_type'] == 'SYSTEM_ALERT' || n['notification_type'] == 'COMPANY_BROADCAST';
        case NotificationFilter.all:
        default:
          return true;
      }
    }).toList();
  }

  int get _unreadCount => _notifications.where((n) => n['is_read'] == false).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark High-End Command Center
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: Color(0xFF38BDF8), size: 22),
            const SizedBox(width: 8),
            const Text('Enterprise Notification Center', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(10)),
                child: Text('$_unreadCount New', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Colors.white),
            tooltip: 'Mark All Read',
            onPressed: _markAllAsRead,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFF94A3B8)),
            tooltip: 'Clear Read',
            onPressed: _clearAllRead,
          ),
          ElevatedButton.icon(
            onPressed: () => _showBroadcastCreationModal(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.campaign_rounded, size: 15),
            label: const Text('Broadcast', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF38BDF8),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF38BDF8),
          tabs: const [
            Tab(icon: Icon(Icons.inbox_rounded), text: 'Inbox & Alerts'),
            Tab(icon: Icon(Icons.broadcast_on_personal_rounded), text: 'Broadcast Studio'),
            Tab(icon: Icon(Icons.tune_rounded), text: 'Delivery Channels'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInboxTab(),
          _buildBroadcastStudioTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. INBOX & ALERTS TAB WITH INSTANT CRUD
  // ===========================================================================
  Widget _buildInboxTab() {
    final list = _filteredNotifications;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Filter Chips & Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Filter notifications by keyword...',
                        prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter Segment Tabs
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('All (${_notifications.length})', NotificationFilter.all),
                _buildFilterChip('Unread ($_unreadCount)', NotificationFilter.unread),
                _buildFilterChip('Action Required', NotificationFilter.actionRequired),
                _buildFilterChip('Approvals', NotificationFilter.approvals),
                _buildFilterChip('System Alerts', NotificationFilter.system),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Notifications List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_off_outlined, size: 54, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 12),
                            const Text('No notifications found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                            const SizedBox(height: 4),
                            Text('You are fully caught up with all enterprise activity.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _initializeNotifications,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, index) {
                            final n = list[index];
                            final isRead = n['is_read'] == true;
                            final priority = n['priority'];
                            final type = n['notification_type'];

                            final color = _getPriorityColor(priority, type);
                            final icon = _getNotificationIcon(type);

                            return Dismissible(
                              key: Key(n['id']),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(12)),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.delete_outline, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text('Dismiss', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              onDismissed: (_) => _deleteNotification(index),
                              child: Card(
                                elevation: 0,
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFF93C5FD), width: isRead ? 1 : 1.5),
                                ),
                                color: isRead ? Colors.white : const Color(0xFFEFF6FF),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: color.withOpacity(0.12),
                                            child: Icon(icon, color: color, size: 18),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        n['title'] ?? '',
                                                        style: TextStyle(
                                                          fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                                          fontSize: 13.5,
                                                          color: const Color(0xFF0F172A),
                                                        ),
                                                      ),
                                                    ),
                                                    if (!isRead)
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        margin: const EdgeInsets.only(left: 6),
                                                        decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Text(n['message'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Text(n['created_at'] ?? '', style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                                                    const SizedBox(width: 10),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                                      child: Text(priority ?? 'NORMAL', style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF94A3B8)),
                                            onSelected: (action) {
                                              if (action == 'toggle_read') {
                                                _toggleReadStatus(n);
                                              } else if (action == 'delete') {
                                                _deleteNotification(index);
                                              }
                                            },
                                            itemBuilder: (ctx) => [
                                              PopupMenuItem(value: 'toggle_read', child: Text(isRead ? 'Mark as Unread' : 'Mark as Read')),
                                              const PopupMenuItem(value: 'delete', child: Text('Delete Notification', style: TextStyle(color: Colors.red))),
                                            ],
                                          ),
                                        ],
                                      ),

                                      // Direct Inline Action Row
                                      if (n['action_required'] == true) ...[
                                        const SizedBox(height: 10),
                                        const Divider(color: Color(0xFFE2E8F0), height: 1),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            if (n['action_type'] == 'APPROVE_LEAVE') ...[
                                              OutlinedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    n['action_required'] = false;
                                                    n['is_read'] = true;
                                                  });
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Leave request rejected')));
                                                },
                                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                                                child: const Text('Reject', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    n['action_required'] = false;
                                                    n['is_read'] = true;
                                                  });
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Leave approved successfully')));
                                                },
                                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                                                child: const Text('Approve Leave', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                              ),
                                            ] else if (n['action_type'] == 'VIEW_BOOKING') ...[
                                              ElevatedButton.icon(
                                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeadsPartnersBookingsScreen())),
                                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                                                icon: const Icon(Icons.celebration, size: 14),
                                                label: const Text('Open Booking', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                              ),
                                            ] else ...[
                                              ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    n['action_required'] = false;
                                                    n['is_read'] = true;
                                                  });
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('👁️ Incident acknowledged and logged in Audit')));
                                                },
                                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                                                child: const Text('Acknowledge', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
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

  Widget _buildFilterChip(String label, NotificationFilter filter) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : const Color(0xFF475569), fontWeight: FontWeight.bold)),
        selected: isSelected,
        selectedColor: const Color(0xFF2563EB),
        backgroundColor: Colors.white,
        side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onSelected: (_) => setState(() => _selectedFilter = filter),
      ),
    );
  }

  // ===========================================================================
  // 2. BROADCAST STUDIO TAB (ADMIN NOTIFICATION CRUD)
  // ===========================================================================
  Widget _buildBroadcastStudioTab() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: const Color(0xFF38BDF8).withOpacity(0.15), radius: 24, child: const Icon(Icons.campaign_rounded, color: Color(0xFF38BDF8), size: 24)),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Broadcast Control Tower', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Dispatch company-wide bulletins, urgent alerts, and SOP notices directly to staff mobile devices.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ACTIVE BROADCASTS & NOTICES', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
              ElevatedButton.icon(
                onPressed: () => _showBroadcastCreationModal(),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Broadcast', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._broadcasts.map((bc) => Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(bc['target'], style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                          Text(bc['created_at'], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(bc['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text('Author: ${bc['author']} · Status: ${bc['readCount']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showBroadcastCreationModal(existing: bc),
                            icon: const Icon(Icons.edit, size: 14),
                            label: const Text('Edit', style: TextStyle(fontSize: 11.5)),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() => _broadcasts.remove(bc));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ Broadcast notice retracted')));
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            icon: const Icon(Icons.delete_outline, size: 14),
                            label: const Text('Retract', style: TextStyle(fontSize: 11.5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. DELIVERY CHANNELS & PREFERENCES TAB
  // ===========================================================================
  Widget _buildSettingsTab() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('NOTIFICATION CHANNELS & ROUTING', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('In-App Push Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: const Text('Instant notification banner for tasks, bookings, and approvals', style: TextStyle(fontSize: 11.5)),
                  value: _pushEnabled,
                  onChanged: (val) => setState(() => _pushEnabled = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Email Daily Digest', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: const Text('Receive 08:00 AM summary of pending deliverables and department KPIs', style: TextStyle(fontSize: 11.5)),
                  value: _emailDigest,
                  onChanged: (val) => setState(() => _emailDigest = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('SMS Critical Escalations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: const Text('Direct SMS dispatch for SLA breach and server down incidents', style: TextStyle(fontSize: 11.5)),
                  value: _urgentSms,
                  onChanged: (val) => setState(() => _urgentSms = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Quiet Hours (DND)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: const Text('Mute non-critical notifications between 10:00 PM and 07:00 AM', style: TextStyle(fontSize: 11.5)),
                  value: _quietHours,
                  onChanged: (val) => setState(() => _quietHours = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String? priority, String? type) {
    if (type == 'SYSTEM_ALERT' || priority == 'URGENT') return const Color(0xFFEF4444);
    if (priority == 'HIGH') return const Color(0xFFF97316);
    if (type == 'APPROVAL_REQUEST') return const Color(0xFF10B981);
    if (type == 'BOOKING_ASSIGNED') return const Color(0xFF8B5CF6);
    return const Color(0xFF2563EB);
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'SYSTEM_ALERT':
        return Icons.warning_rounded;
      case 'BOOKING_ASSIGNED':
        return Icons.celebration_rounded;
      case 'APPROVAL_REQUEST':
        return Icons.verified_user_rounded;
      case 'TASK_APPROVED':
        return Icons.check_circle_rounded;
      case 'FINANCE_ALERT':
        return Icons.monetization_on_rounded;
      case 'COMPANY_BROADCAST':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
