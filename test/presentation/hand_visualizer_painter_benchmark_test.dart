import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synthera_prosthetic_hand/domain/models/hand_state.dart';
import 'package:synthera_prosthetic_hand/presentation/widgets/hand_visualizer.dart';

void main() {
  group('HandVisualizer Widget & Painter Benchmark Suite', () {
    test('Painter benchmark: Paints 200 times under 4ms per paint', () {
      final pose = HandPose.fromAngle(31.5, 0.0, 63.0);
      final painter = RealisticRoboticHandPainter(
        pose: pose,
        handState: HandState.closing,
        isDark: true,
        pulsePhase: 0.5,
        minAngle: 0.0,
        maxAngle: 63.0,
        currentAngle: 31.5,
      );

      const testSize = Size(320, 320);

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 200; i++) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        painter.paint(canvas, testSize);
        recorder.endRecording();
      }
      stopwatch.stop();

      final totalMs = stopwatch.elapsedMicroseconds / 1000.0;
      final avgMsPerPaint = totalMs / 200.0;

      // Target: under 4.0 ms per paint on host machine
      expect(avgMsPerPaint, lessThan(4.0));
    });

    testWidgets('HandVisualizer scales cleanly at 160, 300, and 500 px widths',
        (WidgetTester tester) async {
      for (final width in [160.0, 300.0, 500.0]) {
        for (final isDark in [true, false]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: isDark ? ThemeData.dark() : ThemeData.light(),
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: width,
                    height: 250,
                    child: const HandVisualizer(
                      currentAngle: 25.0,
                      handState: HandState.holding,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 50));
          expect(find.byType(HandVisualizer), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
    });

    testWidgets('Semantics label updates with angle and state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HandVisualizer(
              currentAngle: 42.0,
              handState: HandState.closing,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.bySemanticsLabel(
          RegExp(
            r'Prosthetic hand position 42\.0 degrees, state CLOSING',
            caseSensitive: false,
          ),
        ),
        findsOneWidget,
      );
    });
  });
}
