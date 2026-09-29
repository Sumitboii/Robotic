import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/connection_state.dart';

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
        stateColor = AppTheme.mint;
        stateIcon = Icons.bluetooth_connected;
        break;
      case DeviceConnectionState.connecting:
      case DeviceConnectionState.reconnecting:
        stateColor = AppTheme.amber;
        stateIcon = Icons.bluetooth_searching;
        break;
      case DeviceConnectionState.disconnected:
      case DeviceConnectionState.connectionFailed:
        stateColor = AppTheme.crimson;
        stateIcon = Icons.bluetooth_disabled;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        children: [
          // Device Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: stateColor.withAlpha(isDark ? 40 : 30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stateIcon, size: 20, color: stateColor),
          ),
          const SizedBox(width: 12),

          // Device & Status Text
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
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ESP32 SIM',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF90A4AE),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stateColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      connectionState.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: stateColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Button (Reconnect or Disconnect)
          if (connectionState.isDisconnected)
            ElevatedButton.icon(
              onPressed: onReconnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(
                'RECONNECT',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            )
          else if (connectionState.isTransitioning)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.amber),
              ),
            )
          else
            IconButton(
              tooltip: 'Simulate Disconnect',
              icon: const Icon(Icons.link_off, size: 20),
              color: const Color(0xFF90A4AE),
              onPressed: onDisconnect,
            ),
        ],
      ),
    );
  }
}
