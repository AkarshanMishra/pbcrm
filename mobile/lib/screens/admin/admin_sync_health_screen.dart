import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class AdminSyncHealthScreen extends StatefulWidget {
  const AdminSyncHealthScreen({super.key});

  @override
  State<AdminSyncHealthScreen> createState() => _AdminSyncHealthScreenState();
}

class _AdminSyncHealthScreenState extends State<AdminSyncHealthScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic> _healthData = {};
  List<dynamic> _devices = [];

  @override
  void initState() {
    super.initState();
    _fetchHealthData();
  }

  Future<void> _fetchHealthData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/sync/admin/health/');
      setState(() {
        _healthData = res.data ?? {};
        _devices = (res.data['devices'] as List<dynamic>?) ?? [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDeviceRevoke(dynamic device) async {
    final deviceId = device['id'];
    final isRevoked = device['is_revoked'] ?? false;
    final actionName = isRevoked ? 'Restore' : 'Revoke / Block';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionName Device?'),
        content: Text(
          isRevoked
              ? 'Restore synchronization access for this device?'
              : 'Revoking this device will immediately disable all offline synchronization and block pending mutations.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isRevoked ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await _api.dio.post('/sync/admin/devices/$deviceId/revoke/');
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchHealthData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Device status updated.')),
                  );
                }
              } catch (_) {}
            },
            child: Text('Confirm $actionName'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleForceSync(dynamic device) async {
    final deviceId = device['id'];
    try {
      await _api.dio.post('/sync/admin/devices/$deviceId/force_sync/');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Force sync command dispatched to device.'), backgroundColor: AppTheme.success),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final totalDevices = _healthData['total_devices'] ?? _devices.length;
    final onlineDevices = _healthData['online_devices'] ?? 0;
    final offlineDevices = _healthData['offline_devices'] ?? (totalDevices - onlineDevices);
    final staleDevices = _healthData['stale_devices_24h'] ?? 0;
    final totalPending = _healthData['total_pending_sync_items'] ?? 0;
    final totalErrors = _healthData['total_sync_errors'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync & Device Fleet Health'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Health Data',
            onPressed: _fetchHealthData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Top Health Overview Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Fleet Health Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                              child: const Text('ENGINE LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCol('Total Devices', '$totalDevices', Colors.blue),
                            _buildStatCol('Online', '$onlineDevices', Colors.green),
                            _buildStatCol('Offline', '$offlineDevices', Colors.orange),
                            _buildStatCol('Stale (>24h)', '$staleDevices', Colors.red),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCol('Pending Sync Items', '$totalPending', Colors.indigo),
                            _buildStatCol('Sync Errors / Conflicts', '$totalErrors', Colors.purple),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Device Fleet Table / List
                const Text('Registered Enterprise Devices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                if (_devices.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No devices registered yet.')),
                    ),
                  )
                else
                  ..._devices.map((d) {
                    final isRevoked = d['is_revoked'] ?? false;
                    final isOnline = d['is_online'] ?? false;
                    final empName = d['employee_name'] ?? 'Unassigned';
                    final empCode = d['employee_code'] ?? '';
                    final lastSync = d['last_synced_at'] != null ? d['last_synced_at'].toString().substring(0, 16) : 'Never';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone_android,
                                      color: isRevoked ? Colors.red : (isOnline ? Colors.green : Colors.orange),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      d['device_name'] != null && d['device_name'].toString().isNotEmpty
                                          ? d['device_name']
                                          : d['device_id'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isRevoked
                                        ? Colors.red.shade100
                                        : (isOnline ? Colors.green.shade100 : Colors.orange.shade100),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isRevoked ? 'REVOKED' : (isOnline ? 'ONLINE' : 'OFFLINE'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isRevoked ? Colors.red.shade900 : (isOnline ? Colors.green.shade900 : Colors.orange.shade900),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Employee: $empName ($empCode) • Dept: ${d['department_name'] ?? 'General'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                            Text('App v${d['app_version'] ?? '1.0.0'} • OS: ${d['os_version'] ?? 'Standard'} • Last Sync: $lastSync', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Text('Sync Stats: ${d['successful_sync_count'] ?? 0} Synced | ${d['pending_sync_count'] ?? 0} Pending Queue | ${d['failed_sync_count'] ?? 0} Errors', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _handleForceSync(d),
                                  icon: const Icon(Icons.sync, size: 14),
                                  label: const Text('Force Sync', style: TextStyle(fontSize: 11)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isRevoked ? Colors.green : Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => _handleDeviceRevoke(d),
                                  icon: Icon(isRevoked ? Icons.check : Icons.block, size: 14),
                                  label: Text(isRevoked ? 'Restore Device' : 'Revoke Device', style: const TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }

  Widget _buildStatCol(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }
}
