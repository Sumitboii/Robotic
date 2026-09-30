import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../infrastructure/device/device_service.dart';

/// Clinical Quick Demo & Evaluator Drawer Panel (Assignment §10).
class QuickDemoPanel extends StatefulWidget {
  final DeviceService deviceService;

  const QuickDemoPanel({super.key, required this.deviceService});

  @override
  State<QuickDemoPanel> createState() => _QuickDemoPanelState();
}

class _QuickDemoPanelState extends State<QuickDemoPanel> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFaulted = widget.deviceService.isEmgSensorFaultSimulated;
    final willFailReconnect = widget.deviceService.willFailNextReconnect;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bolt,
                    color:
                        isDark ? AppColors.warningDark : AppColors.warningLight,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'EVALUATOR DEMO & FAULT INJECTION',
                    style: AppTypography.titleMedium(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Test real-time error handling, wire protocol fault responses, and hardware edge cases (§10):',
            style: AppTypography.bodySmall(
              color:
                  isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Action Grid
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              // 1. Invalid Command (Wire protocol rejection)
              _buildActionButton(
                context,
                icon: Icons.error_outline,
                label: 'Send invalid command (FLY)',
                color: AppColors.emergencyRed,
                onPressed: () {
                  widget.deviceService.sendRawCommand('FLY');
                  Navigator.of(context).pop();
                },
              ),

              // 2. EMG Sensor Fault Toggle
              _buildActionButton(
                context,
                icon: isFaulted ? Icons.sensors : Icons.sensors_off,
                label: isFaulted
                    ? 'Restore EMG Sensor'
                    : 'Simulate EMG sensor fault',
                color: isFaulted
                    ? (isDark ? AppColors.successDark : AppColors.successLight)
                    : AppColors.emergencyRed,
                onPressed: () {
                  widget.deviceService.toggleEmgSensorFault();
                  setState(() {});
                },
              ),

              // 3. Fail Next Reconnect Toggle
              _buildActionButton(
                context,
                icon: willFailReconnect
                    ? Icons.check_circle_outline
                    : Icons.wifi_off,
                label: willFailReconnect
                    ? 'Fail Reconnect: [ACTIVE]'
                    : 'Fail next reconnect',
                color: willFailReconnect
                    ? AppColors.emergencyRed
                    : (isDark ? AppColors.warningDark : AppColors.warningLight),
                onPressed: () {
                  widget.deviceService.setFailNextReconnect(!willFailReconnect);
                  setState(() {});
                },
              ),

              // 4. Bio-signal spike trigger
              _buildActionButton(
                context,
                icon: Icons.sensors,
                label: 'Trigger EMG Spike (+170 μV)',
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                onPressed: () {
                  widget.deviceService.triggerEmgSpike(170.0);
                  Navigator.of(context).pop();
                },
              ),

              // 5. Battery to 15% (Low warning)
              _buildActionButton(
                context,
                icon: Icons.battery_alert,
                label: 'Set Battery to 15% (Low)',
                color: isDark ? AppColors.warningDark : AppColors.warningLight,
                onPressed: () {
                  widget.deviceService.triggerDemoBatteryDrain(15.0);
                  Navigator.of(context).pop();
                },
              ),

              // 6. Battery to 0% (Cutoff)
              _buildActionButton(
                context,
                icon: Icons.battery_0_bar,
                label: 'Set Battery to 0% (Cutoff)',
                color: AppColors.emergencyRed,
                onPressed: () {
                  widget.deviceService.triggerDemoBatteryDrain(0.0);
                  Navigator.of(context).pop();
                },
              ),

              // 7. Battery to 100%
              _buildActionButton(
                context,
                icon: Icons.battery_charging_full,
                label: 'Recharge Battery (100%)',
                color: isDark ? AppColors.successDark : AppColors.successLight,
                onPressed: () {
                  widget.deviceService.triggerDemoBatteryDrain(100.0);
                  Navigator.of(context).pop();
                },
              ),

              // 8. Connection drop
              _buildActionButton(
                context,
                icon: Icons.link_off,
                label: 'Simulate Connection Drop',
                color: isDark ? AppColors.warningDark : AppColors.warningLight,
                onPressed: () {
                  widget.deviceService.simulateConnectionDrop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withAlpha(isDark ? 120 : 160)),
        backgroundColor: color.withAlpha(isDark ? 25 : 15),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: AppTypography.labelMedium(color: color),
      ),
    );
  }
}
