import 'dart:async';
import '../../../domain/models/connection_state.dart';
import '../../../domain/models/device_command.dart';
import '../../../domain/models/device_log_entry.dart';
import '../../../domain/models/device_settings.dart';
import '../../../domain/models/device_telemetry.dart';
import '../../../domain/models/operating_mode.dart';
import '../../../domain/models/wire_protocol.dart';
import '../device_service.dart';
import 'simulated_esp32.dart';

/// Concrete Mock Device Service implementing [DeviceService] (Assignment §4).
/// Acts as the communication bridge between the application/UI layer and the simulated ESP32
/// speaking exclusively through canonical wire protocol serial text streams.
class MockDeviceService implements DeviceService {
  final SimulatedEsp32 _esp32;
  StreamSubscription<String>? _rawSubscription;
  final StreamController<DeviceTelemetry> _decodedTelemetryController =
      StreamController<DeviceTelemetry>.broadcast();
  DeviceTelemetry _lastTelemetry;

  MockDeviceService({
    DeviceSettings? initialSettings,
    double initialBattery = 82.0,
  })  : _esp32 = SimulatedEsp32(
          initialSettings: initialSettings,
          initialBattery: initialBattery,
        ),
        _lastTelemetry = DeviceTelemetry.initial() {
    // Pipeline: SimulatedEsp32 emits raw string frames -> MockDeviceService decodes via WireProtocol (§4)
    _rawSubscription = _esp32.rawTelemetryStream.listen((rawFrame) {
      final decoded = WireProtocol.decodeTelemetry(
        rawFrame,
        deviceName: _esp32.deviceName,
        minAngle: _esp32.hand.minAngle,
        maxAngle: _esp32.hand.maxAngle,
      );

      if (decoded != null) {
        _lastTelemetry = decoded;
        if (!_decodedTelemetryController.isClosed) {
          _decodedTelemetryController.add(decoded);
        }
      } else {
        // Safe handling of malformed frame (§10): never throw, produce fallback telemetry with lastError
        final fallback = _lastTelemetry.copyWith(
          lastError: 'Malformed wire frame received: $rawFrame',
          rawFrame: rawFrame,
          timestamp: DateTime.now(),
        );
        _lastTelemetry = fallback;
        if (!_decodedTelemetryController.isClosed) {
          _decodedTelemetryController.add(fallback);
        }
      }
    });
  }

  @override
  Stream<DeviceTelemetry> get telemetryStream =>
      _decodedTelemetryController.stream;

  @override
  Stream<DeviceConnectionState> get connectionStateStream =>
      _esp32.connectionStateStream;

  @override
  Stream<DeviceLogEntry> get logStream => _esp32.logStream;

  @override
  DeviceTelemetry get currentTelemetry => _lastTelemetry;

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
    final wireString = WireProtocol.encodeCommand(command);
    _esp32.processWireCommand(wireString);
  }

  @override
  Future<void> sendRawCommand(String rawCommand) async {
    _esp32.processWireCommand(rawCommand);
  }

  @override
  Future<void> openHand() async {
    await sendCommand(DeviceCommand.open());
  }

  @override
  Future<void> closeHand() async {
    await sendCommand(DeviceCommand.close());
  }

  @override
  Future<void> emergencyStop() async {
    await sendCommand(DeviceCommand.stop());
  }

  @override
  Future<void> setOperatingMode(OperatingMode mode) async {
    await sendCommand(DeviceCommand.setMode(mode));
  }

  @override
  Future<void> updateSettings(DeviceSettings settings) async {
    _esp32.setDeviceName(settings.deviceName);
    await sendCommand(DeviceCommand.updateLimits(
      minAngle: settings.minAngle,
      maxAngle: settings.maxAngle,
    ));
    await setOperatingMode(settings.defaultOperatingMode);
  }

  @override
  Future<void> startCalibration() async {
    await sendCommand(DeviceCommand.calibrate());
  }

  @override
  Future<double> captureCalibrationOpenPosition() async {
    return _lastTelemetry.positionDegrees;
  }

  @override
  Future<double> captureCalibrationClosePosition() async {
    return _lastTelemetry.positionDegrees;
  }

  @override
  Future<void> saveCalibrationLimits(double minAngle, double maxAngle) async {
    await sendCommand(
      DeviceCommand.updateLimits(minAngle: minAngle, maxAngle: maxAngle),
    );
  }

  @override
  Future<void> cancelCalibration() async {
    await sendCommand(DeviceCommand.stop());
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
  Future<void> toggleEmgSensorFault([bool? enable]) async {
    _esp32.toggleEmgSensorFault(enable);
  }

  @override
  Future<void> setFailNextReconnect(bool fail) async {
    _esp32.setFailNextReconnect(fail);
  }

  @override
  bool get isEmgSensorFaultSimulated => _esp32.isEmgSensorFaultSimulated;

  @override
  bool get willFailNextReconnect => _esp32.willFailNextReconnect;

  @override
  void dispose() {
    _rawSubscription?.cancel();
    _decodedTelemetryController.close();
    _esp32.dispose();
  }
}
