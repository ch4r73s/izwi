import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:outgoing_notifications/config/app_constants.dart';
import 'package:outgoing_notifications/config/navigation_key.dart';
import 'package:outgoing_notifications/config/routes.dart';
import 'package:outgoing_notifications/services/storage/secure_storage_service.dart';

class ApiClient {
  final SecureStorageService _storage;

  ApiClient(this._storage);

  Future<http.Response> get(String path) =>
      _withRefresh(() async => _rawGet(path, await _storage.readAccessToken()));

  Future<http.Response> post(String path, Map<String, dynamic> body) =>
      _withRefresh(
        () async => _rawPost(path, await _storage.readAccessToken(), body),
      );

  Future<http.Response> put(String path, Map<String, dynamic> body) =>
      _withRefresh(
        () async => _rawPut(path, await _storage.readAccessToken(), body),
      );

  Future<http.Response> delete(String path) =>
      _withRefresh(
        () async => _rawDelete(path, await _storage.readAccessToken()),
      );

  // ── internals ──────────────────────────────────────────────────────────────

  Future<http.Response> _withRefresh(
    Future<http.Response> Function() call,
  ) async {
    final response = await call();
    if (response.statusCode != 401) return response;

    final refreshed = await _tryRefresh();
    if (refreshed) return call();

    // Refresh failed — clear session and send user back to login.
    await _storage.clearSession();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      Routes.authentication,
      (_) => false,
    );
    return response; // return the 401 so callers don't crash
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.refreshPath}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final role = await _storage.readRole() ?? '';
      await _storage.saveSession(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        role: role,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<http.Response> _rawGet(String path, String? token) => http.get(
    Uri.parse('${AppConstants.apiBaseUrl}$path'),
    headers: {'Authorization': 'Bearer ${token ?? ''}'},
  );

  Future<http.Response> _rawPost(
    String path,
    String? token,
    Map<String, dynamic> body,
  ) => http.post(
    Uri.parse('${AppConstants.apiBaseUrl}$path'),
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer ${token ?? ''}',
    },
    body: jsonEncode(body),
  );

  Future<http.Response> _rawPut(
    String path,
    String? token,
    Map<String, dynamic> body,
  ) => http.put(
    Uri.parse('${AppConstants.apiBaseUrl}$path'),
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer ${token ?? ''}',
    },
    body: jsonEncode(body),
  );

  Future<http.Response> _rawDelete(String path, String? token) => http.delete(
    Uri.parse('${AppConstants.apiBaseUrl}$path'),
    headers: {'Authorization': 'Bearer ${token ?? ''}'},
  );
}
