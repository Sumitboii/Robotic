import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/operating_mode.dart';
import 'common/app_card.dart';
import 'common/segmented_mode_control.dart';

/// Clinical Operating Mode Selector.
///
/// Wraps [SegmentedModeControl] in an [AppCard] with clinical header.
class ModeSelector extends StatelessWidget {
  final OperatingMode currentMode;
  final bool isConnected;
  final ValueChanged<OperatingMode> onModeChanged;

  const ModeSelector({
    super.key,
    required this.currentMode,
    required this.isConnected,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OPERATING MODE',
                style: AppTypography.labelLarge(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.blueDark : AppColors.blueLight)
                      .withAlpha(isDark ? 45 : 30),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(
                    color: (isDark ? AppColors.blueDark : AppColors.blueLight)
                        .withAlpha(isDark ? 120 : 80),
                  ),
                ),
                child: Text(
                  currentMode.displayName.toUpperCase(),
                  style: AppTypography.labelSmall(
                    color: isDark ? AppColors.blueDark : AppColors.blueLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedModeControl(
            currentMode: currentMode,
            isConnected: isConnected,
            onModeChanged: onModeChanged,
          ),
        ],
      ),
    );
  }
}
