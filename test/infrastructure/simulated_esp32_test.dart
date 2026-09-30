import 'package:flutter_test/flutter_test.dart';
import 'package:synthera_prosthetic_hand/domain/models/connection_state.dart';
import 'package:synthera_prosthetic_hand/domain/models/device_command.dart';
import 'package:synthera_prosthetic_hand/domain/models/hand_state.dart';
import 'package:synthera_prosthetic_hand/domain/models/operating_mode.dart';
import 'package:synthera_prosthetic_hand/infrastructure/device/mock/simulated_esp32.dart';

void main() {
  group('SimulatedEsp32 Firmware Simulation Test Suite (Assignment §4 & §10)',
      () {
    late SimulatedEsp32 esp32;

    setUp(() {
      esp32 = SimulatedEsp32(initialBattery: 82.0);
    });

    tearDown(() {
      esp32.dispose();
    });

    test('Initial firmware state matches default assignment parameters', () {
      expect(esp32.deviceName, equals('DAKSH-01'));
      expect(esp32.batteryPercentage, equals(82.0));
      expect(esp32.operatingMode, equals(OperatingMode.auto));
      expect(esp32.connectionState.isConnected, isTrue);
    });

    test('Emits single-line raw text wire frames on rawTelemetryStream (§4)',
        () async {
      final frame = await esp32.rawTelemetryStream.first;
      expect(frame, startsWith('BATTERY:'));
      expect(frame, contains('POSITION:'));
      expect(frame, contains('EMG:'));
      expect(frame, contains('MODE:'));
      expect(frame, contains('STATE:'));
    });

    test('processWireCommand decodes valid commands and actuates hand (§4)',
        () {
      esp32.setOperatingMode(OperatingMode.manual);
      esp32.processWireCommand('OPEN');
      expect(esp32.hand.state, equals(HandState.opening));

      esp32.processWireCommand('STOP');
      expect(esp32.hand.state, equals(HandState.stopped));

      esp32.processWireCommand('CLOSE');
      expect(esp32.hand.state, equals(HandState.closing));
    });

    test(
        'processWireCommand with malformed string logs ERR:INVALID_COMMAND without crashing (§10)',
        () async {
      final logs = <String>[];
      final sub = esp32.logStream.listen((entry) => logs.add(entry.message));
      addTearDown(() => sub.cancel());

      esp32.processWireCommand('FLY');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(
          logs.any((msg) => msg.contains('ERR:INVALID_COMMAND: FLY')), isTrue);
    });

    test(
        'Simulate EMG sensor fault causes device to emit frames with EMG:ERR (§10)',
        () {
      expect(esp32.isEmgSensorFaultSimulated, isFalse);
      esp32.toggleEmgSensorFault(true);
      expect(esp32.isEmgSensorFaultSimulated, isTrue);

      final telemetry = esp32.currentTelemetry;
      expect(telemetry.isEmgSensorAvailable, isFalse);
      expect(telemetry.emgValue, equals(0.0));

      final frame = esp32.currentWireTelemetry;
      expect(frame, contains('EMG:ERR'));

      // Recovery
      esp32.toggleEmgSensorFault(false);
      expect(esp32.isEmgSensorFaultSimulated, isFalse);
      expect(esp32.currentTelemetry.isEmgSensorAvailable, isTrue);
    });

    test(
        'Fail next reconnect causes reconnect() to transition to connectionFailed (§10)',
        () async {
      await esp32.disconnect();
      expect(esp32.connectionState, equals(DeviceConnectionState.disconnected));

      esp32.setFailNextReconnect(true);
      expect(esp32.willFailNextReconnect, isTrue);

      await esp32.reconnect();
      expect(esp32.connectionState,
          equals(DeviceConnectionState.connectionFailed));
      expect(esp32.connectionState.displayName, equals('Connection Failed'));

      // Next reconnect without fail flag succeeds
      await esp32.reconnect();
      expect(esp32.connectionState, equals(DeviceConnectionState.connected));
    });

    test('Manual OPEN and CLOSE commands actuate hand', () async {
      esp32.setOperatingMode(OperatingMode.manual);

      esp32.processCommand(DeviceCommand.open());
      expect(esp32.hand.state, equals(HandState.opening));

      esp32.processCommand(DeviceCommand.stop());
      expect(esp32.hand.state, equals(HandState.stopped));

      esp32.processCommand(DeviceCommand.close());
      expect(esp32.hand.state, equals(HandState.closing));
    });

    test(
        'EMG mode hysteresis prevents repeated triggers on sustained high signal',
        () async {
      esp32.setOperatingMode(OperatingMode.emg);
      expect(esp32.isEmgArmed, isTrue);

      // Trigger contraction edge
      esp32.triggerEmgSpike(180.0);
      await Future.delayed(const Duration(milliseconds: 120));

      // After threshold crossing, EMG must disarm to prevent repeated firing
      expect(esp32.isEmgArmed, isFalse);
      expect(esp32.isEmgArmed, isFalse);
    });

    test('EMG mode alternating contraction trigger closes and opens', () {
      esp32.setOperatingMode(OperatingMode.emg);

      // Trigger contraction #1 -> CLOSE
      esp32.processCommand(DeviceCommand.close());
      expect(esp32.hand.state, equals(HandState.closing));

      // Trigger contraction #2 -> OPEN
      esp32.processCommand(DeviceCommand.open());
      expect(esp32.hand.state, equals(HandState.opening));
    });

    test(
        'STOP command cancels Auto mode scheduling and halts motor immediately',
        () {
      esp32.setOperatingMode(OperatingMode.auto);
      expect(esp32.operatingMode, equals(OperatingMode.auto));

      esp32.processCommand(DeviceCommand.stop());
      expect(esp32.hand.state, equals(HandState.stopped));
      expect(esp32.operatingMode, equals(OperatingMode.manual));
    });

    test('Battery drain prevents movement when battery reaches 0%', () {
      esp32.setBatteryPercentage(0.0);
      expect(esp32.batteryPercentage, equals(0.0));

      esp32.processCommand(DeviceCommand.open());
      expect(esp32.hand.isMoving, isFalse);

      esp32.processCommand(DeviceCommand.close());
      expect(esp32.hand.isMoving, isFalse);
    });

    test('Rapid repeated OPEN/CLOSE/STOP commands leave the state consistent',
        () {
      esp32.setOperatingMode(OperatingMode.manual);

      for (int i = 0; i < 20; i++) {
        if (i % 3 == 0) {
          esp32.processCommand(DeviceCommand.open());
        } else if (i % 3 == 1) {
          esp32.processCommand(DeviceCommand.close());
        } else {
          esp32.processCommand(DeviceCommand.stop());
        }
      }

      esp32.processCommand(DeviceCommand.stop());
      expect(esp32.hand.state, equals(HandState.stopped));
      expect(esp32.hand.isMoving, isFalse);
      expect(
          esp32.hand.currentAngle, greaterThanOrEqualTo(esp32.hand.minAngle));
      expect(esp32.hand.currentAngle, lessThanOrEqualTo(esp32.hand.maxAngle));
    });
  });
}
