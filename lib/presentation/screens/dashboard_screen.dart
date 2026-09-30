import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/device_providers.dart';
import '../../application/providers/settings_provider.dart';
import '../../application/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/battery_indicator.dart';
import '../widgets/common/metric_tile.dart';
import '../widgets/connection_banner.dart';
import '../widgets/control_panel.dart';
import '../widgets/device_log_sheet.dart';
import '../widgets/emg_graph.dart';
import '../widgets/hand_visualizer.dart';
import '../widgets/mode_selector.dart';
import '../widgets/quick_demo_panel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceService = ref.watch(deviceServiceProvider);
    final telemetryAsync = ref.watch(telemetryStreamProvider);
    final connectionAsync = ref.watch(connectionStateStreamProvider);
    final emgHistory = ref.watch(emgHistoryProvider);
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final logs = ref.watch(deviceLogsProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    final telemetry = telemetryAsync.value ?? deviceService.currentTelemetry;
    final connectionState =
        connectionAsync.value ?? deviceService.currentConnectionState;
    final settings = settingsAsync.value;

    final emgThreshold = settings?.emgThreshold ?? 120.0;
    final batteryWarning = settings?.batteryWarningThreshold ?? 20.0;
    final minAngle = settings?.minAngle ?? 0.0;
    final maxAngle = settings?.maxAngle ?? 63.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs + 2),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    .withAlpha(isDark ? 40 : 25),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color:
                      (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                          .withAlpha(isDark ? 100 : 60),
                ),
              ),
              child: Icon(
                Icons.precision_manufacturing,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SYNTHERA ROBOTICS',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFontFamily,
                      fontFamilyFallback: AppTypography.uiFontFallbacks,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    'Prosthetic Hand Simulator',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFontFamily,
                      fontFamilyFallback: AppTypography.uiFontFallbacks,
                      fontSize: 10,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Theme Toggle
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              currentThemeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              size: 20,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            onPressed: () {
              final nextMode = currentThemeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
              ref.read(themeModeProvider.notifier).setThemeMode(nextMode);
            },
          ),
          // Quick Demo Trigger Button
          IconButton(
            tooltip: 'Demo Triggers',
            icon: Icon(
              Icons.bolt,
              color: isDark ? AppColors.warningDark : AppColors.warningLight,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => QuickDemoPanel(deviceService: deviceService),
              );
            },
          ),
          // Device Logs Button
          IconButton(
            tooltip: 'Device Logs',
            icon: Icon(
              Icons.receipt_long,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => DeviceLogSheet(
                  logs: logs,
                  onClear: () => ref.read(deviceLogsProvider.notifier).clear(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            if (isWide) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: SingleChildScrollView(
                    padding: AppSpacing.edgeInsetsScreenWide,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Pane: Hero Visualizer & Actuator Controls
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              HandVisualizer(
                                currentAngle: telemetry.positionDegrees,
                                minAngle: minAngle,
                                maxAngle: maxAngle,
                                handState: telemetry.handState,
                                height: 320,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ModeSelector(
                                currentMode: telemetry.operatingMode,
                                isConnected: connectionState.isConnected,
                                onModeChanged: (mode) =>
                                    deviceService.setOperatingMode(mode),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ControlPanel(
                                handState: telemetry.handState,
                                isConnected: connectionState.isConnected,
                                isBatteryDepleted:
                                    telemetry.batteryPercentage <= 0.0,
                                onOpen: () => deviceService.openHand(),
                                onClose: () => deviceService.closeHand(),
                                onStop: () => deviceService.emergencyStop(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xl),

                        // Right Pane: Telemetry Readouts & EMG Graph
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ConnectionBanner(
                                deviceName: telemetry.deviceName,
                                connectionState: connectionState,
                                onReconnect: () => deviceService.reconnect(),
                                onDisconnect: () => deviceService.disconnect(),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: BatteryIndicator(
                                      batteryPercentage:
                                          telemetry.batteryPercentage,
                                      warningThreshold: batteryWarning,
                                      isLowBattery: telemetry.isLowBattery,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: MetricTile(
                                      label: 'EMG SENSOR',
                                      value:
                                          telemetry.emgValue.toStringAsFixed(0),
                                      unit: 'μV',
                                      icon: Icons.sensors,
                                      accentColor:
                                          telemetry.emgValue >= emgThreshold
                                              ? AppColors.dangerDark
                                              : (isDark
                                                  ? AppColors.primaryDark
                                                  : AppColors.primaryLight),
                                      progress: (telemetry.emgValue / 250.0)
                                          .clamp(0.0, 1.0),
                                      progressColor:
                                          telemetry.emgValue >= emgThreshold
                                              ? AppColors.dangerDark
                                              : null,
                                      helperText:
                                          telemetry.emgValue >= emgThreshold
                                              ? 'ACTIVE'
                                              : 'IDLE',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              EmgGraph(
                                emgHistory: emgHistory,
                                emgThreshold: emgThreshold,
                                currentEmg: telemetry.emgValue,
                                height: 200,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Single Column Layout for Mobile & Compact screens (< 900px)
            return SingleChildScrollView(
              padding: AppSpacing.edgeInsetsScreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Connection Status Banner
                  ConnectionBanner(
                    deviceName: telemetry.deviceName,
                    connectionState: connectionState,
                    onReconnect: () => deviceService.reconnect(),
                    onDisconnect: () => deviceService.disconnect(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 2. Hand Visualization (Custom Kinematics)
                  HandVisualizer(
                    currentAngle: telemetry.positionDegrees,
                    minAngle: minAngle,
                    maxAngle: maxAngle,
                    handState: telemetry.handState,
                    height: 250,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 3. Battery & EMG Dual Readouts
                  Row(
                    children: [
                      Expanded(
                        child: BatteryIndicator(
                          batteryPercentage: telemetry.batteryPercentage,
                          warningThreshold: batteryWarning,
                          isLowBattery: telemetry.isLowBattery,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: MetricTile(
                          label: 'EMG SENSOR',
                          value: telemetry.emgValue.toStringAsFixed(0),
                          unit: 'μV',
                          icon: Icons.sensors,
                          accentColor: telemetry.emgValue >= emgThreshold
                              ? AppColors.dangerDark
                              : (isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primaryLight),
                          progress:
                              (telemetry.emgValue / 250.0).clamp(0.0, 1.0),
                          progressColor: telemetry.emgValue >= emgThreshold
                              ? AppColors.dangerDark
                              : null,
                          helperText: telemetry.emgValue >= emgThreshold
                              ? 'ACTIVE'
                              : 'IDLE',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 4. Real-time EMG Signal Graph
                  EmgGraph(
                    emgHistory: emgHistory,
                    emgThreshold: emgThreshold,
                    currentEmg: telemetry.emgValue,
                    height: 155,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 5. Operating Mode Selector
                  ModeSelector(
                    currentMode: telemetry.operatingMode,
                    isConnected: connectionState.isConnected,
                    onModeChanged: (mode) =>
                        deviceService.setOperatingMode(mode),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 6. Actuator Controls (OPEN / CLOSE / STOP)
                  ControlPanel(
                    handState: telemetry.handState,
                    isConnected: connectionState.isConnected,
                    isBatteryDepleted: telemetry.batteryPercentage <= 0.0,
                    onOpen: () => deviceService.openHand(),
                    onClose: () => deviceService.closeHand(),
                    onStop: () => deviceService.emergencyStop(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
