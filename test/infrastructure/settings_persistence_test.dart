import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synthera_prosthetic_hand/domain/models/device_settings.dart';
import 'package:synthera_prosthetic_hand/domain/models/operating_mode.dart';
import 'package:synthera_prosthetic_hand/infrastructure/repositories/settings_repository.dart';

void main() {
  group('Settings & Calibration Local Persistence Test Suite', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Loads default factory configuration when no stored data exists',
        () async {
      final repository = LocalSettingsRepository();
      final settings = await repository.loadSettings();

      expect(settings.deviceName, equals('DAKSH-01'));
      expect(settings.minAngle, equals(0.0));
      expect(settings.maxAngle, equals(63.0));
      expect(settings.emgThreshold, equals(120.0));
      expect(settings.batteryWarningThreshold, equals(20.0));
      expect(settings.defaultOperatingMode, equals(OperatingMode.auto));
    });

    test(
        'Persists and restores updated hardware settings and calibration limits',
        () async {
      final repository = LocalSettingsRepository();

      const customSettings = DeviceSettings(
        deviceName: 'SYNTHERA-TITAN',
        minAngle: 5.0,
        maxAngle: 58.0,
        emgThreshold: 145.0,
        batteryWarningThreshold: 18.0,
        defaultOperatingMode: OperatingMode.emg,
      );

      final saveSuccess = await repository.saveSettings(customSettings);
      expect(saveSuccess, isTrue);

      // Create new instance representing an app restart
      final restartRepository = LocalSettingsRepository();
      final loadedSettings = await restartRepository.loadSettings();

      expect(loadedSettings.deviceName, equals('SYNTHERA-TITAN'));
      expect(loadedSettings.minAngle, equals(5.0));
      expect(loadedSettings.maxAngle, equals(58.0));
      expect(loadedSettings.emgThreshold, equals(145.0));
      expect(loadedSettings.batteryWarningThreshold, equals(18.0));
      expect(loadedSettings.defaultOperatingMode, equals(OperatingMode.emg));
    });

    test('Rejects saving invalid settings configurations with ArgumentError',
        () async {
      final repository = LocalSettingsRepository();

      const invalidSettings = DeviceSettings(
        deviceName: '',
        minAngle: 50.0,
        maxAngle: 30.0,
      );

      expect(
        () => repository.saveSettings(invalidSettings),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Factory reset clears persistent storage and restores defaults',
        () async {
      final repository = LocalSettingsRepository();

      const customSettings = DeviceSettings(
        deviceName: 'CUSTOM-02',
        minAngle: 10.0,
        maxAngle: 50.0,
      );
      await repository.saveSettings(customSettings);

      final resetSuccess = await repository.resetSettings();
      expect(resetSuccess, isTrue);

      final postResetSettings = await repository.loadSettings();
      expect(postResetSettings.deviceName, equals('DAKSH-01'));
      expect(postResetSettings.minAngle, equals(0.0));
      expect(postResetSettings.maxAngle, equals(63.0));
    });
  });
}
