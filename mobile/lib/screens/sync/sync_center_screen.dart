import 'package:flutter/material.dart';
import '../../core/sync/offline_sync_engine.dart';
import '../../core/theme/app_theme.dart';

class SyncCenterScreen extends StatefulWidget {
  const SyncCenterScreen({super.key});

  @override
  State<SyncCenterScreen> createState() => _SyncCenterScreenState();
}

class _SyncCenterScreenState extends State<SyncCenterScreen> {
  final OfflineSyncEngine _syncEngine = OfflineSyncEngine();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _syncEngine.addListener(_onSyncEngineChanged);
  }

  @override
  void dispose() {
    _syncEngine.removeListener(_onSyncEngineChanged);
    super.dispose();
  }

  void _onSyncEngineChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleManualSync() async {
    setState(() => _isSyncing = true);
    final success = await _syncEngine.syncNow();
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✓ Synchronization completed successfully!' : 'Offline: Changes saved in local queue.'),
          backgroundColor: success ? AppTheme.success : Colors.orange.shade800,
        ),
      );
    }
  }

  void _showConflictDialog(SyncQueueItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Reconciliation Conflict', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This record was updated on the server while you were offline. Choose how to reconcile:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('YOUR OFFLINE VERSION:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.indigo)),
                  const SizedBox(height: 4),
                  Text('Action: ${item.actionType}', style: const TextStyle(fontSize: 12)),
                  Text('Time: ${item.clientTimestamp.toString().substring(0, 16)}', style: const TextStyle(fontSize: 12)),
                  if (item.payload.isNotEmpty)
                    Text('Data: ${item.payload.toString()}', style: const TextStyle(fontSize: 11, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _syncEngine.resolveConflict(item.clientId, true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reconciled: Kept Authoritative Server Record.')),
              );
            },
            child: const Text('Keep Server Record', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _syncEngine.resolveConflict(item.clientId, false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Re-queued offline change with priority.')),
              );
            },
            child: const Text('Apply My Offline Change'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _syncEngine.networkState;
    final queue = _syncEngine.queue;
    final pendingCount = _syncEngine.pendingCount;
    final syncedCount = _syncEngine.syncedCount;
    final conflictCount = _syncEngine.conflictCount;
    final failedCount = _syncEngine.failedCount;
    final lastSyncStr = _syncEngine.lastSyncTime != null
        ? _syncEngine.lastSyncTime!.toString().substring(11, 19)
        : 'Never in session';

    Color stateColor = Colors.green;
    String stateTitle = "Online & Connected";
    String stateSubtitle = "Server is authoritative. Background synchronization active.";
    IconData stateIcon = Icons.cloud_done;

    if (state == SyncNetworkState.syncing) {
      stateColor = Colors.blue;
      stateTitle = "Synchronizing Now...";
      stateSubtitle = "Uploading offline changes to the central server.";
      stateIcon = Icons.sync;
    } else if (state == SyncNetworkState.offline) {
      stateColor = Colors.amber.shade900;
      stateTitle = "Offline Mode";
      stateSubtitle = "No internet connection. Changes safely preserved in local queue.";
      stateIcon = Icons.cloud_off;
    } else if (state == SyncNetworkState.syncIssue) {
      stateColor = Colors.red;
      stateTitle = "Sync Attention Required";
      stateSubtitle = "One or more items encountered conflict or validation error.";
      stateIcon = Icons.sync_problem;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline & Sync Center'),
        actions: [
          if (syncedCount > 0)
            IconButton(
              icon: const Icon(Icons.cleaning_services),
              tooltip: 'Clear Synced History',
              onPressed: () {
                _syncEngine.clearSyncedItems();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Cleared synchronized audit items.')),
                );
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Connection Status Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: stateColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(stateIcon, size: 30, color: stateColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stateTitle,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: stateColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stateSubtitle,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Metrics Grid
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricCol('Pending', '$pendingCount', Colors.orange.shade800),
                  _buildMetricCol('Synced', '$syncedCount', Colors.green),
                  _buildMetricCol('Issues', '${conflictCount + failedCount}', Colors.red),
                  _buildMetricCol('Last Sync', lastSyncStr, Colors.blueGrey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sync Now Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSyncing ? null : _handleManualSync,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isSyncing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sync),
              label: Text(_isSyncing ? 'SYNCHRONIZING WITH SERVER...' : 'SYNC NOW WITH SERVER'),
            ),
          ),
          const SizedBox(height: 24),

          // Local Queue Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Local Offline Queue (${queue.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Auto-retries on reconnection',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (queue.isEmpty)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(36),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                      SizedBox(height: 10),
                      Text('All local data is fully synchronized!', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Any new offline punches, tasks, or reports will appear here.', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            )
          else
            ...queue.map((item) {
              final status = item.status;
              Color itemColor = Colors.orange;
              IconData itemIcon = Icons.hourglass_top;

              if (status == 'SYNCED') {
                itemColor = Colors.green;
                itemIcon = Icons.check_circle;
              } else if (status == 'SYNCING') {
                itemColor = Colors.blue;
                itemIcon = Icons.sync;
              } else if (status == 'CONFLICT') {
                itemColor = Colors.purple;
                itemIcon = Icons.warning_amber;
              } else if (status == 'FAILED') {
                itemColor = Colors.red;
                itemIcon = Icons.error_outline;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(itemIcon, color: itemColor, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _formatActionName(item.actionType),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: itemColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(color: itemColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Queued at: ${item.clientTimestamp.toString().substring(0, 19)} • ID: ${item.clientId}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      if (item.errorMessage != null && item.errorMessage!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Reason: ${item.errorMessage}',
                            style: TextStyle(fontSize: 11, color: Colors.red.shade800),
                          ),
                        ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status == 'CONFLICT')
                            TextButton.icon(
                              onPressed: () => _showConflictDialog(item),
                              icon: const Icon(Icons.rule, size: 14),
                              label: const Text('Resolve Conflict', style: TextStyle(fontSize: 11)),
                            ),
                          if (status == 'PENDING' || status == 'FAILED')
                            TextButton.icon(
                              onPressed: _handleManualSync,
                              icon: const Icon(Icons.refresh, size: 14),
                              label: const Text('Retry', style: TextStyle(fontSize: 11)),
                            ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                            tooltip: 'Discard Queued Item',
                            onPressed: () {
                              _syncEngine.removeQueueItem(item.clientId);
                            },
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

  Widget _buildMetricCol(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }

  String _formatActionName(String raw) {
    switch (raw) {
      case 'ATTENDANCE_PUNCH':
        return 'Attendance Punch (Offline)';
      case 'TASK_CREATE':
        return 'Create Task';
      case 'TASK_UPDATE':
        return 'Update Task';
      case 'DAILY_REPORT':
        return 'Daily Work Report';
      case 'MARKETING_VISIT':
        return 'Marketing Field Visit';
      case 'MARKETING_LEAD':
        return 'Marketing Lead';
      case 'OPERATIONS_CHECKLIST':
        return 'Operations Checklist';
      case 'IT_TICKET_NOTE':
        return 'IT Ticket Note';
      case 'HR_REQUEST':
        return 'HR Request';
      default:
        return raw.replaceAll('_', ' ');
    }
  }
}
