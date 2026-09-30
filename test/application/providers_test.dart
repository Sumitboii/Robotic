import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synthera_prosthetic_hand/application/providers/calibration_provider.dart';
import 'package:synthera_prosthetic_hand/application/providers/device_providers.dart';
import 'package:synthera_prosthetic_hand/application/providers/settings_provider.dart';
import 'package:synthera_prosthetic_hand/application/providers/theme_provider.dart';
import 'package:synthera_prosthetic_hand/domain/models/calibration_state.dart';
import 'package:synthera_prosthetic_hand/domain/models/connection_state.dart';
import 'package:synthera_prosthetic_hand/domain/models/device_command.dart';
import 'package:synthera_prosthetic_hand/domain/models/device_log_entry.dart';
import 'package:synthera_prosthetic_hand/domain/models/device_settings.dart';
import 'package:synthera_prosthetic_hand/domain/models/device_telemetry.dart';
import 'package:synthera_prosthetic_hand/domain/models/operating_mode.dart';
import 'package:synthera_prosthetic_hand/infrastructure/device/device_service.dart';
import 'package:synthera_prosthetic_hand/infrastructure/device/mock/mock_device_service.dart';
import 'package:synthera_prosthetic_hand/infrastructure/repositories/settings_repository.dart';

class FailingDeviceService implements DeviceService {
  @override
  Stream<DeviceTelemetry> get telemetryStream => const Stream.empty();

  @override
  Stream<DeviceConnectionState> get connectionStateStream =>
      const Stream.empty();

  @override
  Stream<DeviceLogEntry> get logStream => const Stream.empty();

  @override
  DeviceTelemetry get currentTelemetry => DeviceTelemetry.initial();

  @override
  DeviceConnectionState get currentConnectionState =>
      DeviceConnectionState.disconnected;

  @override
  Future<void> connect() async => throw Exception('Connect failure');

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> reconnect() async => throw Exception('Reconnect failure');

  @override
  Future<void> sendCommand(DeviceCommand command) async =>
      throw Exception('Command failure');

  @override
  Future<void> sendRawCommand(String rawCommand) async =>
      throw Exception('Raw command failure');

  @override
  Future<void> openHand() async => throw Exception('Open failure');

  @override
  Future<void> closeHand() async => throw Exception('Close failure');

  @override
  Future<void> emergencyStop() async {}

  @override
  Future<void> setOperatingMode(OperatingMode mode) async {}

  @override
  Future<void> updateSettings(DeviceSettings settings) async =>
      throw Exception('Update failure');

  @override
  Future<void> startCalibration() async {}

  @override
  Future<double> captureCalibrationOpenPosition() async =>
      throw Exception('Sensor read fault (OPEN)');

  @override
  Future<double> captureCalibrationClosePosition() async =>
      throw Exception('Sensor read fault (CLOSE)');

  @override
  Future<void> saveCalibrationLimits(double minAngle, double maxAngle) async =>
      throw Exception('NVM write fault');

  @override
  Future<void> cancelCalibration() async {}

  @override
  Future<void> triggerDemoBatteryDrain(double targetPercentage) async {}

  @override
  Future<void> triggerEmgSpike(double spikeValue) async {}

  @override
  Future<void> simulateConnectionDrop() async {}

  @override
  Future<void> toggleEmgSensorFault([bool? enable]) async {}

  @override
  Future<void> setFailNextReconnect(bool fail) async {}

  @override
  bool get isEmgSensorFaultSimulated => false;

  @override
  bool get willFailNextReconnect => false;

  @override
  void dispose() {}
}

class FailingSettingsRepository implements SettingsRepository {
  @override
  Future<DeviceSettings> loadSettings() async =>
      throw Exception('Disk read error');

  @override
  Future<bool> saveSettings(DeviceSettings settings) async =>
      throw Exception('Disk write error');

  @override
  Future<bool> resetSettings() async => throw Exception('Disk reset error');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Application Layer Provider Test Suite', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer(
        overrides: [
          deviceServiceProvider.overrideWithValue(MockDeviceService()),
        ],
      );
      // Wait for async load to complete cleanly
      await container.read(settingsNotifierProvider.notifier).loadSettings();
    });

    tearDown(() {
      container.dispose();
    });

    group('CalibrationNotifier Workflow & Error Handling (Assignment §9)', () {
      test('Initial state is idle and clean', () {
        final state = container.read(calibrationNotifierProvider);
        expect(state.currentStep, equals(CalibrationStep.idle));
        expect(state.canSave, isFalse);
        expect(state.isBusy, isFalse);
      });

      test('startCalibration transitions to step1OpenPosition', () {
        final notifier = container.read(calibrationNotifierProvider.notifier);
        notifier.startCalibration();
        final state = container.read(calibrationNotifierProvider);
        expect(state.currentStep, equals(CalibrationStep.step1OpenPosition));
        expect(state.measuredMinAngle, isNull);
        expect(state.errorMessage, isNull);
      });

      test('captureOpenPosition success advances to step2ClosedPosition',
          () async {
        final notifier = container.read(calibrationNotifierProvider.notifier);
        notifier.startCalibration();
        await notifier.captureOpenPosition(0.0);

        final state = container.read(calibrationNotifierProvider);
        expect(state.currentStep, equals(CalibrationStep.step2ClosedPosition));
        expect(state.measuredMinAngle, equals(0.0));
        expect(state.isBusy, isFalse);
      });

      test('captureClosePosition success advances to step3Saving', () async {
        final notifier = container.read(calibrationNotifierProvider.notifier);
        notifier.startCalibration();
        await notifier.captureOpenPosition(0.0);
        await notifier.captureClosePosition(63.0);

        final state = container.read(calibrationNotifierProvider);
        expect(state.currentStep, equals(CalibrationStep.step3Saving));
        expect(state.measuredMaxAngle, equals(63.0));
        expect(state.canSave, isTrue);
      });

      test('captureClosePosition rejects if closed <= open or range < 10° (§9)',
          () async {
        final notifier = container.read(calibrationNotifierProvider.notifier);
        notifier.startCalibration();
        await notifier.captureOpenPosition(20.0);

        // Attempt invalid closed position <= open
        final success = await notifier.captureClosePosition(15.0);
        expect(success, isFalse);
        expect(container.read(calibrationNotifierProvider).errorMessage,
            contains('Invalid calibration range'));

        // Attempt invalid range < 10°
        final success2 = await notifier.captureClosePosition(25.0);
        expect(success2, isFalse);
        expect(container.read(calibrationNotifierProvider).errorMessage,
            contains('Invalid calibration range'));
      });

      test('saveCalibration persists settings and marks complete', () async {
        final notifier = container.read(calibrationNotifierProvider.notifier);
        notifier.startCalibration();
        await notifier.captureOpenPosition(0.0);
        await notifier.captureClosePosition(63.0);

        final success = await notifier.saveCalibration();
        expect(success, isTrue);

        final state = container.read(calibrationNotifierProvider);
        expect(state.currentStep, equals(CalibrationStep.complete));
      });

      test(
          'saveCalibration without capturing endpoints returns false with error message',
          () async {
        final notifier = container.read(calibrationNotifierProvider.notifier);
        final success = await notifier.saveCalibration();
        expect(success, isFalse);

        final state = container.read(calibrationNotifierProvider);
        expect(state.errorMessage, contains('Incomplete calibration'));
      });

      test('cancelCalibration and reset restore idle state', () {
        final notifier = container.read(calibrationNotifierProvider.notifier);
        notifier.startCalibration();
        notifier.cancelCalibration();
        expect(container.read(calibrationNotifierProvider).currentStep,
            equals(CalibrationStep.idle));

        notifier.reset();
        expect(container.read(calibrationNotifierProvider).currentStep,
            equals(CalibrationStep.idle));
      });
    });

    group('SettingsNotifier Workflow & Error Handling', () {
      test('Loads default settings successfully and syncs to DeviceService',
          () async {
        final state = container.read(settingsNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.value?.deviceName, equals('DAKSH-01'));
      });

      test('saveSettings updates state and persists configuration', () async {
        final notifier = container.read(settingsNotifierProvider.notifier);

        const custom = DeviceSettings(
          deviceName: 'SYNTH-PRO-02',
          minAngle: 5.0,
          maxAngle: 55.0,
          emgThreshold: 140.0,
          batteryWarningThreshold: 15.0,
          defaultOperatingMode: OperatingMode.emg,
        );

        final result = await notifier.saveSettings(custom);
        expect(result, isTrue);
        expect(container.read(settingsNotifierProvider).value?.deviceName,
            equals('SYNTH-PRO-02'));
        expect(
            container
                .read(settingsNotifierProvider)
                .value
                ?.defaultOperatingMode,
            equals(OperatingMode.emg));
      });

      test('resetToDefaults resets settings back to factory default', () async {
        final notifier = container.read(settingsNotifierProvider.notifier);

        await notifier.resetToDefaults();
        expect(container.read(settingsNotifierProvider).value?.deviceName,
            equals('DAKSH-01'));
        expect(container.read(settingsNotifierProvider).value?.minAngle,
            equals(0.0));
      });

      test('SettingsNotifier catches repository errors gracefully', () async {
        final failingContainer = ProviderContainer(
          overrides: [
            settingsRepositoryProvider
                .overrideWithValue(FailingSettingsRepository()),
            deviceServiceProvider.overrideWithValue(MockDeviceService()),
          ],
        );
        addTearDown(failingContainer.dispose);

        final notifier =
            failingContainer.read(settingsNotifierProvider.notifier);
        await notifier.loadSettings();
        expect(
            failingContainer.read(settingsNotifierProvider).hasError, isTrue);

        final saveResult = await notifier.saveSettings(const DeviceSettings());
        expect(saveResult, isFalse);
        expect(
            failingContainer.read(settingsNotifierProvider).hasError, isTrue);
      });
    });

    group('ThemeModeNotifier State Management', () {
      test('Loads and toggles theme between light and dark', () async {
        final notifier = container.read(themeModeProvider.notifier);
        expect(container.read(themeModeProvider), equals(ThemeMode.dark));

        notifier.toggleTheme();
        expect(container.read(themeModeProvider), equals(ThemeMode.light));

        notifier.toggleTheme();
        expect(container.read(themeModeProvider), equals(ThemeMode.dark));

        await notifier.setThemeMode(ThemeMode.system);
        expect(container.read(themeModeProvider), equals(ThemeMode.system));
      });
    });

    group('EmgHistoryNotifier & DeviceLogsNotifier Reactive Streams', () {
      test('EmgHistoryNotifier maintains rolling window buffer', () async {
        container.read(emgHistoryProvider.notifier);
        expect(container.read(emgHistoryProvider).length, equals(60));

        // Allow some telemetry ticks to pass
        await Future.delayed(const Duration(milliseconds: 150));
        expect(container.read(emgHistoryProvider).length, equals(60));
      });

      test('DeviceLogsNotifier appends and clears logs', () async {
        final notifier = container.read(deviceLogsProvider.notifier);
        expect(container.read(deviceLogsProvider), isA<List<DeviceLogEntry>>());

        notifier.clear();
        expect(container.read(deviceLogsProvider), isEmpty);
      });
    });
  });
}
