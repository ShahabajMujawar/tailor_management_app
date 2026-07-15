/// Repository interface for managing application-wide settings.
abstract class SettingsRepository {
  /// Saves or updates a setting key-value pair in SQLite.
  Future<void> saveSetting(String key, String value);

  /// Retrieves a setting value by key. Returns defaultVal if not found.
  Future<String> getSetting(String key, {String defaultValue = ''});
}
