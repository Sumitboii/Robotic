import 'package:flutter_test/flutter_test.dart';
import 'package:synthera_prosthetic_hand/domain/models/device_command.dart';
import 'package:synthera_prosthetic_hand/domain/models/device_telemetry.dart';
import 'package:synthera_prosthetic_hand/domain/models/hand_state.dart';
import 'package:synthera_prosthetic_hand/domain/models/operating_mode.dart';
import 'package:synthera_prosthetic_hand/domain/models/wire_protocol.dart';

void main() {
  group('Canonical WireProtocol Telemetry & Command Codec Test Suite (Spec §2)',
      () {
    test('Exact spec §2 example parses into expected DeviceTelemetry model',
        () {
      const specRaw = '''
BATTERY:82
POSITION:45
EMG:127
MODE:AUTO
STATE:HOLDING
''';

      final telemetry = WireProtocol.decodeTelemetry(specRaw);
      expect(telemetry, isNotNull);
      expect(telemetry!.batteryPercentage, equals(82.0));
      expect(telemetry.positionDegrees, equals(45.0));
      expect(telemetry.emgValue, equals(127.0));
      expect(telemetry.operatingMode, equals(OperatingMode.auto));
      expect(telemetry.handState, equals(HandState.holding));
      expect(telemetry.isLowBattery, isFalse);
    });

    test(
        'Inline single-line spec example with space separators parses correctly',
        () {
      const inlineRaw =
          'BATTERY:82 POSITION:45 EMG:127 MODE:AUTO STATE:HOLDING';
      final telemetry = WireProtocol.decodeTelemetry(inlineRaw);
      expect(telemetry, isNotNull);
      expect(telemetry!.batteryPercentage, equals(82.0));
      expect(telemetry.positionDegrees, equals(45.0));
      expect(telemetry.emgValue, equals(127.0));
      expect(telemetry.operatingMode, equals(OperatingMode.auto));
      expect(telemetry.handState, equals(HandState.holding));
    });

    test('Round-trip encode and decode preserves every telemetry field', () {
      final original = DeviceTelemetry(
        deviceName: 'DAKSH-01',
        batteryPercentage: 65.0,
        positionDegrees: 30.0,
        emgValue: 185.0,
        operatingMode: OperatingMode.emg,
        handState: HandState.closing,
        minAngle: 0.0,
        maxAngle: 63.0,
        timestamp: DateTime.now(),
      );

      final encoded = WireProtocol.encodeTelemetry(original);
      expect(encoded, contains('BATTERY:65'));
      expect(encoded, contains('POSITION:30'));
      expect(encoded, contains('EMG:185'));
      expect(encoded, contains('MODE:EMG'));
      expect(encoded, contains('STATE:CLOSING'));

      final decoded = WireProtocol.decodeTelemetry(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.batteryPercentage, equals(65.0));
      expect(decoded.positionDegrees, equals(30.0));
      expect(decoded.emgValue, equals(185.0));
      expect(decoded.operatingMode, equals(OperatingMode.emg));
      expect(decoded.handState, equals(HandState.closing));
    });

    test(
        'Command encode/decode round-trip for OPEN, CLOSE, STOP, CALIBRATE, SET_MODE, UPDATE_LIMITS',
        () {
      expect(WireProtocol.encodeCommand(DeviceCommand.open()), equals('OPEN'));
      expect(WireProtocol.decodeCommand('OPEN')?.type,
          equals(DeviceCommandType.open));

      expect(
          WireProtocol.encodeCommand(DeviceCommand.close()), equals('CLOSE'));
      expect(WireProtocol.decodeCommand('CLOSE')?.type,
          equals(DeviceCommandType.close));

      expect(WireProtocol.encodeCommand(DeviceCommand.stop()), equals('STOP'));
      expect(WireProtocol.decodeCommand('STOP')?.type,
          equals(DeviceCommandType.stop));

      expect(WireProtocol.encodeCommand(DeviceCommand.calibrate()),
          equals('CALIBRATE'));
      expect(WireProtocol.decodeCommand('CALIBRATE')?.type,
          equals(DeviceCommandType.calibrate));

      final setModeCmd = DeviceCommand.setMode(OperatingMode.emg);
      expect(WireProtocol.encodeCommand(setModeCmd), equals('SET_MODE:EMG'));
      final decodedSetMode = WireProtocol.decodeCommand('SET_MODE:EMG');
      expect(decodedSetMode?.type, equals(DeviceCommandType.setMode));
      expect(decodedSetMode?.payload, equals(OperatingMode.emg));

      final updateLimitsCmd =
          DeviceCommand.updateLimits(minAngle: 5.0, maxAngle: 55.0);
      expect(WireProtocol.encodeCommand(updateLimitsCmd),
          equals('UPDATE_LIMITS:5.0:55.0'));
      final decodedLimits =
          WireProtocol.decodeCommand('UPDATE_LIMITS:5.0:55.0');
      expect(decodedLimits?.type, equals(DeviceCommandType.updateLimits));
      expect((decodedLimits?.payload as Map)['minAngle'], equals(5.0));
      expect((decodedLimits?.payload as Map)['maxAngle'], equals(55.0));

      final resetBattCmd = DeviceCommand(type: DeviceCommandType.resetBattery);
      expect(WireProtocol.encodeCommand(resetBattCmd), equals('RESET_BATTERY'));
      expect(WireProtocol.decodeCommand('RESET_BATTERY')?.type,
          equals(DeviceCommandType.resetBattery));
    });

    group('Tolerant & Safe Parsing Edge Cases (No Exceptions)', () {
      test('Empty string or whitespace returns null without exception', () {
        expect(WireProtocol.decodeTelemetry(''), isNull);
        expect(WireProtocol.decodeTelemetry('   \n\t  \r\n '), isNull);
        expect(WireProtocol.decodeCommand(''), isNull);
        expect(WireProtocol.decodeCommand('   '), isNull);
      });

      test('Unknown keys are ignored safely', () {
        const rawWithUnknown = '''
FIRMWARE_VER:2.4.1
BATTERY:77
UNKNOWN_SENSOR:999.2
POSITION:20
EMG:90
EXTRA_DATA:ABC_XYZ
MODE:MANUAL
STATE:OPEN
''';
        final telemetry = WireProtocol.decodeTelemetry(rawWithUnknown);
        expect(telemetry, isNotNull);
        expect(telemetry!.batteryPercentage, equals(77.0));
        expect(telemetry.positionDegrees, equals(20.0));
        expect(telemetry.emgValue, equals(90.0));
        expect(telemetry.operatingMode, equals(OperatingMode.manual));
        expect(telemetry.handState, equals(HandState.open));
      });

      test('Missing keys fall back to sensible defaults', () {
        const rawPartial = 'BATTERY:50\nPOSITION:15';
        final telemetry = WireProtocol.decodeTelemetry(rawPartial);
        expect(telemetry, isNotNull);
        expect(telemetry!.batteryPercentage, equals(50.0));
        expect(telemetry.positionDegrees, equals(15.0));
        expect(telemetry.emgValue, equals(127.0)); // sensible default
        expect(telemetry.operatingMode, equals(OperatingMode.auto));
        expect(telemetry.handState, equals(HandState.holding));
      });

      test('Non-numeric values fall back safely to defaults', () {
        const rawInvalidNumbers = '''
BATTERY:invalid_number
POSITION:not_a_float
EMG:corrupted_signal
MODE:AUTO
STATE:HOLDING
''';
        final telemetry = WireProtocol.decodeTelemetry(rawInvalidNumbers);
        expect(telemetry, isNotNull);
        expect(telemetry!.batteryPercentage, equals(82.0)); // safe default
        expect(telemetry.positionDegrees, equals(45.0)); // safe default
        expect(telemetry.emgValue, equals(127.0)); // safe default
      });

      test('Out-of-range values are safely clamped to physical bounds', () {
        const rawOutOfRange = '''
BATTERY:150
POSITION:999.0
EMG:400
MODE:MANUAL
STATE:HOLDING
''';
        final telemetry = WireProtocol.decodeTelemetry(
          rawOutOfRange,
          minAngle: 0.0,
          maxAngle: 63.0,
        );
        expect(telemetry, isNotNull);
        expect(telemetry!.batteryPercentage, equals(100.0)); // clamped to 100%
        expect(telemetry.positionDegrees, equals(63.0)); // clamped to maxAngle
        expect(telemetry.emgValue, equals(255.0)); // clamped to 255
      });

      test('Negative out-of-range values are safely clamped to lower bounds',
          () {
        const rawNegative = '''
BATTERY:-35
POSITION:-50.0
EMG:-10
MODE:MANUAL
STATE:HOLDING
''';
        final telemetry = WireProtocol.decodeTelemetry(
          rawNegative,
          minAngle: 0.0,
          maxAngle: 63.0,
        );
        expect(telemetry, isNotNull);
        expect(telemetry!.batteryPercentage, equals(0.0)); // clamped to 0%
        expect(telemetry.positionDegrees, equals(0.0)); // clamped to minAngle
        expect(telemetry.emgValue, equals(0.0)); // clamped to 0
      });

      test('Empty lines and irregular whitespace are handled cleanly', () {
        const messyRaw = '''

  
   BATTERY  :   82  
   
   POSITION : 45.0   
   
   EMG   :   127   
   MODE :   AUTO   
   STATE :   HOLDING   
   
''';
        final telemetry = WireProtocol.decodeTelemetry(messyRaw);
        expect(telemetry, isNotNull);
        expect(telemetry!.batteryPercentage, equals(82.0));
        expect(telemetry.positionDegrees, equals(45.0));
        expect(telemetry.emgValue, equals(127.0));
        expect(telemetry.operatingMode, equals(OperatingMode.auto));
        expect(telemetry.handState, equals(HandState.holding));
      });

      test('Legacy CSV format is supported as secondary fallback', () {
        const csvRaw = '0.714, 45.0, 82.0, 127.0, HOLDING, AUTO';
        final telemetry = WireProtocol.decodeTelemetry(csvRaw);
        expect(telemetry, isNotNull);
        expect(telemetry!.batteryPercentage, equals(82.0));
        expect(telemetry.positionDegrees, equals(45.0));
        expect(telemetry.emgValue, equals(127.0));
        expect(telemetry.operatingMode, equals(OperatingMode.auto));
        expect(telemetry.handState, equals(HandState.holding));
      });
    });
  });
}
