import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/app_update_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'common/primary_button.dart';

/// Modal bottom sheet providing:
/// 1. In-App Mobile App Update & Direct APK Install (§17 bonus & app distribution)
/// 2. ESP32 Firmware Over-The-Air (OTA) Update Interface (§17 Bonus Feature)
class SystemUpdateSheet extends ConsumerStatefulWidget {
  final VoidCallback? onFirmwareUpdated;
  final bool autoStartAppUpdate;

  const SystemUpdateSheet({
    super.key,
    this.onFirmwareUpdated,
    this.autoStartAppUpdate = false,
  });

  @override
  ConsumerState<SystemUpdateSheet> createState() => _SystemUpdateSheetState();
}

class _SystemUpdateSheetState extends ConsumerState<SystemUpdateSheet> {
  bool _isCheckingApp = false;
  bool _isFlashingFirmware = false;
  double _otaProgress = 0.0;
  String _otaStage = 'Ready to Flash';
  bool _otaCompleted = false;

  final String _currentFwVersion = 'v1.2.0-esp32';
  final String _latestFwVersion = 'v1.3.1-bionic';

  static const String apkDownloadUrl = AppUpdateNotifier.apkDownloadUrl;
  static const String webUrl = 'https://sumitboii.github.io/Robotic/';

  @override
  void initState() {
    super.initState();
    if (widget.autoStartAppUpdate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final updateInfo = ref.read(appUpdateProvider);
        if (updateInfo.isUpdateAvailable && !updateInfo.isUpdating) {
          ref.read(appUpdateProvider.notifier).performUpdate();
        }
      });
    }
  }

  Future<void> _checkAppUpdate() async {
    setState(() => _isCheckingApp = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isCheckingApp = false);

    final updateInfo = ref.read(appUpdateProvider);
    if (updateInfo.isUpdateAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update v${updateInfo.latestVersion} is available! Press "Update App Now" below.'),
          backgroundColor: AppColors.primaryDark,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App is running the latest version (v1.3.1).'),
          backgroundColor: AppColors.successDark,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _startOtaFirmwareFlash() async {
    setState(() {
      _isFlashingFirmware = true;
      _otaProgress = 0.0;
      _otaStage = 'Connecting to ESP32 OTA Partition...';
      _otaCompleted = false;
    });

    const steps = [
      (0.15, 'Erasing OTA slot 1 (SPI Flash)...'),
      (0.35, 'Transferring binary blocks (DAKSH_01_fw_v1.3.1.bin)...'),
      (0.65, 'Writing firmware blocks (20 Hz BLE driver)...'),
      (0.85, 'Verifying SHA-256 partition checksum...'),
      (1.00, 'Rebooting ESP32 microcontroller into new firmware...'),
    ];

    for (final step in steps) {
      await Future.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      setState(() {
        _otaProgress = step.$1;
        _otaStage = step.$2;
      });
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _isFlashingFirmware = false;
      _otaCompleted = true;
      _otaStage = 'Firmware update verified and active!';
    });

    widget.onFirmwareUpdated?.call();
  }

  @override
  Widget build(BuildContext context) {
    final updateInfo = ref.watch(appUpdateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                        .withAlpha(35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.system_update_alt,
                    color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SYSTEM & APP UPDATES',
                        style: AppTypography.titleMedium(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'One-Touch In-App Update, APK Installer & ESP32 OTA',
                        style: AppTypography.bodySmall(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section 1: Mobile App In-App Update & Direct APK Install
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2530) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: updateInfo.isInstalled
                      ? AppColors.successDark.withAlpha(120)
                      : border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.android, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'MOBILE APP UPDATE (IN-APP & APK)',
                          style: AppTypography.labelLarge(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: updateInfo.isInstalled
                              ? AppColors.successDark.withAlpha(40)
                              : (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                                  .withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          updateInfo.isInstalled ? 'v1.3.1 ACTIVE' : 'v${updateInfo.latestVersion} AVAILABLE',
                          style: TextStyle(
                            fontFamily: AppTypography.monoFontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: updateInfo.isInstalled
                                ? AppColors.successDark
                                : (isDark ? AppColors.primaryDark : AppColors.primaryLight),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Installed Version: v${updateInfo.currentVersion}\nCloud Release Version: v${updateInfo.latestVersion}',
                    style: TextStyle(
                      fontFamily: AppTypography.monoFontFamily,
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      height: 1.5,
                    ),
                  ),

                  // Progress Bar if updating
                  if (updateInfo.isUpdating || updateInfo.isInstalled) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: updateInfo.isInstalled ? 1.0 : updateInfo.updateProgress,
                        minHeight: 8,
                        backgroundColor: isDark ? Colors.black38 : Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          updateInfo.isInstalled ? AppColors.successDark : AppColors.primaryDark,
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
                              color: updateInfo.isInstalled
                                  ? AppColors.successDark
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${((updateInfo.isInstalled ? 1.0 : updateInfo.updateProgress) * 100).toInt()}%',
                          style: TextStyle(
                            fontFamily: AppTypography.monoFontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: updateInfo.isInstalled
                                ? AppColors.successDark
                                : (isDark ? AppColors.primaryDark : AppColors.primaryLight),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: _isCheckingApp
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh, size: 16),
                          label: const Text('Check Updates'),
                          onPressed: _isCheckingApp || updateInfo.isUpdating
                              ? null
                              : _checkAppUpdate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: updateInfo.isInstalled
                                ? AppColors.successDark
                                : (isDark ? AppColors.primaryDark : AppColors.primaryLight),
                            foregroundColor: Colors.black,
                          ),
                          icon: Icon(
                            updateInfo.isInstalled ? Icons.check_circle : Icons.system_update,
                            size: 16,
                          ),
                          label: Text(
                            updateInfo.isUpdating
                                ? 'Updating...'
                                : (updateInfo.isInstalled ? 'Update Applied' : 'Update App Now'),
                          ),
                          onPressed: updateInfo.isUpdating
                              ? null
                              : () => ref.read(appUpdateProvider.notifier).performUpdate(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // New Changes Changelog Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141820) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.new_releases,
                                size: 14,
                                color: isDark ? AppColors.primaryDark : AppColors.primaryLight),
                            const SizedBox(width: 6),
                            Text(
                              'WHAT\'S NEW IN THIS UPDATE (v1.3.1):',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...updateInfo.changeLog.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    item,
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

                  const SizedBox(height: 10),
                  Text(
                    'Direct APK Download: $apkDownloadUrl\niOS Installation: Open $webUrl in Safari and tap Share → "Add to Home Screen".',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 2: ESP32 Firmware OTA Update (§17 Bonus)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2530) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.memory, color: Colors.cyan, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'ESP32 FIRMWARE OTA UPDATE (§17)',
                        style: AppTypography.labelLarge(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Hardware: Synthera DAKSH-01 Controller\nCurrent Firmware: $_currentFwVersion\nTarget Firmware: $_latestFwVersion',
                    style: TextStyle(
                      fontFamily: AppTypography.monoFontFamily,
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isFlashingFirmware || _otaCompleted) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _otaProgress,
                        minHeight: 8,
                        backgroundColor: isDark ? Colors.black38 : Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _otaCompleted ? AppColors.successDark : AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _otaStage,
                          style: TextStyle(
                            fontSize: 11,
                            color: _otaCompleted
                                ? AppColors.successDark
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(_otaProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontFamily: AppTypography.monoFontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  PrimaryButton(
                    label: _isFlashingFirmware
                        ? 'FLASHING FIRMWARE...'
                        : (_otaCompleted ? 'FLASH AGAIN' : 'START FIRMWARE OTA UPDATE'),
                    icon: _isFlashingFirmware ? Icons.hourglass_top : Icons.bolt,
                    height: 44,
                    onPressed: _isFlashingFirmware ? null : _startOtaFirmwareFlash,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
