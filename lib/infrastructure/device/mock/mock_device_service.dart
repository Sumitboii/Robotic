import 'dart:async';
import '../../../domain/models/connection_state.dart';
import '../../../domain/models/device_command.dart';
import '../../../domain/models/device_log_entry.dart';
import '../../../domain/models/device_settings.dart';
import '../../../domain/models/device_telemetry.dart';
import '../../../domain/models/operating_mode.dart';
import '../device_service.dart';
import 'simulated_esp32.dart';

/// Concrete Mock Device Service implementing [DeviceService].
/// Acts as the communication bridge between the application/UI layer and the simulated ESP32.
class MockDeviceService implements DeviceService {
  final SimulatedEsp32 _esp32;

  MockDeviceService({
    DeviceSettings? initialSettings,
    double initialBattery = 82.0,
  }) : _esp32 = SimulatedEsp32(
          initialSettings: initialSettings,
          initialBattery: initialBattery,
        );

  @override
  Stream<DeviceTelemetry> get telemetryStream => _esp32.telemetryStream;

  @override
  Stream<DeviceConnectionState> get connectionStateStream =>
      _esp32.connectionStateStream;

  @override
  Stream<DeviceLogEntry> get logStream => _esp32.logStream;

  @override
  DeviceTelemetry get currentTelemetry => _esp32.currentTelemetry;

  @override
  DeviceConnectionState get currentConnectionState => _esp32.connectionState;

  SimulatedEsp32 get simulatedEsp32 => _esp32;

  @override
  Future<void> connect() async {
    await _esp32.connect();
  }

  @override
  Future<void> disconnect() async {
    await _esp32.disconnect();
  }

  @override
  Future<void> reconnect() async {
    await _esp32.reconnect();
  }

  @override
  Future<void> sendCommand(DeviceCommand command) async {
    _esp32.processCommand(command);
  }

  @override
  Future<void> openHand() async {
    _esp32.processCommand(DeviceCommand.open());
  }

  @override
  Future<void> closeHand() async {
    _esp32.processCommand(DeviceCommand.close());
  }

  @override
  Future<void> emergencyStop() async {
    _esp32.processCommand(DeviceCommand.stop());
  }

  @override
  Future<void> setOperatingMode(OperatingMode mode) async {
    _esp32.setOperatingMode(mode);
  }

  @override
  Future<void> updateSettings(DeviceSettings settings) async {
    _esp32.updateSettings(settings);
  }

  @override
  Future<void> startCalibration() async {
    _esp32.processCommand(DeviceCommand.calibrate());
  }

  @override
  Future<double> captureCalibrationOpenPosition() async {
    _esp32.hand.open();
    return _esp32.hand.minAngle;
  }

  @override
  Future<double> captureCalibrationClosePosition() async {
    _esp32.hand.close();
    return _esp32.hand.maxAngle;
  }

  @override
  Future<void> saveCalibrationLimits(double minAngle, double maxAngle) async {
    _esp32.processCommand(
      DeviceCommand.updateLimits(minAngle: minAngle, maxAngle: maxAngle),
    );
  }

  @override
  Future<void> cancelCalibration() async {
    _esp32.processCommand(DeviceCommand.stop());
  }

  @override
  Future<void> triggerDemoBatteryDrain(double targetPercentage) async {
    _esp32.setBatteryPercentage(targetPercentage);
  }

  @override
  Future<void> triggerEmgSpike(double spikeValue) async {
    _esp32.triggerEmgSpike(spikeValue);
  }

  @override
  Future<void> simulateConnectionDrop() async {
    await _esp32.disconnect();
  }

  @override
  void dispose() {
    _esp32.dispose();
  }
}
