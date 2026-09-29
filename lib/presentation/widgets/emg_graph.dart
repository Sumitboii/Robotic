import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

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
    this.height = 140.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverThreshold = currentEmg >= emgThreshold;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverThreshold
              ? AppTheme.crimson.withAlpha(153)
              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          width: isOverThreshold ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Responsive Fitting
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 16,
                      color: isDark ? AppTheme.cyan : const Color(0xFF0091EA),
                    ),
                    const SizedBox(width: 6),
                    const Flexible(
                      child: Text(
                        'EMG SIGNAL',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF90A4AE),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isOverThreshold
                      ? AppTheme.crimson.withAlpha(51)
                      : (isDark ? Colors.white10 : Colors.black12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color:
                        isOverThreshold ? AppTheme.crimson : Colors.transparent,
                  ),
                ),
                child: Text(
                  'THRESH: ${emgThreshold.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: isOverThreshold
                        ? AppTheme.crimson
                        : const Color(0xFF90A4AE),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                currentEmg.toStringAsFixed(0),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isOverThreshold
                      ? AppTheme.crimson
                      : (isDark ? AppTheme.cyan : const Color(0xFF0091EA)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Oscilloscope Waveform View
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomPaint(
                size: Size.infinite,
                painter: _EmgWaveformPainter(
                  history: emgHistory,
                  threshold: emgThreshold,
                  isDark: isDark,
                  isOverThreshold: isOverThreshold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmgWaveformPainter extends CustomPainter {
  final List<double> history;
  final double threshold;
  final bool isDark;
  final bool isOverThreshold;

  _EmgWaveformPainter({
    required this.history,
    required this.threshold,
    required this.isDark,
    required this.isOverThreshold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    const minVal = 0.0;
    const maxVal = 250.0;
    const range = maxVal - minVal;

    // Draw background grid lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withAlpha(12)
      ..strokeWidth = 0.8;

    canvas.drawLine(Offset(0, size.height * 0.25),
        Offset(size.width, size.height * 0.25), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.5),
        Offset(size.width, size.height * 0.5), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.75),
        Offset(size.width, size.height * 0.75), gridPaint);

    // Draw Threshold Line (Dashed)
    final threshY = (1.0 - (threshold - minVal) / range) * size.height;
    final threshPaint = Paint()
      ..color = AppTheme.crimson.withAlpha(180)
      ..strokeWidth = 1.2;

    const dashWidth = 5.0;
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

    // Compute Waveform Points
    final dx = size.width / (history.length - 1);
    final points = <Offset>[];
    for (int i = 0; i < history.length; i++) {
      final normY = (1.0 - (history[i] - minVal) / range).clamp(0.0, 1.0);
      points.add(Offset(i * dx, normY * size.height));
    }

    // Create Waveform Path
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

    // Gradient area fill
    final fillColor = isOverThreshold ? AppTheme.crimson : AppTheme.cyan;
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        fillColor.withAlpha(isDark ? 80 : 50),
        fillColor.withAlpha(0),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final linePaint = Paint()
      ..color = fillColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(wavePath, linePaint);

    // Latest sample pulse dot
    final lastPoint = points.last;
    final dotPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lastPoint, 3.5, dotPaint);

    final glowPaint = Paint()
      ..color = fillColor.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(lastPoint, 5.5, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _EmgWaveformPainter oldDelegate) => true;
}
