import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/hand_state.dart';
import 'common/app_card.dart';
import 'common/status_chip.dart';

/// Clinical Prosthetic Hand Kinematics Visualizer.
///
/// Features articulated bionic finger geometry with smooth rounded phalanges,
/// anatomical joint pivots, tendon strain paths, angular limit sweep arc,
/// and accessible multi-modal state indicators.
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
    this.height = 250.0,
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
      duration: const Duration(milliseconds: 1400),
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
    IconData stateIcon;
    switch (widget.handState) {
      case HandState.opening:
        stateColor = isDark ? AppColors.successDark : AppColors.successLight;
        stateIcon = Icons.arrow_outward;
        break;
      case HandState.closing:
        stateColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
        stateIcon = Icons.compress;
        break;
      case HandState.holding:
      case HandState.open:
      case HandState.closed:
        stateColor = isDark ? AppColors.blueDark : AppColors.blueLight;
        stateIcon = Icons.lock_outline;
        break;
      case HandState.stopped:
        stateColor = AppColors.emergencyRed;
        stateIcon = Icons.error_outline;
        break;
      case HandState.calibrating:
        stateColor = isDark ? AppColors.warningDark : AppColors.warningLight;
        stateIcon = Icons.tune;
        break;
    }

    final semanticsText =
        'Prosthetic hand position ${widget.currentAngle.toStringAsFixed(1)} degrees, state ${widget.handState.displayName}';

    return Semantics(
      label: semanticsText,
      container: true,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderColor: widget.handState.isMoving
            ? stateColor.withAlpha(140)
            : (widget.handState == HandState.stopped
                ? AppColors.emergencyRed.withAlpha(180)
                : null),
        borderWidth:
            (widget.handState.isMoving || widget.handState == HandState.stopped)
                ? 1.5
                : 1.0,
        child: SizedBox(
          height: widget.height - 24, // subtract padding
          child: Stack(
            clipBehavior: Clip.antiAlias,
            children: [
              // Technical Clinical Grid Overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: _ClinicalGridPainter(
                    gridColor: (isDark ? Colors.white : Colors.black)
                        .withAlpha(isDark ? 8 : 10),
                  ),
                ),
              ),

              // Bionic Articulated Hand Custom Painter
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _BionicHandPainter(
                        closureRatio: ratio,
                        currentAngle: widget.currentAngle,
                        minAngle: widget.minAngle,
                        maxAngle: widget.maxAngle,
                        handState: widget.handState,
                        isDark: isDark,
                        pulseValue: _pulseController.value,
                        stateColor: stateColor,
                      ),
                    );
                  },
                ),
              ),

              // Top Right State Chip (Multi-modal)
              Positioned(
                top: 0,
                right: 0,
                child: StatusChip(
                  label: widget.handState.displayName,
                  icon: stateIcon,
                  color: stateColor,
                ),
              ),

              // Bottom Left / Right Telemetry Readouts
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface)
                        .withAlpha(200),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Position readout
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'JOINT ANGLE',
                            style: AppTypography.labelSmall(
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                          Text(
                            '${widget.currentAngle.toStringAsFixed(1)}°',
                            style: AppTypography.monoValueLarge(
                              color: isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),

                      // Stroke closure readout
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'CLOSURE',
                              style: AppTypography.labelSmall(
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${(ratio * 100).toStringAsFixed(0)}% [${widget.minAngle.toStringAsFixed(0)}° - ${widget.maxAngle.toStringAsFixed(0)}°]',
                              style: AppTypography.monoValueSmall(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BionicHandPainter extends CustomPainter {
  final double closureRatio; // 0.0 (open) to 1.0 (closed)
  final double currentAngle;
  final double minAngle;
  final double maxAngle;
  final HandState handState;
  final bool isDark;
  final double pulseValue;
  final Color stateColor;

  _BionicHandPainter({
    required this.closureRatio,
    required this.currentAngle,
    required this.minAngle,
    required this.maxAngle,
    required this.handState,
    required this.isDark,
    required this.pulseValue,
    required this.stateColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.54);

    // ── 1. Draw Kinematic Angular Limit Sweep Arc ──
    final arcRadius = math.min(size.width, size.height) * 0.38;
    final arcPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withAlpha(15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final activeArcPaint = Paint()
      ..color = stateColor.withAlpha(isDark ? 120 : 160)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const startRadian = -math.pi * 0.85;
    const sweepRange = math.pi * 0.70;
    final activeSweep = sweepRange * closureRatio;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arcRadius),
      startRadian,
      sweepRange,
      false,
      arcPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arcRadius),
      startRadian,
      activeSweep,
      false,
      activeArcPaint,
    );

    // ── 2. Materials & Shaders ──
    final chassisFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [Color(0xFF243144), Color(0xFF161F2C)]
            : const [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
      ).createShader(Rect.fromCenter(center: center, width: 120, height: 120));

    final chassisStroke = Paint()
      ..color = isDark ? const Color(0xFF3B4D66) : const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final jointCore = Paint()
      ..color = isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9);

    final jointRing = Paint()
      ..color = stateColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // ── 3. Draw Wrist & Palm Chassis ──
    // Wrist mount
    final wristRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 46),
        width: 64,
        height: 24,
      ),
      const Radius.circular(AppRadius.sm),
    );
    canvas.drawRRect(wristRRect, chassisFill);
    canvas.drawRRect(wristRRect, chassisStroke);

    // Palm core polygon
    final palmPath = Path()
      ..moveTo(center.dx - 44, center.dy + 34)
      ..lineTo(center.dx + 44, center.dy + 34)
      ..lineTo(center.dx + 48, center.dy - 12)
      ..lineTo(center.dx - 48, center.dy - 12)
      ..close();

    canvas.drawPath(palmPath, chassisFill);
    canvas.drawPath(palmPath, chassisStroke);

    // Palm Center Master Actuator Glow
    final hubCenter = Offset(center.dx, center.dy + 12);
    final glowRadius = 13.0 + pulseValue * 3.0;
    final glowPaint = Paint()
      ..color =
          stateColor.withAlpha((isDark ? 40 : 30) + (pulseValue * 40).toInt())
      ..style = PaintingStyle.fill;

    canvas.drawCircle(hubCenter, glowRadius, glowPaint);
    canvas.drawCircle(hubCenter, 10, jointCore);
    canvas.drawCircle(hubCenter, 10, jointRing);
    canvas.drawCircle(hubCenter, 3.5, Paint()..color = stateColor);

    // ── 4. Articulated Bionic Phalanges ──
    final fingerBases = [
      Offset(center.dx - 40, center.dy + 12), // Thumb
      Offset(center.dx - 30, center.dy - 12), // Index
      Offset(center.dx - 10, center.dy - 14), // Middle
      Offset(center.dx + 10, center.dy - 13), // Ring
      Offset(center.dx + 30, center.dy - 10), // Pinky
    ];

    final fingerLengths = [
      [22.0, 18.0], // Thumb
      [28.0, 22.0], // Index
      [32.0, 24.0], // Middle
      [29.0, 22.0], // Ring
      [23.0, 18.0], // Pinky
    ];

    final baseAngles = [
      -math.pi * 0.78, // Thumb
      -math.pi * 0.58, // Index
      -math.pi * 0.50, // Middle
      -math.pi * 0.42, // Ring
      -math.pi * 0.28, // Pinky
    ];

    for (int i = 0; i < 5; i++) {
      final base = fingerBases[i];
      final l1 = fingerLengths[i][0];
      final l2 = fingerLengths[i][1];

      final curl1 = (i == 0)
          ? closureRatio * 0.95 // Thumb rotates inward across palm plane
          : closureRatio * 0.85;
      final curl2 = closureRatio * 1.15;

      final angle1 = baseAngles[i] +
          (i == 0 ? curl1 : (i <= 2 ? curl1 * 0.4 : -curl1 * 0.4));

      final p1 = Offset(
        base.dx + l1 * math.cos(angle1) * (1.0 - closureRatio * 0.35),
        base.dy +
            l1 * math.sin(angle1) * (1.0 - closureRatio * 0.25) +
            (closureRatio * 14),
      );

      final angle2 = angle1 + curl2;
      final p2 = Offset(
        p1.dx + l2 * math.cos(angle2) * (1.0 - closureRatio * 0.40),
        p1.dy +
            l2 * math.sin(angle2) * (1.0 - closureRatio * 0.30) +
            (closureRatio * 18),
      );

      // Phalanx bone stroke with rounded structural cap
      final bonePaint = Paint()
        ..color = isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (i == 0 || i == 2) ? 6.5 : 5.2
        ..strokeCap = StrokeCap.round;

      // Active tendon guide line
      final tendonPaint = Paint()
        ..color = stateColor.withAlpha(isDark ? 160 : 200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;

      // Draw phalanx segments
      canvas.drawLine(base, p1, bonePaint);
      canvas.drawLine(p1, p2, bonePaint);

      // Draw tendon alignment guide
      canvas.drawLine(base, p1, tendonPaint);
      canvas.drawLine(p1, p2, tendonPaint);

      // Draw anatomical joint nodes
      _drawJoint(canvas, base, 4.5, jointCore, jointRing);
      _drawJoint(canvas, p1, 3.5, jointCore, jointRing);
      _drawJoint(canvas, p2, 2.5, jointCore, jointRing);
    }
  }

  void _drawJoint(
    Canvas canvas,
    Offset pos,
    double radius,
    Paint corePaint,
    Paint ringPaint,
  ) {
    canvas.drawCircle(pos, radius, corePaint);
    canvas.drawCircle(pos, radius, ringPaint);
    canvas.drawCircle(pos, radius * 0.4, Paint()..color = ringPaint.color);
  }

  @override
  bool shouldRepaint(covariant _BionicHandPainter oldDelegate) {
    return oldDelegate.closureRatio != closureRatio ||
        oldDelegate.currentAngle != currentAngle ||
        oldDelegate.minAngle != minAngle ||
        oldDelegate.maxAngle != maxAngle ||
        oldDelegate.handState != handState ||
        oldDelegate.isDark != isDark ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.stateColor != stateColor;
  }
}

class _ClinicalGridPainter extends CustomPainter {
  final Color gridColor;

  _ClinicalGridPainter({required this.gridColor});

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
  bool shouldRepaint(covariant _ClinicalGridPainter oldDelegate) => false;
}
