enum LogLevel { info, warning, error, command, telemetry }

class DeviceLogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String source;

  const DeviceLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.source = 'SIM-ESP32',
  });

  factory DeviceLogEntry.info(String message, {String source = 'SIM-ESP32'}) =>
      DeviceLogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        message: message,
        source: source,
      );

  factory DeviceLogEntry.warning(String message,
          {String source = 'SIM-ESP32'}) =>
      DeviceLogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.warning,
        message: message,
        source: source,
      );

  factory DeviceLogEntry.error(String message, {String source = 'SIM-ESP32'}) =>
      DeviceLogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.error,
        message: message,
        source: source,
      );

  factory DeviceLogEntry.command(String message, {String source = 'APP'}) =>
      DeviceLogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.command,
        message: message,
        source: source,
      );

  factory DeviceLogEntry.telemetry(String message,
          {String source = 'SIM-ESP32'}) =>
      DeviceLogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.telemetry,
        message: message,
        source: source,
      );
}
