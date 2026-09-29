import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

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
    if (batteryPercentage <= warningThreshold) {
      levelColor = AppTheme.crimson;
    } else if (batteryPercentage <= 40.0) {
      levelColor = AppTheme.amber;
    } else {
      levelColor = AppTheme.mint;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLowBattery
              ? AppTheme.crimson.withAlpha(153)
              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          width: isLowBattery ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Icon(
                batteryPercentage <= warningThreshold
                    ? Icons.battery_alert
                    : (batteryPercentage <= 50
                        ? Icons.battery_3_bar
                        : Icons.battery_full),
                size: 15,
                color: levelColor,
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'BATTERY',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF90A4AE),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (isLowBattery)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.crimson.withAlpha(51),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.crimson, width: 0.8),
                  ),
                  child: const Text(
                    'LOW',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.crimson,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Percentage Readout
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                batteryPercentage.toStringAsFixed(0),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: levelColor,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                '%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                batteryPercentage <= 0.0
                    ? 'DEPLETED'
                    : (batteryPercentage <= warningThreshold
                        ? 'CRITICAL'
                        : 'NOMINAL'),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: levelColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Battery Level Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (batteryPercentage / 100.0).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: isDark ? Colors.white10 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(levelColor),
            ),
          ),
        ],
      ),
    );
  }
}
