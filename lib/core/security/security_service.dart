import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service responsible for managing cryptographic operations,
/// password hashing, and secure storage of session data.
class SecurityService {
  final FlutterSecureStorage _secureStorage;

  SecurityService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _sessionKey = 'auth_session_username';

  /// Hashes a password using SHA-256 with a pre-defined static salt.
  String hashPassword(String password) {
    const String salt = "SavileRowMasterTailorSalt_2026";
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Saves the active username in secure storage to establish a session.
  Future<void> saveSession(String username) async {
    await _secureStorage.write(key: _sessionKey, value: username);
  }

  /// Retrieves the active session username, if it exists.
  Future<String?> getSession() async {
    return await _secureStorage.read(key: _sessionKey);
  }

  /// Clears the active session from secure storage.
  Future<void> clearSession() async {
    await _secureStorage.delete(key: _sessionKey);
  }

  /// Checks if an active session exists in secure storage.
  Future<bool> hasSession() async {
    final session = await getSession();
    return session != null && session.isNotEmpty;
  }
}
