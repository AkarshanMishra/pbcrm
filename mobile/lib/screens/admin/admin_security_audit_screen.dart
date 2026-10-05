import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class AdminSecurityAuditScreen extends StatefulWidget {
  const AdminSecurityAuditScreen({super.key});

  @override
  State<AdminSecurityAuditScreen> createState() => _AdminSecurityAuditScreenState();
}

class _AdminSecurityAuditScreenState extends State<AdminSecurityAuditScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;
  bool _isLoading = true;

  Map<String, dynamic>? _metrics;
  List<dynamic> _auditLogs = [];
  List<dynamic> _sessions = [];
  List<dynamic> _devices = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchSecurityData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchSecurityData() async {
    setState(() => _isLoading = true);
    try {
      final mRes = await _api.dio.get('/security/metrics/');
      final aRes = await _api.dio.get('/audit/logs/');
      final sRes = await _api.dio.get('/security/sessions/');
      final dRes = await _api.dio.get('/security/devices/');

      setState(() {
        _metrics = mRes.data['metrics'];
        _auditLogs = aRes.data['results'] ?? aRes.data ?? [];
        _sessions = sRes.data['sessions'] ?? sRes.data ?? [];
        _devices = dRes.data['devices'] ?? dRes.data ?? [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showAuditLogDetail(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.history_edu, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(log['event_type'] ?? 'Audit Event', style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAuditRow('Timestamp', log['timestamp'] ?? '--'),
              _buildAuditRow('Actor / User', log['actor_email'] ?? log['actor_username'] ?? 'System / Admin'),
              _buildAuditRow('Action', log['action'] ?? log['event_type'] ?? '--'),
              _buildAuditRow('Target Model', log['target_model'] ?? '--'),
              _buildAuditRow('Target ID', log['target_id'] ?? '--'),
              _buildAuditRow('IP Address', log['ip_address'] ?? '127.0.0.1'),
              const SizedBox(height: 12),
              const Text('Payload / Metadata:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  log['metadata'] != null ? log['metadata'].toString() : 'No additional metadata attached.',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildAuditRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security & Compliance Operations Center'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primary,
          tabs: [
            const Tab(icon: Icon(Icons.shield), text: 'Security Hub'),
            Tab(icon: const Icon(Icons.history), text: 'Audit Trail (${_auditLogs.length})'),
            Tab(icon: const Icon(Icons.devices), text: 'Sessions (${_sessions.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSecurityHubTab(),
                _buildAuditLogsTab(),
                _buildSessionsTab(),
              ],
            ),
    );
  }

  Widget _buildSecurityHubTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Enterprise Security Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSecurityKpi('Failed Logins', '${_metrics?['failed_logins_24h'] ?? 0}', Colors.red)),
            const SizedBox(width: 8),
            Expanded(child: _buildSecurityKpi('Locked Accounts', '${_metrics?['locked_accounts'] ?? 0}', Colors.orange)),
            const SizedBox(width: 8),
            Expanded(child: _buildSecurityKpi('Active Sessions', '${_metrics?['active_sessions'] ?? 0}', Colors.blue)),
          ],
        ),
        const SizedBox(height: 20),

        const Text('Real-time Security Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.verified_user, color: Colors.green),
                title: const Text('Zero-Trust Role-Based Access Control (RBAC)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('All API endpoints enforce strict server-side permission validation.'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.enhanced_encryption, color: Colors.indigo),
                title: const Text('Cryptographic Refresh Token Rotation', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Tokens automatically blacklisted on logout, password reset, or revocation.'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.fingerprint, color: Colors.teal),
                title: const Text('Device Binding & Anomaly Detection', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Hardware UUID signature verified with automated session revocation.'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuditLogsTab() {
    if (_auditLogs.isEmpty) {
      return const Center(child: Text('No audit logs recorded.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _auditLogs.length,
      itemBuilder: (ctx, idx) {
        final log = _auditLogs[idx];
        final event = log['event_type'] ?? log['action'] ?? 'EVENT';
        final user = log['actor_email'] ?? log['actor_username'] ?? 'Admin';
        final time = log['timestamp'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEFF6FF),
              child: Icon(Icons.security, color: AppTheme.primary, size: 20),
            ),
            title: Text(event, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('By $user • $time', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => _showAuditLogDetail(log),
          ),
        );
      },
    );
  }

  Widget _buildSessionsTab() {
    if (_sessions.isEmpty) {
      return const Center(child: Text('No active sessions found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sessions.length,
      itemBuilder: (ctx, idx) {
        final s = _sessions[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.laptop_chromebook, color: AppTheme.primary),
            title: Text(s['user_email'] ?? s['device_name'] ?? 'Session', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('IP: ${s['ip_address'] ?? '127.0.0.1'} • Last active: ${s['last_active'] ?? 'Recent'}'),
            trailing: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Revoke'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecurityKpi(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
