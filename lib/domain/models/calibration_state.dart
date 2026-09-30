enum CalibrationStep {
  idle,
  step1OpenPosition,
  step2ClosedPosition,
  step3Saving,
  complete,
  failed;

  String get stepTitle {
    switch (this) {
      case CalibrationStep.idle:
        return 'Calibration Ready';
      case CalibrationStep.step1OpenPosition:
        return 'Step 1: Set OPEN Position';
      case CalibrationStep.step2ClosedPosition:
        return 'Step 2: Set CLOSED Position';
      case CalibrationStep.step3Saving:
        return 'Step 3: Verifying & Saving Limits';
      case CalibrationStep.complete:
        return 'Calibration Complete';
      case CalibrationStep.failed:
        return 'Calibration Incomplete / Failed';
    }
  }

  String get instructions {
    switch (this) {
      case CalibrationStep.idle:
        return 'Press "Start Calibration" to begin mechanical limit calibration.';
      case CalibrationStep.step1OpenPosition:
        return 'Command hand to OPEN position. Once position settles, capture the zero reference angle.';
      case CalibrationStep.step2ClosedPosition:
        return 'Command hand to CLOSED position. Once settled, capture the maximum stroke angle.';
      case CalibrationStep.step3Saving:
        return 'Validating physical range and saving mechanical limits to persistent storage.';
      case CalibrationStep.complete:
        return 'Mechanical limits verified and saved successfully.';
      case CalibrationStep.failed:
        return 'Calibration aborted or invalid mechanical range detected. Please retry.';
    }
  }

  int get stepIndex {
    switch (this) {
      case CalibrationStep.idle:
        return 0;
      case CalibrationStep.step1OpenPosition:
        return 1;
      case CalibrationStep.step2ClosedPosition:
        return 2;
      case CalibrationStep.step3Saving:
      case CalibrationStep.complete:
      case CalibrationStep.failed:
        return 3;
    }
  }
}

class CalibrationState {
  final CalibrationStep currentStep;
  final double? measuredMinAngle;
  final double? measuredMaxAngle;
  final String? errorMessage;
  final bool isBusy;

  const CalibrationState({
    this.currentStep = CalibrationStep.idle,
    this.measuredMinAngle,
    this.measuredMaxAngle,
    this.errorMessage,
    this.isBusy = false,
  });

  bool get isComplete => currentStep == CalibrationStep.complete;
  bool get canSave =>
      measuredMinAngle != null &&
      measuredMaxAngle != null &&
      measuredMinAngle! < measuredMaxAngle! &&
      (measuredMaxAngle! - measuredMinAngle!) >= 10.0;

  CalibrationState copyWith({
    CalibrationStep? currentStep,
    double? measuredMinAngle,
    double? measuredMaxAngle,
    String? errorMessage,
    bool? isBusy,
  }) {
    return CalibrationState(
      currentStep: currentStep ?? this.currentStep,
      measuredMinAngle: measuredMinAngle ?? this.measuredMinAngle,
      measuredMaxAngle: measuredMaxAngle ?? this.measuredMaxAngle,
      errorMessage: errorMessage,
      isBusy: isBusy ?? this.isBusy,
    );
  }
}
