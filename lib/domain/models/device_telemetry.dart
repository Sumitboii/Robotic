import 'hand_state.dart';
import 'operating_mode.dart';
import 'wire_protocol.dart';

class DeviceTelemetry {
  final String deviceName;
  final double batteryPercentage;
  final double positionDegrees;
  final double emgValue;
  final OperatingMode operatingMode;
  final HandState handState;
  final double minAngle;
  final double maxAngle;
  final bool isLowBattery;
  final String? lastError;
  final DateTime timestamp;

  const DeviceTelemetry({
    required this.deviceName,
    required this.batteryPercentage,
    required this.positionDegrees,
    required this.emgValue,
    required this.operatingMode,
    required this.handState,
    this.minAngle = 0.0,
    this.maxAngle = 63.0,
    this.isLowBattery = false,
    this.lastError,
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
    OperatingMode? operatingMode,
    HandState? handState,
    double? minAngle,
    double? maxAngle,
    bool? isLowBattery,
    String? lastError,
    DateTime? timestamp,
  }) {
    return DeviceTelemetry(
      deviceName: deviceName ?? this.deviceName,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      positionDegrees: positionDegrees ?? this.positionDegrees,
      emgValue: emgValue ?? this.emgValue,
      operatingMode: operatingMode ?? this.operatingMode,
      handState: handState ?? this.handState,
      minAngle: minAngle ?? this.minAngle,
      maxAngle: maxAngle ?? this.maxAngle,
      isLowBattery: isLowBattery ?? this.isLowBattery,
      lastError: lastError,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Format as canonical line-oriented wire telemetry string (Spec §2)
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
      'pos: ${positionDegrees.toStringAsFixed(1)}°, emg: ${emgValue.toStringAsFixed(0)}, '
      'mode: ${operatingMode.displayName}, state: ${handState.displayName})';
}
