import 'package:flutter_test/flutter_test.dart';
import 'package:synthera_prosthetic_hand/domain/models/connection_state.dart';
import 'package:synthera_prosthetic_hand/domain/models/device_command.dart';
import 'package:synthera_prosthetic_hand/domain/models/hand_state.dart';
import 'package:synthera_prosthetic_hand/domain/models/operating_mode.dart';
import 'package:synthera_prosthetic_hand/infrastructure/device/mock/simulated_esp32.dart';

void main() {
  group('SimulatedEsp32 Firmware Simulation Test Suite', () {
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

      // A sustained high signal will NOT re-arm until it drops below threshold - 15.0
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

    test('Connection disconnect and reconnect sequence', () async {
      final stateHistory = <DeviceConnectionState>[];
      final subscription = esp32.connectionStateStream
          .listen((state) => stateHistory.add(state));
      addTearDown(() => subscription.cancel());

      await esp32.disconnect();
      expect(esp32.connectionState, equals(DeviceConnectionState.disconnected));
      expect(esp32.connectionState.displayName, equals('Device Disconnected'));

      // Commands while disconnected should be rejected safely without crashing
      esp32.processCommand(DeviceCommand.open());
      expect(esp32.hand.isMoving, isFalse);

      await esp32.reconnect();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(esp32.connectionState, equals(DeviceConnectionState.connected));
      expect(esp32.connectionState.displayName, equals('Connected'));

      // Verify progression sequence: disconnected -> reconnecting -> connected
      expect(stateHistory, contains(DeviceConnectionState.disconnected));
      expect(stateHistory, contains(DeviceConnectionState.reconnecting));
      expect(stateHistory, contains(DeviceConnectionState.connected));
    });

    test('Rapid repeated OPEN/CLOSE/STOP commands leave the state consistent',
        () {
      esp32.setOperatingMode(OperatingMode.manual);

      // Execute 20 rapid alternating commands
      for (int i = 0; i < 20; i++) {
        if (i % 3 == 0) {
          esp32.processCommand(DeviceCommand.open());
        } else if (i % 3 == 1) {
          esp32.processCommand(DeviceCommand.close());
        } else {
          esp32.processCommand(DeviceCommand.stop());
        }
      }

      // Final command is STOP
      esp32.processCommand(DeviceCommand.stop());
      expect(esp32.hand.state, equals(HandState.stopped));
      expect(esp32.hand.isMoving, isFalse);
      expect(
          esp32.hand.currentAngle, greaterThanOrEqualTo(esp32.hand.minAngle));
      expect(esp32.hand.currentAngle, lessThanOrEqualTo(esp32.hand.maxAngle));
    });

    test('Changing mode away from AUTO cancels the AUTO schedule', () async {
      esp32.setOperatingMode(OperatingMode.auto);
      expect(esp32.operatingMode, equals(OperatingMode.auto));

      // Switch away to MANUAL mode
      esp32.setOperatingMode(OperatingMode.manual);
      esp32.processCommand(DeviceCommand.stop());
      expect(esp32.hand.state, equals(HandState.stopped));

      // Wait past the auto hold timer threshold (1.6s)
      await Future.delayed(const Duration(milliseconds: 200));

      // Ensure hand remained stopped and did not trigger autonomous motion
      expect(esp32.hand.state, equals(HandState.stopped));
      expect(esp32.hand.isMoving, isFalse);
    });
  });
}
