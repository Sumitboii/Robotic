import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/app_update_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/platform_downloader.dart';

/// Shows the in-app update popup dialog
Future<void> showAppUpdateDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const AppUpdateDialog(),
  );
}

/// A dedicated popup dialog that prompts users when an update is available,
/// animates the download and installation in-app, and provides an instant
/// reload/restart action to see the new changes immediately.
class AppUpdateDialog extends ConsumerWidget {
  const AppUpdateDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateInfo = ref.watch(appUpdateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF161C24) : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final isInstalled = updateInfo.isInstalled;
    final isUpdating = updateInfo.isUpdating;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isInstalled
              ? AppColors.successDark.withAlpha(160)
              : (isDark ? AppColors.primaryDark : AppColors.primaryLight).withAlpha(100),
          width: 1.5,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isInstalled
                              ? AppColors.successDark
                              : (isDark ? AppColors.primaryDark : AppColors.primaryLight))
                          .withAlpha(35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isInstalled ? Icons.verified : Icons.system_update,
                      color: isInstalled
                          ? AppColors.successDark
                          : (isDark ? AppColors.primaryDark : AppColors.primaryLight),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isInstalled ? 'UPDATE INSTALLED!' : 'NEW UPDATE AVAILABLE',
                              style: TextStyle(
                                fontFamily: AppTypography.monoFontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isInstalled
                                    ? AppColors.successDark.withAlpha(40)
                                    : Colors.orange.withAlpha(40),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isInstalled ? 'v1.3.1' : 'v${updateInfo.latestVersion}',
                                style: TextStyle(
                                  fontFamily: AppTypography.monoFontFamily,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isInstalled ? AppColors.successDark : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isInstalled
                              ? 'Version 1.3.1 active. All features upgraded.'
                              : 'Prosthetic hand simulator update is ready to install.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress Bar while updating or completed
              if (isUpdating || isInstalled) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: isInstalled ? 1.0 : updateInfo.updateProgress,
                    minHeight: 10,
                    backgroundColor: isDark ? Colors.black38 : Colors.black12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isInstalled ? AppColors.successDark : AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        updateInfo.statusMessage,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isInstalled
                              ? AppColors.successDark
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                      ),
                    ),
                    Text(
                      '${((isInstalled ? 1.0 : updateInfo.updateProgress) * 100).toInt()}%',
                      style: TextStyle(
                        fontFamily: AppTypography.monoFontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isInstalled
                            ? AppColors.successDark
                            : (isDark ? AppColors.primaryDark : AppColors.primaryLight),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // What's New Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F141C) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.new_releases,
                          size: 14,
                          color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'WHAT\'S IN THIS UPDATE:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...updateInfo.changeLog.map(
                      (change) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                change,
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.3,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              if (!isInstalled) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isUpdating ? null : () => Navigator.of(context).pop(),
                        child: const Text('Remind Later'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark ? AppColors.primaryDark : AppColors.primaryLight,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: isUpdating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.download, size: 18),
                        label: Text(
                          isUpdating ? 'UPDATING...' : 'UPDATE APP NOW',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: isUpdating
                            ? null
                            : () => ref.read(appUpdateProvider.notifier).performUpdate(),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successDark,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text(
                          'RELOAD & SEE CHANGES',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          triggerAppReload();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
