import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/hand_state.dart';
import 'common/app_card.dart';
import 'common/danger_button.dart';

/// Clinical Actuator Control Panel.
///
/// Houses OPEN, CLOSE, and priority STOP controls with clear visual
/// hierarchy, disabled state annotations, and tactile haptic confirmation.
class ControlPanel extends StatelessWidget {
  final HandState handState;
  final bool isConnected;
  final bool isBatteryDepleted;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final VoidCallback onStop;

  const ControlPanel({
    super.key,
    required this.handState,
    required this.isConnected,
    this.isBatteryDepleted = false,
    required this.onOpen,
    required this.onClose,
    required this.onStop,
  });

  void _triggerHaptic() {
    if (!kIsWeb) {
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = isConnected && !isBatteryDepleted;

    final isOpening = handState == HandState.opening;
    final isClosing = handState == HandState.closing;
    final isStopped = handState == HandState.stopped;

    String? disabledReason;
    if (!isConnected) {
      disabledReason = 'DISCONNECTED';
    } else if (isBatteryDepleted) {
      disabledReason = 'BATTERY DEPLETED (0%)';
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'ACTUATOR CONTROLS',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              if (disabledReason != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emergencyRed.withAlpha(isDark ? 50 : 30),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: Border.all(
                      color: AppColors.emergencyRed.withAlpha(120),
                    ),
                  ),
                  child: Text(
                    disabledReason,
                    style: AppTypography.labelSmall(
                      color: AppColors.emergencyRed,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Primary Directional Motion Controls (OPEN / CLOSE)
          Row(
            children: [
              // OPEN BUTTON
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: enabled
                        ? () {
                            _triggerHaptic();
                            onOpen();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOpening
                          ? (isDark
                              ? AppColors.successDark
                              : AppColors.successLight)
                          : (isDark
                              ? const Color(0xFF132A22)
                              : const Color(0xFFE6F4EA)),
                      foregroundColor: isOpening
                          ? Colors.black
                          : (isDark
                              ? AppColors.successDark
                              : const Color(0xFF137333)),
                      elevation: isOpening ? 3 : 0,
                      side: BorderSide(
                        color: isOpening
                            ? (isDark
                                ? AppColors.successDark
                                : AppColors.successLight)
                            : (isDark
                                ? AppColors.successDark.withAlpha(90)
                                : const Color(0xFF81C995)),
                        width: isOpening ? 2.0 : 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                    label: const Text(
                      'OPEN',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // CLOSE BUTTON
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: enabled
                        ? () {
                            _triggerHaptic();
                            onClose();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isClosing
                          ? (isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight)
                          : (isDark
                              ? const Color(0xFF0E2533)
                              : const Color(0xFFE0F2FE)),
                      foregroundColor: isClosing
                          ? Colors.black
                          : (isDark
                              ? AppColors.primaryDark
                              : const Color(0xFF0369A1)),
                      elevation: isClosing ? 3 : 0,
                      side: BorderSide(
                        color: isClosing
                            ? (isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight)
                            : (isDark
                                ? AppColors.primaryDark.withAlpha(90)
                                : const Color(0xFF7DD3FC)),
                        width: isClosing ? 2.0 : 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    label: const Text(
                      'CLOSE',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // EMERGENCY STOP BUTTON (Distinct Clinical Red, Minimum 56dp Height)
          DangerButton(
            label: 'STOP',
            isActive: isStopped,
            height: 56.0,
            onPressed: isConnected ? onStop : null,
            tooltip: 'Halt all motor drive actuation immediately',
          ),
        ],
      ),
    );
  }
}
