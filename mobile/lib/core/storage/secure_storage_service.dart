import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static const _keyAccessToken = 'pcrm_access_token';
  static const _keyRefreshToken = 'pcrm_refresh_token';
  static const _keyUserData = 'pcrm_user_data';
  static const _keyDeviceId = 'pcrm_device_id';
  static const _keyServerBaseUrl = 'pcrm_server_base_url';

  final Map<String, String> _memoryStore = {};
  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ==========================================
  // TOKENS PERSISTENCE
  // ==========================================
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _memoryStore[_keyAccessToken] = accessToken;
    _memoryStore[_keyRefreshToken] = refreshToken;

    try {
      final prefs = await _getPrefs();
      await prefs.setString(_keyAccessToken, accessToken);
      await prefs.setString(_keyRefreshToken, refreshToken);
    } catch (_) {}

    if (!kIsWeb) {
      try {
        await _secureStorage.write(key: _keyAccessToken, value: accessToken).timeout(const Duration(milliseconds: 600));
        await _secureStorage.write(key: _keyRefreshToken, value: refreshToken).timeout(const Duration(milliseconds: 600));
      } catch (_) {}
    }
  }

  Future<String?> getAccessToken() async {
    if (_memoryStore.containsKey(_keyAccessToken) && _memoryStore[_keyAccessToken]!.isNotEmpty) {
      return _memoryStore[_keyAccessToken];
    }

    try {
      final prefs = await _getPrefs();
      final val = prefs.getString(_keyAccessToken);
      if (val != null && val.isNotEmpty) {
        _memoryStore[_keyAccessToken] = val;
        return val;
      }
    } catch (_) {}

    if (!kIsWeb) {
      try {
        final val = await _secureStorage.read(key: _keyAccessToken).timeout(const Duration(milliseconds: 600));
        if (val != null && val.isNotEmpty) {
          _memoryStore[_keyAccessToken] = val;
          return val;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<String?> getRefreshToken() async {
    if (_memoryStore.containsKey(_keyRefreshToken) && _memoryStore[_keyRefreshToken]!.isNotEmpty) {
      return _memoryStore[_keyRefreshToken];
    }

    try {
      final prefs = await _getPrefs();
      final val = prefs.getString(_keyRefreshToken);
      if (val != null && val.isNotEmpty) {
        _memoryStore[_keyRefreshToken] = val;
        return val;
      }
    } catch (_) {}

    if (!kIsWeb) {
      try {
        final val = await _secureStorage.read(key: _keyRefreshToken).timeout(const Duration(milliseconds: 600));
        if (val != null && val.isNotEmpty) {
          _memoryStore[_keyRefreshToken] = val;
          return val;
        }
      } catch (_) {}
    }
    return null;
  }

  // ==========================================
  // USER PROFILE DATA
  // ==========================================
  Future<void> saveUserData(String jsonString) async {
    _memoryStore[_keyUserData] = jsonString;

    try {
      final prefs = await _getPrefs();
      await prefs.setString(_keyUserData, jsonString);
    } catch (_) {}

    if (!kIsWeb) {
      try {
        await _secureStorage.write(key: _keyUserData, value: jsonString).timeout(const Duration(milliseconds: 600));
      } catch (_) {}
    }
  }

  Future<String?> getUserData() async {
    if (_memoryStore.containsKey(_keyUserData) && _memoryStore[_keyUserData]!.isNotEmpty) {
      return _memoryStore[_keyUserData];
    }

    try {
      final prefs = await _getPrefs();
      final val = prefs.getString(_keyUserData);
      if (val != null && val.isNotEmpty) {
        _memoryStore[_keyUserData] = val;
        return val;
      }
    } catch (_) {}

    if (!kIsWeb) {
      try {
        final val = await _secureStorage.read(key: _keyUserData).timeout(const Duration(milliseconds: 600));
        if (val != null && val.isNotEmpty) {
          _memoryStore[_keyUserData] = val;
          return val;
        }
      } catch (_) {}
    }
    return null;
  }

  // ==========================================
  // DEVICE ID & SETTINGS
  // ==========================================
  Future<void> saveDeviceId(String id) async {
    _memoryStore[_keyDeviceId] = id;
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_keyDeviceId, id);
    } catch (_) {}

    if (!kIsWeb) {
      try {
        await _secureStorage.write(key: _keyDeviceId, value: id).timeout(const Duration(milliseconds: 600));
      } catch (_) {}
    }
  }

  Future<String?> getDeviceId() async {
    if (_memoryStore.containsKey(_keyDeviceId)) {
      return _memoryStore[_keyDeviceId];
    }

    try {
      final prefs = await _getPrefs();
      final val = prefs.getString(_keyDeviceId);
      if (val != null && val.isNotEmpty) {
        _memoryStore[_keyDeviceId] = val;
        return val;
      }
    } catch (_) {}

    if (!kIsWeb) {
      try {
        final val = await _secureStorage.read(key: _keyDeviceId).timeout(const Duration(milliseconds: 600));
        if (val != null && val.isNotEmpty) {
          _memoryStore[_keyDeviceId] = val;
          return val;
        }
      } catch (_) {}
    }
    return 'web-client-device';
  }

  Future<void> saveServerBaseUrl(String url) async {
    _memoryStore[_keyServerBaseUrl] = url;
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_keyServerBaseUrl, url);
    } catch (_) {}

    if (!kIsWeb) {
      try {
        await _secureStorage.write(key: _keyServerBaseUrl, value: url).timeout(const Duration(milliseconds: 600));
      } catch (_) {}
    }
  }

  Future<String?> getServerBaseUrl() async {
    if (_memoryStore.containsKey(_keyServerBaseUrl)) {
      return _memoryStore[_keyServerBaseUrl];
    }

    try {
      final prefs = await _getPrefs();
      final val = prefs.getString(_keyServerBaseUrl);
      if (val != null && val.isNotEmpty) {
        _memoryStore[_keyServerBaseUrl] = val;
        return val;
      }
    } catch (_) {}

    if (!kIsWeb) {
      try {
        final val = await _secureStorage.read(key: _keyServerBaseUrl).timeout(const Duration(milliseconds: 600));
        if (val != null && val.isNotEmpty) {
          _memoryStore[_keyServerBaseUrl] = val;
          return val;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> clearAll() async {
    _memoryStore.clear();

    try {
      final prefs = await _getPrefs();
      await prefs.remove(_keyAccessToken);
      await prefs.remove(_keyRefreshToken);
      await prefs.remove(_keyUserData);
    } catch (_) {}

    if (!kIsWeb) {
      try {
        await _secureStorage.delete(key: _keyAccessToken).timeout(const Duration(milliseconds: 600));
        await _secureStorage.delete(key: _keyRefreshToken).timeout(const Duration(milliseconds: 600));
        await _secureStorage.delete(key: _keyUserData).timeout(const Duration(milliseconds: 600));
      } catch (_) {}
    }
  }
}
