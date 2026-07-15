import '../../../../core/database/database_service.dart';
import '../../../../core/security/security_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementation of the [AuthRepository] interface using SQLite database
/// and [SecurityService] secure session storage.
class AuthRepositoryImpl implements AuthRepository {
  final DatabaseService _dbService;
  final SecurityService _securityService;

  AuthRepositoryImpl(this._dbService, this._securityService);

  @override
  Future<User> login(String username, String password) async {
    final db = await _dbService.database;
    final hashedPassword = _securityService.hashPassword(password);

    // Using parameterized queries to prevent SQL Injection
    final results = await db.rawQuery(
      'SELECT id, username, role FROM users WHERE username = ? AND password_hash = ? LIMIT 1',
      [username.trim(), hashedPassword],
    );

    if (results.isEmpty) {
      throw Exception('Invalid username or password.');
    }

    final row = results.first;
    final user = User(
      id: row['id'] as int,
      username: row['username'] as String,
      role: row['role'] as String,
    );

    // Store login session securely
    await _securityService.saveSession(user.username);
    return user;
  }

  @override
  Future<User> register(String username, String password, String role) async {
    final db = await _dbService.database;
    final cleanUsername = username.trim();

    if (cleanUsername.isEmpty || password.length < 8) {
      throw Exception('Username must not be empty and password must be at least 8 characters.');
    }

    // Check if user already exists
    final existing = await db.rawQuery(
      'SELECT id FROM users WHERE username = ? LIMIT 1',
      [cleanUsername],
    );

    if (existing.isNotEmpty) {
      throw Exception('Username already exists.');
    }

    final hashedPassword = _securityService.hashPassword(password);
    final now = DateTime.now().toIso8601String();

    final userId = await db.rawInsert(
      'INSERT INTO users (username, password_hash, role, created_at) VALUES (?, ?, ?, ?)',
      [cleanUsername, hashedPassword, role, now],
    );

    final user = User(
      id: userId,
      username: cleanUsername,
      role: role,
    );

    // Automatically establish session on registration
    await _securityService.saveSession(user.username);
    return user;
  }

  @override
  Future<User?> getCurrentUser() async {
    final username = await _securityService.getSession();
    if (username == null) return null;

    final db = await _dbService.database;
    final results = await db.rawQuery(
      'SELECT id, username, role FROM users WHERE username = ? LIMIT 1',
      [username],
    );

    if (results.isEmpty) {
      // Session is invalid/stale, clear it
      await _securityService.clearSession();
      return null;
    }

    final row = results.first;
    return User(
      id: row['id'] as int,
      username: row['username'] as String,
      role: row['role'] as String,
    );
  }

  @override
  Future<void> logout() async {
    await _securityService.clearSession();
  }

  @override
  Future<void> resetPassword(String username, String newPassword) async {
    final db = await _dbService.database;
    final cleanUsername = username.trim();

    if (newPassword.length < 8) {
      throw Exception('Password must be at least 8 characters.');
    }

    // Check if user exists
    final existing = await db.rawQuery(
      'SELECT id FROM users WHERE username = ? LIMIT 1',
      [cleanUsername],
    );

    if (existing.isEmpty) {
      throw Exception('Username not found.');
    }

    final hashedPassword = _securityService.hashPassword(newPassword);

    await db.rawUpdate(
      'UPDATE users SET password_hash = ? WHERE username = ?',
      [hashedPassword, cleanUsername],
    );
  }
}
