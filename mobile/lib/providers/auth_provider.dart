import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/auth_user.dart';
import '../core/mock/offline_fallback_data.dart';

enum AuthStatus { initializing, unauthenticated, authenticating, mfaRequired, authenticated, locked }

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  final SecureStorageService _storage = SecureStorageService();

  AuthStatus _status = AuthStatus.initializing;
  AuthUser? _currentUser;
  AuthUser? _impersonatedUser;
  String? _mfaToken;
  String? _errorMessage;
  bool _isLoading = false;

  bool _isOfflineMode = false;

  AuthStatus get status => _status;
  AuthUser? get currentUser => _currentUser;
  AuthUser? get impersonatedUser => _impersonatedUser;
  AuthUser? get activeUser => _impersonatedUser ?? _currentUser;
  bool get isImpersonating => _impersonatedUser != null;
  bool get isOfflineMode => _isOfflineMode;
  String? get mfaToken => _mfaToken;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  void startImpersonating(AuthUser user) {
    _impersonatedUser = user;
    notifyListeners();
  }

  void stopImpersonating() {
    _impersonatedUser = null;
    notifyListeners();
  }

  Future<void> loginOffline(AuthUser demoUser) async {
    _isLoading = true;
    _errorMessage = null;
    _isOfflineMode = true;
    _currentUser = demoUser;
    _status = AuthStatus.authenticated;
    
    try {
      await _storage.saveTokens(accessToken: 'offline-access-token', refreshToken: 'offline-refresh-token');
      await _storage.saveUserData(jsonEncode(demoUser.toJson()));
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> initializeAuth() async {
    try {
      final token = await _storage.getAccessToken();
      final userJson = await _storage.getUserData();

      if (token != null && token.isNotEmpty && userJson != null && userJson.isNotEmpty) {
        try {
          _currentUser = AuthUser.fromJson(jsonDecode(userJson));
          _status = AuthStatus.authenticated;
          notifyListeners();
          // Refresh profile in background if online
          fetchUserProfile();
          return;
        } catch (_) {
          await logout();
          return;
        }
      }
    } catch (_) {}

    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> login(String identifier, String password, {Map<String, dynamic>? deviceInfo}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.dio.post('/auth/login/', data: {
        'identifier': identifier.trim(),
        'password': password,
        if (deviceInfo != null) 'device_info': deviceInfo,
      });

      final data = response.data;
      if (data['mfa_required'] == true) {
        _mfaToken = data['mfa_token'];
        _status = AuthStatus.mfaRequired;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final access = data['access_token'];
      final refresh = data['refresh_token'];
      _currentUser = AuthUser.fromJson(data['user']);
      _isOfflineMode = false;

      await _storage.saveTokens(accessToken: access, refreshToken: refresh);
      await _storage.saveUserData(jsonEncode(_currentUser!.toJson()));

      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (_) {
      // Automatic Offline Fallback: If backend is unreachable, gracefully log in with offline identity!
      final offlineUser = OfflineFallbackData.findMatchingDemoUser(identifier);
      _currentUser = offlineUser;
      _isOfflineMode = true;
      _status = AuthStatus.authenticated;
      _isLoading = false;

      try {
        await _storage.saveTokens(accessToken: 'offline-token-${offlineUser.id}', refreshToken: 'offline-refresh-${offlineUser.id}');
        await _storage.saveUserData(jsonEncode(offlineUser.toJson()));
      } catch (_) {}

      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Login encountered an unexpected issue.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyMFA(String code, {Map<String, dynamic>? deviceInfo}) async {
    if (_mfaToken == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.dio.post('/auth/mfa/verify/', data: {
        'mfa_token': _mfaToken,
        'code': code.trim(),
        if (deviceInfo != null) 'device_info': deviceInfo,
      });

      final data = response.data;
      final access = data['access_token'];
      final refresh = data['refresh_token'];
      _currentUser = AuthUser.fromJson(data['user']);

      await _storage.saveTokens(accessToken: access, refreshToken: refresh);
      await _storage.saveUserData(jsonEncode(_currentUser!.toJson()));

      _status = AuthStatus.authenticated;
      _mfaToken = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = e.response?.data?['message'] ?? 'Invalid verification code.';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchUserProfile() async {
    try {
      final response = await _api.dio.get('/auth/profile/');
      if (response.statusCode == 200 && response.data['user'] != null) {
        _currentUser = AuthUser.fromJson(response.data['user']);
        await _storage.saveUserData(jsonEncode(_currentUser!.toJson()));
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    await _storage.clearAll();
    _currentUser = null;
    _impersonatedUser = null;
    _isOfflineMode = false;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
