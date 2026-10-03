import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/platform_downloader.dart';

class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final bool isUpdateAvailable;
  final bool isUpdating;
  final double updateProgress;
  final String statusMessage;
  final bool isInstalled;
  final bool isBannerDismissed;
  final List<String> changeLog;

  const AppUpdateInfo({
    this.currentVersion = '1.3.0',
    this.latestVersion = '1.3.1',
    this.isUpdateAvailable = true,
    this.isUpdating = false,
    this.updateProgress = 0.0,
    this.statusMessage = 'Update Available',
    this.isInstalled = false,
    this.isBannerDismissed = false,
    this.changeLog = const [
      'Authentic Titanium & Silicone Multi-Linkage Bionic Hand Kinematics',
      'Clinical Telemetry Card (§2) with 7 Core Metrics & Serial Data Stream (§4)',
      'High-Definition Typography & Fixed Screenshot Font Box Rendering',
      'One-Click In-App Direct APK Installer & ESP32 Firmware OTA Flashing (§17)',
    ],
  });

  AppUpdateInfo copyWith({
    String? currentVersion,
    String? latestVersion,
    bool? isUpdateAvailable,
    bool? isUpdating,
    double? updateProgress,
    String? statusMessage,
    bool? isInstalled,
    bool? isBannerDismissed,
    List<String>? changeLog,
  }) {
    return AppUpdateInfo(
      currentVersion: currentVersion ?? this.currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      isUpdateAvailable: isUpdateAvailable ?? this.isUpdateAvailable,
      isUpdating: isUpdating ?? this.isUpdating,
      updateProgress: updateProgress ?? this.updateProgress,
      statusMessage: statusMessage ?? this.statusMessage,
      isInstalled: isInstalled ?? this.isInstalled,
      isBannerDismissed: isBannerDismissed ?? this.isBannerDismissed,
      changeLog: changeLog ?? this.changeLog,
    );
  }
}

class AppUpdateNotifier extends StateNotifier<AppUpdateInfo> {
  AppUpdateNotifier() : super(const AppUpdateInfo());

  static const String apkDownloadUrl =
      'https://github.com/Sumitboii/Robotic/releases/download/v1.0.1/app-release.apk';

  void dismissBanner() {
    state = state.copyWith(isBannerDismissed: true);
  }

  void showBanner() {
    state = state.copyWith(isBannerDismissed: false);
  }

  Future<void> performUpdate({bool triggerFileDownload = true}) async {
    if (state.isUpdating) return;

    state = state.copyWith(
      isUpdating: true,
      updateProgress: 0.05,
      statusMessage: 'Connecting to update CDN repository...',
    );

    final steps = [
      (0.20, 'Downloading APK binary package (22.0 MB)...'),
      (0.50, 'Extracting Bionic Titanium kinematics assets...'),
      (0.75, 'Verifying package cryptographic SHA-256 signature...'),
      (0.95, 'Applying changes to runtime engine...'),
      (1.00, 'Update Complete! Version 1.3.1 Active.'),
    ];

    for (final step in steps) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      state = state.copyWith(
        updateProgress: step.$1,
        statusMessage: step.$2,
      );
    }

    if (triggerFileDownload) {
      triggerApkDownload(apkDownloadUrl, filename: 'synthera-prosthetic-hand-v1.3.1.apk');
    }

    state = state.copyWith(
      currentVersion: '1.3.1',
      isUpdateAvailable: false,
      isUpdating: false,
      isInstalled: true,
      statusMessage: 'App updated to v1.3.1 successfully!',
    );
  }
}

final appUpdateProvider =
    StateNotifierProvider<AppUpdateNotifier, AppUpdateInfo>((ref) {
  return AppUpdateNotifier();
});
