import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../domain/repositories/settings_repository.dart';

/// Notifier class that manages loading and saving specific settings keys.
class SettingsNotifier extends StateNotifier<Map<String, String>> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super({});

  /// Loads settings keys from database.
  Future<void> loadSettings() async {
    final prefix = await _repository.getSetting('receipt_prefix', defaultValue: 'SRM-2026');
    final shopName = await _repository.getSetting('shop_name', defaultValue: 'Savile Row Master');
    final address = await _repository.getSetting('shop_address', defaultValue: 'London, UK');

    state = {
      'receipt_prefix': prefix,
      'shop_name': shopName,
      'shop_address': address,
    };
  }

  /// Saves a setting value.
  Future<void> saveSetting(String key, String value) async {
    await _repository.saveSetting(key, value);
    state = {...state, key: value};
  }
}

/// Provider of the [SettingsNotifier] state.
final settingsProvider = StateNotifierProvider<SettingsNotifier, Map<String, String>>((ref) {
  final notifier = SettingsNotifier(locator<SettingsRepository>());
  notifier.loadSettings();
  return notifier;
});
