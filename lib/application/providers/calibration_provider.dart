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

  Future<void> captureOpenPosition() async {
    state = state.copyWith(isBusy: true, errorMessage: null);
    try {
      final deviceService = ref.read(deviceServiceProvider);
      final openAngle = await deviceService.captureCalibrationOpenPosition();
      if (!mounted) return;
      state = state.copyWith(
        currentStep: CalibrationStep.step2ClosedPosition,
        measuredMinAngle: openAngle,
        isBusy: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Failed to capture OPEN position: $e',
      );
    }
  }

  Future<void> captureClosePosition() async {
    state = state.copyWith(isBusy: true, errorMessage: null);
    try {
      final deviceService = ref.read(deviceServiceProvider);
      final closeAngle = await deviceService.captureCalibrationClosePosition();
      if (!mounted) return;

      if (state.measuredMinAngle != null &&
          closeAngle <= state.measuredMinAngle!) {
        state = state.copyWith(
          isBusy: false,
          errorMessage:
              'Closed position ($closeAngle°) must be greater than open position (${state.measuredMinAngle}°).',
        );
        return;
      }

      state = state.copyWith(
        currentStep: CalibrationStep.step3Saving,
        measuredMaxAngle: closeAngle,
        isBusy: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Failed to capture CLOSED position: $e',
      );
    }
  }

  Future<bool> saveCalibration() async {
    if (!state.canSave) {
      state = state.copyWith(
        errorMessage:
            'Incomplete calibration. Both endpoints must be captured.',
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

      // 2. Persist in settings
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

      if (mounted) {
        state = state.copyWith(
          currentStep: CalibrationStep.complete,
          isBusy: false,
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          currentStep: CalibrationStep.failed,
          isBusy: false,
          errorMessage: 'Failed to save calibration: $e',
        );
      }
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
