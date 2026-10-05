import 'package:flutter/material.dart';
import '../core/sync/offline_sync_engine.dart';
import '../screens/sync/sync_center_screen.dart';

class ConnectivityStatusBanner extends StatefulWidget {
  final bool showWhenOnline;
  const ConnectivityStatusBanner({super.key, this.showWhenOnline = false});

  @override
  State<ConnectivityStatusBanner> createState() => _ConnectivityStatusBannerState();
}

class _ConnectivityStatusBannerState extends State<ConnectivityStatusBanner> {
  final OfflineSyncEngine _syncEngine = OfflineSyncEngine();

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

  void _openSyncCenter() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SyncCenterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _syncEngine.networkState;
    final pending = _syncEngine.pendingCount;
    final conflicts = _syncEngine.conflictCount + _syncEngine.failedCount;

    if (state == SyncNetworkState.online && !widget.showWhenOnline && pending == 0 && conflicts == 0) {
      return const SizedBox.shrink();
    }

    Color bgColor = Colors.green.shade700;
    Color fgColor = Colors.white;
    IconData icon = Icons.cloud_done;
    String message = "🟢 Connected & Synced";

    if (state == SyncNetworkState.syncing) {
      bgColor = Colors.blue.shade700;
      icon = Icons.sync;
      message = "🔵 Syncing $pending offline changes...";
    } else if (state == SyncNetworkState.offline) {
      bgColor = Colors.amber.shade900;
      icon = Icons.cloud_off;
      message = pending > 0
          ? "🟠 Offline — $pending changes queued for auto-sync"
          : "🟠 Offline Mode — Showing cached records";
    } else if (state == SyncNetworkState.syncIssue || conflicts > 0) {
      bgColor = Colors.red.shade800;
      icon = Icons.sync_problem;
      message = "🔴 Sync Alert — $conflicts items require attention";
    }

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            if (state == SyncNetworkState.syncing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else
              Icon(icon, size: 18, color: fgColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _openSyncCenter,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sync Center',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
