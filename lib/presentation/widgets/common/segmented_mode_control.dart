import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/operating_mode.dart';

/// Clinical Segmented Mode Selector Control.
///
/// Provides tactile mode switching (MANUAL, EMG, AUTO) with high contrast feedback
/// and accessible semantics.
class SegmentedModeControl extends StatelessWidget {
  final OperatingMode currentMode;
  final bool isConnected;
  final ValueChanged<OperatingMode> onModeChanged;

  const SegmentedModeControl({
    super.key,
    required this.currentMode,
    required this.isConnected,
    required this.onModeChanged,
  });

  void _selectMode(OperatingMode mode) {
    if (!isConnected || mode == currentMode) return;
    if (!kIsWeb) {
      try {
        HapticFeedback.selectionClick();
      } catch (_) {}
    }
    onModeChanged(mode);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mode Selector Buttons
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceElevated
                : AppColors.lightSurfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.0,
            ),
          ),
          child: Row(
            children: OperatingMode.values.map((mode) {
              final isSelected = mode == currentMode;
              final accentColor =
                  isDark ? AppColors.primaryDark : AppColors.primaryLight;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Semantics(
                    button: true,
                    selected: isSelected,
                    enabled: isConnected,
                    label: 'Operating mode: ${mode.displayName}',
                    child: InkWell(
                      onTap: isConnected ? () => _selectMode(mode) : null,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                          horizontal: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                  ? AppColors.darkSurface
                                  : AppColors.lightSurface)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isSelected
                                ? (isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primaryLight)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black
                                        .withAlpha(isDark ? 50 : 15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getIconForMode(mode),
                              size: 18,
                              color: isSelected
                                  ? accentColor
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              mode.displayName,
                              style: AppTypography.labelLarge(
                                color: isSelected
                                    ? (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary)
                                    : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Mode Explanation Caption
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text(
            currentMode.description,
            style: AppTypography.bodySmall(
              color:
                  isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIconForMode(OperatingMode mode) {
    switch (mode) {
      case OperatingMode.manual:
        return Icons.pan_tool_alt_outlined;
      case OperatingMode.emg:
        return Icons.sensors;
      case OperatingMode.auto:
        return Icons.sync;
    }
  }
}
