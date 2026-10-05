import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineStorageService {
  static final OfflineStorageService _instance = OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ==========================================
  // CACHE ENTITIES FOR OFFLINE BROWSING
  // ==========================================
  Future<void> cacheData(String key, dynamic data) async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = jsonEncode(data);
      await prefs.setString('cache_$key', jsonStr);
      await prefs.setString('cache_time_$key', DateTime.now().toIso8601String());
    } catch (_) {}
  }

  Future<dynamic> getCachedData(String key) async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString('cache_$key');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return jsonDecode(jsonStr);
      }
    } catch (_) {}
    return null;
  }

  Future<DateTime?> getLastCachedTime(String key) async {
    try {
      final prefs = await _getPrefs();
      final timeStr = prefs.getString('cache_time_$key');
      if (timeStr != null && timeStr.isNotEmpty) {
        return DateTime.tryParse(timeStr);
      }
    } catch (_) {}
    return null;
  }

  Future<void> clearAllCache() async {
    try {
      final prefs = await _getPrefs();
      final keys = prefs.getKeys().where((k) => k.startsWith('cache_')).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }
}
