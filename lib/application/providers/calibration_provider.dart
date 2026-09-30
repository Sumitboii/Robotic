import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/calibration_state.dart';
import 'device_providers.dart';
import 'settings_provider.dart';

class CalibrationNotifier extends StateNotifier<CalibrationState> {
  final Ref ref;

  CalibrationNotifier(this.ref) : super(const CalibrationState());

  void startCalibration() {
    final deviceService = ref.read(deviceServiceProvider);
    deviceService.startCalibration();
    state = const CalibrationState(
      currentStep: CalibrationStep.step1OpenPosition,
      measuredMinAngle: null,
      measuredMaxAngle: null,
      errorMessage: null,
      isBusy: false,
    );
  }

  Future<void> moveToOpen() async {
    final deviceService = ref.read(deviceServiceProvider);
    await deviceService.openHand();
  }

  Future<void> moveToClosed() async {
    final deviceService = ref.read(deviceServiceProvider);
    await deviceService.closeHand();
  }

  Future<bool> captureOpenPosition([double? explicitAngle]) async {
    state = state.copyWith(isBusy: true, errorMessage: null);
    try {
      final deviceService = ref.read(deviceServiceProvider);
      final currentTelemetry = deviceService.currentTelemetry;

      // Guard: do not capture while hand is actively moving
      if (explicitAngle == null && currentTelemetry.handState.isMoving) {
        state = state.copyWith(
          isBusy: false,
          errorMessage:
              'Cannot capture: Hand is currently moving. Please wait for position to settle.',
        );
        return false;
      }

      final openAngle = explicitAngle ?? currentTelemetry.positionDegrees;
      state = state.copyWith(
        currentStep: CalibrationStep.step2ClosedPosition,
        measuredMinAngle: openAngle,
        isBusy: false,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Failed to capture OPEN position: $e',
      );
      return false;
    }
  }

  Future<bool> captureClosePosition([double? explicitAngle]) async {
    state = state.copyWith(isBusy: true, errorMessage: null);
    try {
      final deviceService = ref.read(deviceServiceProvider);
      final currentTelemetry = deviceService.currentTelemetry;

      // Guard: do not capture while hand is actively moving
      if (explicitAngle == null && currentTelemetry.handState.isMoving) {
        state = state.copyWith(
          isBusy: false,
          errorMessage:
              'Cannot capture: Hand is currently moving. Please wait for position to settle.',
        );
        return false;
      }

      final closeAngle = explicitAngle ?? currentTelemetry.positionDegrees;
      final minAngle = state.measuredMinAngle ?? 0.0;

      // Validate range (§9)
      if (closeAngle <= minAngle || (closeAngle - minAngle) < 10.0) {
        state = state.copyWith(
          isBusy: false,
          errorMessage:
              'Invalid calibration range: Closed angle (${closeAngle.toStringAsFixed(1)}°) must exceed open angle (${minAngle.toStringAsFixed(1)}°) by at least 10°.',
        );
        return false;
      }

      state = state.copyWith(
        currentStep: CalibrationStep.step3Saving,
        measuredMaxAngle: closeAngle,
        isBusy: false,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Failed to capture CLOSED position: $e',
      );
      return false;
    }
  }

  Future<bool> saveCalibration() async {
    if (!state.canSave) {
      state = state.copyWith(
        errorMessage:
            'Incomplete calibration. Both valid endpoints must be captured.',
      );
      return false;
    }

    state = state.copyWith(isBusy: true);
    try {
      final min = state.measuredMinAngle!;
      final max = state.measuredMaxAngle!;

      // 1. Update active device service
      final deviceService = ref.read(deviceServiceProvider);
      await deviceService.saveCalibrationLimits(min, max);

      // 2. Persist in settings repository
      final currentSettings = ref.read(settingsNotifierProvider).value;
      if (currentSettings != null) {
        final updatedSettings = currentSettings.copyWith(
          minAngle: min,
          maxAngle: max,
        );
        await ref
            .read(settingsNotifierProvider.notifier)
            .saveSettings(updatedSettings);
      }

      state = state.copyWith(
        currentStep: CalibrationStep.complete,
        isBusy: false,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        currentStep: CalibrationStep.failed,
        isBusy: false,
        errorMessage: 'Failed to save calibration: $e',
      );
      return false;
    }
  }

  void cancelCalibration() {
    final deviceService = ref.read(deviceServiceProvider);
    deviceService.cancelCalibration();
    state = const CalibrationState(
      currentStep: CalibrationStep.idle,
      errorMessage: null,
      isBusy: false,
    );
  }

  void reset() {
    state = const CalibrationState();
  }
}

final calibrationNotifierProvider =
    StateNotifierProvider<CalibrationNotifier, CalibrationState>((ref) {
  return CalibrationNotifier(ref);
});
