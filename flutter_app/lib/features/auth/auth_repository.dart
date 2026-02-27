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

  static const Map<String, ({String password, UserRole role})>
  _demoCredentials = {
    'admin': (password: 'adminpass', role: UserRole.admin),
    'user': (password: 'userpass', role: UserRole.user),
    'guest': (password: 'guestpass', role: UserRole.guest),
  };

  Future<AuthSession?> signIn({
    required String username,
    required String password,
  }) async {
    final credential = _demoCredentials[username.trim()];
    if (credential == null || credential.password != password) {
      return null;
    }

    return AuthSession(
      role: credential.role,
      accessToken: 'local-access-${username.trim()}',
      refreshToken: 'local-refresh-${username.trim()}',
    );
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
