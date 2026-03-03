import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:outgoing_notifications/config/app_constants.dart';
import 'package:outgoing_notifications/enums/user_role.dart';
import 'package:outgoing_notifications/services/storage/secure_storage_service.dart';

class AuthSession {
  final UserRole role;
  final String accessToken;
  final String refreshToken;

  const AuthSession({
    required this.role,
    required this.accessToken,
    required this.refreshToken,
  });
}

class AuthRepository {
  AuthRepository(this._secureStorageService);

  final SecureStorageService _secureStorageService;

  Future<AuthSession?> signIn({
    required String username,
    required String password,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}${AppConstants.loginPath}',
      );
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'identifier': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      final roleString =
          (data['user'] as Map<String, dynamic>)['role'] as String;

      return AuthSession(
        role: _roleFromApiValue(roleString),
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } on TimeoutException {
      throw Exception('Request timed out. Check your connection.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unable to reach the server. Check your connection.');
    }
  }

  Future<void> persistSession(AuthSession session) async {
    await _secureStorageService.saveSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      role: _roleToStorageValue(session.role),
    );
  }

  Future<UserRole?> getPersistedRole() async {
    final hasSession = await _secureStorageService.hasActiveSession();
    if (!hasSession) {
      return null;
    }

    final rawRole = await _secureStorageService.readRole();
    return _roleFromStorageValue(rawRole);
  }

  Future<void> signOut() => _secureStorageService.clearSession();

  UserRole _roleFromApiValue(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'user':
        return UserRole.user;
      default:
        return UserRole.guest;
    }
  }

  String _roleToStorageValue(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.user:
        return 'user';
      case UserRole.guest:
        return 'guest';
    }
  }

  UserRole _roleFromStorageValue(String? rawRole) {
    switch (rawRole) {
      case 'admin':
      case 'UserRole.admin':
        return UserRole.admin;
      case 'user':
      case 'UserRole.user':
        return UserRole.user;
      default:
        return UserRole.guest;
    }
  }
}
