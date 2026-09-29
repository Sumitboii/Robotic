enum OperatingMode {
  manual,
  emg,
  auto;

  String get displayName {
    switch (this) {
      case OperatingMode.manual:
        return 'MANUAL';
      case OperatingMode.emg:
        return 'EMG';
      case OperatingMode.auto:
        return 'AUTO';
    }
  }

  String get description {
    switch (this) {
      case OperatingMode.manual:
        return 'Direct manual control (OPEN / CLOSE / STOP)';
      case OperatingMode.emg:
        return 'Bio-signal contraction threshold edge control';
      case OperatingMode.auto:
        return 'Automated periodic open/hold/close cycle';
    }
  }

  static OperatingMode fromString(String value) {
    switch (value.toUpperCase()) {
      case 'MANUAL':
        return OperatingMode.manual;
      case 'EMG':
        return OperatingMode.emg;
      case 'AUTO':
        return OperatingMode.auto;
      default:
        return OperatingMode.manual;
    }
  }
}
