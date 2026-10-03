import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/device_providers.dart';
import '../../application/providers/settings_provider.dart';
import '../../application/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/device_log_entry.dart';
import '../../domain/models/operating_mode.dart';
import '../widgets/assignment_telemetry_card.dart';
import '../widgets/battery_indicator.dart';
import '../widgets/common/metric_tile.dart';
import '../widgets/connection_banner.dart';
import '../widgets/control_panel.dart';
import '../widgets/device_log_sheet.dart';
import '../widgets/emg_graph.dart';
import '../widgets/hand_visualizer.dart';
import '../widgets/mode_selector.dart';
import '../widgets/quick_demo_panel.dart';
import '../widgets/system_update_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _dismissedError;

  @override
  Widget build(BuildContext context) {
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
    final isLowBattery = telemetry.batteryPercentage <= batteryWarning;

    // Check for recent rejected command in logs
    final recentErrorLog = logs.isNotEmpty &&
            logs.first.level == LogLevel.error &&
            logs.first.message.contains('ERR:INVALID_COMMAND')
        ? logs.first.message
        : null;

    final activeError = telemetry.lastError ?? recentErrorLog;
    final showErrorBanner =
        activeError != null && activeError != _dismissedError;

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
          // System Updates & OTA Button
          IconButton(
            tooltip: 'System & App Updates',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.system_update_alt,
                  color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const SystemUpdateSheet(),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Prominent Low Battery Banner (§10)
                        if (isLowBattery) ...[
                          _buildLowBatteryBanner(telemetry.batteryPercentage),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Invalid Command Error Alert (§10)
                        if (showErrorBanner) ...[
                          _buildInvalidCommandAlert(activeError),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        Row(
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
                                  if (telemetry.operatingMode ==
                                          OperatingMode.emg &&
                                      !telemetry.isEmgSensorAvailable) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    _buildEmgSensorOfflineNote(),
                                  ],
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
                                    deviceName: settings?.deviceName ??
                                        telemetry.deviceName,
                                    connectionState: connectionState,
                                    onReconnect: () =>
                                        deviceService.reconnect(),
                                    onDisconnect: () =>
                                        deviceService.disconnect(),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  AssignmentTelemetryCard(
                                    telemetry: telemetry,
                                    connectionState: connectionState,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: BatteryIndicator(
                                          batteryPercentage:
                                              telemetry.batteryPercentage,
                                          warningThreshold: batteryWarning,
                                          isLowBattery: isLowBattery,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: MetricTile(
                                          label: 'EMG SENSOR',
                                          value: telemetry.isEmgSensorAvailable
                                              ? telemetry.emgValue
                                                  .toStringAsFixed(0)
                                              : 'N/A',
                                          unit: telemetry.isEmgSensorAvailable
                                              ? 'uV'
                                              : '',
                                          icon: telemetry.isEmgSensorAvailable
                                              ? Icons.sensors
                                              : Icons.sensors_off,
                                          accentColor: !telemetry
                                                  .isEmgSensorAvailable
                                              ? AppColors.emergencyRed
                                              : (telemetry.emgValue >=
                                                      emgThreshold
                                                  ? AppColors.dangerDark
                                                  : (isDark
                                                      ? AppColors.primaryDark
                                                      : AppColors
                                                          .primaryLight)),
                                          progress:
                                              telemetry.isEmgSensorAvailable
                                                  ? (telemetry.emgValue / 250.0)
                                                      .clamp(0.0, 1.0)
                                                  : 0.0,
                                          progressColor:
                                              !telemetry.isEmgSensorAvailable
                                                  ? AppColors.emergencyRed
                                                  : (telemetry.emgValue >=
                                                          emgThreshold
                                                      ? AppColors.dangerDark
                                                      : null),
                                          helperText:
                                              !telemetry.isEmgSensorAvailable
                                                  ? 'UNAVAILABLE'
                                                  : (telemetry.emgValue >=
                                                          emgThreshold
                                                      ? 'ACTIVE'
                                                      : 'IDLE'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  EmgGraph(
                                    emgHistory: emgHistory,
                                    emgThreshold: emgThreshold,
                                    currentEmg: telemetry.emgValue,
                                    isSensorAvailable:
                                        telemetry.isEmgSensorAvailable,
                                    height: 200,
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                  // Prominent Low Battery Banner (§10)
                  if (isLowBattery) ...[
                    _buildLowBatteryBanner(telemetry.batteryPercentage),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  // Invalid Command Error Alert (§10)
                  if (showErrorBanner) ...[
                    _buildInvalidCommandAlert(activeError),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  // 1. Connection Status Banner
                  ConnectionBanner(
                    deviceName: settings?.deviceName ?? telemetry.deviceName,
                    connectionState: connectionState,
                    onReconnect: () => deviceService.reconnect(),
                    onDisconnect: () => deviceService.disconnect(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Specification §2 Core Telemetry Grid
                  AssignmentTelemetryCard(
                    telemetry: telemetry,
                    connectionState: connectionState,
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
                          isLowBattery: isLowBattery,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: MetricTile(
                          label: 'EMG SENSOR',
                          value: telemetry.isEmgSensorAvailable
                              ? telemetry.emgValue.toStringAsFixed(0)
                              : 'N/A',
                          unit: telemetry.isEmgSensorAvailable ? 'uV' : '',
                          icon: telemetry.isEmgSensorAvailable
                              ? Icons.sensors
                              : Icons.sensors_off,
                          accentColor: !telemetry.isEmgSensorAvailable
                              ? AppColors.emergencyRed
                              : (telemetry.emgValue >= emgThreshold
                                  ? AppColors.dangerDark
                                  : (isDark
                                      ? AppColors.primaryDark
                                      : AppColors.primaryLight)),
                          progress: telemetry.isEmgSensorAvailable
                              ? (telemetry.emgValue / 250.0).clamp(0.0, 1.0)
                              : 0.0,
                          progressColor: !telemetry.isEmgSensorAvailable
                              ? AppColors.emergencyRed
                              : (telemetry.emgValue >= emgThreshold
                                  ? AppColors.dangerDark
                                  : null),
                          helperText: !telemetry.isEmgSensorAvailable
                              ? 'UNAVAILABLE'
                              : (telemetry.emgValue >= emgThreshold
                                  ? 'ACTIVE'
                                  : 'IDLE'),
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
                    isSensorAvailable: telemetry.isEmgSensorAvailable,
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
                  if (telemetry.operatingMode == OperatingMode.emg &&
                      !telemetry.isEmgSensorAvailable) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _buildEmgSensorOfflineNote(),
                  ],
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

  Widget _buildLowBatteryBanner(double percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.emergencyRed.withAlpha(35),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.emergencyRed, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.emergencyRed, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '⚠ LOW BATTERY  Battery: ${percentage.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontFamily: AppTypography.monoFontFamily,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: AppColors.emergencyRed,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidCommandAlert(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.emergencyRed.withAlpha(25),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.emergencyRed),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.emergencyRed, size: 18),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Invalid command rejected by device',
              style: TextStyle(
                color: AppColors.emergencyRed,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close,
                size: 16, color: AppColors.emergencyRed),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _dismissedError = message;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmgSensorOfflineNote() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.emergencyRed.withAlpha(20),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.emergencyRed.withAlpha(120)),
      ),
      child: const Row(
        children: [
          Icon(Icons.sensors_off, size: 14, color: AppColors.emergencyRed),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'EMG mode paused: Sensor unavailable or disconnected',
              style: TextStyle(
                color: AppColors.emergencyRed,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
