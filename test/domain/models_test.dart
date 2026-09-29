import 'package:flutter_test/flutter_test.dart';
import 'package:synthera_prosthetic_hand/domain/models/calibration_state.dart';
import 'package:synthera_prosthetic_hand/domain/models/connection_state.dart';
import 'package:synthera_prosthetic_hand/domain/models/device_command.dart';
import 'package:synthera_prosthetic_hand/domain/models/device_settings.dart';
import 'package:synthera_prosthetic_hand/domain/models/device_telemetry.dart';
import 'package:synthera_prosthetic_hand/domain/models/hand_state.dart';
import 'package:synthera_prosthetic_hand/domain/models/operating_mode.dart';

void main() {
  group('Domain Models Test Suite', () {
    test('DeviceTelemetry wire protocol serialization and parsing', () {
      final telemetry = DeviceTelemetry(
        deviceName: 'DAKSH-01',
        batteryPercentage: 82.0,
        positionDegrees: 45.0,
        emgValue: 127.0,
        operatingMode: OperatingMode.auto,
        handState: HandState.holding,
        timestamp: DateTime.now(),
      );

      final wireStr = telemetry.toWireProtocol();
      expect(wireStr, contains('BATTERY:82'));
      expect(wireStr, contains('POSITION:45'));
      expect(wireStr, contains('EMG:127'));
      expect(wireStr, contains('MODE:AUTO'));
      expect(wireStr, contains('STATE:HOLDING'));

      final parsed =
          DeviceTelemetry.parseWireProtocol(wireStr, deviceName: 'DAKSH-01');
      expect(parsed, isNotNull);
      expect(parsed!.batteryPercentage, equals(82.0));
      expect(parsed.positionDegrees, equals(45.0));
      expect(parsed.emgValue, equals(127.0));
      expect(parsed.operatingMode, equals(OperatingMode.auto));
      expect(parsed.handState, equals(HandState.holding));

      // Malformed / empty packet strings produce null without throwing exceptions
      expect(
        DeviceTelemetry.parseWireProtocol('MALFORMED_UNRECOGNIZED_TOKEN',
            deviceName: 'DAKSH-01'),
        isNull,
      );
      expect(
        DeviceTelemetry.parseWireProtocol('', deviceName: 'DAKSH-01'),
        isNull,
      );
    });

    test('DeviceCommand wire protocol formatting', () {
      expect(DeviceCommand.open().toWireProtocol(), equals('OPEN'));
      expect(DeviceCommand.close().toWireProtocol(), equals('CLOSE'));
      expect(DeviceCommand.stop().toWireProtocol(), equals('STOP'));
      expect(DeviceCommand.calibrate().toWireProtocol(), equals('CALIBRATE'));
      expect(
        DeviceCommand.setMode(OperatingMode.emg).toWireProtocol(),
        equals('SET_MODE:EMG'),
      );
      expect(
        DeviceCommand.updateLimits(minAngle: 5.0, maxAngle: 60.0)
            .toWireProtocol(),
        equals('UPDATE_LIMITS:5.0:60.0'),
      );
    });

    test('DeviceSettings validation rules', () {
      // Valid settings
      expect(
        DeviceSettings.validate(
          deviceName: 'DAKSH-01',
          minAngle: 0.0,
          maxAngle: 63.0,
          emgThreshold: 120.0,
          batteryWarningThreshold: 20.0,
        ),
        isNull,
      );

      // Blank device name
      expect(
        DeviceSettings.validate(
          deviceName: '   ',
          minAngle: 0.0,
          maxAngle: 63.0,
          emgThreshold: 120.0,
          batteryWarningThreshold: 20.0,
        ),
        isNotNull,
      );

      // minAngle >= maxAngle
      expect(
        DeviceSettings.validate(
          deviceName: 'DAKSH-01',
          minAngle: 65.0,
          maxAngle: 60.0,
          emgThreshold: 120.0,
          batteryWarningThreshold: 20.0,
        ),
        contains('strictly less than'),
      );

      // Motion range too small (< 10 deg)
      expect(
        DeviceSettings.validate(
          deviceName: 'DAKSH-01',
          minAngle: 10.0,
          maxAngle: 15.0,
          emgThreshold: 120.0,
          batteryWarningThreshold: 20.0,
        ),
        contains('at least 10 degrees'),
      );

      // EMG threshold out of bounds
      expect(
        DeviceSettings.validate(
          deviceName: 'DAKSH-01',
          minAngle: 0.0,
          maxAngle: 63.0,
          emgThreshold: 10.0,
          batteryWarningThreshold: 20.0,
        ),
        isNotNull,
      );

      // Battery warning threshold out of bounds
      expect(
        DeviceSettings.validate(
          deviceName: 'DAKSH-01',
          minAngle: 0.0,
          maxAngle: 63.0,
          emgThreshold: 120.0,
          batteryWarningThreshold: 80.0,
        ),
        isNotNull,
      );
    });

    test('CalibrationState canSave validation', () {
      const state1 = CalibrationState(
        measuredMinAngle: 0.0,
        measuredMaxAngle: 60.0,
      );
      expect(state1.canSave, isTrue);

      const stateIncomplete = CalibrationState(
        measuredMinAngle: 0.0,
        measuredMaxAngle: null,
      );
      expect(stateIncomplete.canSave, isFalse);

      const stateInvalidRange = CalibrationState(
        measuredMinAngle: 50.0,
        measuredMaxAngle: 52.0, // range < 10
      );
      expect(stateInvalidRange.canSave, isFalse);
    });

    test('ConnectionState helper properties', () {
      expect(DeviceConnectionState.connected.isConnected, isTrue);
      expect(DeviceConnectionState.disconnected.isDisconnected, isTrue);
      expect(DeviceConnectionState.connecting.isTransitioning, isTrue);
      expect(DeviceConnectionState.reconnecting.isTransitioning, isTrue);
    });
  });
}
