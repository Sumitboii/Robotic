class AppConstants {
  static const String appTitle = 'Synthera Robotics';
  static const String defaultDeviceName = 'DAKSH-01';

  // Default mechanical limits in degrees
  static const double defaultMinAngle = 0.0;
  static const double defaultMaxAngle = 63.0;

  // Mechanical hard constraints
  static const double absoluteMinAngle = 0.0;
  static const double absoluteMaxAngle = 180.0;

  // EMG signal bounds
  static const double defaultEmgThreshold = 120.0;
  static const double minEmgThreshold = 50.0;
  static const double maxEmgThreshold = 250.0;
  static const double emgBaselineMin = 30.0;
  static const double emgBaselineMax = 70.0;

  // Battery parameters
  static const double defaultBatteryWarningThreshold = 20.0;
  static const double initialBatteryPercentage = 82.0;

  // Simulation timing
  static const int telemetryUpdateIntervalMs = 50; // 20 Hz
  static const int emgGraphWindowSamples = 60;
  static const double defaultMovementSpeedDegPerSec = 45.0; // degrees / sec
}
