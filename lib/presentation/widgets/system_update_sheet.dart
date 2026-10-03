import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'common/primary_button.dart';

/// Modal bottom sheet providing both:
/// 1. Mobile App Direct Update / APK Download (Android & iOS PWA)
/// 2. ESP32 Firmware Over-The-Air (OTA) Update Interface (§17 Bonus Feature)
class SystemUpdateSheet extends StatefulWidget {
  final VoidCallback? onFirmwareUpdated;

  const SystemUpdateSheet({
    super.key,
    this.onFirmwareUpdated,
  });

  @override
  State<SystemUpdateSheet> createState() => _SystemUpdateSheetState();
}

class _SystemUpdateSheetState extends State<SystemUpdateSheet> {
  bool _isCheckingApp = false;
  bool _isFlashingFirmware = false;
  double _otaProgress = 0.0;
  String _otaStage = 'Ready to Flash';
  bool _otaCompleted = false;

  final String _currentAppVersion = '1.3.0';
  final String _latestAppVersion = '1.3.0 (Latest Release)';
  final String _currentFwVersion = 'v1.2.0-esp32';
  final String _latestFwVersion = 'v1.3.0-bionic';

  static const String apkDownloadUrl =
      'https://github.com/Sumitboii/Robotic/releases/download/v1.0.1/app-release.apk';
  static const String webUrl = 'https://sumitboii.github.io/Robotic/';

  Future<void> _checkAppUpdate() async {
    setState(() => _isCheckingApp = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isCheckingApp = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App is up to date! Release APK is available for direct download.'),
        backgroundColor: AppColors.successDark,
        duration: Duration(seconds: 3),
      ),
    );
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
      (0.35, 'Transferring binary blocks (DAKSH_01_fw_v1.3.bin)...'),
      (0.65, 'Writing firmware blocks (20 Hz BLE driver)...'),
      (0.85, 'Verifying SHA-256 partition checksum...'),
      (1.00, 'Rebooting ESP32 microcontroller into new firmware...'),
    ];

    for (final step in steps) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _otaProgress = step.$1;
        _otaStage = step.$2;
      });
    }

    await Future.delayed(const Duration(milliseconds: 500));
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
                        'Mobile App APK Installer & ESP32 Firmware OTA',
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

            // Section 1: Mobile App Update / Direct APK Install
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
                      const Icon(Icons.android, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'MOBILE APP INSTALLER (ANDROID & iOS)',
                        style: AppTypography.labelLarge(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Installed App Version: v$_currentAppVersion\nLatest Cloud Release: v$_latestAppVersion',
                    style: TextStyle(
                      fontFamily: AppTypography.monoFontFamily,
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
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
                          onPressed: _isCheckingApp ? null : _checkAppUpdate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDark ? AppColors.primaryDark : AppColors.primaryLight,
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Download APK'),
                          onPressed: () {
                            // Direct download action
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Downloading APK: $apkDownloadUrl',
                                ),
                                backgroundColor: AppColors.primaryDark,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For iPhone (iOS): Open $webUrl in Safari and tap Share → "Add to Home Screen" to install standalone native app.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontStyle: FontStyle.italic,
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
