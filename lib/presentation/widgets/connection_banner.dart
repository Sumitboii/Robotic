import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/connection_state.dart';
import 'common/app_card.dart';
import 'common/status_chip.dart';

/// Clinical Device Connection Status Banner.
///
/// Displays device identifier, firmware tag, multi-modal status badge,
/// and clear reconnect/disconnect actions.
class ConnectionBanner extends StatelessWidget {
  final String deviceName;
  final DeviceConnectionState connectionState;
  final VoidCallback onReconnect;
  final VoidCallback onDisconnect;

  const ConnectionBanner({
    super.key,
    required this.deviceName,
    required this.connectionState,
    required this.onReconnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color stateColor;
    IconData stateIcon;
    switch (connectionState) {
      case DeviceConnectionState.connected:
        stateColor = isDark ? AppColors.successDark : AppColors.successLight;
        stateIcon = Icons.bluetooth_connected;
        break;
      case DeviceConnectionState.connecting:
      case DeviceConnectionState.reconnecting:
        stateColor = isDark ? AppColors.warningDark : AppColors.warningLight;
        stateIcon = Icons.bluetooth_searching;
        break;
      case DeviceConnectionState.disconnected:
      case DeviceConnectionState.connectionFailed:
        stateColor = AppColors.emergencyRed;
        stateIcon = Icons.bluetooth_disabled;
        break;
    }

    final isDisconnected = connectionState.isDisconnected;
    final isTransitioning = connectionState.isTransitioning;

    return Semantics(
      label:
          'Device $deviceName connection state is ${connectionState.displayName}',
      container: true,
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        borderColor: isDisconnected
            ? AppColors.emergencyRed.withAlpha(140)
            : (isTransitioning
                ? (isDark ? AppColors.warningDark : AppColors.warningLight)
                    .withAlpha(140)
                : null),
        borderWidth: (isDisconnected || isTransitioning) ? 1.5 : 1.0,
        child: Row(
          children: [
            // Status Icon Container
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: stateColor.withAlpha(isDark ? 40 : 25),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: stateColor.withAlpha(isDark ? 100 : 70),
                  width: 1.0,
                ),
              ),
              child: Icon(stateIcon, size: 20, color: stateColor),
            ),
            const SizedBox(width: AppSpacing.md),

            // Device Profile & Connection State
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          deviceName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.monoFontFamily,
                            fontFamilyFallback: AppTypography.monoFontFallbacks,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black12,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          'ESP32 SIM',
                          style: AppTypography.labelSmall(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  StatusChip(
                    label: connectionState.displayName,
                    icon: null,
                    color: stateColor,
                  ),
                ],
              ),
            ),

            // Action / State Indicator
            if (isDisconnected)
              ElevatedButton.icon(
                onPressed: onReconnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  minimumSize: const Size(0, 38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text(
                  'RECONNECT',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              )
            else if (isTransitioning)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(stateColor),
                ),
              )
            else
              IconButton(
                tooltip: 'Disconnect Simulator',
                icon: const Icon(Icons.link_off, size: 20),
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                onPressed: onDisconnect,
              ),
          ],
        ),
      ),
    );
  }
}
