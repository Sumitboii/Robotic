import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

/// Clinical Emergency Danger Button.
///
/// Prominent, high-contrast emergency actuator button with a minimum 56dp height,
/// dedicated red styling, high priority tactile feedback, and accessible emergency semantics.
class DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isFullWidth;
  final double height;
  final bool isActive;
  final String? tooltip;

  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.stop_circle,
    this.isFullWidth = true,
    this.height = 56.0,
    this.isActive = false,
    this.tooltip,
  });

  void _handlePress() {
    if (onPressed == null) return;
    if (!kIsWeb) {
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
    }
    onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isActive
        ? AppColors.emergencyRed
        : (isDark
            ? AppColors.emergencyRedBgDark
            : AppColors.emergencyRedBgLight);

    final fg = isActive
        ? Colors.white
        : (isDark ? const Color(0xFFFF6B6B) : AppColors.emergencyRed);

    final borderColor = isActive ? Colors.white : AppColors.emergencyRed;

    final buttonChild = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 22, color: fg),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.uiFontFamily,
              fontFamilyFallback: AppTypography.uiFontFallbacks,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: fg,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final button = SizedBox(
      height: height,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed != null ? _handlePress : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: isActive ? 4 : 0,
          side: BorderSide(color: borderColor, width: 2.0),
          disabledBackgroundColor: isDark
              ? AppColors.darkSurfaceElevated
              : AppColors.lightSurfaceElevated,
          disabledForegroundColor:
              isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        child: buttonChild,
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
