import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/hand_state.dart';
import 'common/status_chip.dart';

/// Pure mathematical kinematics model for the robotic hand joints.
class HandPose {
  final double closure; // 0.0 (fully open) to 1.0 (fully closed)
  final double thumbBaseAngle;
  final double thumbPipAngle;
  final double thumbDipAngle;

  final double indexMcpAngle;
  final double indexPipAngle;
  final double indexDipAngle;

  final double middleMcpAngle;
  final double middlePipAngle;
  final double middleDipAngle;

  final double ringMcpAngle;
  final double ringPipAngle;
  final double ringDipAngle;

  final double pinkyMcpAngle;
  final double pinkyPipAngle;
  final double pinkyDipAngle;

  const HandPose({
    required this.closure,
    required this.thumbBaseAngle,
    required this.thumbPipAngle,
    required this.thumbDipAngle,
    required this.indexMcpAngle,
    required this.indexPipAngle,
    required this.indexDipAngle,
    required this.middleMcpAngle,
    required this.middlePipAngle,
    required this.middleDipAngle,
    required this.ringMcpAngle,
    required this.ringPipAngle,
    required this.ringDipAngle,
    required this.pinkyMcpAngle,
    required this.pinkyPipAngle,
    required this.pinkyDipAngle,
  });

  /// Computes physiological robotic joint angles from device angle and calibration limits.
  factory HandPose.fromAngle(
    double angle, [
    double minAngle = 0.0,
    double maxAngle = 63.0,
  ]) {
    final range = maxAngle - minAngle;
    final t = range <= 0.0 ? 0.0 : ((angle - minAngle) / range).clamp(0.0, 1.0);

    // Staggered easing for organic mechanical motion:
    // - Thumb leads slightly (closes first for grip positioning)
    // - Index & Middle follow nominal path
    // - Ring & Pinky lag slightly (power grip conform)
    final tThumb = (t * 1.12).clamp(0.0, 1.0);
    final tIndex = t;
    final tMiddle = (t * 1.02).clamp(0.0, 1.0);
    final tRing = (t < 0.05 ? 0.0 : (t - 0.05) / 0.95).clamp(0.0, 1.0);
    final tPinky = (t < 0.09 ? 0.0 : (t - 0.09) / 0.91).clamp(0.0, 1.0);

    // Coupling parameters: MCP up to 80°, PIP up to 100°, DIP ~ 0.7 * PIP
    double computeMcp(double fraction) => fraction * 78.0;
    double computePip(double fraction) => fraction * 98.0;
    double computeDip(double fraction) => fraction * 68.6;

    // Thumb opposition kinematics (angled base opposition + 2 flexion joints)
    final thumbBase = tThumb * 42.0; // Opposes across palm
    final thumbPip = tThumb * 55.0;
    final thumbDip = tThumb * 48.0;

    return HandPose(
      closure: t,
      thumbBaseAngle: thumbBase,
      thumbPipAngle: thumbPip,
      thumbDipAngle: thumbDip,
      indexMcpAngle: computeMcp(tIndex),
      indexPipAngle: computePip(tIndex),
      indexDipAngle: computeDip(tIndex),
      middleMcpAngle: computeMcp(tMiddle),
      middlePipAngle: computePip(tMiddle),
      middleDipAngle: computeDip(tMiddle),
      ringMcpAngle: computeMcp(tRing),
      ringPipAngle: computePip(tRing),
      ringDipAngle: computeDip(tRing),
      pinkyMcpAngle: computeMcp(tPinky),
      pinkyPipAngle: computePip(tPinky),
      pinkyDipAngle: computeDip(tPinky),
    );
  }
}

/// Realistic High-End Vector Robotic Prosthetic Hand Visualizer.
///
/// Features engineered matte carbon-fiber & titanium segments, beveled palm panels,
/// visible hinge joint caps, tendon tension lines, servo housing bulges,
/// status LED ring, and continuous 60fps kinematic motion interpolation.
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
    );
    if (widget.handState.isMoving) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(HandVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.handState.isMoving && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.handState.isMoving && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

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

    final displayedAngle = widget.currentAngle;
    final pose = HandPose.fromAngle(
      displayedAngle,
      widget.minAngle,
      widget.maxAngle,
    );

    final semanticsLabel =
        'Prosthetic hand position ${displayedAngle.toStringAsFixed(1)} degrees, state ${widget.handState.displayName}';

    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final cardBorder = widget.handState.isMoving
        ? stateColor.withAlpha(140)
        : (widget.handState == HandState.stopped
            ? AppColors.emergencyRed.withAlpha(180)
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder));

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: Container(
        height: widget.height,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: cardBorder, width: 1.0),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 260.0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.precision_manufacturing,
                            size: 16,
                            color: isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight,
                          ),
                          if (!isCompact) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Flexible(
                              child: Text(
                                'BIONIC KINEMATICS',
                                style: AppTypography.labelMedium(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: StatusChip(
                        label: widget.handState.displayName,
                        icon: stateIcon,
                        color: stateColor,
                        isPulsing:
                            widget.handState.isMoving && !isReducedMotion,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                // Hero Hand Canvas
                Expanded(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: RealisticRoboticHandPainter(
                        pose: pose,
                        handState: widget.handState,
                        isDark: isDark,
                        pulsePhase:
                            isReducedMotion ? 0.5 : _pulseController.value,
                        minAngle: widget.minAngle,
                        maxAngle: widget.maxAngle,
                        currentAngle: displayedAngle,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                // Angular Readout & Calibration Limits Indicator
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MIN: ${widget.minAngle.toStringAsFixed(1)}°',
                        style: TextStyle(
                          fontFamily: AppTypography.monoFontFamily,
                          fontFamilyFallback: AppTypography.monoFontFallbacks,
                          fontSize: 10,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: stateColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: stateColor.withAlpha(60)),
                        ),
                        child: Text(
                          '${displayedAngle.toStringAsFixed(1)}° (${(pose.closure * 100).toStringAsFixed(0)}% GRIP)',
                          style: TextStyle(
                            fontFamily: AppTypography.monoFontFamily,
                            fontFamilyFallback: AppTypography.monoFontFallbacks,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: stateColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'MAX: ${widget.maxAngle.toStringAsFixed(1)}°',
                        style: TextStyle(
                          fontFamily: AppTypography.monoFontFamily,
                          fontFamilyFallback: AppTypography.monoFontFallbacks,
                          fontSize: 10,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Vector Painter rendering a photorealistic engineered robotic prosthetic hand.
class RealisticRoboticHandPainter extends CustomPainter {
  final HandPose pose;
  final HandState handState;
  final bool isDark;
  final double pulsePhase;
  final double minAngle;
  final double maxAngle;
  final double currentAngle;

  RealisticRoboticHandPainter({
    required this.pose,
    required this.handState,
    required this.isDark,
    required this.pulsePhase,
    required this.minAngle,
    required this.maxAngle,
    required this.currentAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Palette & Material Colors
    final accentColor = handState == HandState.stopped
        ? AppColors.emergencyRed
        : (handState.isMoving
            ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
            : (isDark ? AppColors.blueDark : AppColors.blueLight));

    final baseSegmentDark =
        isDark ? const Color(0xFF1E232B) : const Color(0xFFE2E7ED);
    final baseSegmentLight =
        isDark ? const Color(0xFF2E3846) : const Color(0xFFFFFFFF);
    final jointTitanium =
        isDark ? const Color(0xFF4A5568) : const Color(0xFF94A3B8);
    final jointHighlight =
        isDark ? const Color(0xFF718096) : const Color(0xFFCBD5E1);
    final rubberTip =
        isDark ? const Color(0xFF0F1216) : const Color(0xFF334155);
    final seamColor =
        isDark ? const Color(0xFF12161D) : const Color(0xFFCBD5E1);

    // Coordinate system: Hand spans roughly 240 x 300 reference units
    final scale = math.min(size.width / 260.0, size.height / 320.0);
    canvas.save();
    canvas.translate(
      size.width / 2.0,
      size.height * 0.90, // Position wrist near bottom center
    );
    canvas.scale(scale, scale);

    // 1. Soft Floor Glow & Contact Shadow
    _drawContactShadow(canvas, accentColor);

    // 2. Wrist Cuff & Status LED Ring
    _drawWristCuff(
      canvas,
      baseSegmentDark,
      baseSegmentLight,
      jointTitanium,
      accentColor,
    );

    // 3. Engineered Paneled Palm with Bulge & Micro-screws
    _drawEngineeredPalm(
      canvas,
      baseSegmentDark,
      baseSegmentLight,
      jointTitanium,
      seamColor,
      accentColor,
    );

    // 4. Five Articulated Fingers (Thumb, Index, Middle, Ring, Pinky)
    // Thumb: Base on opposed left axis (-35°), 2 phalanges
    _drawThumb(
      canvas,
      pose.thumbBaseAngle,
      pose.thumbPipAngle,
      pose.thumbDipAngle,
      baseSegmentDark,
      baseSegmentLight,
      jointTitanium,
      jointHighlight,
      rubberTip,
      accentColor,
    );

    // Fingers: Knuckle origins along curved palm arc
    // Proportions: Index 0.92, Middle 1.00, Ring 0.94, Pinky 0.74
    // Index
    _drawFinger(
      canvas,
      baseOrigin: const Offset(-42, -152),
      baseAngle: -6.0 * math.pi / 180.0,
      lengthScale: 0.92,
      mcpAngle: pose.indexMcpAngle,
      pipAngle: pose.indexPipAngle,
      dipAngle: pose.indexDipAngle,
      baseSegmentDark: baseSegmentDark,
      baseSegmentLight: baseSegmentLight,
      jointTitanium: jointTitanium,
      jointHighlight: jointHighlight,
      rubberTip: rubberTip,
      accentColor: accentColor,
    );

    // Middle (Reference 1.00)
    _drawFinger(
      canvas,
      baseOrigin: const Offset(-14, -160),
      baseAngle: -1.0 * math.pi / 180.0,
      lengthScale: 1.00,
      mcpAngle: pose.middleMcpAngle,
      pipAngle: pose.middlePipAngle,
      dipAngle: pose.middleDipAngle,
      baseSegmentDark: baseSegmentDark,
      baseSegmentLight: baseSegmentLight,
      jointTitanium: jointTitanium,
      jointHighlight: jointHighlight,
      rubberTip: rubberTip,
      accentColor: accentColor,
    );

    // Ring
    _drawFinger(
      canvas,
      baseOrigin: const Offset(15, -154),
      baseAngle: 4.0 * math.pi / 180.0,
      lengthScale: 0.94,
      mcpAngle: pose.ringMcpAngle,
      pipAngle: pose.ringPipAngle,
      dipAngle: pose.ringDipAngle,
      baseSegmentDark: baseSegmentDark,
      baseSegmentLight: baseSegmentLight,
      jointTitanium: jointTitanium,
      jointHighlight: jointHighlight,
      rubberTip: rubberTip,
      accentColor: accentColor,
    );

    // Pinky
    _drawFinger(
      canvas,
      baseOrigin: const Offset(42, -142),
      baseAngle: 10.0 * math.pi / 180.0,
      lengthScale: 0.76,
      mcpAngle: pose.pinkyMcpAngle,
      pipAngle: pose.pinkyPipAngle,
      dipAngle: pose.pinkyDipAngle,
      baseSegmentDark: baseSegmentDark,
      baseSegmentLight: baseSegmentLight,
      jointTitanium: jointTitanium,
      jointHighlight: jointHighlight,
      rubberTip: rubberTip,
      accentColor: accentColor,
    );

    canvas.restore();
  }

  void _drawContactShadow(Canvas canvas, Color accentColor) {
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withAlpha(isDark ? 90 : 40),
          Colors.transparent,
        ],
      ).createShader(const Rect.fromLTWH(-100, -20, 200, 45));
    canvas.drawOval(const Rect.fromLTWH(-95, -15, 190, 35), shadowPaint);
  }

  void _drawWristCuff(
    Canvas canvas,
    Color bgDark,
    Color bgLight,
    Color titanium,
    Color accent,
  ) {
    const cuffRect = Rect.fromLTWH(-48, -42, 96, 42);
    final cuffRRect =
        RRect.fromRectAndRadius(cuffRect, const Radius.circular(8));

    // Metallic Cuff Body
    final cuffPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [bgLight, bgDark],
      ).createShader(cuffRect);
    canvas.drawRRect(cuffRRect, cuffPaint);

    // Vent Slots
    final ventPaint = Paint()
      ..color = isDark ? Colors.black45 : Colors.black12
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    for (int i = -3; i <= 3; i++) {
      final x = i * 11.0;
      canvas.drawLine(Offset(x, -34), Offset(x, -14), ventPaint);
    }

    // Status LED Ring at Wrist Interface
    final ledGlowPaint = Paint()
      ..color = accent.withAlpha((100 + (pulsePhase * 120)).toInt())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-44, -45, 88, 5),
        const Radius.circular(3),
      ),
      ledGlowPaint,
    );

    final ledCorePaint = Paint()
      ..color = accent
      ..strokeWidth = 2.0;
    canvas.drawLine(
        const Offset(-42, -42.5), const Offset(42, -42.5), ledCorePaint);
  }

  void _drawEngineeredPalm(
    Canvas canvas,
    Color bgDark,
    Color bgLight,
    Color titanium,
    Color seam,
    Color accent,
  ) {
    final palmPath = Path()
      ..moveTo(-52, -45)
      ..lineTo(-62, -100) // Thenar slope
      ..lineTo(-50, -150) // Index base
      ..lineTo(-20, -165) // Middle base
      ..lineTo(22, -158) // Ring base
      ..lineTo(54, -138) // Hypothenar slope
      ..lineTo(52, -45)
      ..close();

    // 1. Palm Main Plate with Top-Left Lighting
    final palmPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [bgLight, bgDark],
      ).createShader(const Rect.fromLTWH(-65, -170, 130, 130));
    canvas.drawPath(palmPath, palmPaint);

    // 2. Beveled Center Plate
    final centerPlate = Path()
      ..moveTo(-32, -60)
      ..lineTo(-38, -125)
      ..lineTo(0, -145)
      ..lineTo(34, -125)
      ..lineTo(30, -60)
      ..close();

    final centerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          bgLight.withAlpha(isDark ? 180 : 230),
          bgDark.withAlpha(isDark ? 220 : 255),
        ],
      ).createShader(const Rect.fromLTWH(-40, -150, 80, 100));
    canvas.drawPath(centerPlate, centerPaint);

    // Panel Seams
    final seamPaint = Paint()
      ..color = seam
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(centerPlate, seamPaint);

    // 3. Servo-Housing Bulge (Thenar Axis)
    final thenarBulge = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.6, -0.2),
        radius: 0.8,
        colors: [
          titanium.withAlpha(isDark ? 160 : 200),
          bgDark,
        ],
      ).createShader(const Rect.fromLTWH(-68, -115, 38, 55));
    canvas.drawOval(const Rect.fromLTWH(-66, -112, 34, 48), thenarBulge);

    // 4. Micro-screws / Fasteners
    final screwPositions = [
      const Offset(-28, -68),
      const Offset(26, -68),
      const Offset(-32, -120),
      const Offset(28, -120),
      const Offset(0, -140),
    ];
    final screwPaint = Paint()..color = titanium;
    final screwSlot = Paint()
      ..color = seam
      ..strokeWidth = 1.0;
    for (final pos in screwPositions) {
      canvas.drawCircle(pos, 2.2, screwPaint);
      canvas.drawLine(
        Offset(pos.dx - 1.2, pos.dy),
        Offset(pos.dx + 1.2, pos.dy),
        screwSlot,
      );
    }
  }

  void _drawThumb(
    Canvas canvas,
    double baseAngleDeg,
    double pipAngleDeg,
    double dipAngleDeg,
    Color bgDark,
    Color bgLight,
    Color titanium,
    Color titaniumHl,
    Color rubber,
    Color accent,
  ) {
    canvas.save();
    // Origin at Thenar pivot
    canvas.translate(-52, -88);
    // Base orientation (-38° from vertical + dynamic opposition angle)
    final baseRad = (-38.0 + baseAngleDeg * 0.45) * math.pi / 180.0;
    canvas.rotate(baseRad);

    // 1. Metacarpal Base Segment
    _drawSegment(
      canvas,
      width: 17,
      length: 34,
      bgDark: bgDark,
      bgLight: bgLight,
    );

    // MCP Joint
    _drawJointCap(canvas, 9.5, titanium, titaniumHl, accent);

    // 2. Proximal Phalanx
    canvas.translate(0, -34);
    final pipRad = (pipAngleDeg * 0.45) * math.pi / 180.0;
    canvas.rotate(pipRad);
    _drawSegment(
      canvas,
      width: 15,
      length: 28,
      bgDark: bgDark,
      bgLight: bgLight,
    );

    // PIP Joint
    _drawJointCap(canvas, 8.5, titanium, titaniumHl, accent);

    // 3. Distal Phalanx with Rubber Grip
    canvas.translate(0, -28);
    final dipRad = (dipAngleDeg * 0.45) * math.pi / 180.0;
    canvas.rotate(dipRad);
    _drawDistalPhalanx(
      canvas,
      width: 13,
      length: 24,
      bgDark: bgDark,
      bgLight: bgLight,
      rubber: rubber,
    );

    canvas.restore();
  }

  void _drawFinger(
    Canvas canvas, {
    required Offset baseOrigin,
    required double baseAngle,
    required double lengthScale,
    required double mcpAngle,
    required double pipAngle,
    required double dipAngle,
    required Color baseSegmentDark,
    required Color baseSegmentLight,
    required Color jointTitanium,
    required Color jointHighlight,
    required Color rubberTip,
    required Color accentColor,
  }) {
    canvas.save();
    canvas.translate(baseOrigin.dx, baseOrigin.dy);
    canvas.rotate(baseAngle);

    // Phalanx Dimensions
    final p1Len = 38.0 * lengthScale;
    final p2Len = 29.0 * lengthScale;
    final p3Len = 24.0 * lengthScale;
    final fWidth = 14.0 * lengthScale;

    // MCP Joint
    _drawJointCap(
        canvas, fWidth * 0.60, jointTitanium, jointHighlight, accentColor);

    // MCP Curl
    final mcpRad = (mcpAngle * 0.48) * math.pi / 180.0;
    canvas.rotate(mcpRad);

    // 1. Proximal Phalanx
    _drawSegment(
      canvas,
      width: fWidth,
      length: p1Len,
      bgDark: baseSegmentDark,
      bgLight: baseSegmentLight,
    );
    _drawTendonCable(canvas, fWidth, p1Len, accentColor);

    // PIP Joint
    canvas.translate(0, -p1Len);
    _drawJointCap(
      canvas,
      fWidth * 0.54,
      jointTitanium,
      jointHighlight,
      accentColor,
    );

    // PIP Curl
    final pipRad = (pipAngle * 0.52) * math.pi / 180.0;
    canvas.rotate(pipRad);

    // 2. Middle Phalanx
    _drawSegment(
      canvas,
      width: fWidth * 0.88,
      length: p2Len,
      bgDark: baseSegmentDark,
      bgLight: baseSegmentLight,
    );
    _drawTendonCable(canvas, fWidth * 0.88, p2Len, accentColor);

    // DIP Joint
    canvas.translate(0, -p2Len);
    _drawJointCap(
      canvas,
      fWidth * 0.48,
      jointTitanium,
      jointHighlight,
      accentColor,
    );

    // DIP Curl
    final dipRad = (dipAngle * 0.52) * math.pi / 180.0;
    canvas.rotate(dipRad);

    // 3. Distal Phalanx & Fingertip Pad
    _drawDistalPhalanx(
      canvas,
      width: fWidth * 0.78,
      length: p3Len,
      bgDark: baseSegmentDark,
      bgLight: baseSegmentLight,
      rubber: rubberTip,
    );

    canvas.restore();
  }

  void _drawSegment(
    Canvas canvas, {
    required double width,
    required double length,
    required Color bgDark,
    required Color bgLight,
  }) {
    final rect = Rect.fromLTWH(-width / 2.0, -length, width, length);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3.5));

    // Linear Material Gradient
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [bgLight, bgDark],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);

    // Beveled Edge Highlight
    final hlPaint = Paint()
      ..color = Colors.white.withAlpha(isDark ? 40 : 120)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(-width / 2.0 + 1, -length + 2),
      Offset(-width / 2.0 + 1, -2),
      hlPaint,
    );
  }

  void _drawDistalPhalanx(
    Canvas canvas, {
    required double width,
    required double length,
    required Color bgDark,
    required Color bgLight,
    required Color rubber,
  }) {
    final rect = Rect.fromLTWH(-width / 2.0, -length, width, length);
    final path = Path()
      ..moveTo(-width / 2.0, 0)
      ..lineTo(-width / 2.0, -length + (width / 2.0))
      ..quadraticBezierTo(
        -width / 2.0,
        -length,
        0,
        -length,
      )
      ..quadraticBezierTo(
        width / 2.0,
        -length,
        width / 2.0,
        -length + (width / 2.0),
      )
      ..lineTo(width / 2.0, 0)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [bgLight, bgDark],
      ).createShader(rect);
    canvas.drawPath(path, paint);

    // Rubber Friction Pad at Tip
    final padPaint = Paint()..color = rubber;
    final padPath = Path()
      ..moveTo(-width * 0.38, -length + 4)
      ..quadraticBezierTo(0, -length + 1, width * 0.38, -length + 4)
      ..quadraticBezierTo(0, -length + 7, -width * 0.38, -length + 4)
      ..close();
    canvas.drawPath(padPath, padPaint);
  }

  void _drawJointCap(
    Canvas canvas,
    double radius,
    Color titanium,
    Color titaniumHl,
    Color accent,
  ) {
    // Outer Joint Disc
    final discPaint = Paint()
      ..shader = RadialGradient(
        colors: [titaniumHl, titanium],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.drawCircle(Offset.zero, radius, discPaint);

    // Inner Axle Pin with State Accent Center
    canvas.drawCircle(
      Offset.zero,
      radius * 0.50,
      Paint()..color = isDark ? Colors.black54 : Colors.black26,
    );
    canvas.drawCircle(
      Offset.zero,
      radius * 0.28,
      Paint()..color = accent,
    );
  }

  void _drawTendonCable(
    Canvas canvas,
    double width,
    double length,
    Color accent,
  ) {
    final cablePaint = Paint()
      ..color = accent.withAlpha(isDark ? 80 : 120)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      const Offset(0, -2),
      Offset(0, -length + 2),
      cablePaint,
    );
  }

  @override
  bool shouldRepaint(covariant RealisticRoboticHandPainter oldDelegate) {
    return oldDelegate.currentAngle != currentAngle ||
        oldDelegate.handState != handState ||
        oldDelegate.isDark != isDark ||
        (handState.isMoving && oldDelegate.pulsePhase != pulsePhase);
  }
}
