import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Represents the status of the user authentication process.
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Represents the state containing authentication status, current user,
/// and any error messages.
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  const AuthState.initial()
      : status = AuthStatus.initial,
        user = null,
        errorMessage = null;

  const AuthState.loading()
      : status = AuthStatus.loading,
        user = null,
        errorMessage = null;

  const AuthState.authenticated(User user)
      : status = AuthStatus.authenticated,
        this.user = user,
        errorMessage = null;

  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null,
        errorMessage = null;

  const AuthState.error(String message)
      : status = AuthStatus.error,
        user = null,
        errorMessage = message;
}

/// Notifier class that manages authentication session, login, and registration states.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState.initial()) {
    checkSession();
  }

  /// Checks secure storage for an existing active user session.
  Future<void> checkSession() async {
    state = const AuthState.loading();
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Attempts to sign in the user.
  Future<bool> signIn(String username, String password) async {
    state = const AuthState.loading();
    try {
      final user = await _repository.login(username, password);
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  /// Attempts to register a new user with a specified role (defaults to 'admin').
  Future<bool> signUp(String username, String password, {String role = 'admin'}) async {
    state = const AuthState.loading();
    try {
      final user = await _repository.register(username, password, role);
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  /// Logs out the user and clears all secure session storage.
  Future<void> signOut() async {
    state = const AuthState.loading();
    await _repository.logout();
    state = const AuthState.unauthenticated();
  }

  /// Resets the user's password.
  Future<bool> resetPassword(String username, String newPassword) async {
    state = const AuthState.loading();
    try {
      await _repository.resetPassword(username, newPassword);
      state = const AuthState.unauthenticated();
      return true;
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

/// Provider of the [AuthNotifier] state.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(locator<AuthRepository>());
});
