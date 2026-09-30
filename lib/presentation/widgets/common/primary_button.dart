import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

/// Clinical Primary Action Button.
///
/// Features minimum 48dp touch target, tactile state feedback, loading indicator,
/// and web-safe haptic feedback.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final String? tooltip;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 48.0,
    this.tooltip,
  });

  void _handlePress() {
    if (onPressed == null || isLoading) return;
    if (!kIsWeb) {
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}
    }
    onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? AppColors.primaryDark : AppColors.primaryLight);
    final fg = foregroundColor ?? (isDark ? Colors.black : Colors.white);

    final buttonChild = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.labelLarge(color: fg),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    final button = SizedBox(
      height: height,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed != null && !isLoading ? _handlePress : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
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
