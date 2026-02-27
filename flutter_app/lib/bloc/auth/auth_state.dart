import 'package:equatable/equatable.dart';
import 'package:outgoing_notifications/enums/user_role.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.initial, this.role, this.message});

  final AuthStatus status;
  final UserRole? role;
  final String? message;

  AuthState copyWith({AuthStatus? status, UserRole? role, String? message}) {
    return AuthState(
      status: status ?? this.status,
      role: role ?? this.role,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, role, message];
}
