import '../entities/user.dart';

/// Repository interface for managing authentication operations.
abstract class AuthRepository {
  /// Attempts to log in a user. Returns the authenticated [User] if successful,
  /// otherwise throws an exception with user-friendly text.
  Future<User> login(String username, String password);

  /// Registers a new user. Returns the registered [User] if successful.
  Future<User> register(String username, String password, String role);

  /// Retrieves the currently logged in user, if any.
  Future<User?> getCurrentUser();

  /// Logs out the current user and clears session tokens.
  Future<void> logout();

  /// Resets the password for a user.
  Future<void> resetPassword(String username, String newPassword);
}
