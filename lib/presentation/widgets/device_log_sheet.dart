import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/device_log_entry.dart';

class DeviceLogSheet extends StatelessWidget {
  final List<DeviceLogEntry> logs;
  final VoidCallback onClear;

  const DeviceLogSheet({
    super.key,
    required this.logs,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeFormat = DateFormat('HH:mm:ss.SSS');

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(100),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.terminal, size: 20, color: AppTheme.cyan),
                    const SizedBox(width: 8),
                    Text(
                      'DEVICE EVENT LOGS (${logs.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Clear Logs',
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: onClear,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Log List
          Expanded(
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      'No device log events recorded yet.',
                      style: TextStyle(color: Color(0xFF90A4AE)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      Color levelColor;
                      switch (log.level) {
                        case LogLevel.info:
                          levelColor = AppTheme.cyan;
                          break;
                        case LogLevel.warning:
                          levelColor = AppTheme.amber;
                          break;
                        case LogLevel.error:
                          levelColor = AppTheme.crimson;
                          break;
                        case LogLevel.command:
                          levelColor = AppTheme.mint;
                          break;
                        case LogLevel.telemetry:
                          levelColor = AppTheme.blue;
                          break;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              timeFormat.format(log.timestamp),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Color(0xFF78909C),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: levelColor.withAlpha(40),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                log.level.name.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: levelColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                log.message,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
