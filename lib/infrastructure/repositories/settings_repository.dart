import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/device_settings.dart';

abstract class SettingsRepository {
  Future<DeviceSettings> loadSettings();
  Future<bool> saveSettings(DeviceSettings settings);
  Future<bool> resetSettings();
}

class LocalSettingsRepository implements SettingsRepository {
  static const String _settingsKey = 'synthera_device_settings_v1';
  DeviceSettings _cachedSettings = const DeviceSettings();

  @override
  Future<DeviceSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_settingsKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _cachedSettings = DeviceSettings.fromJson(map);
      }
    } catch (_) {
      // Fallback to defaults on error / uninitialized storage
    }
    return _cachedSettings;
  }

  @override
  Future<bool> saveSettings(DeviceSettings settings) async {
    final validationError = DeviceSettings.validate(
      deviceName: settings.deviceName,
      minAngle: settings.minAngle,
      maxAngle: settings.maxAngle,
      emgThreshold: settings.emgThreshold,
      batteryWarningThreshold: settings.batteryWarningThreshold,
    );

    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    _cachedSettings = settings;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(settings.toJson());
      return await prefs.setString(_settingsKey, raw);
    } catch (_) {
      return true; // cached in-memory
    }
  }

  @override
  Future<bool> resetSettings() async {
    _cachedSettings = const DeviceSettings();
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_settingsKey);
    } catch (_) {
      return true;
    }
  }
}
