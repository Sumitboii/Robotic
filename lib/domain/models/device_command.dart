import 'operating_mode.dart';
import 'wire_protocol.dart';

enum DeviceCommandType {
  open,
  close,
  stop,
  calibrate,
  setMode,
  updateLimits,
  resetBattery;

  String get wireName {
    switch (this) {
      case DeviceCommandType.open:
        return 'OPEN';
      case DeviceCommandType.close:
        return 'CLOSE';
      case DeviceCommandType.stop:
        return 'STOP';
      case DeviceCommandType.calibrate:
        return 'CALIBRATE';
      case DeviceCommandType.setMode:
        return 'SET_MODE';
      case DeviceCommandType.updateLimits:
        return 'UPDATE_LIMITS';
      case DeviceCommandType.resetBattery:
        return 'RESET_BATTERY';
    }
  }
}

class DeviceCommand {
  final DeviceCommandType type;
  final dynamic payload;
  final DateTime timestamp;

  DeviceCommand({
    required this.type,
    this.payload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory DeviceCommand.open() => DeviceCommand(type: DeviceCommandType.open);

  factory DeviceCommand.close() => DeviceCommand(type: DeviceCommandType.close);

  factory DeviceCommand.stop() => DeviceCommand(type: DeviceCommandType.stop);

  factory DeviceCommand.calibrate() =>
      DeviceCommand(type: DeviceCommandType.calibrate);

  factory DeviceCommand.setMode(OperatingMode mode) => DeviceCommand(
        type: DeviceCommandType.setMode,
        payload: mode,
      );

  factory DeviceCommand.updateLimits({
    required double minAngle,
    required double maxAngle,
  }) =>
      DeviceCommand(
        type: DeviceCommandType.updateLimits,
        payload: {'minAngle': minAngle, 'maxAngle': maxAngle},
      );

  String toWireProtocol() => WireProtocol.encodeCommand(this);

  static DeviceCommand? parseWireProtocol(String raw) =>
      WireProtocol.decodeCommand(raw);

  @override
  String toString() => 'DeviceCommand($type, payload: $payload)';
}
