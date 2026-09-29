import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/device_settings.dart';
import '../../infrastructure/repositories/settings_repository.dart';
import 'device_providers.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return LocalSettingsRepository();
});

class SettingsNotifier extends StateNotifier<AsyncValue<DeviceSettings>> {
  final Ref ref;
  final SettingsRepository _repository;

  SettingsNotifier(this.ref, this._repository)
      : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final settings = await _repository.loadSettings();
      if (mounted) {
        state = AsyncValue.data(settings);
      }
      final deviceService = ref.read(deviceServiceProvider);
      await deviceService.updateSettings(settings);
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<bool> saveSettings(DeviceSettings newSettings) async {
    try {
      final success = await _repository.saveSettings(newSettings);
      if (success) {
        if (mounted) {
          state = AsyncValue.data(newSettings);
        }
        final deviceService = ref.read(deviceServiceProvider);
        await deviceService.updateSettings(newSettings);
      }
      return success;
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
      return false;
    }
  }

  Future<void> resetToDefaults() async {
    const defaultSettings = DeviceSettings();
    await saveSettings(defaultSettings);
  }
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<DeviceSettings>>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(ref, repo);
});
