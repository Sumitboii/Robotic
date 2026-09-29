import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/hand_state.dart';

class HandVisualizer extends StatefulWidget {
  final double currentAngle;
  final double minAngle;
  final double maxAngle;
  final HandState handState;
  final double height;

  const HandVisualizer({
    super.key,
    required this.currentAngle,
    this.minAngle = 0.0,
    this.maxAngle = 63.0,
    required this.handState,
    this.height = 240.0,
  });

  @override
  State<HandVisualizer> createState() => _HandVisualizerState();
}

class _HandVisualizerState extends State<HandVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final range = widget.maxAngle - widget.minAngle;
    final ratio = range > 0
        ? ((widget.currentAngle - widget.minAngle) / range).clamp(0.0, 1.0)
        : 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color stateColor;
    switch (widget.handState) {
      case HandState.opening:
        stateColor = AppTheme.mint;
        break;
      case HandState.closing:
        stateColor = AppTheme.cyan;
        break;
      case HandState.holding:
      case HandState.open:
      case HandState.closed:
        stateColor = isDark ? Colors.white70 : Colors.black87;
        break;
      case HandState.stopped:
        stateColor = AppTheme.crimson;
        break;
      case HandState.calibrating:
        stateColor = AppTheme.amber;
        break;
    }

    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.handState.isMoving
              ? stateColor.withAlpha(128)
              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          width: widget.handState.isMoving ? 1.5 : 1.0,
        ),
      ),
      child: Stack(
        children: [
          // Background technical grid pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _RoboticGridPainter(
                gridColor: (isDark ? Colors.white : Colors.black).withAlpha(10),
              ),
            ),
          ),

          // Custom Articulated Prosthetic Hand Painter
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ProstheticHandPainter(
                  closureRatio: ratio,
                  handState: widget.handState,
                  isDark: isDark,
                  pulseValue: _pulseController.value,
                ),
              );
            },
          ),

          // Top Right State Badge
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: stateColor.withAlpha(isDark ? 51 : 38),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: stateColor.withAlpha(153)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: stateColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.handState.displayName,
                    style: TextStyle(
                      color: stateColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Angle & Range Readout
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'POSITION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF78909C),
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      '${widget.currentAngle.toStringAsFixed(1)}°',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.cyan : const Color(0xFF0091EA),
                      ),
                    ),
                  ],
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'RANGE / CLOSURE',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF78909C),
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        '${(ratio * 100).toStringAsFixed(0)}% (${widget.minAngle.toStringAsFixed(0)}°-${widget.maxAngle.toStringAsFixed(0)}°)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProstheticHandPainter extends CustomPainter {
  final double closureRatio; // 0.0 (open) to 1.0 (closed)
  final HandState handState;
  final bool isDark;
  final double pulseValue;

  _ProstheticHandPainter({
    required this.closureRatio,
    required this.handState,
    required this.isDark,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.52);

    final chassisPaint = Paint()
      ..color = isDark ? const Color(0xFF2C384A) : const Color(0xFF90A4AE)
      ..style = PaintingStyle.fill;

    final chassisStroke = Paint()
      ..color = isDark ? AppTheme.cyan.withAlpha(100) : const Color(0xFF455A64)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final jointPaint = Paint()
      ..color = isDark ? const Color(0xFF1E2838) : const Color(0xFFCFD8DC)
      ..style = PaintingStyle.fill;

    final jointPinPaint = Paint()
      ..color = isDark ? AppTheme.cyan : const Color(0xFF0091EA)
      ..style = PaintingStyle.fill;

    // 1. Draw Wrist Mount Chassis
    final wristRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 45),
        width: 60,
        height: 28,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(wristRect, chassisPaint);
    canvas.drawRRect(wristRect, chassisStroke);

    // 2. Draw Palm Hub Body
    final palmPath = Path();
    palmPath.moveTo(center.dx - 42, center.dy + 35);
    palmPath.lineTo(center.dx + 42, center.dy + 35);
    palmPath.lineTo(center.dx + 46, center.dy - 10);
    palmPath.lineTo(center.dx - 46, center.dy - 10);
    palmPath.close();

    canvas.drawPath(palmPath, chassisPaint);
    canvas.drawPath(palmPath, chassisStroke);

    // Palm Center Status Glow Ring
    final glowColor = handState == HandState.stopped
        ? AppTheme.crimson
        : (handState.isMoving ? AppTheme.cyan : AppTheme.blue);

    final glowRingPaint = Paint()
      ..color = glowColor.withAlpha((70 + pulseValue * 60).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(Offset(center.dx, center.dy + 12), 12, jointPaint);
    canvas.drawCircle(Offset(center.dx, center.dy + 12), 12, glowRingPaint);
    canvas.drawCircle(Offset(center.dx, center.dy + 12), 4, jointPinPaint);

    // 3. Articulated Fingers (Thumb, Index, Middle, Ring, Pinky)
    // As closureRatio goes 0.0 -> 1.0, finger joints rotate inwards/curls down
    final fingerBases = [
      Offset(center.dx - 38, center.dy + 12), // Thumb (mounted on side)
      Offset(center.dx - 28, center.dy - 10), // Index
      Offset(center.dx - 9, center.dy - 12), // Middle
      Offset(center.dx + 10, center.dy - 11), // Ring
      Offset(center.dx + 28, center.dy - 8), // Pinky
    ];

    final fingerLengths = [
      [22.0, 18.0], // Thumb
      [26.0, 22.0], // Index
      [30.0, 24.0], // Middle
      [27.0, 22.0], // Ring
      [22.0, 18.0], // Pinky
    ];

    final baseAngles = [
      -math.pi * 0.75, // Thumb extends left-up
      -math.pi * 0.58, // Index
      -math.pi * 0.50, // Middle
      -math.pi * 0.42, // Ring
      -math.pi * 0.28, // Pinky
    ];

    for (int i = 0; i < 5; i++) {
      final base = fingerBases[i];
      final l1 = fingerLengths[i][0];
      final l2 = fingerLengths[i][1];

      // Rotation curl angle based on closure ratio
      final curl1 = (i == 0)
          ? closureRatio * 0.9 // thumb flexes across palm
          : closureRatio * 0.85;
      final curl2 = closureRatio * 1.1;

      final angle1 = baseAngles[i] +
          (i == 0 ? curl1 : (i <= 2 ? curl1 * 0.4 : -curl1 * 0.4));
      final p1 = Offset(
        base.dx + l1 * math.cos(angle1) * (1.0 - closureRatio * 0.35),
        base.dy +
            l1 * math.sin(angle1) * (1.0 - closureRatio * 0.25) +
            (closureRatio * 15),
      );

      final angle2 = angle1 + curl2;
      final p2 = Offset(
        p1.dx + l2 * math.cos(angle2) * (1.0 - closureRatio * 0.4),
        p1.dy +
            l2 * math.sin(angle2) * (1.0 - closureRatio * 0.3) +
            (closureRatio * 20),
      );

      // Draw Finger Segments
      final segmentPaint = Paint()
        ..color = isDark ? const Color(0xFF37474F) : const Color(0xFF78909C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (i == 0 || i == 2) ? 6.5 : 5.5
        ..strokeCap = StrokeCap.round;

      final tendonPaint = Paint()
        ..color =
            isDark ? AppTheme.cyan.withAlpha(180) : const Color(0xFF0091EA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      // Proximal phalanx
      canvas.drawLine(base, p1, segmentPaint);
      // Distal phalanx
      canvas.drawLine(p1, p2, segmentPaint);

      // Tendon guideline
      canvas.drawLine(base, p1, tendonPaint);
      canvas.drawLine(p1, p2, tendonPaint);

      // Joints
      canvas.drawCircle(base, 4.0, jointPaint);
      canvas.drawCircle(base, 2.0, jointPinPaint);
      canvas.drawCircle(p1, 3.2, jointPaint);
      canvas.drawCircle(p1, 1.6, jointPinPaint);
      canvas.drawCircle(p2, 2.5, jointPinPinPaint(jointPinPaint));
    }
  }

  Paint jointPinPinPaint(Paint p) => p;

  @override
  bool shouldRepaint(covariant _ProstheticHandPainter oldDelegate) {
    return oldDelegate.closureRatio != closureRatio ||
        oldDelegate.handState != handState ||
        oldDelegate.isDark != isDark ||
        oldDelegate.pulseValue != pulseValue;
  }
}

class _RoboticGridPainter extends CustomPainter {
  final Color gridColor;

  _RoboticGridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.8;

    const step = 20.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoboticGridPainter oldDelegate) => false;
}
