import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/operating_mode.dart';

class ModeSelector extends StatelessWidget {
  final OperatingMode currentMode;
  final bool isConnected;
  final ValueChanged<OperatingMode> onModeChanged;

  const ModeSelector({
    super.key,
    required this.currentMode,
    required this.isConnected,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OPERATING MODE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF90A4AE),
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.blue.withAlpha(isDark ? 51 : 38),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  currentMode.displayName,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Mode Selector Segmented Bar
          Row(
            children: OperatingMode.values.map((mode) {
              final isSelected = mode == currentMode;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: isConnected ? () => onModeChanged(mode) : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? AppTheme.cyan.withAlpha(51)
                                : const Color(0xFF0091EA))
                            : (isDark
                                ? Colors.white.withAlpha(10)
                                : Colors.black.withAlpha(10)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? (isDark
                                  ? AppTheme.cyan
                                  : const Color(0xFF0091EA))
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getIconForMode(mode),
                            size: 18,
                            color: isSelected
                                ? (isDark ? AppTheme.cyan : Colors.white)
                                : const Color(0xFF90A4AE),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mode.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? (isDark ? AppTheme.cyan : Colors.white)
                                  : const Color(0xFF90A4AE),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Mode Description Subtitle
          Text(
            currentMode.description,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF78909C),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForMode(OperatingMode mode) {
    switch (mode) {
      case OperatingMode.manual:
        return Icons.pan_tool;
      case OperatingMode.emg:
        return Icons.sensors;
      case OperatingMode.auto:
        return Icons.autorenew;
    }
  }
}
