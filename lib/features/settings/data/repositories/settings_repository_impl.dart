import '../../../../core/database/database_service.dart';
import '../../domain/repositories/settings_repository.dart';

/// SQLite implementation of the [SettingsRepository] interface.
class SettingsRepositoryImpl implements SettingsRepository {
  final DatabaseService _dbService;

  SettingsRepositoryImpl(this._dbService);

  @override
  Future<void> saveSetting(String key, String value) async {
    final db = await _dbService.database;
    await db.rawInsert(
      'INSERT OR REPLACE INTO settings (setting_key, setting_value) VALUES (?, ?)',
      [key, value],
    );
  }

  @override
  Future<String> getSetting(String key, {String defaultValue = ''}) async {
    final db = await _dbService.database;
    final results = await db.rawQuery(
      'SELECT setting_value FROM settings WHERE setting_key = ? LIMIT 1',
      [key],
    );

    if (results.isEmpty) return defaultValue;
    return results.first['setting_value'] as String;
  }
}
