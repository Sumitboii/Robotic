import 'package:flutter_test/flutter_test.dart';
import 'package:synthera_prosthetic_hand/domain/models/device_settings.dart';
import 'package:synthera_prosthetic_hand/domain/models/operating_mode.dart';
import 'package:synthera_prosthetic_hand/infrastructure/device/mock/mock_device_service.dart';

void main() {
  group('MockDeviceService API Test Suite (Assignment §4 & §10)', () {
    late MockDeviceService service;

    setUp(() {
      service = MockDeviceService();
    });

    tearDown(() {
      service.dispose();
    });

    test(
        'Telemetry stream receives and decodes raw wire frames from simulated ESP32 (§4)',
        () async {
      expect(service.currentConnectionState.isConnected, isTrue);
      expect(service.currentTelemetry.deviceName, equals('DAKSH-01'));

      final telemetry = await service.telemetryStream.first;
      expect(telemetry.deviceName, equals('DAKSH-01'));
      expect(telemetry.batteryPercentage, greaterThanOrEqualTo(0.0));
      expect(telemetry.positionDegrees, greaterThanOrEqualTo(0.0));
      expect(telemetry.isEmgSensorAvailable, isTrue);
    });

    test(
        'Command shortcuts send wire commands to actuate simulated device (§4)',
        () async {
      await service.openHand();
      expect(service.simulatedEsp32.hand.targetAngle, equals(0.0));

      await service.emergencyStop();
      expect(service.simulatedEsp32.hand.isMoving, isFalse);

      await service.closeHand();
      expect(service.simulatedEsp32.hand.targetAngle, equals(63.0));
    });

    test(
        'sendRawCommand sends arbitrary text frame for fuzz/error testing (§10)',
        () async {
      await service.sendRawCommand('FLY');
      // Should not throw and ESP32 logs error
      expect(service.currentTelemetry, isNotNull);
    });

    test(
        'EMG sensor fault injection sets telemetry isEmgSensorAvailable to false (§10)',
        () async {
      await service.toggleEmgSensorFault(true);
      expect(service.isEmgSensorFaultSimulated, isTrue);

      final telemetry = await service.telemetryStream.first;
      expect(telemetry.isEmgSensorAvailable, isFalse);

      // Recovery
      await service.toggleEmgSensorFault(false);
      expect(service.isEmgSensorFaultSimulated, isFalse);
    });

    test('Mode changes and Settings update sync with device', () async {
      await service.setOperatingMode(OperatingMode.manual);
      expect(
          service.simulatedEsp32.operatingMode, equals(OperatingMode.manual));

      const newSettings = DeviceSettings(
        deviceName: 'SYNTHERA-X1',
        minAngle: 5.0,
        maxAngle: 55.0,
        emgThreshold: 135.0,
        batteryWarningThreshold: 15.0,
        defaultOperatingMode: OperatingMode.emg,
      );

      await service.updateSettings(newSettings);
      expect(service.simulatedEsp32.deviceName, equals('SYNTHERA-X1'));
      expect(service.simulatedEsp32.hand.minAngle, equals(5.0));
      expect(service.simulatedEsp32.hand.maxAngle, equals(55.0));
      expect(service.simulatedEsp32.operatingMode, equals(OperatingMode.emg));
    });

    test('Calibration limits capture and application', () async {
      await service.startCalibration();
      await service.saveCalibrationLimits(2.0, 60.0);

      expect(service.simulatedEsp32.hand.minAngle, equals(2.0));
      expect(service.simulatedEsp32.hand.maxAngle, equals(60.0));
    });

    test('Demo controls trigger battery drain and EMG spike', () async {
      await service.triggerDemoBatteryDrain(15.0);
      expect(service.simulatedEsp32.batteryPercentage, equals(15.0));

      await service.triggerEmgSpike(150.0);
      await Future.delayed(const Duration(milliseconds: 120));
      expect(
          service.simulatedEsp32.currentTelemetry.emgValue, greaterThan(80.0));
    });
  });
}
