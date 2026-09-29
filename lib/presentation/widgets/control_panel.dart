import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/hand_state.dart';

class ControlPanel extends StatelessWidget {
  final HandState handState;
  final bool isConnected;
  final bool isBatteryDepleted;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final VoidCallback onStop;

  const ControlPanel({
    super.key,
    required this.handState,
    required this.isConnected,
    this.isBatteryDepleted = false,
    required this.onOpen,
    required this.onClose,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = isConnected && !isBatteryDepleted;

    final isOpening = handState == HandState.opening;
    final isClosing = handState == HandState.closing;
    final isStopped = handState == HandState.stopped;

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
              const Flexible(
                child: Text(
                  'ACTUATOR CONTROLS',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF90A4AE),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (isBatteryDepleted)
                const Text(
                  'LOCKED: 0%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.crimson,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // OPEN BUTTON
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: enabled ? onOpen : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOpening
                        ? AppTheme.mint
                        : (isDark
                            ? const Color(0xFF1E3326)
                            : const Color(0xFFE8F5E9)),
                    foregroundColor: isOpening
                        ? Colors.black
                        : (isDark ? AppTheme.mint : const Color(0xFF2E7D32)),
                    elevation: isOpening ? 4 : 0,
                    side: BorderSide(
                      color: isOpening
                          ? AppTheme.mint
                          : AppTheme.mint.withAlpha(100),
                      width: isOpening ? 2.0 : 1.0,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.keyboard_double_arrow_left, size: 16),
                  label: const Text(
                    'OPEN',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // EMERGENCY STOP BUTTON (Priority center styling)
              Expanded(
                flex: 4,
                child: ElevatedButton.icon(
                  onPressed: isConnected ? onStop : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isStopped
                        ? AppTheme.crimson
                        : (isDark
                            ? const Color(0xFF3E171E)
                            : const Color(0xFFFFEBEE)),
                    foregroundColor: isStopped
                        ? Colors.white
                        : (isDark ? AppTheme.crimson : const Color(0xFFC62828)),
                    elevation: isStopped ? 6 : 1,
                    side: BorderSide(
                      color: isStopped ? Colors.white : AppTheme.crimson,
                      width: 2.0,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.stop_circle, size: 18),
                  label: const Text(
                    'STOP',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // CLOSE BUTTON
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: enabled ? onClose : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isClosing
                        ? AppTheme.cyan
                        : (isDark
                            ? const Color(0xFF143142)
                            : const Color(0xFFE0F7FA)),
                    foregroundColor: isClosing
                        ? Colors.black
                        : (isDark ? AppTheme.cyan : const Color(0xFF00838F)),
                    elevation: isClosing ? 4 : 0,
                    side: BorderSide(
                      color: isClosing
                          ? AppTheme.cyan
                          : AppTheme.cyan.withAlpha(100),
                      width: isClosing ? 2.0 : 1.0,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.keyboard_double_arrow_right, size: 16),
                  label: const Text(
                    'CLOSE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
