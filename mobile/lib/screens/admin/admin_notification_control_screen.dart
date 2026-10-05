import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class AdminNotificationControlScreen extends StatefulWidget {
  const AdminNotificationControlScreen({super.key});

  @override
  State<AdminNotificationControlScreen> createState() => _AdminNotificationControlScreenState();
}

class _AdminNotificationControlScreenState extends State<AdminNotificationControlScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedTypeFilter = 'ALL';

  // 1. MASTER NOTIFICATIONS DISPATCH LOG (FULL CRUD)
  final List<Map<String, dynamic>> _masterNotifications = [
    {
      'id': 'NOTIF-2026-901',
      'title': 'System Maintenance: Offline Sync Engine V2 Deployment',
      'message': 'All mobile clients will automatically migrate SQLite queues at 02:00 AM. Zero downtime expected.',
      'target': 'ALL_DEPARTMENTS',
      'targetCount': 124,
      'readCount': 118,
      'channels': ['IN_APP', 'EMAIL'],
      'priority': 'HIGH',
      'type': 'ANNOUNCEMENT',
      'author': 'Akarshan Mishra (Super Admin)',
      'status': 'DELIVERED',
      'created_at': '05 Oct 2026, 09:00 AM',
      'recipients': [
        {'name': 'Akarshan Mishra', 'dept': 'IT', 'status': 'READ', 'readAt': '09:05 AM'},
        {'name': 'Neha Sharma', 'dept': 'HR', 'status': 'READ', 'readAt': '09:12 AM'},
        {'name': 'Rohan Gupta', 'dept': 'Marketing', 'status': 'READ', 'readAt': '09:20 AM'},
        {'name': 'Kavita Nair', 'dept': 'Operations', 'status': 'READ', 'readAt': '09:30 AM'},
        {'name': 'Amit Verma', 'dept': 'Operations', 'status': 'UNREAD', 'readAt': '—'},
        {'name': 'Ritu Saxena', 'dept': 'Operations', 'status': 'UNREAD', 'readAt': '—'},
      ],
    },
    {
      'id': 'NOTIF-2026-902',
      'title': 'High-Value Booking Alert: TechCorp Annual Meet (₹ 3,40,000)',
      'message': 'Booking BK-2026-090 posted for Royal Palms Resort. 12% settlement payout calculated at ₹ 40,800.',
      'target': 'ACCOUNTS & OPERATIONS',
      'targetCount': 41,
      'readCount': 39,
      'channels': ['IN_APP', 'SMS_URGENT'],
      'priority': 'URGENT',
      'type': 'FINANCE_ALERT',
      'author': 'System Automated Engine',
      'status': 'DELIVERED',
      'created_at': '05 Oct 2026, 11:30 AM',
      'recipients': [
        {'name': 'Deepak Verma', 'dept': 'Accounts', 'status': 'READ', 'readAt': '11:32 AM'},
        {'name': 'Kavita Nair', 'dept': 'Operations', 'status': 'READ', 'readAt': '11:35 AM'},
      ],
    },
    {
      'id': 'NOTIF-2026-903',
      'title': 'Q4 Banquet Commission Policy Enforcement (12%)',
      'message': 'Strict compliance mandatory for all partner onboarding teams starting Q4.',
      'target': 'MARKETING_FIELD',
      'targetCount': 24,
      'readCount': 24,
      'channels': ['IN_APP', 'EMAIL', 'WHATSAPP'],
      'priority': 'NORMAL',
      'type': 'POLICY_UPDATE',
      'author': 'Neha Sharma (HR)',
      'status': 'DELIVERED',
      'created_at': '04 Oct 2026, 04:15 PM',
      'recipients': [
        {'name': 'Rohan Gupta', 'dept': 'Marketing', 'status': 'READ', 'readAt': '04:20 PM'},
        {'name': 'Sunil Yadav', 'dept': 'Marketing', 'status': 'READ', 'readAt': '04:35 PM'},
      ],
    },
  ];

  // 2. AUTOMATED TRIGGER RULES (FULL CRUD)
  final List<Map<String, dynamic>> _triggerRules = [
    {
      'id': 'RULE-01',
      'name': 'Overdue Task SLA Escalation',
      'event': 'TASK_OVERDUE_24H',
      'target': 'Assignee + Department Manager',
      'channel': 'In-App + Email Digest',
      'priority': 'HIGH',
      'enabled': true,
      'desc': 'When any task deadline breaches by 24h, notify assignee and manager with escalation tag.',
    },
    {
      'id': 'RULE-02',
      'name': 'High-Value Booking Threshold (> ₹ 2,00,000)',
      'event': 'BOOKING_CREATED_HIGH_VALUE',
      'target': 'Super Admin + Accounts Lead',
      'channel': 'In-App + SMS Urgent',
      'priority': 'URGENT',
      'enabled': true,
      'desc': 'Instantly alert root management when a banquet booking exceeds ₹ 2,00,000 threshold.',
    },
    {
      'id': 'RULE-03',
      'name': 'Attendance Correction Request Alert',
      'event': 'ATTENDANCE_CORRECTION_SUBMITTED',
      'target': 'HR Department Lead',
      'channel': 'In-App Push',
      'priority': 'NORMAL',
      'enabled': true,
      'desc': 'Route employee biometric / field punch correction requests to HR for 1-click approval.',
    },
    {
      'id': 'RULE-04',
      'name': '12% Partner Commission Payout Approval Gate',
      'event': 'SETTLEMENT_BATCH_GENERATED',
      'target': 'Accounts Lead + Operations Lead',
      'channel': 'In-App + Email',
      'priority': 'HIGH',
      'enabled': true,
      'desc': 'Trigger verification notice when event is marked COMPLETE to initiate 12% partner payout.',
    },
  ];

  // 3. REUSABLE TEMPLATE LIBRARY (FULL CRUD)
  final List<Map<String, dynamic>> _templates = [
    {
      'id': 'TMPL-01',
      'name': 'Task Assignment Blueprint',
      'subject': 'New Deliverable Assigned: {{task_title}}',
      'body': 'Hello {{employee_name}}, you have been assigned to "{{task_title}}" due on {{due_date}}. Priority: {{priority}}.',
      'category': 'Tasks & Operations',
      'variables': ['{{employee_name}}', '{{task_title}}', '{{due_date}}', '{{priority}}'],
    },
    {
      'id': 'TMPL-02',
      'name': 'Banquet Booking Confirmation',
      'subject': 'Booking Confirmed: {{booking_id}} at {{partner_name}}',
      'body': 'Booking {{booking_id}} for {{client_name}} (₹ {{amount}}) has been confirmed at {{partner_name}} for event date {{event_date}}.',
      'category': 'Sales & Bookings',
      'variables': ['{{booking_id}}', '{{partner_name}}', '{{client_name}}', '{{amount}}', '{{event_date}}'],
    },
    {
      'id': 'TMPL-03',
      'name': 'Emergency System Maintenance',
      'subject': 'URGENT: Scheduled Platform Maintenance ({{start_time}} - {{end_time}})',
      'body': 'Please save all offline work. Platform updates scheduled between {{start_time}} and {{end_time}}.',
      'category': 'IT & Infrastructure',
      'variables': ['{{start_time}}', '{{end_time}}'],
    },
  ];

  // 4. OUTBOX QUEUE METRICS
  final int _totalSent = 1480;
  final int _delivered = 1472;
  final int _failed = 8;
  final int _pendingQueue = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ===========================================================================
  // MODALS & CRUD OPERATIONS
  // ===========================================================================
  void _showComposeNotificationModal({Map<String, dynamic>? existing}) {
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final msgCtrl = TextEditingController(text: existing?['message'] ?? '');
    String target = existing?['target'] ?? 'ALL_DEPARTMENTS';
    String priority = existing?['priority'] ?? 'HIGH';
    String type = existing?['type'] ?? 'ANNOUNCEMENT';
    List<String> channels = existing?['channels'] != null
        ? List<String>.from(existing!['channels'])
        : ['IN_APP', 'EMAIL'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.send_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 10),
              Text(existing == null ? 'Admin Notification Dispatcher' : 'Edit Notification Notice', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Headline / Subject', hintText: 'e.g. Critical Security Alert or Company Policy', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: target,
                          decoration: const InputDecoration(labelText: 'Audience Scope', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'ALL_DEPARTMENTS', child: Text('🏢 All Staff (124)')),
                            DropdownMenuItem(value: 'IT_OPERATIONS', child: Text('💻 IT & Operations (49)')),
                            DropdownMenuItem(value: 'MARKETING_FIELD', child: Text('📣 Marketing & Field (24)')),
                            DropdownMenuItem(value: 'HR_MANAGERS', child: Text('👥 HR & Managers (18)')),
                            DropdownMenuItem(value: 'ACCOUNTS & OPERATIONS', child: Text('💰 Accounts & Ops (41)')),
                          ],
                          onChanged: (val) => setModalState(() => target = val ?? 'ALL_DEPARTMENTS'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: priority,
                          decoration: const InputDecoration(labelText: 'Priority Level', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'URGENT', child: Text('🔴 Urgent (SLA Alert)')),
                            DropdownMenuItem(value: 'HIGH', child: Text('🟠 High Priority')),
                            DropdownMenuItem(value: 'NORMAL', child: Text('🟡 Normal')),
                            DropdownMenuItem(value: 'INFO', child: Text('🔵 Informational')),
                          ],
                          onChanged: (val) => setModalState(() => priority = val ?? 'HIGH'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Notification Category', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'ANNOUNCEMENT', child: Text('📢 Company Bulletin / Announcement')),
                      DropdownMenuItem(value: 'FINANCE_ALERT', child: Text('💰 Financial & 12% Settlement Alert')),
                      DropdownMenuItem(value: 'POLICY_UPDATE', child: Text('📜 Policy & Compliance Notice')),
                      DropdownMenuItem(value: 'TASK_ALERT', child: Text('📋 Task / Sprint Escalation')),
                      DropdownMenuItem(value: 'SYSTEM_MAINTENANCE', child: Text('⚙️ IT & Offline Sync Maintenance')),
                    ],
                    onChanged: (val) => setModalState(() => type = val ?? 'ANNOUNCEMENT'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Rich Body Content', hintText: 'Enter complete notification text and instructions...', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                  const Text('Delivery Channels:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('In-App Push', style: TextStyle(fontSize: 11)),
                        selected: channels.contains('IN_APP'),
                        onSelected: (sel) => setModalState(() => sel ? channels.add('IN_APP') : channels.remove('IN_APP')),
                      ),
                      FilterChip(
                        label: const Text('Email Gateway', style: TextStyle(fontSize: 11)),
                        selected: channels.contains('EMAIL'),
                        onSelected: (sel) => setModalState(() => sel ? channels.add('EMAIL') : channels.remove('EMAIL')),
                      ),
                      FilterChip(
                        label: const Text('SMS Urgent Hook', style: TextStyle(fontSize: 11)),
                        selected: channels.contains('SMS_URGENT'),
                        onSelected: (sel) => setModalState(() => sel ? channels.add('SMS_URGENT') : channels.remove('SMS_URGENT')),
                      ),
                      FilterChip(
                        label: const Text('WhatsApp API', style: TextStyle(fontSize: 11)),
                        selected: channels.contains('WHATSAPP'),
                        onSelected: (sel) => setModalState(() => sel ? channels.add('WHATSAPP') : channels.remove('WHATSAPP')),
                      ),
                    ],
                  ),
                ],
              ),
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
                    existing['message'] = msgCtrl.text.trim();
                    existing['target'] = target;
                    existing['priority'] = priority;
                    existing['type'] = type;
                    existing['channels'] = channels;
                  } else {
                    _masterNotifications.insert(0, {
                      'id': 'NOTIF-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                      'title': titleCtrl.text.trim(),
                      'message': msgCtrl.text.trim(),
                      'target': target,
                      'targetCount': target == 'ALL_DEPARTMENTS' ? 124 : 35,
                      'readCount': 0,
                      'channels': channels,
                      'priority': priority,
                      'type': type,
                      'author': 'Akarshan Mishra (Super Admin)',
                      'status': 'DELIVERED',
                      'created_at': 'Just now',
                      'recipients': [
                        {'name': 'Akarshan Mishra', 'dept': 'IT', 'status': 'UNREAD', 'readAt': '—'},
                        {'name': 'Neha Sharma', 'dept': 'HR', 'status': 'UNREAD', 'readAt': '—'},
                        {'name': 'Rohan Gupta', 'dept': 'Marketing', 'status': 'UNREAD', 'readAt': '—'},
                      ],
                    });
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('🚀 Notification "${titleCtrl.text.trim()}" successfully dispatched')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              child: Text(existing == null ? 'Dispatch Notification' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _openReadReceiptsInspector(Map<String, dynamic> notif) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final recipients = (notif['recipients'] ?? []) as List<dynamic>;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  children: [
                    CircleAvatar(backgroundColor: const Color(0xFF2563EB).withOpacity(0.12), child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF2563EB))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notif['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Delivery Stats: ${notif['readCount']}/${notif['targetCount']} Read (${((notif['readCount'] / (notif['targetCount'] > 0 ? notif['targetCount'] : 1)) * 100).toInt()}%)', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('RECIPIENT TELEMETRY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🔔 Follow-up nudge sent to all unread recipients')),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                      icon: const Icon(Icons.notifications_active, size: 14),
                      label: const Text('Resend Nudge to Unread', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...recipients.map((r) => Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFE2E8F0))),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: r['status'] == 'READ' ? Colors.green.shade100 : Colors.amber.shade100,
                          child: Icon(r['status'] == 'READ' ? Icons.check : Icons.hourglass_empty, size: 14, color: r['status'] == 'READ' ? Colors.green : Colors.amber.shade800),
                        ),
                        title: Text(r['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('${r['dept']} Department · Read: ${r['readAt']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: r['status'] == 'READ' ? Colors.green.withOpacity(0.12) : Colors.amber.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                          child: Text(r['status'], style: TextStyle(color: r['status'] == 'READ' ? Colors.green.shade800 : Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddEditRuleModal({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final descCtrl = TextEditingController(text: existing?['desc'] ?? '');
    String event = existing?['event'] ?? 'TASK_OVERDUE_24H';
    String target = existing?['target'] ?? 'Assignee + Department Manager';
    String channel = existing?['channel'] ?? 'In-App + Email Digest';
    String priority = existing?['priority'] ?? 'HIGH';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setRuleState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing == null ? 'Create Automated Notification Trigger' : 'Edit Trigger Rule', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Rule Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: event,
                  decoration: const InputDecoration(labelText: 'Trigger Event', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'TASK_OVERDUE_24H', child: Text('Task Overdue > 24 Hours')),
                    DropdownMenuItem(value: 'BOOKING_CREATED_HIGH_VALUE', child: Text('Booking Value > ₹ 2,00,000')),
                    DropdownMenuItem(value: 'ATTENDANCE_CORRECTION_SUBMITTED', child: Text('Attendance Correction Submitted')),
                    DropdownMenuItem(value: 'SETTLEMENT_BATCH_GENERATED', child: Text('12% Partner Settlement Generated')),
                    DropdownMenuItem(value: 'CRITICAL_TICKET_LOGGED', child: Text('High/Urgent Support Ticket Logged')),
                  ],
                  onChanged: (val) => setRuleState(() => event = val ?? 'TASK_OVERDUE_24H'),
                ),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Condition & Rationale', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                setState(() {
                  if (existing != null) {
                    existing['name'] = nameCtrl.text.trim();
                    existing['event'] = event;
                    existing['desc'] = descCtrl.text.trim();
                  } else {
                    _triggerRules.add({
                      'id': 'RULE-${_triggerRules.length + 1}',
                      'name': nameCtrl.text.trim(),
                      'event': event,
                      'target': target,
                      'channel': channel,
                      'priority': priority,
                      'enabled': true,
                      'desc': descCtrl.text.trim(),
                    });
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Automated Trigger Rule saved')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              child: const Text('Save Trigger Rule'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditTemplateModal({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final subjCtrl = TextEditingController(text: existing?['subject'] ?? '');
    final bodyCtrl = TextEditingController(text: existing?['body'] ?? '');
    String category = existing?['category'] ?? 'Tasks & Operations';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(existing == null ? 'Create Notification Template' : 'Edit Template Blueprint', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Template Title', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: subjCtrl, decoration: const InputDecoration(labelText: 'Subject Line (with variables)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: bodyCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Body Template (e.g. {{employee_name}})', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              setState(() {
                if (existing != null) {
                  existing['name'] = nameCtrl.text.trim();
                  existing['subject'] = subjCtrl.text.trim();
                  existing['body'] = bodyCtrl.text.trim();
                } else {
                  _templates.add({
                    'id': 'TMPL-${_templates.length + 1}',
                    'name': nameCtrl.text.trim(),
                    'subject': subjCtrl.text.trim(),
                    'body': bodyCtrl.text.trim(),
                    'category': category,
                    'variables': ['{{name}}', '{{id}}'],
                  });
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Notification Template saved')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            child: const Text('Save Template'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark SaaS Command Hub
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.mark_email_unread_rounded, color: Color(0xFF38BDF8), size: 22),
            SizedBox(width: 8),
            Text('Admin Notification Engine & Dispatch Studio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showComposeNotificationModal(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Dispatch Notification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 14),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF38BDF8),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF38BDF8),
          tabs: const [
            Tab(icon: Icon(Icons.campaign_rounded), text: 'Master Dispatches'),
            Tab(icon: Icon(Icons.bolt_rounded), text: 'Automated Triggers'),
            Tab(icon: Icon(Icons.style_rounded), text: 'Template Blueprints'),
            Tab(icon: Icon(Icons.outbox_rounded), text: 'Outbox & Telemetry'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMasterDispatchesTab(),
          _buildAutomatedTriggersTab(),
          _buildTemplatesTab(),
          _buildOutboxTelemetryTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: MASTER NOTIFICATIONS DISPATCH FEED (FULL CRUD)
  // ===========================================================================
  Widget _buildMasterDispatchesTab() {
    final filtered = _masterNotifications.where((n) {
      if (_searchQuery.isNotEmpty) {
        final title = n['title'].toString().toLowerCase();
        final msg = n['message'].toString().toLowerCase();
        if (!title.contains(_searchQuery) && !msg.contains(_searchQuery)) return false;
      }
      if (_selectedTypeFilter != 'ALL' && n['type'] != _selectedTypeFilter) return false;
      return true;
    }).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search dispatches by headline or message...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedTypeFilter,
                  dropdownColor: Colors.white,
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('All Types')),
                    DropdownMenuItem(value: 'ANNOUNCEMENT', child: Text('Announcements')),
                    DropdownMenuItem(value: 'FINANCE_ALERT', child: Text('Financial Alerts')),
                    DropdownMenuItem(value: 'POLICY_UPDATE', child: Text('Policy Updates')),
                  ],
                  onChanged: (val) => setState(() => _selectedTypeFilter = val ?? 'ALL'),
                ),
              ],
            ),
          ),

          // Master Dispatch List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final notif = filtered[index];
                final priority = notif['priority'];
                final color = priority == 'URGENT'
                    ? const Color(0xFFEF4444)
                    : priority == 'HIGH'
                        ? const Color(0xFFF97316)
                        : const Color(0xFF2563EB);

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                              child: Text(notif['type'], style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10.5)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                              child: Text('Scope: ${notif['target']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Color(0xFF475569))),
                            ),
                            const Spacer(),
                            Text(notif['created_at'], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF64748B)),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _showComposeNotificationModal(existing: notif);
                                } else if (val == 'receipts') {
                                  _openReadReceiptsInspector(notif);
                                } else if (val == 'retract') {
                                  setState(() => _masterNotifications.remove(notif));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ Notification retracted across all devices')));
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(value: 'receipts', child: Text('📊 View Read Receipts')),
                                const PopupMenuItem(value: 'edit', child: Text('✏️ Edit Notification')),
                                const PopupMenuItem(value: 'retract', child: Text('🗑️ Retract / Delete Alert', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(notif['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                        const SizedBox(height: 4),
                        Text(notif['message'], style: const TextStyle(color: Color(0xFF475569), fontSize: 12.5, height: 1.3)),
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFFF1F5F9), height: 1),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text('Author: ${notif['author']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5)),
                            const Spacer(),
                            InkWell(
                              onTap: () => _openReadReceiptsInspector(notif),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFBFDBFE))),
                                child: Row(
                                  children: [
                                    const Icon(Icons.people_alt_rounded, size: 14, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 6),
                                    Text('${notif['readCount']} / ${notif['targetCount']} Read', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 11.5)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  // ===========================================================================
  // TAB 2: AUTOMATED TRIGGER RULES (FULL CRUD)
  // ===========================================================================
  Widget _buildAutomatedTriggersTab() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('EVENT-DRIVEN NOTIFICATION TRIGGERS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
              ElevatedButton.icon(
                onPressed: () => _showAddEditRuleModal(),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Trigger Rule', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ..._triggerRules.map((rule) => Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                        child: const Icon(Icons.bolt_rounded, color: Color(0xFF2563EB)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(rule['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F172A)))),
                                Switch(
                                  value: rule['enabled'] == true,
                                  onChanged: (val) => setState(() => rule['enabled'] = val),
                                ),
                              ],
                            ),
                            Text('Event: ${rule['event']} · Target: ${rule['target']}', style: const TextStyle(color: Color(0xFF2563EB), fontSize: 11.5, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(rule['desc'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showAddEditRuleModal(existing: rule),
                                  icon: const Icon(Icons.edit, size: 14),
                                  label: const Text('Edit Rule', style: TextStyle(fontSize: 11.5)),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() => _triggerRules.remove(rule));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ Trigger rule deleted')));
                                  },
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  icon: const Icon(Icons.delete_outline, size: 14),
                                  label: const Text('Delete', style: TextStyle(fontSize: 11.5)),
                                ),
                              ],
                            ),
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

  // ===========================================================================
  // TAB 3: TEMPLATES BLUEPRINTS (FULL CRUD)
  // ===========================================================================
  Widget _buildTemplatesTab() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('REUSABLE MESSAGE BLUEPRINTS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
              ElevatedButton.icon(
                onPressed: () => _showAddEditTemplateModal(),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Template', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ..._templates.map((tmpl) => Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tmpl['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F172A))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                            child: Text(tmpl['category'], style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Subject: ${tmpl['subject']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF2563EB))),
                      const SizedBox(height: 4),
                      Text(tmpl['body'], style: const TextStyle(color: Color(0xFF475569), fontSize: 12)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: (tmpl['variables'] as List<dynamic>).map((v) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFBFDBFE))),
                              child: Text(v.toString(), style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF1E40AF))),
                            )).toList(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showAddEditTemplateModal(existing: tmpl),
                            icon: const Icon(Icons.edit, size: 14),
                            label: const Text('Edit', style: TextStyle(fontSize: 11.5)),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() => _templates.remove(tmpl));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ Template deleted')));
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            icon: const Icon(Icons.delete_outline, size: 14),
                            label: const Text('Delete', style: TextStyle(fontSize: 11.5)),
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
  // TAB 4: OUTBOX QUEUE & TELEMETRY
  // ===========================================================================
  Widget _buildOutboxTelemetryTab() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('PUSH DISPATCH PIPELINE TELEMETRY', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildQueueMetricCard('Total Dispatches', '$_totalSent', Icons.send_rounded, const Color(0xFF2563EB))),
              const SizedBox(width: 10),
              Expanded(child: _buildQueueMetricCard('Delivered (99.4%)', '$_delivered', Icons.check_circle_rounded, const Color(0xFF10B981))),
              const SizedBox(width: 10),
              Expanded(child: _buildQueueMetricCard('Failed / Bounced', '$_failed', Icons.error_rounded, const Color(0xFFEF4444))),
              const SizedBox(width: 10),
              Expanded(child: _buildQueueMetricCard('Queue Backlog', '$_pendingQueue', Icons.hourglass_empty_rounded, const Color(0xFFF59E0B))),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('FAILED DISPATCH LOGS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔄 Retrying 8 failed push notifications...')));
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Retry All Failed', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildFailedLogTile('SMS Gateway Timeout (Recipient: +91 99887 00012)', 'Gateway response 504. Queued for 2nd retry.', '10 mins ago'),
          _buildFailedLogTile('FCM Token Expired (Device ID: #DEV-804)', 'Device token invalidated on client update.', '1 hour ago'),
        ],
      ),
    );
  }

  Widget _buildQueueMetricCard(String label, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 18),
              Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFailedLogTile(String title, String desc, String time) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFFCA5A5))),
      color: const Color(0xFFFEF2F2),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF991B1B))),
        subtitle: Text('$desc · $time', style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D))),
        trailing: TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Retrying dispatch...')));
          },
          child: const Text('Retry Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
        ),
      ),
    );
  }
}
