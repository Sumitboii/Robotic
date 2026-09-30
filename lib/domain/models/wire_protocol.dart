import 'device_command.dart';
import 'device_telemetry.dart';
import 'hand_state.dart';
import 'operating_mode.dart';

/// Canonical wire protocol codec for Synthera Prosthetic Hand communication (Assignment §4).
///
/// Single-line format:
/// `BATTERY:82 POSITION:45 EMG:127 MODE:AUTO STATE:HOLDING`
///
/// Multi-line format (also accepted):
/// ```text
/// BATTERY:82
/// POSITION:45
/// EMG:127
/// MODE:AUTO
/// STATE:HOLDING
/// ```
///
/// Commands:
/// - `OPEN`
/// - `CLOSE`
/// - `STOP`
/// - `CALIBRATE`
/// - `SET_MODE:AUTO`
/// - `UPDATE_LIMITS:0.0:63.0`
/// - `RESET_BATTERY`
class WireProtocol {
  const WireProtocol._();

  /// Encodes a [DeviceCommand] to its canonical wire protocol string representation.
  static String encodeCommand(DeviceCommand command) {
    if (command.payload == null) {
      return command.type.wireName;
    }
    if (command.payload is OperatingMode) {
      return '${command.type.wireName}:${(command.payload as OperatingMode).displayName}';
    }
    if (command.payload is Map) {
      final map = command.payload as Map;
      return '${command.type.wireName}:${map['minAngle']}:${map['maxAngle']}';
    }
    return '${command.type.wireName}:${command.payload}';
  }

  /// Safely parses a raw wire command string into a [DeviceCommand].
  /// Returns null if the command is unrecognized or empty. Never throws an exception.
  static DeviceCommand? decodeCommand(String raw) {
    try {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;

      final parts = trimmed.split(':');
      final name = parts[0].trim().toUpperCase();

      switch (name) {
        case 'OPEN':
          return DeviceCommand.open();
        case 'CLOSE':
          return DeviceCommand.close();
        case 'STOP':
          return DeviceCommand.stop();
        case 'CALIBRATE':
          return DeviceCommand.calibrate();
        case 'SET_MODE':
          if (parts.length > 1) {
            final mode = OperatingMode.fromString(parts[1].trim());
            return DeviceCommand.setMode(mode);
          }
          return DeviceCommand.setMode(OperatingMode.manual);
        case 'UPDATE_LIMITS':
          if (parts.length >= 3) {
            final min = double.tryParse(parts[1].trim()) ?? 0.0;
            final max = double.tryParse(parts[2].trim()) ?? 63.0;
            return DeviceCommand.updateLimits(minAngle: min, maxAngle: max);
          }
          return null;
        case 'RESET_BATTERY':
          return DeviceCommand(type: DeviceCommandType.resetBattery);
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// Encodes [DeviceTelemetry] into the canonical single-line `KEY:VALUE` wire string (Assignment §4).
  /// Example: `BATTERY:82 POSITION:45 EMG:127 MODE:AUTO STATE:HOLDING`
  static String encodeTelemetry(DeviceTelemetry telemetry) {
    final emgStr = telemetry.isEmgSensorAvailable
        ? _formatNumber(telemetry.emgValue)
        : 'ERR';
    return 'BATTERY:${_formatNumber(telemetry.batteryPercentage)} '
        'POSITION:${_formatNumber(telemetry.positionDegrees)} '
        'EMG:$emgStr '
        'MODE:${telemetry.operatingMode.displayName} '
        'STATE:${telemetry.handState.displayName}';
  }

  /// Safely decodes a raw wire string into [DeviceTelemetry].
  ///
  /// Tolerant parsing handles:
  /// - Single-line `KEY:VALUE` frame: `BATTERY:82 POSITION:45 EMG:127 MODE:AUTO STATE:HOLDING`
  /// - Multi-line newline-separated (`\n`, `\r\n`) pairs.
  /// - Space-separated, comma-separated, or semicolon-separated tokens.
  /// - Missing or non-numeric/fault EMG values (`EMG:ERR`, `EMG:FAULT`, `EMG:NAN` -> sets `isEmgSensorAvailable = false`).
  /// - Unknown/extra keys (gracefully ignored).
  /// - Out-of-range values (clamped to physical limits).
  /// - Legacy CSV format as secondary fallback.
  ///
  /// Never throws an exception.
  static DeviceTelemetry? decodeTelemetry(
    String raw, {
    String deviceName = 'DAKSH-01',
    double minAngle = 0.0,
    double maxAngle = 63.0,
  }) {
    try {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;

      final map = <String, String>{};

      // Match KEY:VALUE or KEY=VALUE tokens across lines, spaces, semicolons
      final kvRegex = RegExp(r'([A-Za-z0-9_]+)\s*[:=]\s*([^\s;,\r\n]+)');
      final matches = kvRegex.allMatches(trimmed);

      for (final match in matches) {
        final key = match.group(1)?.trim().toUpperCase();
        final value = match.group(2)?.trim();
        if (key != null && value != null) {
          map[key] = value;
        }
      }

      if (map.isNotEmpty) {
        // Safe extraction with bounds clamping
        double battery = 82.0;
        if (map.containsKey('BATTERY') || map.containsKey('BATT')) {
          final rawVal = map['BATTERY'] ?? map['BATT']!;
          final parsed = double.tryParse(rawVal);
          if (parsed != null) {
            battery = parsed;
          }
        }

        double position = 45.0;
        if (map.containsKey('POSITION') || map.containsKey('POS')) {
          final rawVal = map['POSITION'] ?? map['POS']!;
          final parsed = double.tryParse(rawVal);
          if (parsed != null) {
            position = parsed;
          }
        }

        bool emgSensorAvailable = true;
        double emg = 127.0;
        if (map.containsKey('EMG')) {
          final rawEmg = map['EMG']!;
          final upper = rawEmg.toUpperCase();
          if (upper == 'ERR' ||
              upper == 'FAULT' ||
              upper == 'NAN' ||
              upper == 'INVALID') {
            emgSensorAvailable = false;
            emg = 0.0;
          } else {
            final parsed = double.tryParse(rawEmg);
            if (parsed != null) {
              emg = parsed;
            } else {
              emgSensorAvailable = false;
              emg = 0.0;
            }
          }
        } else {
          // If EMG key is completely absent from the frame, mark as unavailable
          emgSensorAvailable = false;
          emg = 0.0;
        }

        OperatingMode mode = OperatingMode.auto;
        if (map.containsKey('MODE')) {
          mode = OperatingMode.fromString(map['MODE']!);
        }

        HandState state = HandState.holding;
        if (map.containsKey('STATE')) {
          state = HandState.fromString(map['STATE']!);
        }

        return DeviceTelemetry(
          deviceName: deviceName,
          batteryPercentage: battery.clamp(0.0, 100.0),
          positionDegrees: position.clamp(minAngle, maxAngle),
          emgValue: emg.clamp(0.0, 255.0),
          isEmgSensorAvailable: emgSensorAvailable,
          operatingMode: mode,
          handState: state,
          minAngle: minAngle,
          maxAngle: maxAngle,
          isLowBattery: battery <= 20.0,
          rawFrame: trimmed,
          timestamp: DateTime.now(),
        );
      }

      // Secondary fallback: Legacy CSV format (<pos_norm>,<angle>,<battery_pct>,<emg_val>,<state>,<mode>)
      if (trimmed.contains(',')) {
        final tokens = trimmed.split(',').map((s) => s.trim()).toList();
        if (tokens.length >= 6) {
          final posAngle = double.tryParse(tokens[1]) ?? 45.0;
          final battery = double.tryParse(tokens[2]) ?? 82.0;
          final emg = double.tryParse(tokens[3]) ?? 127.0;
          final state = HandState.fromString(tokens[4]);
          final mode = OperatingMode.fromString(tokens[5]);

          return DeviceTelemetry(
            deviceName: deviceName,
            batteryPercentage: battery.clamp(0.0, 100.0),
            positionDegrees: posAngle.clamp(minAngle, maxAngle),
            emgValue: emg.clamp(0.0, 255.0),
            isEmgSensorAvailable: true,
            operatingMode: mode,
            handState: state,
            minAngle: minAngle,
            maxAngle: maxAngle,
            isLowBattery: battery <= 20.0,
            rawFrame: trimmed,
            timestamp: DateTime.now(),
          );
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static String _formatNumber(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }
}
