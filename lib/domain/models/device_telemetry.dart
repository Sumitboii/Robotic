import 'hand_state.dart';
import 'operating_mode.dart';
import 'wire_protocol.dart';

class DeviceTelemetry {
  final String deviceName;
  final double batteryPercentage;
  final double positionDegrees;
  final double emgValue;
  final bool isEmgSensorAvailable;
  final OperatingMode operatingMode;
  final HandState handState;
  final double minAngle;
  final double maxAngle;
  final bool isLowBattery;
  final String? lastError;
  final String? rawFrame;
  final DateTime timestamp;

  const DeviceTelemetry({
    required this.deviceName,
    required this.batteryPercentage,
    required this.positionDegrees,
    required this.emgValue,
    this.isEmgSensorAvailable = true,
    required this.operatingMode,
    required this.handState,
    this.minAngle = 0.0,
    this.maxAngle = 63.0,
    this.isLowBattery = false,
    this.lastError,
    this.rawFrame,
    required this.timestamp,
  });

  factory DeviceTelemetry.initial({
    String deviceName = 'DAKSH-01',
    double minAngle = 0.0,
    double maxAngle = 63.0,
  }) {
    return DeviceTelemetry(
      deviceName: deviceName,
      batteryPercentage: 82.0,
      positionDegrees: 45.0,
      emgValue: 127.0,
      isEmgSensorAvailable: true,
      operatingMode: OperatingMode.auto,
      handState: HandState.holding,
      minAngle: minAngle,
      maxAngle: maxAngle,
      isLowBattery: false,
      timestamp: DateTime.now(),
    );
  }

  DeviceTelemetry copyWith({
    String? deviceName,
    double? batteryPercentage,
    double? positionDegrees,
    double? emgValue,
    bool? isEmgSensorAvailable,
    OperatingMode? operatingMode,
    HandState? handState,
    double? minAngle,
    double? maxAngle,
    bool? isLowBattery,
    String? lastError,
    String? rawFrame,
    DateTime? timestamp,
  }) {
    return DeviceTelemetry(
      deviceName: deviceName ?? this.deviceName,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      positionDegrees: positionDegrees ?? this.positionDegrees,
      emgValue: emgValue ?? this.emgValue,
      isEmgSensorAvailable: isEmgSensorAvailable ?? this.isEmgSensorAvailable,
      operatingMode: operatingMode ?? this.operatingMode,
      handState: handState ?? this.handState,
      minAngle: minAngle ?? this.minAngle,
      maxAngle: maxAngle ?? this.maxAngle,
      isLowBattery: isLowBattery ?? this.isLowBattery,
      lastError: lastError,
      rawFrame: rawFrame ?? this.rawFrame,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Format as canonical single-line wire telemetry string (§4)
  String toWireProtocol() => WireProtocol.encodeTelemetry(this);

  /// Parse from simulated/BLE wire protocol string
  static DeviceTelemetry? parseWireProtocol(
    String raw, {
    String deviceName = 'DAKSH-01',
    double minAngle = 0.0,
    double maxAngle = 63.0,
  }) {
    return WireProtocol.decodeTelemetry(
      raw,
      deviceName: deviceName,
      minAngle: minAngle,
      maxAngle: maxAngle,
    );
  }

  @override
  String toString() =>
      'DeviceTelemetry(device: $deviceName, batt: ${batteryPercentage.toStringAsFixed(0)}%, '
      'pos: ${positionDegrees.toStringAsFixed(1)}°, emg: ${isEmgSensorAvailable ? emgValue.toStringAsFixed(0) : 'UNAVAILABLE'}, '
      'mode: ${operatingMode.displayName}, state: ${handState.displayName})';
}
