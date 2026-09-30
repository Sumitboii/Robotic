import 'dart:async';
import '../../domain/models/connection_state.dart';
import '../../domain/models/device_command.dart';
import '../../domain/models/device_log_entry.dart';
import '../../domain/models/device_settings.dart';
import '../../domain/models/device_telemetry.dart';
import '../../domain/models/operating_mode.dart';

/// Abstract Device Service interface (Assignment §4 & §11).
/// Decouples UI and application state from the concrete communication implementation.
/// Conceptually swappable between [MockDeviceService] (Simulator) and [BleDeviceService] (Real ESP32).
abstract class DeviceService {
  /// Live stream of device telemetry data (20 Hz)
  Stream<DeviceTelemetry> get telemetryStream;

  /// Live stream of connectivity state
  Stream<DeviceConnectionState> get connectionStateStream;

  /// Live stream of device event logs
  Stream<DeviceLogEntry> get logStream;

  /// Latest snapshot of telemetry
  DeviceTelemetry get currentTelemetry;

  /// Latest snapshot of connection state
  DeviceConnectionState get currentConnectionState;

  /// Connect to the device (simulated or BLE peripheral)
  Future<void> connect();

  /// Disconnect from the device
  Future<void> disconnect();

  /// Reconnect to the device
  Future<void> reconnect();

  /// Send a high-level command (OPEN, CLOSE, STOP, etc.)
  Future<void> sendCommand(DeviceCommand command);

  /// Send a raw wire protocol command string (for error and fuzz testing §10)
  Future<void> sendRawCommand(String rawCommand);

  /// Quick command shortcuts
  Future<void> openHand();
  Future<void> closeHand();
  Future<void> emergencyStop();

  /// Change operating mode (MANUAL, EMG, AUTO)
  Future<void> setOperatingMode(OperatingMode mode);

  /// Update hardware settings and motion limits
  Future<void> updateSettings(DeviceSettings settings);

  /// Calibration workflow methods (§9)
  Future<void> startCalibration();
  Future<double> captureCalibrationOpenPosition();
  Future<double> captureCalibrationClosePosition();
  Future<void> saveCalibrationLimits(double minAngle, double maxAngle);
  Future<void> cancelCalibration();

  /// Developer / Demo controls for presentation (§10)
  Future<void> triggerDemoBatteryDrain(double targetPercentage);
  Future<void> triggerEmgSpike(double spikeValue);
  Future<void> simulateConnectionDrop();
  Future<void> toggleEmgSensorFault([bool? enable]);
  Future<void> setFailNextReconnect(bool fail);
  bool get isEmgSensorFaultSimulated;
  bool get willFailNextReconnect;

  /// Release resources and timers
  void dispose();
}
