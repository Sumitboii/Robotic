import '../../core/constants/app_constants.dart';
import 'operating_mode.dart';

class DeviceSettings {
  final String deviceName;
  final double minAngle;
  final double maxAngle;
  final double emgThreshold;
  final double batteryWarningThreshold;
  final OperatingMode defaultOperatingMode;

  const DeviceSettings({
    this.deviceName = AppConstants.defaultDeviceName,
    this.minAngle = AppConstants.defaultMinAngle,
    this.maxAngle = AppConstants.defaultMaxAngle,
    this.emgThreshold = AppConstants.defaultEmgThreshold,
    this.batteryWarningThreshold = AppConstants.defaultBatteryWarningThreshold,
    this.defaultOperatingMode = OperatingMode.auto,
  });

  DeviceSettings copyWith({
    String? deviceName,
    double? minAngle,
    double? maxAngle,
    double? emgThreshold,
    double? batteryWarningThreshold,
    OperatingMode? defaultOperatingMode,
  }) {
    return DeviceSettings(
      deviceName: deviceName ?? this.deviceName,
      minAngle: minAngle ?? this.minAngle,
      maxAngle: maxAngle ?? this.maxAngle,
      emgThreshold: emgThreshold ?? this.emgThreshold,
      batteryWarningThreshold:
          batteryWarningThreshold ?? this.batteryWarningThreshold,
      defaultOperatingMode: defaultOperatingMode ?? this.defaultOperatingMode,
    );
  }

  /// Validation logic returning error message or null if valid
  static String? validate({
    required String deviceName,
    required double minAngle,
    required double maxAngle,
    required double emgThreshold,
    required double batteryWarningThreshold,
  }) {
    if (deviceName.trim().isEmpty) {
      return 'Device name cannot be blank.';
    }
    if (minAngle < AppConstants.absoluteMinAngle ||
        minAngle > AppConstants.absoluteMaxAngle) {
      return 'Minimum angle must be between ${AppConstants.absoluteMinAngle}° and ${AppConstants.absoluteMaxAngle}°.';
    }
    if (maxAngle < AppConstants.absoluteMinAngle ||
        maxAngle > AppConstants.absoluteMaxAngle) {
      return 'Maximum angle must be between ${AppConstants.absoluteMinAngle}° and ${AppConstants.absoluteMaxAngle}°.';
    }
    if (minAngle >= maxAngle) {
      return 'Minimum angle ($minAngle°) must be strictly less than maximum angle ($maxAngle°).';
    }
    if (maxAngle - minAngle < 10.0) {
      return 'Motion range must be at least 10 degrees.';
    }
    if (emgThreshold < AppConstants.minEmgThreshold ||
        emgThreshold > AppConstants.maxEmgThreshold) {
      return 'EMG threshold must be between ${AppConstants.minEmgThreshold} and ${AppConstants.maxEmgThreshold}.';
    }
    if (batteryWarningThreshold < 5.0 || batteryWarningThreshold > 50.0) {
      return 'Battery warning threshold must be between 5% and 50%.';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'deviceName': deviceName,
        'minAngle': minAngle,
        'maxAngle': maxAngle,
        'emgThreshold': emgThreshold,
        'batteryWarningThreshold': batteryWarningThreshold,
        'defaultOperatingMode': defaultOperatingMode.displayName,
      };

  factory DeviceSettings.fromJson(Map<String, dynamic> json) {
    return DeviceSettings(
      deviceName:
          json['deviceName'] as String? ?? AppConstants.defaultDeviceName,
      minAngle: (json['minAngle'] as num?)?.toDouble() ??
          AppConstants.defaultMinAngle,
      maxAngle: (json['maxAngle'] as num?)?.toDouble() ??
          AppConstants.defaultMaxAngle,
      emgThreshold: (json['emgThreshold'] as num?)?.toDouble() ??
          AppConstants.defaultEmgThreshold,
      batteryWarningThreshold:
          (json['batteryWarningThreshold'] as num?)?.toDouble() ??
              AppConstants.defaultBatteryWarningThreshold,
      defaultOperatingMode: OperatingMode.fromString(
          json['defaultOperatingMode'] as String? ?? 'AUTO'),
    );
  }
}
