import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/hand_state.dart';
import 'common/status_chip.dart';

/// Pure mathematical kinematics model for the robotic hand joints.
class HandPose {
  final double closure; // 0.0 (fully open) to 1.0 (fully closed)

  // Thumb articulation
  final double thumbOpposition; // 0.0 to 1.0 across palm
  final double thumbFlexion; // 0.0 to 1.0 curl

  // Finger articulation fractions (0.0 = extended, 1.0 = fully curled into fist)
  final double indexFlexion;
  final double middleFlexion;
  final double ringFlexion;
  final double pinkyFlexion;

  // Joint angles for backward compatibility and test verification
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
    required this.thumbOpposition,
    required this.thumbFlexion,
    required this.indexFlexion,
    required this.middleFlexion,
    required this.ringFlexion,
    required this.pinkyFlexion,
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

    // Staggered organic mechanical motion profiles:
    // - Thumb leads slightly (closes first for grip positioning)
    // - Index & Middle follow nominal path
    // - Ring & Pinky lag slightly (power grip conform)
    final tThumb = (t * 1.15).clamp(0.0, 1.0);
    final tIndex = t;
    final tMiddle = (t * 1.03).clamp(0.0, 1.0);
    final tRing = (t < 0.04 ? 0.0 : (t - 0.04) / 0.96).clamp(0.0, 1.0);
    final tPinky = (t < 0.08 ? 0.0 : (t - 0.08) / 0.92).clamp(0.0, 1.0);

    // Joint angle calculations for tests
    double computeMcp(double fraction) => fraction * 78.0;
    double computePip(double fraction) => fraction * 98.0;
    double computeDip(double fraction) => fraction * 68.6;

    final thumbBase = tThumb * 42.0;
    final thumbPip = tThumb * 55.0;
    final thumbDip = tThumb * 48.0;

    return HandPose(
      closure: t,
      thumbOpposition: tThumb,
      thumbFlexion: tThumb,
      indexFlexion: tIndex,
      middleFlexion: tMiddle,
      ringFlexion: tRing,
      pinkyFlexion: tPinky,
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
/// Features authentic aerospace titanium and carbon-fiber materials,
/// true 2.5D perspective foreshortening grip flexion, multi-linkage phalanges,
/// high-friction silicone grip pads, thenar/hypothenar actuator chambers,
/// and live mechanical status indicators.
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

/// CustomPainter rendering a high-fidelity, photorealistic bionic prosthetic hand.
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

    // Active power status / state color
    final accentColor = handState == HandState.stopped
        ? AppColors.emergencyRed
        : (handState.isMoving
            ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
            : (isDark ? AppColors.blueDark : AppColors.blueLight));

    // Dynamic metallic & aerospace composite materials
    final metalDark = isDark ? const Color(0xFF1E2530) : const Color(0xFF94A3B8);
    final metalMid = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final metalLight = isDark ? const Color(0xFF475569) : const Color(0xFFF1F5F9);
    final carbonPlates = isDark ? const Color(0xFF0F172A) : const Color(0xFF64748B);
    final titaniumKnuckle = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final chromeHighlight = isDark ? const Color(0xFF94A3B8) : const Color(0xFFFFFFFF);
    final siliconeGrip = isDark ? const Color(0xFF090D16) : const Color(0xFF334155);

    // Reference Coordinate System:
    // Centered horizontally, wrist base near bottom
    final scale = math.min(size.width / 260.0, size.height / 300.0);
    canvas.save();
    canvas.translate(size.width / 2.0, size.height * 0.90);
    canvas.scale(scale, scale);

    // 1. Soft Floor Contact Shadow
    _drawContactShadow(canvas);

    // 2. Wrist Interface Socket & Status Ring
    _drawWristSocket(canvas, metalDark, metalMid, metalLight, accentColor);

    // 3. Ergonomic Bionic Palm Exoskeleton
    _drawBionicPalm(canvas, metalDark, metalMid, metalLight, carbonPlates, titaniumKnuckle, accentColor);

    // 4. Opposable Bionic Thumb (CMC swivel & flexion)
    _drawOpposableThumb(
      canvas,
      pose.thumbOpposition,
      pose.thumbFlexion,
      metalDark,
      metalMid,
      metalLight,
      titaniumKnuckle,
      siliconeGrip,
      accentColor,
    );

    // 5. Four Articulated Fingers (Index, Middle, Ring, Pinky) with natural 2.5D perspective curl
    // Index Finger
    _drawArticulatedFinger(
      canvas,
      origin: const Offset(-38, -145),
      baseSpreadRad: -0.07, // slight natural outward splay
      lengthScale: 0.93,
      width: 14.5,
      flexion: pose.indexFlexion,
      curlInwardFactor: 0.12,
      metalDark: metalDark,
      metalMid: metalMid,
      metalLight: metalLight,
      knuckleColor: titaniumKnuckle,
      siliconeGrip: siliconeGrip,
      accentColor: accentColor,
    );

    // Middle Finger (Primary Longest Digit)
    _drawArticulatedFinger(
      canvas,
      origin: const Offset(-12, -156),
      baseSpreadRad: -0.01,
      lengthScale: 1.00,
      width: 15.0,
      flexion: pose.middleFlexion,
      curlInwardFactor: 0.04,
      metalDark: metalDark,
      metalMid: metalMid,
      metalLight: metalLight,
      knuckleColor: titaniumKnuckle,
      siliconeGrip: siliconeGrip,
      accentColor: accentColor,
    );

    // Ring Finger
    _drawArticulatedFinger(
      canvas,
      origin: const Offset(14, -150),
      baseSpreadRad: 0.06,
      lengthScale: 0.94,
      width: 14.2,
      flexion: pose.ringFlexion,
      curlInwardFactor: -0.06,
      metalDark: metalDark,
      metalMid: metalMid,
      metalLight: metalLight,
      knuckleColor: titaniumKnuckle,
      siliconeGrip: siliconeGrip,
      accentColor: accentColor,
    );

    // Pinky Finger (Smallest, most splayed)
    _drawArticulatedFinger(
      canvas,
      origin: const Offset(38, -138),
      baseSpreadRad: 0.14,
      lengthScale: 0.78,
      width: 13.0,
      flexion: pose.pinkyFlexion,
      curlInwardFactor: -0.16,
      metalDark: metalDark,
      metalMid: metalMid,
      metalLight: metalLight,
      knuckleColor: titaniumKnuckle,
      siliconeGrip: siliconeGrip,
      accentColor: accentColor,
    );

    canvas.restore();
  }

  void _drawContactShadow(Canvas canvas) {
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withAlpha(isDark ? 100 : 45),
          Colors.transparent,
        ],
      ).createShader(const Rect.fromLTWH(-90, -18, 180, 40));
    canvas.drawOval(const Rect.fromLTWH(-85, -15, 170, 32), shadowPaint);
  }

  void _drawWristSocket(
    Canvas canvas,
    Color metalDark,
    Color metalMid,
    Color metalLight,
    Color accent,
  ) {
    // Structural wrist collar
    const collarRect = Rect.fromLTWH(-46, -38, 92, 38);
    final collarRRect = RRect.fromRectAndRadius(collarRect, const Radius.circular(8));

    final collarPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [metalDark, metalMid, metalLight, metalDark],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ).createShader(collarRect);
    canvas.drawRRect(collarRRect, collarPaint);

    // Lateral bevel chamfers
    final chamferPaint = Paint()
      ..color = Colors.black.withAlpha(isDark ? 90 : 35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(collarRRect, chamferPaint);

    // Heat dissipation vent channels
    final ventPaint = Paint()
      ..color = isDark ? const Color(0xFF090D16) : const Color(0xFF64748B).withAlpha(120)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (int i = -3; i <= 3; i++) {
      final x = i * 11.5;
      canvas.drawLine(Offset(x, -30), Offset(x, -10), ventPaint);
    }

    // Glowing Servo Status LED Ring
    final glowAlpha = (110 + (pulsePhase * 130)).toInt().clamp(0, 255);
    final haloPaint = Paint()
      ..color = accent.withAlpha(glowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-42, -41, 84, 5), const Radius.circular(3)),
      haloPaint,
    );

    final ledPaint = Paint()
      ..color = accent
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-40, -38.5), const Offset(40, -38.5), ledPaint);
  }

  void _drawBionicPalm(
    Canvas canvas,
    Color metalDark,
    Color metalMid,
    Color metalLight,
    Color carbon,
    Color titanium,
    Color accent,
  ) {
    // Contoured palm exoskeleton outline
    final palmPath = Path()
      ..moveTo(-48, -40)
      ..lineTo(-60, -85) // Thenar muscular flare
      ..lineTo(-54, -135) // Index knuckle base
      ..lineTo(-22, -155) // Middle knuckle arch
      ..lineTo(22, -150) // Ring knuckle arch
      ..lineTo(54, -130) // Pinky hypothenar flare
      ..lineTo(50, -85)
      ..lineTo(48, -40)
      ..close();

    // 1. Palm Main Body with Cylindrical Anodized Finish
    final palmPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [metalLight, metalMid, metalDark],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(const Rect.fromLTWH(-65, -160, 130, 125));
    canvas.drawPath(palmPath, palmPaint);

    // 2. High-Tech Carbon Fiber Inlay Plate
    final carbonPath = Path()
      ..moveTo(-32, -55)
      ..lineTo(-38, -118)
      ..lineTo(0, -138)
      ..lineTo(34, -118)
      ..lineTo(30, -55)
      ..close();

    final carbonPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [carbon, metalDark],
      ).createShader(const Rect.fromLTWH(-40, -140, 80, 90));
    canvas.drawPath(carbonPath, carbonPaint);

    // Carbon Plate Perimeter Seam
    final seamPaint = Paint()
      ..color = titanium.withAlpha(isDark ? 160 : 200)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(carbonPath, seamPaint);

    // 3. Actuator Tendon Cable Channels (4 linear guides running from wrist to knuckles)
    final tendonPaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : const Color(0xFF64748B).withAlpha(140)
      ..strokeWidth = 2.0;
    final tendonWires = Paint()
      ..color = titanium
      ..strokeWidth = 1.0;

    final tendonX = [-26.0, -8.0, 9.0, 24.0];
    final knuckleY = [-142.0, -152.0, -146.0, -135.0];

    for (int i = 0; i < 4; i++) {
      final start = Offset(tendonX[i] * 0.7, -46);
      final end = Offset(tendonX[i], knuckleY[i]);
      canvas.drawLine(start, end, tendonPaint);
      canvas.drawLine(start, end, tendonWires);
    }

    // 4. Thenar Servo Chamber (Motor bulge on thumb lateral edge)
    final thenarBulge = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.2),
        radius: 0.8,
        colors: [titanium.withAlpha(isDark ? 160 : 220), metalDark],
      ).createShader(const Rect.fromLTWH(-68, -110, 36, 50));
    canvas.drawOval(const Rect.fromLTWH(-66, -106, 32, 44), thenarBulge);

    // 5. Structural Titanium Fasteners (Hex Screws)
    final screwPositions = [
      const Offset(-26, -62),
      const Offset(24, -62),
      const Offset(-32, -114),
      const Offset(28, -114),
      const Offset(0, -132),
    ];
    final screwPaint = Paint()..color = titanium;
    final screwSlot = Paint()
      ..color = isDark ? Colors.black : Colors.white
      ..strokeWidth = 0.9;
    for (final pos in screwPositions) {
      canvas.drawCircle(pos, 2.4, screwPaint);
      canvas.drawLine(Offset(pos.dx - 1.4, pos.dy), Offset(pos.dx + 1.4, pos.dy), screwSlot);
    }
  }

  void _drawOpposableThumb(
    Canvas canvas,
    double opposition,
    double flexion,
    Color metalDark,
    Color metalMid,
    Color metalLight,
    Color titanium,
    Color silicone,
    Color accent,
  ) {
    canvas.save();
    // Origin at the Thenar base pivot
    canvas.translate(-50, -82);

    // Opposition kinematics:
    // When open (0.0): Splayed outward at -40°
    // When closed (1.0): Sweeps inward across the palm (+18°) toward index/middle fingers
    final sweepAngle = (-40.0 + (opposition * 58.0)) * math.pi / 180.0;
    canvas.rotate(sweepAngle);

    // 1. Metacarpal Base Segment
    _drawPhalanxSegment(
      canvas,
      width: 17.5,
      length: 32.0,
      metalDark: metalDark,
      metalMid: metalMid,
      metalLight: metalLight,
      siliconeGrip: silicone,
      showGripPad: true,
      gripOnRightSide: true,
    );

    // MCP Joint Swivel
    _drawKnuckleHinge(canvas, 10.0, titanium, accent);

    // 2. Proximal Phalanx
    canvas.translate(0, -32.0);
    final pipCurl = (flexion * 42.0) * math.pi / 180.0;
    canvas.rotate(pipCurl);

    _drawPhalanxSegment(
      canvas,
      width: 15.5,
      length: 27.0,
      metalDark: metalDark,
      metalMid: metalMid,
      metalLight: metalLight,
      siliconeGrip: silicone,
      showGripPad: true,
      gripOnRightSide: true,
    );

    // IP Joint
    _drawKnuckleHinge(canvas, 8.8, titanium, accent);

    // 3. Distal Phalanx & Soft High-Traction Thumb Pad
    canvas.translate(0, -27.0);
    final dipCurl = (flexion * 38.0) * math.pi / 180.0;
    canvas.rotate(dipCurl);

    _drawBionicFingertip(
      canvas,
      width: 14.0,
      length: 24.0,
      metalDark: metalDark,
      metalMid: metalMid,
      metalLight: metalLight,
      silicone: silicone,
      accent: accent,
    );

    canvas.restore();
  }

  void _drawArticulatedFinger(
    Canvas canvas, {
    required Offset origin,
    required double baseSpreadRad,
    required double lengthScale,
    required double width,
    required double flexion,
    required double curlInwardFactor,
    required Color metalDark,
    required Color metalMid,
    required Color metalLight,
    required Color knuckleColor,
    required Color siliconeGrip,
    required Color accentColor,
  }) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);

    // Base alignment + natural convergence toward palm midline as hand closes
    final dynamicSpread = baseSpreadRad + (flexion * curlInwardFactor);
    canvas.rotate(dynamicSpread);

    // Segment lengths (anatomical scale)
    final p1Length = 38.0 * lengthScale;
    final p2Length = 28.0 * lengthScale;
    final p3Length = 24.0 * lengthScale;

    // 1. MCP Base Knuckle (Chassis Joint)
    _drawKnuckleHinge(canvas, width * 0.62, knuckleColor, accentColor);

    // 2. Proximal Phalanx
    // In 2.5D perspective, as the finger curls forward into a grip,
    // the segment foreshortens along the vertical axis
    final p1Foreshorten = (1.0 - (flexion * 0.42)).clamp(0.45, 1.0);
    final p1EffectiveLength = p1Length * p1Foreshorten;

    _drawPhalanxSegment(
      canvas,
      width: width,
      length: p1EffectiveLength,
      metalDark: metalDark,
      metalMid: metalMid,
      metalLight: metalLight,
      siliconeGrip: siliconeGrip,
      showGripPad: true,
      gripOnRightSide: false,
    );

    // 3. PIP Knuckle Hinge
    canvas.translate(0, -p1EffectiveLength);
    final p2Foreshorten = (1.0 - (flexion * 0.48)).clamp(0.38, 1.0);
    final p2EffectiveLength = p2Length * p2Foreshorten;

    _drawKnuckleHinge(canvas, width * 0.54, knuckleColor, accentColor);

    // 4. Intermediate Phalanx
    _drawPhalanxSegment(
      canvas,
      width: width * 0.88,
      length: p2EffectiveLength,
      metalDark: metalDark,
      metalMid: metalMid,
      metalLight: metalLight,
      siliconeGrip: siliconeGrip,
      showGripPad: true,
      gripOnRightSide: false,
    );

    // 5. DIP Knuckle Hinge
    canvas.translate(0, -p2EffectiveLength);
    final p3Foreshorten = (1.0 - (flexion * 0.52)).clamp(0.34, 1.0);
    final p3EffectiveLength = p3Length * p3Foreshorten;

    _drawKnuckleHinge(canvas, width * 0.48, knuckleColor, accentColor);

    // 6. Distal Phalanx & Tactile Bionic Fingertip
    _drawBionicFingertip(
      canvas,
      width: width * 0.80,
      length: p3EffectiveLength,
      metalDark: metalDark,
      metalMid: metalMid,
      metalLight: metalLight,
      silicone: siliconeGrip,
      accent: accentColor,
    );

    canvas.restore();
  }

  void _drawPhalanxSegment(
    Canvas canvas, {
    required double width,
    required double length,
    required Color metalDark,
    required Color metalMid,
    required Color metalLight,
    required Color siliconeGrip,
    required bool showGripPad,
    required bool gripOnRightSide,
  }) {
    final rect = Rect.fromLTWH(-width / 2.0, -length, width, length);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3.5));

    // Metallic cylindrical gradient
    final shellPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [metalLight, metalMid, metalDark],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, shellPaint);

    // Specular Chamfer Highlight along top edge
    final hlPaint = Paint()
      ..color = Colors.white.withAlpha(isDark ? 55 : 140)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(-width / 2.0 + 1, -length + 1.5), Offset(width / 2.0 - 1, -length + 1.5), hlPaint);

    // Titanium Tendon Line (central high-strength core cable)
    final cablePaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : const Color(0xFF64748B)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, -length + 3), Offset(0, -3), cablePaint);

    // Tactile Silicone Grip Treads on contact surface
    if (showGripPad) {
      final padWidth = width * 0.35;
      final padX = gripOnRightSide ? (width / 2.0 - padWidth) : (-width / 2.0);
      final padRect = Rect.fromLTWH(padX, -length + 3, padWidth, length - 6);
      final padPaint = Paint()..color = siliconeGrip;
      canvas.drawRRect(RRect.fromRectAndRadius(padRect, const Radius.circular(2)), padPaint);

      // Grooves / Treads
      final treadPaint = Paint()
        ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)
        ..strokeWidth = 1.0;
      final step = (length - 8) / 3.0;
      for (int i = 1; i <= 2; i++) {
        final y = -length + 4 + (i * step);
        canvas.drawLine(Offset(padX + 1, y), Offset(padX + padWidth - 1, y), treadPaint);
      }
    }
  }

  void _drawKnuckleHinge(Canvas canvas, double radius, Color titanium, Color accent) {
    // Outer Titanium Cylinder Cap
    final outerPaint = Paint()
      ..shader = RadialGradient(
        colors: [titanium, isDark ? const Color(0xFF1E293B) : const Color(0xFF64748B)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.drawCircle(Offset.zero, radius, outerPaint);

    // Inner Concentric Chrome Pin
    final chromePaint = Paint()..color = isDark ? const Color(0xFFCBD5E1) : Colors.white;
    canvas.drawCircle(Offset.zero, radius * 0.50, chromePaint);

    // Pivot Pin Axle Center
    final axlePaint = Paint()..color = isDark ? const Color(0xFF0F172A) : const Color(0xFF334155);
    canvas.drawCircle(Offset.zero, radius * 0.22, axlePaint);
  }

  void _drawBionicFingertip(
    Canvas canvas, {
    required double width,
    required double length,
    required Color metalDark,
    required Color metalMid,
    required Color metalLight,
    required Color silicone,
    required Color accent,
  }) {
    final tipPath = Path()
      ..moveTo(-width / 2.0, 0)
      ..lineTo(-width / 2.0, -length * 0.60)
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
        -length * 0.60,
      )
      ..lineTo(width / 2.0, 0)
      ..close();

    // Metallic Exoskeleton Armor
    final armorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [metalLight, metalMid, metalDark],
      ).createShader(Rect.fromLTWH(-width / 2.0, -length, width, length));
    canvas.drawPath(tipPath, armorPaint);

    // High-Traction Ergonomic Fingertip Sensor Pad
    final padPath = Path()
      ..moveTo(-width * 0.35, -2)
      ..lineTo(-width * 0.35, -length * 0.75)
      ..quadraticBezierTo(
        -width * 0.20,
        -length + 2,
        0,
        -length + 2,
      )
      ..quadraticBezierTo(
        width * 0.20,
        -length + 2,
        width * 0.35,
        -length * 0.75,
      )
      ..lineTo(width * 0.35, -2)
      ..close();

    final padPaint = Paint()..color = silicone;
    canvas.drawPath(padPath, padPaint);

    // Micro Tactile Sensor Dot Indicator
    final sensorPaint = Paint()..color = accent.withAlpha(isDark ? 220 : 180);
    canvas.drawCircle(Offset(0, -length + 4.5), 1.4, sensorPaint);
  }

  @override
  bool shouldRepaint(covariant RealisticRoboticHandPainter oldDelegate) {
    return oldDelegate.pose != pose ||
        oldDelegate.handState != handState ||
        oldDelegate.isDark != isDark ||
        oldDelegate.pulsePhase != pulsePhase ||
        oldDelegate.currentAngle != currentAngle ||
        oldDelegate.minAngle != minAngle ||
        oldDelegate.maxAngle != maxAngle;
  }
}
