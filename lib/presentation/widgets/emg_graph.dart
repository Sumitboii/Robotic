import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'common/app_card.dart';
import 'common/status_chip.dart';

/// Clinical Real-Time Biosensor (EMG) Oscilloscope Graph.
///
/// Features smooth continuous Bezier curve rendering, soft gradient fill under curve,
/// labeled dashed threshold limit line, high-contrast spike trigger highlighting,
/// and [RepaintBoundary] isolation for 20Hz rendering performance.
class EmgGraph extends StatelessWidget {
  final List<double> emgHistory;
  final double emgThreshold;
  final double currentEmg;
  final double height;

  const EmgGraph({
    super.key,
    required this.emgHistory,
    required this.emgThreshold,
    required this.currentEmg,
    this.height = 160.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverThreshold = currentEmg >= emgThreshold;

    final primaryColor = isOverThreshold
        ? AppColors.dangerDark
        : (isDark ? AppColors.primaryDark : AppColors.primaryLight);

    final statusText = isOverThreshold ? 'SPIKE' : 'IDLE';

    return RepaintBoundary(
      child: Semantics(
        label:
            'EMG signal ${currentEmg.toStringAsFixed(0)} microvolts, threshold ${emgThreshold.toStringAsFixed(0)} microvolts, state $statusText',
        container: true,
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          borderColor:
              isOverThreshold ? AppColors.dangerDark.withAlpha(160) : null,
          borderWidth: isOverThreshold ? 1.5 : 1.0,
          child: SizedBox(
            height: height - 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar with Signal Stats & Status
                Row(
                  children: [
                    Icon(Icons.show_chart, size: 16, color: primaryColor),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'EMG SIGNAL',
                        style: AppTypography.labelMedium(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    StatusChip(
                      label: statusText,
                      icon: isOverThreshold ? Icons.bolt : Icons.sensors,
                      color: isOverThreshold
                          ? AppColors.dangerDark
                          : (isDark
                              ? AppColors.successDark
                              : AppColors.successLight),
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Text(
                      '${currentEmg.toStringAsFixed(0)} μV',
                      style: AppTypography.monoValueMedium(color: primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Oscilloscope Waveform Canvas
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _ClinicalEmgWaveformPainter(
                        history: emgHistory,
                        threshold: emgThreshold,
                        isDark: isDark,
                        isOverThreshold: isOverThreshold,
                        primaryColor: primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClinicalEmgWaveformPainter extends CustomPainter {
  final List<double> history;
  final double threshold;
  final bool isDark;
  final bool isOverThreshold;
  final Color primaryColor;

  _ClinicalEmgWaveformPainter({
    required this.history,
    required this.threshold,
    required this.isDark,
    required this.isOverThreshold,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    const minVal = 0.0;
    const maxVal = 250.0;
    const range = maxVal - minVal;

    // ── 1. Draw Faint Medical Grid Lines ──
    final gridPaint = Paint()
      ..color =
          (isDark ? Colors.white : Colors.black).withAlpha(isDark ? 8 : 12)
      ..strokeWidth = 0.8;

    for (double yRatio in [0.25, 0.50, 0.75]) {
      final y = size.height * yRatio;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double xRatio in [0.25, 0.50, 0.75]) {
      final x = size.width * xRatio;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // ── 2. Draw Dashed Threshold Line with Callout ──
    final threshY =
        (1.0 - (threshold - minVal) / range).clamp(0.0, 1.0) * size.height;
    final threshPaint = Paint()
      ..color =
          (isDark ? AppColors.dangerDark : AppColors.dangerLight).withAlpha(180)
      ..strokeWidth = 1.2;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, threshY),
        Offset(math.min(startX + dashWidth, size.width), threshY),
        threshPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // Threshold baseline text callout
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'TH: ${threshold.toStringAsFixed(0)} μV',
        style: TextStyle(
          fontFamily: AppTypography.monoFontFamily,
          fontFamilyFallback: AppTypography.monoFontFallbacks,
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: (isDark ? AppColors.dangerDark : AppColors.dangerLight)
              .withAlpha(220),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(size.width - textPainter.width - 4,
          (threshY - 12).clamp(2, size.height - 14)),
    );

    // ── 3. Smooth Bezier Waveform Calculation ──
    final dx = size.width / math.max(1, history.length - 1);
    final points = <Offset>[];
    for (int i = 0; i < history.length; i++) {
      final normY = (1.0 - (history[i] - minVal) / range).clamp(0.0, 1.0);
      points.add(Offset(i * dx, normY * size.height));
    }

    final wavePath = Path();
    final fillPath = Path();

    wavePath.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, size.height);
    fillPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      wavePath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
      fillPath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    // ── 4. Gradient Fill Under Waveform ──
    final fillShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryColor.withAlpha(isDark ? (isOverThreshold ? 90 : 60) : 40),
        primaryColor.withAlpha(0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPaint = Paint()
      ..shader = fillShader
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // ── 5. Waveform Stroke Line ──
    final strokePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(wavePath, strokePaint);

    // ── 6. Active Leading Pulse Dot ──
    final lastPt = points.last;
    final dotPaint = Paint()..color = primaryColor;
    canvas.drawCircle(lastPt, 3.5, dotPaint);

    final glowPaint = Paint()
      ..color = primaryColor.withAlpha(90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(lastPt, 6.0, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _ClinicalEmgWaveformPainter oldDelegate) => true;
}
