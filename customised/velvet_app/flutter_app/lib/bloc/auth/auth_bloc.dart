import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:outgoing_notifications/bloc/auth/auth_event.dart';
import 'package:outgoing_notifications/bloc/auth/auth_state.dart';
import 'package:outgoing_notifications/features/auth/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authRepository) : super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _authRepository;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final persistedRole = await _authRepository.getPersistedRole();
    if (persistedRole == null) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, role: null));
      return;
    }

    emit(state.copyWith(status: AuthStatus.authenticated, role: persistedRole));
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, message: null));

    try {
      final session = await _authRepository.signIn(
        username: event.username,
        password: event.password,
      );

      if (session == null) {
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            message: 'Invalid username or password',
            role: null,
          ),
        );
        return;
      }

      await _authRepository.persistSession(session);
      emit(
        state.copyWith(status: AuthStatus.authenticated, role: session.role),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: e.toString().replaceFirst('Exception: ', ''),
          role: null,
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
    emit(state.copyWith(status: AuthStatus.unauthenticated, role: null));
  }
}
