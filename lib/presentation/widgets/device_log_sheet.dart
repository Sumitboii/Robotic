import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/device_log_entry.dart';

/// Clinical Device Event Log Sheet.
class DeviceLogSheet extends StatelessWidget {
  final List<DeviceLogEntry> logs;
  final VoidCallback onClear;

  const DeviceLogSheet({
    super.key,
    required this.logs,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeFormat = DateFormat('HH:mm:ss.SSS');

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(
                top: AppSpacing.sm, bottom: AppSpacing.xs),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.terminal,
                      size: 20,
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'DEVICE EVENT LOGS (${logs.length})',
                      style: AppTypography.titleMedium(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Clear Logs',
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: onClear,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),

          // Event Log Stream List
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Text(
                      'No device log events recorded yet.',
                      style: AppTypography.bodyMedium(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      Color levelColor;
                      switch (log.level) {
                        case LogLevel.info:
                          levelColor = isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight;
                          break;
                        case LogLevel.warning:
                          levelColor = isDark
                              ? AppColors.warningDark
                              : AppColors.warningLight;
                          break;
                        case LogLevel.error:
                          levelColor = AppColors.emergencyRed;
                          break;
                        case LogLevel.command:
                          levelColor = isDark
                              ? AppColors.successDark
                              : AppColors.successLight;
                          break;
                        case LogLevel.telemetry:
                          levelColor =
                              isDark ? AppColors.blueDark : AppColors.blueLight;
                          break;
                      }

                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.xs + 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              timeFormat.format(log.timestamp),
                              style: TextStyle(
                                fontFamily: AppTypography.monoFontFamily,
                                fontFamilyFallback:
                                    AppTypography.monoFontFallbacks,
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: levelColor.withAlpha(isDark ? 40 : 25),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xs),
                                border: Border.all(
                                  color:
                                      levelColor.withAlpha(isDark ? 100 : 70),
                                ),
                              ),
                              child: Text(
                                log.level.name.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: AppTypography.monoFontFamily,
                                  fontFamilyFallback:
                                      AppTypography.monoFontFallbacks,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: levelColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                log.message,
                                style: TextStyle(
                                  fontFamily: AppTypography.monoFontFamily,
                                  fontFamilyFallback:
                                      AppTypography.monoFontFallbacks,
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
