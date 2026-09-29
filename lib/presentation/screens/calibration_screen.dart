import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/calibration_provider.dart';
import '../../application/providers/device_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/calibration_state.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CALIBRATION',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (calibState.currentStep != CalibrationStep.idle &&
              calibState.currentStep != CalibrationStep.complete)
            TextButton.icon(
              onPressed: () => calibNotifier.cancelCalibration(),
              icon: const Icon(Icons.cancel, color: AppTheme.crimson, size: 16),
              label: const Text(
                'ABORT',
                style: TextStyle(
                  color: AppTheme.crimson,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Live Hand Visualizer during Calibration
              HandVisualizer(
                currentAngle: telemetry.positionDegrees,
                minAngle: calibState.measuredMinAngle ?? telemetry.minAngle,
                maxAngle: calibState.measuredMaxAngle ?? telemetry.maxAngle,
                handState: telemetry.handState,
                height: 220,
              ),
              const SizedBox(height: 16),

              // 2. Step Progress Stepper / Header
              _buildProgressCard(context, calibState, isDark),
              const SizedBox(height: 16),

              // 3. Endpoint Measurement Cards
              Row(
                children: [
                  Expanded(
                    child: _buildAngleCard(
                      title: 'OPEN LIMIT (MIN)',
                      angle: calibState.measuredMinAngle,
                      isDark: isDark,
                      accentColor: AppTheme.mint,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAngleCard(
                      title: 'CLOSED LIMIT (MAX)',
                      angle: calibState.measuredMaxAngle,
                      isDark: isDark,
                      accentColor: AppTheme.cyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Error banner if any
              if (calibState.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.crimson.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.crimson),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.crimson, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          calibState.errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.crimson,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 5. Context Action Button based on Step
              _buildActionControls(context, calibState, calibNotifier),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(
      BuildContext context, CalibrationState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  state.currentStep.stepTitle.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: AppTheme.cyan,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'STEP ${state.currentStep.stepIndex} OF 3',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF78909C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.currentStep.stepIndex / 3.0,
              minHeight: 6,
              backgroundColor: isDark ? Colors.white10 : Colors.black12,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.cyan),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            state.currentStep.instructions,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAngleCard({
    required String title,
    required double? angle,
    required bool isDark,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: angle != null
              ? accentColor.withAlpha(120)
              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF78909C),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            angle != null ? '${angle.toStringAsFixed(1)}°' : '--.-°',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: angle != null
                  ? accentColor
                  : (isDark ? Colors.white24 : Colors.black26),
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
  ) {
    if (state.isBusy) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Actuating prosthetic servo & measuring endpoint...',
                style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE)),
              ),
            ],
          ),
        ),
      );
    }

    switch (state.currentStep) {
      case CalibrationStep.idle:
        return ElevatedButton.icon(
          onPressed: () => notifier.startCalibration(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.cyan,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: const Icon(Icons.play_arrow),
          label: const Text('START CALIBRATION SEQUENCE'),
        );

      case CalibrationStep.step1OpenPosition:
        return ElevatedButton.icon(
          onPressed: () => notifier.captureOpenPosition(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.mint,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('DRIVE & RECORD OPEN POSITION (0°)'),
        );

      case CalibrationStep.step2ClosedPosition:
        return ElevatedButton.icon(
          onPressed: () => notifier.captureClosePosition(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.cyan,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('DRIVE & RECORD CLOSED POSITION (63°)'),
        );

      case CalibrationStep.step3Saving:
        return ElevatedButton.icon(
          onPressed: state.canSave ? () => notifier.saveCalibration() : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: const Icon(Icons.save),
          label: const Text('SAVE & APPLY CALIBRATED LIMITS'),
        );

      case CalibrationStep.complete:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.mint.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.mint),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, color: AppTheme.mint, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Calibration complete! Physical endpoints verified and synchronized.',
                      style: TextStyle(
                        color: AppTheme.mint,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => notifier.reset(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('RE-CALIBRATE AGAIN'),
            ),
          ],
        );

      case CalibrationStep.failed:
        return ElevatedButton.icon(
          onPressed: () => notifier.startCalibration(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.crimson,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: const Icon(Icons.refresh),
          label: const Text('RETRY CALIBRATION'),
        );
    }
  }
}
