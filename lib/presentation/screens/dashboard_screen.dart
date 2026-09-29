import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/device_providers.dart';
import '../../application/providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/battery_indicator.dart';
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

    final telemetry = telemetryAsync.value ?? deviceService.currentTelemetry;
    final connectionState =
        connectionAsync.value ?? deviceService.currentConnectionState;
    final settings = settingsAsync.value;

    final emgThreshold = settings?.emgThreshold ?? 120.0;
    final batteryWarning = settings?.batteryWarningThreshold ?? 20.0;
    final minAngle = settings?.minAngle ?? 0.0;
    final maxAngle = settings?.maxAngle ?? 63.0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.cyan.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.precision_manufacturing,
                  color: AppTheme.cyan, size: 20),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SYNTHERA ROBOTICS',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    'Prosthetic Hand Simulator',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF90A4AE),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Quick Demo Trigger Button
          IconButton(
            tooltip: 'Demo Triggers',
            icon: const Icon(Icons.bolt, color: AppTheme.amber),
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
            icon: const Icon(Icons.receipt_long, color: Color(0xFF90A4AE)),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              const SizedBox(height: 12),

              // 2. Hand Visualization (Custom Kinematics)
              HandVisualizer(
                currentAngle: telemetry.positionDegrees,
                minAngle: minAngle,
                maxAngle: maxAngle,
                handState: telemetry.handState,
                height: 230,
              ),
              const SizedBox(height: 12),

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
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniEmgCard(
                      emgValue: telemetry.emgValue,
                      threshold: emgThreshold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4. Real-time EMG Signal Graph
              EmgGraph(
                emgHistory: emgHistory,
                emgThreshold: emgThreshold,
                currentEmg: telemetry.emgValue,
                height: 140,
              ),
              const SizedBox(height: 12),

              // 5. Operating Mode Selector
              ModeSelector(
                currentMode: telemetry.operatingMode,
                isConnected: connectionState.isConnected,
                onModeChanged: (mode) => deviceService.setOperatingMode(mode),
              ),
              const SizedBox(height: 12),

              // 6. Actuator Controls (OPEN / STOP / CLOSE)
              ControlPanel(
                handState: telemetry.handState,
                isConnected: connectionState.isConnected,
                isBatteryDepleted: telemetry.batteryPercentage <= 0.0,
                onOpen: () => deviceService.openHand(),
                onClose: () => deviceService.closeHand(),
                onStop: () => deviceService.emergencyStop(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniEmgCard extends StatelessWidget {
  final double emgValue;
  final double threshold;

  const _MiniEmgCard({
    required this.emgValue,
    required this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOver = emgValue >= threshold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOver
              ? AppTheme.crimson.withAlpha(153)
              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          width: isOver ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sensors,
                size: 15,
                color: isOver ? AppTheme.crimson : AppTheme.cyan,
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'EMG SENSOR',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF90A4AE),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (isOver)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.crimson.withAlpha(51),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.crimson,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                emgValue.toStringAsFixed(0),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isOver
                      ? AppTheme.crimson
                      : (isDark ? AppTheme.cyan : const Color(0xFF0091EA)),
                ),
              ),
              const SizedBox(width: 3),
              const Text(
                'μV',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF78909C),
                ),
              ),
              const Spacer(),
              Text(
                isOver ? 'SPIKE' : 'IDLE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isOver ? AppTheme.crimson : AppTheme.mint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (emgValue / 250.0).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: isDark ? Colors.white10 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? AppTheme.crimson : AppTheme.cyan,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
