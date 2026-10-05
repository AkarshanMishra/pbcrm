import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class SecurityCenterScreen extends StatefulWidget {
  const SecurityCenterScreen({super.key});

  @override
  State<SecurityCenterScreen> createState() => _SecurityCenterScreenState();
}

class _SecurityCenterScreenState extends State<SecurityCenterScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _devices = [];
  List<dynamic> _sessions = [];

  @override
  void initState() {
    super.initState();
    _fetchSecurityData();
  }

  Future<void> _fetchSecurityData() async {
    setState(() => _isLoading = true);
    try {
      final devRes = await _api.dio.get('/auth/devices/');
      final sessRes = await _api.dio.get('/auth/sessions/');
      setState(() {
        _devices = devRes.data['results'] ?? devRes.data ?? [];
        _sessions = sessRes.data['results'] ?? sessRes.data ?? [];
      });
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _revokeDevice(String id, String name) async {
    try {
      await _api.dio.post('/auth/devices/$id/revoke/');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Revoked device '$name'"), backgroundColor: AppTheme.success),
      );
      _fetchSecurityData();
    } catch (_) {}
  }

  Future<void> _revokeOtherSessions() async {
    try {
      final res = await _api.dio.post('/auth/sessions/revoke-others/');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.data['message']), backgroundColor: AppTheme.success),
      );
      _fetchSecurityData();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security & Device Center')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchSecurityData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Active Sessions Header Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.shield_outlined, color: AppTheme.primary),
                              SizedBox(width: 8),
                              Text('Active Sessions & Tokens', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You currently have ${_sessions.length} active authenticated session(s).',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _revokeOtherSessions,
                            icon: const Icon(Icons.phonelink_erase, color: AppTheme.error),
                            label: const Text('Log Out Other Devices', style: TextStyle(color: AppTheme.error)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.error)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('Registered Devices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  if (_devices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No devices registered.', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ..._devices.map((d) {
                      final name = d['device_name'] ?? 'Device';
                      final type = d['device_type'] ?? 'MOBILE';
                      final id = d['id'];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            type == 'IOS' ? Icons.phone_iphone : Icons.phone_android,
                            color: AppTheme.primary,
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('ID: ${d['device_id']}\nLast active: ${d['last_active_at'] ?? "Recently"}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                            tooltip: 'Revoke Access',
                            onPressed: () => _revokeDevice(id, name),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
