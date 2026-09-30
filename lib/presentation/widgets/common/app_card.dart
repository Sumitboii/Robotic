import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Clinical Card container with consistent borders, padding, and elevation.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final String? title;
  final Widget? leading;
  final Widget? trailing;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final double? borderRadius;
  final String? semanticsLabel;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.title,
    this.leading,
    this.trailing,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final border =
        borderColor ?? (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final radius = borderRadius ?? AppRadius.lg;

    final content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: border,
          width: borderWidth ?? 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || leading != null || trailing != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: AppTypography.labelLarge(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          Padding(
            padding: padding ?? AppSpacing.edgeInsetsCard,
            child: child,
          ),
        ],
      ),
    );

    if (semanticsLabel != null) {
      return Semantics(
        label: semanticsLabel,
        container: true,
        child: content,
      );
    }
    return content;
  }
}
