import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../storage/secure_storage_service.dart';

enum SyncNetworkState {
  online,
  offline,
  syncing,
  syncIssue
}

class SyncQueueItem {
  final String clientId;
  final String actionType;
  final DateTime clientTimestamp;
  final Map<String, dynamic> payload;
  String status; // 'PENDING', 'SYNCING', 'SYNCED', 'CONFLICT', 'FAILED'
  String? serverEntityId;
  String? errorMessage;
  Map<String, dynamic>? conflictDetails;

  SyncQueueItem({
    required this.clientId,
    required this.actionType,
    required this.clientTimestamp,
    required this.payload,
    this.status = 'PENDING',
    this.serverEntityId,
    this.errorMessage,
    this.conflictDetails,
  });

  Map<String, dynamic> toJson() => {
    'client_id': clientId,
    'action_type': actionType,
    'client_timestamp': clientTimestamp.toIso8601String(),
    'payload': payload,
    'status': status,
    'server_entity_id': serverEntityId,
    'error_message': errorMessage,
    'conflict_details': conflictDetails,
  };

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => SyncQueueItem(
    clientId: json['client_id'] ?? '',
    actionType: json['action_type'] ?? 'GENERIC_MUTATION',
    clientTimestamp: DateTime.tryParse(json['client_timestamp'] ?? '') ?? DateTime.now(),
    payload: json['payload'] is Map ? Map<String, dynamic>.from(json['payload']) : {},
    status: json['status'] ?? 'PENDING',
    serverEntityId: json['server_entity_id'],
    errorMessage: json['error_message'],
    conflictDetails: json['conflict_details'] is Map ? Map<String, dynamic>.from(json['conflict_details']) : null,
  );
}

class OfflineSyncEngine extends ChangeNotifier {
  static final OfflineSyncEngine _instance = OfflineSyncEngine._internal();
  factory OfflineSyncEngine() => _instance;

  final ApiClient _api = ApiClient();
  final SecureStorageService _storage = SecureStorageService();

  SyncNetworkState _networkState = SyncNetworkState.online;
  SyncNetworkState get networkState => _networkState;

  List<SyncQueueItem> _queue = [];
  List<SyncQueueItem> get queue => List.unmodifiable(_queue);

  int get pendingCount => _queue.where((item) => item.status == 'PENDING' || item.status == 'SYNCING').length;
  int get syncedCount => _queue.where((item) => item.status == 'SYNCED').length;
  int get conflictCount => _queue.where((item) => item.status == 'CONFLICT').length;
  int get failedCount => _queue.where((item) => item.status == 'FAILED').length;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  Timer? _autoSyncTimer;
  bool _isSyncing = false;

  OfflineSyncEngine._internal() {
    _loadQueueFromStorage();
    _startPeriodicSync();
  }

  Future<void> _loadQueueFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString('pcrm_offline_sync_queue');
      if (queueJson != null && queueJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(queueJson);
        _queue = list.map((item) => SyncQueueItem.fromJson(item as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveQueueToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _queue.map((item) => item.toJson()).toList();
      await prefs.setString('pcrm_offline_sync_queue', jsonEncode(list));
    } catch (_) {}
  }

  void _startPeriodicSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (pendingCount > 0 && !_isSyncing) {
        syncNow();
      } else {
        _pingHeartbeat();
      }
    });
  }

  // ==========================================
  // ENQUEUE ACTIONS OFFLINE
  // ==========================================
  Future<String> enqueueAction({
    required String actionType,
    required Map<String, dynamic> payload,
    String? clientId,
  }) async {
    final id = clientId ?? 'client-${DateTime.now().millisecondsSinceEpoch}-${_queue.length + 1}';
    final item = SyncQueueItem(
      clientId: id,
      actionType: actionType,
      clientTimestamp: DateTime.now(),
      payload: payload,
      status: 'PENDING',
    );

    _queue.insert(0, item);
    await _saveQueueToStorage();
    notifyListeners();

    // Trigger sync immediately if online
    if (!_isSyncing) {
      syncNow();
    }
    return id;
  }

  // ==========================================
  // RUN BATCH SYNCHRONIZATION
  // ==========================================
  Future<bool> syncNow() async {
    if (_isSyncing) return false;
    _isSyncing = true;
    _networkState = SyncNetworkState.syncing;
    notifyListeners();

    try {
      final deviceId = await _storage.getDeviceId() ?? 'device-offline-01';
      final pendingItems = _queue.where((i) => i.status == 'PENDING' || i.status == 'FAILED').toList();

      if (pendingItems.isEmpty) {
        _networkState = conflictCount > 0 ? SyncNetworkState.syncIssue : SyncNetworkState.online;
        _isSyncing = false;
        notifyListeners();
        return true;
      }

      // Mark items as syncing
      for (var item in pendingItems) {
        item.status = 'SYNCING';
      }
      notifyListeners();

      final response = await _api.dio.post('/sync/batch/', data: {
        'device_id': deviceId,
        'device_name': kIsWeb ? 'Web Browser Client' : 'Mobile Application Device',
        'items': pendingItems.map((item) => {
          'client_id': item.clientId,
          'action_type': item.actionType,
          'client_timestamp': item.clientTimestamp.toIso8601String(),
          'payload': item.payload,
        }).toList(),
      });

      if (response.statusCode == 200 && response.data != null) {
        final results = (response.data['results'] as List<dynamic>?) ?? [];
        for (var res in results) {
          final cId = res['client_id'];
          final status = res['status'] ?? 'SYNCED';
          final sEntityId = res['server_entity_id'];
          final errorMsg = res['error'];

          final queueItem = _queue.firstWhere((q) => q.clientId == cId, orElse: () => SyncQueueItem(clientId: '', actionType: '', clientTimestamp: DateTime.now(), payload: {}));
          if (queueItem.clientId.isNotEmpty) {
            queueItem.status = status;
            queueItem.serverEntityId = sEntityId;
            queueItem.errorMessage = errorMsg;
          }
        }

        _lastSyncTime = DateTime.now();
        await _saveQueueToStorage();

        if (conflictCount > 0 || failedCount > 0) {
          _networkState = SyncNetworkState.syncIssue;
        } else {
          _networkState = SyncNetworkState.online;
        }
        _isSyncing = false;
        notifyListeners();
        return true;
      } else {
        _setAllPendingToFailed(pendingItems, 'Server response ${response.statusCode}');
      }
    } catch (e) {
      final pendingItems = _queue.where((i) => i.status == 'SYNCING').toList();
      _setAllPendingToFailed(pendingItems, e.toString());
      _networkState = SyncNetworkState.offline;
    }

    _isSyncing = false;
    notifyListeners();
    return false;
  }

  void _setAllPendingToFailed(List<SyncQueueItem> items, String reason) {
    for (var item in items) {
      item.status = 'PENDING';
      item.errorMessage = reason;
    }
    _saveQueueToStorage();
  }

  Future<void> _pingHeartbeat() async {
    try {
      final deviceId = await _storage.getDeviceId() ?? 'device-offline-01';
      final res = await _api.dio.post('/sync/heartbeat/', data: {
        'device_id': deviceId,
        'pending_count': pendingCount,
      });
      if (res.statusCode == 200) {
        if (_networkState == SyncNetworkState.offline) {
          _networkState = SyncNetworkState.online;
          notifyListeners();
        }
      }
    } catch (_) {
      if (_networkState != SyncNetworkState.offline) {
        _networkState = SyncNetworkState.offline;
        notifyListeners();
      }
    }
  }

  void removeQueueItem(String clientId) {
    _queue.removeWhere((i) => i.clientId == clientId);
    _saveQueueToStorage();
    notifyListeners();
  }

  void clearSyncedItems() {
    _queue.removeWhere((i) => i.status == 'SYNCED');
    _saveQueueToStorage();
    notifyListeners();
  }

  void resolveConflict(String clientId, bool keepServer) {
    final item = _queue.firstWhere((i) => i.clientId == clientId, orElse: () => SyncQueueItem(clientId: '', actionType: '', clientTimestamp: DateTime.now(), payload: {}));
    if (item.clientId.isNotEmpty) {
      if (keepServer) {
        _queue.remove(item);
      } else {
        item.status = 'PENDING';
      }
      _saveQueueToStorage();
      notifyListeners();
      if (!keepServer) {
        syncNow();
      }
    }
  }
}
