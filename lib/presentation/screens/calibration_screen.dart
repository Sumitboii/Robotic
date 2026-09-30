import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/calibration_provider.dart';
import '../../application/providers/device_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/calibration_state.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/metric_tile.dart';
import '../widgets/common/primary_button.dart';
import '../widgets/common/status_chip.dart';
import '../widgets/hand_visualizer.dart';

class CalibrationScreen extends ConsumerWidget {
  const CalibrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calibState = ref.watch(calibrationNotifierProvider);
    final calibNotifier = ref.read(calibrationNotifierProvider.notifier);
    final telemetryAsync = ref.watch(telemetryStreamProvider);
    final deviceService = ref.watch(deviceServiceProvider);

    final telemetry = telemetryAsync.value ?? deviceService.currentTelemetry;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isCalibrating = calibState.currentStep != CalibrationStep.idle &&
        calibState.currentStep != CalibrationStep.complete;

    final isHandMoving = telemetry.handState.isMoving;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CALIBRATION'),
        actions: [
          if (isCalibrating)
            TextButton.icon(
              onPressed: () => calibNotifier.cancelCalibration(),
              icon: const Icon(Icons.cancel,
                  color: AppColors.emergencyRed, size: 16),
              label: const Text(
                'ABORT',
                style: TextStyle(
                  color: AppColors.emergencyRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            if (isWide) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: SingleChildScrollView(
                    padding: AppSpacing.edgeInsetsScreenWide,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Live Kinematics Preview
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              HandVisualizer(
                                currentAngle: telemetry.positionDegrees,
                                minAngle: calibState.measuredMinAngle ??
                                    telemetry.minAngle,
                                maxAngle: calibState.measuredMaxAngle ??
                                    telemetry.maxAngle,
                                handState: telemetry.handState,
                                height: 320,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: MetricTile(
                                      label: 'OPEN LIMIT (MIN)',
                                      value: calibState.measuredMinAngle != null
                                          ? calibState.measuredMinAngle!
                                              .toStringAsFixed(1)
                                          : '--.-',
                                      unit: '°',
                                      icon: Icons.lock_open,
                                      accentColor: isDark
                                          ? AppColors.successDark
                                          : AppColors.successLight,
                                      badge: calibState.measuredMinAngle != null
                                          ? StatusChip(
                                              label: 'CAPTURED',
                                              icon: Icons.check,
                                              color: isDark
                                                  ? AppColors.successDark
                                                  : AppColors.successLight,
                                            )
                                          : null,
                                      helperText: 'Target: 0.0°',
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: MetricTile(
                                      label: 'CLOSED LIMIT (MAX)',
                                      value: calibState.measuredMaxAngle != null
                                          ? calibState.measuredMaxAngle!
                                              .toStringAsFixed(1)
                                          : '--.-',
                                      unit: '°',
                                      icon: Icons.lock_outline,
                                      accentColor: isDark
                                          ? AppColors.primaryDark
                                          : AppColors.primaryLight,
                                      badge: calibState.measuredMaxAngle != null
                                          ? StatusChip(
                                              label: 'CAPTURED',
                                              icon: Icons.check,
                                              color: isDark
                                                  ? AppColors.primaryDark
                                                  : AppColors.primaryLight,
                                            )
                                          : null,
                                      helperText: 'Target: 63.0°',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xl),

                        // Right Column: Stepper & Controls
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildStepperCard(context, calibState, isDark),
                              const SizedBox(height: AppSpacing.md),
                              if (calibState.errorMessage != null) ...[
                                _buildErrorBanner(calibState.errorMessage!),
                                const SizedBox(height: AppSpacing.md),
                              ],
                              _buildActionControls(
                                context,
                                calibState,
                                calibNotifier,
                                isDark,
                                isHandMoving,
                                telemetry.positionDegrees,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Mobile Column Layout (< 900px)
            return SingleChildScrollView(
              padding: AppSpacing.edgeInsetsScreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Live Hand Visualizer
                  HandVisualizer(
                    currentAngle: telemetry.positionDegrees,
                    minAngle: calibState.measuredMinAngle ?? telemetry.minAngle,
                    maxAngle: calibState.measuredMaxAngle ?? telemetry.maxAngle,
                    handState: telemetry.handState,
                    height: 230,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 2. Clinical Stepper Progress Header
                  _buildStepperCard(context, calibState, isDark),
                  const SizedBox(height: AppSpacing.md),

                  // 3. Endpoint Measurement Tiles
                  Row(
                    children: [
                      Expanded(
                        child: MetricTile(
                          label: 'OPEN LIMIT (MIN)',
                          value: calibState.measuredMinAngle != null
                              ? calibState.measuredMinAngle!.toStringAsFixed(1)
                              : '--.-',
                          unit: '°',
                          icon: Icons.lock_open,
                          accentColor: isDark
                              ? AppColors.successDark
                              : AppColors.successLight,
                          badge: calibState.measuredMinAngle != null
                              ? StatusChip(
                                  label: 'CAPTURED',
                                  icon: Icons.check,
                                  color: isDark
                                      ? AppColors.successDark
                                      : AppColors.successLight,
                                )
                              : null,
                          helperText: 'Target: 0.0°',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: MetricTile(
                          label: 'CLOSED LIMIT (MAX)',
                          value: calibState.measuredMaxAngle != null
                              ? calibState.measuredMaxAngle!.toStringAsFixed(1)
                              : '--.-',
                          unit: '°',
                          icon: Icons.lock_outline,
                          accentColor: isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight,
                          badge: calibState.measuredMaxAngle != null
                              ? StatusChip(
                                  label: 'CAPTURED',
                                  icon: Icons.check,
                                  color: isDark
                                      ? AppColors.primaryDark
                                      : AppColors.primaryLight,
                                )
                              : null,
                          helperText: 'Target: 63.0°',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 4. Error Banner
                  if (calibState.errorMessage != null) ...[
                    _buildErrorBanner(calibState.errorMessage!),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // 5. Context Action Controls
                  _buildActionControls(
                    context,
                    calibState,
                    calibNotifier,
                    isDark,
                    isHandMoving,
                    telemetry.positionDegrees,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepperCard(
    BuildContext context,
    CalibrationState state,
    bool isDark,
  ) {
    final currentStepIdx = state.currentStep.stepIndex;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'CALIBRATION WIZARD',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              StatusChip(
                label: 'STEP ${state.currentStep.stepIndex} OF 3',
                icon: Icons.timeline,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 3-Stage Progress Line with Numbered Nodes
          Row(
            children: [
              Expanded(
                  child:
                      _buildStepNode(1, 'Open Limit', currentStepIdx, isDark)),
              _buildStepConnector(1 < currentStepIdx, isDark),
              Expanded(
                  child: _buildStepNode(
                      2, 'Closed Limit', currentStepIdx, isDark)),
              _buildStepConnector(2 < currentStepIdx, isDark),
              Expanded(
                  child: _buildStepNode(3, 'Save', currentStepIdx, isDark)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Instruction Text
          Text(
            state.currentStep.stepTitle.toUpperCase(),
            style: AppTypography.labelLarge(
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            state.currentStep.instructions,
            style: AppTypography.bodySmall(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode(
    int step,
    String title,
    int currentStep,
    bool isDark,
  ) {
    final isDone = step < currentStep;
    final isCurrent = step == currentStep;
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? (isDark ? AppColors.successDark : AppColors.successLight)
                : (isCurrent
                    ? primaryColor
                    : (isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated)),
            border: Border.all(
              color: isDone
                  ? (isDark ? AppColors.successDark : AppColors.successLight)
                  : (isCurrent
                      ? primaryColor
                      : (isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder)),
              width: 1.5,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '$step',
                    style: TextStyle(
                      fontFamily: AppTypography.monoFontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isCurrent
                          ? (isDark ? Colors.black : Colors.white)
                          : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: AppTypography.labelSmall(
            color: isCurrent
                ? (isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary)
                : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isDone, bool isDark) {
    return Container(
      width: 16,
      height: 2,
      margin: const EdgeInsets.only(bottom: 14),
      color: isDone
          ? (isDark ? AppColors.successDark : AppColors.successLight)
          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.emergencyRed.withAlpha(40),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.emergencyRed),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.emergencyRed, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.emergencyRed,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionControls(
    BuildContext context,
    CalibrationState state,
    CalibrationNotifier notifier,
    bool isDark,
    bool isHandMoving,
    double currentPosition,
  ) {
    if (state.isBusy) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Communicating with prosthetic hardware...',
                style: AppTypography.bodySmall(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    switch (state.currentStep) {
      case CalibrationStep.idle:
        return PrimaryButton(
          label: 'START CALIBRATION SEQUENCE',
          icon: Icons.play_arrow,
          height: 52,
          onPressed: () => notifier.startCalibration(),
        );

      case CalibrationStep.step1OpenPosition:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => notifier.moveToOpen(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Move to OPEN'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton(
                    label: isHandMoving
                        ? 'Moving (${currentPosition.toStringAsFixed(0)}°)...'
                        : 'Capture OPEN (${currentPosition.toStringAsFixed(1)}°)',
                    icon: Icons.check_circle_outline,
                    height: 48,
                    backgroundColor:
                        isDark ? AppColors.successDark : AppColors.successLight,
                    foregroundColor: Colors.white,
                    onPressed: isHandMoving
                        ? null
                        : () => notifier.captureOpenPosition(currentPosition),
                  ),
                ),
              ],
            ),
          ],
        );

      case CalibrationStep.step2ClosedPosition:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => notifier.moveToClosed(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Move to CLOSED'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton(
                    label: isHandMoving
                        ? 'Moving (${currentPosition.toStringAsFixed(0)}°)...'
                        : 'Capture CLOSED (${currentPosition.toStringAsFixed(1)}°)',
                    icon: Icons.check_circle_outline,
                    height: 48,
                    backgroundColor:
                        isDark ? AppColors.primaryDark : AppColors.primaryLight,
                    foregroundColor: Colors.white,
                    onPressed: isHandMoving
                        ? null
                        : () => notifier.captureClosePosition(currentPosition),
                  ),
                ),
              ],
            ),
          ],
        );

      case CalibrationStep.step3Saving:
        final minAngle = state.measuredMinAngle ?? 0.0;
        final maxAngle = state.measuredMaxAngle ?? 63.0;
        final range = maxAngle - minAngle;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.blueDark : AppColors.blueLight)
                    .withAlpha(30),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isDark ? AppColors.blueDark : AppColors.blueLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CALIBRATION SUMMARY',
                    style: AppTypography.labelMedium(
                      color: isDark ? AppColors.blueDark : AppColors.blueLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Open Limit: ${minAngle.toStringAsFixed(1)}°  |  Closed Limit: ${maxAngle.toStringAsFixed(1)}°  |  Total Range: ${range.toStringAsFixed(1)}°',
                    style: AppTypography.bodySmall(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'SAVE & APPLY CALIBRATED LIMITS',
              icon: Icons.save,
              height: 52,
              backgroundColor:
                  isDark ? AppColors.blueDark : AppColors.blueLight,
              foregroundColor: Colors.white,
              onPressed:
                  state.canSave ? () => notifier.saveCalibration() : null,
            ),
          ],
        );

      case CalibrationStep.complete:
        final minAngle = state.measuredMinAngle ?? 0.0;
        final maxAngle = state.measuredMaxAngle ?? 63.0;
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.successDark : AppColors.successLight)
                    .withAlpha(40),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color:
                      isDark ? AppColors.successDark : AppColors.successLight,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified,
                    color:
                        isDark ? AppColors.successDark : AppColors.successLight,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Calibration Complete! Measured limits (${minAngle.toStringAsFixed(1)}° to ${maxAngle.toStringAsFixed(1)}°) applied and persisted.',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.successDark
                            : AppColors.successLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'RE-CALIBRATE AGAIN',
              icon: Icons.refresh,
              height: 48,
              onPressed: () => notifier.reset(),
            ),
          ],
        );

      case CalibrationStep.failed:
        return PrimaryButton(
          label: 'RETRY CALIBRATION',
          icon: Icons.refresh,
          height: 52,
          backgroundColor: AppColors.emergencyRed,
          foregroundColor: Colors.white,
          onPressed: () => notifier.startCalibration(),
        );
    }
  }
}
