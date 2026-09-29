import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../infrastructure/device/device_service.dart';

class QuickDemoPanel extends StatelessWidget {
  final DeviceService deviceService;

  const QuickDemoPanel({super.key, required this.deviceService});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.science, color: AppTheme.amber, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'DEMO & EVALUATOR CONTROLS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
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
          const Text(
            'Use these instant triggers to verify reactive simulator behaviors during evaluation without waiting:',
            style: TextStyle(fontSize: 12, color: Color(0xFF78909C)),
          ),
          const SizedBox(height: 16),

          // Action Grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionButton(
                context,
                icon: Icons.flash_on,
                label: 'Trigger EMG Spike (+170)',
                color: AppTheme.cyan,
                onPressed: () {
                  deviceService.triggerEmgSpike(170.0);
                  Navigator.of(context).pop();
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.battery_alert,
                label: 'Set Battery to 15% (Low)',
                color: AppTheme.amber,
                onPressed: () {
                  deviceService.triggerDemoBatteryDrain(15.0);
                  Navigator.of(context).pop();
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.battery_0_bar,
                label: 'Set Battery to 0% (Safe Cutoff)',
                color: AppTheme.crimson,
                onPressed: () {
                  deviceService.triggerDemoBatteryDrain(0.0);
                  Navigator.of(context).pop();
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.battery_charging_full,
                label: 'Recharge Battery (100%)',
                color: AppTheme.mint,
                onPressed: () {
                  deviceService.triggerDemoBatteryDrain(100.0);
                  Navigator.of(context).pop();
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.link_off,
                label: 'Simulate Connection Drop',
                color: Colors.orangeAccent,
                onPressed: () {
                  deviceService.simulateConnectionDrop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
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
        side: BorderSide(color: color.withAlpha(150)),
        backgroundColor: color.withAlpha(isDark ? 25 : 15),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
