import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Clinical Telemetry Metric Tile.
///
/// Displays real-time measurement telemetry with high-contrast tabular mono numerals,
/// dedicated unit labels, optional progress indicator, and accessibility semantics.
class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData? icon;
  final Color? accentColor;
  final Widget? badge;
  final double? progress;
  final Color? progressColor;
  final String? helperText;
  final VoidCallback? onTap;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.icon,
    this.accentColor,
    this.badge,
    this.progress,
    this.progressColor,
    this.helperText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = accentColor ??
        (isDark ? AppColors.primaryDark : AppColors.primaryLight);

    final tileContent = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: primaryAccent),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTypography.labelSmall(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 2),
                badge!,
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),

          // Primary Numeric Readout Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                        child: Text(
                          value,
                          key: ValueKey<String>(value),
                          style: AppTypography.monoValueLarge(
                              color: primaryAccent),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (unit != null) ...[
                      const SizedBox(width: 2),
                      Text(
                        unit!,
                        style: AppTypography.titleSmall(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (helperText != null) ...[
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    helperText!,
                    style: AppTypography.labelSmall(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ],
          ),

          // Optional Progress Track
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.xs + 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor:
                    isDark ? Colors.white12 : Colors.black.withAlpha(20),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progressColor ?? primaryAccent,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Semantics(
      label: '$label: $value ${unit ?? ""}',
      container: true,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: tileContent,
            )
          : tileContent,
    );
  }
}
