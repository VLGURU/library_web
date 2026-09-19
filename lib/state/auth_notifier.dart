import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth_api.dart';
import '../models/app_user.dart';
import '../models/role.dart';

class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kUserJson = 'auth_user_json';
  static const _kLoginAt = 'auth_login_at_ms';

  final SharedPreferences _prefs;
  final AuthApi _api;

  AuthNotifier(this._prefs, this._api);

  AppUser? _user;
  String? _accessToken;
  String? _refreshToken;

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  bool get isAuthenticated => _accessToken != null;

  // ВНИМАНИЕ: это клиентская проверка — удобство интерфейса, не защита.
  bool has(Role role) => _user != null && _user!.role.level >= role.level;

  Future<void> restore() async {
    final access = _prefs.getString(_kAccess);
    final refresh = _prefs.getString(_kRefresh);
    final userJson = _prefs.getString(_kUserJson);

    if (access == null) return;

    _accessToken = access;
    _refreshToken = refresh;

    if (userJson != null) {
      try {
        _user = AppUser.fromJson((jsonDecode(userJson) as Map).cast<String, dynamic>());
      } catch (_) {
        _user = null;
      }
    }

    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final result = await _api.login(username, password);

    _accessToken = result.accessToken;
    _refreshToken = result.refreshToken;
    _user = result.user;

    await _prefs.setString(_kAccess, result.accessToken);
    await _prefs.setString(_kRefresh, result.refreshToken);
    await _prefs.setString(_kUserJson, jsonEncode(result.user.toJson()));
    await _prefs.setInt(_kLoginAt, DateTime.now().millisecondsSinceEpoch);

    notifyListeners();
  }

  Future<void> register({
    required String username,
    required String password,
    required String fullName,
  }) async {
    final result = await _api.register(username: username, password: password, fullName: fullName);

    _accessToken = result.accessToken;
    _refreshToken = result.refreshToken;
    _user = result.user;

    await _prefs.setString(_kAccess, result.accessToken);
    await _prefs.setString(_kRefresh, result.refreshToken);
    await _prefs.setString(_kUserJson, jsonEncode(result.user.toJson()));
    await _prefs.setInt(_kLoginAt, DateTime.now().millisecondsSinceEpoch);

    notifyListeners();
  }

  Future<void> refreshTokens() async {
    final refresh = _refreshToken ?? _prefs.getString(_kRefresh);
    if (refresh == null) throw Exception('No refresh token');

    final result = await _api.refresh(refresh);

    _accessToken = result.accessToken;
    _refreshToken = result.refreshToken;
    _user = result.user;

    await _prefs.setString(_kAccess, result.accessToken);
    await _prefs.setString(_kRefresh, result.refreshToken);
    await _prefs.setString(_kUserJson, jsonEncode(result.user.toJson()));

    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _accessToken = null;
    _refreshToken = null;

    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kUserJson);
    await _prefs.remove(_kLoginAt);

    notifyListeners();
  }
}