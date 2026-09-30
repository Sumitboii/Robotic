import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'common/metric_tile.dart';
import 'common/status_chip.dart';

/// Clinical Power & Battery Management Readout.
///
/// Displays percentage, state classification (DEPLETED, CRITICAL, NOMINAL),
/// dynamic color change at threshold, and multi-modal alert status.
class BatteryIndicator extends StatelessWidget {
  final double batteryPercentage;
  final double warningThreshold;
  final bool isLowBattery;

  const BatteryIndicator({
    super.key,
    required this.batteryPercentage,
    this.warningThreshold = 20.0,
    required this.isLowBattery,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color levelColor;
    IconData batteryIcon;
    String statusLabel;

    if (batteryPercentage <= 0.0) {
      levelColor = AppColors.emergencyRed;
      batteryIcon = Icons.battery_alert;
      statusLabel = 'DEPLETED';
    } else if (batteryPercentage <= warningThreshold || isLowBattery) {
      levelColor = AppColors.emergencyRed;
      batteryIcon = Icons.battery_alert;
      statusLabel = 'CRITICAL';
    } else if (batteryPercentage <= 40.0) {
      levelColor = isDark ? AppColors.warningDark : AppColors.warningLight;
      batteryIcon = Icons.battery_3_bar;
      statusLabel = 'LOW';
    } else {
      levelColor = isDark ? AppColors.successDark : AppColors.successLight;
      batteryIcon = Icons.battery_full;
      statusLabel = 'NOMINAL';
    }

    return MetricTile(
      label: 'BATTERY',
      value: batteryPercentage.toStringAsFixed(0),
      unit: '%',
      icon: batteryIcon,
      accentColor: levelColor,
      progress: batteryPercentage / 100.0,
      progressColor: levelColor,
      badge: isLowBattery
          ? StatusChip(
              label: 'LOW',
              icon: Icons.warning_amber_rounded,
              color: levelColor,
            )
          : null,
      helperText: statusLabel,
    );
  }
}
