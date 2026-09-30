import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Clinical Status Chip.
///
/// Multi-modal indicator (Color + Icon + Text) to guarantee WCAG compliance
/// and ensure meaning is never conveyed by color alone.
class StatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool isPulsing;
  final VoidCallback? onTap;

  const StatusChip({
    super.key,
    required this.label,
    this.icon,
    required this.color,
    this.isPulsing = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs - 1,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 45 : 30),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: color.withAlpha(isDark ? 140 : 100),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: AppSpacing.xs),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: AppSpacing.xs + 1),
          ],
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelSmall(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      label: 'Status: $label',
      container: true,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: chip,
            )
          : chip,
    );
  }
}
