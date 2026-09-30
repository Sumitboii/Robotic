import 'package:flutter_test/flutter_test.dart';
import 'package:synthera_prosthetic_hand/presentation/widgets/hand_visualizer.dart';

void main() {
  group('HandPose Kinematics Unit Test Suite', () {
    test('0° angle yields fully open pose (closure = 0.0)', () {
      final pose = HandPose.fromAngle(0.0, 0.0, 63.0);
      expect(pose.closure, equals(0.0));
      expect(pose.thumbBaseAngle, equals(0.0));
      expect(pose.thumbPipAngle, equals(0.0));
      expect(pose.thumbDipAngle, equals(0.0));
      expect(pose.indexMcpAngle, equals(0.0));
      expect(pose.indexPipAngle, equals(0.0));
      expect(pose.indexDipAngle, equals(0.0));
      expect(pose.middleMcpAngle, equals(0.0));
      expect(pose.middlePipAngle, equals(0.0));
      expect(pose.middleDipAngle, equals(0.0));
      expect(pose.ringMcpAngle, equals(0.0));
      expect(pose.ringPipAngle, equals(0.0));
      expect(pose.ringDipAngle, equals(0.0));
      expect(pose.pinkyMcpAngle, equals(0.0));
      expect(pose.pinkyPipAngle, equals(0.0));
      expect(pose.pinkyDipAngle, equals(0.0));
    });

    test('63° angle yields fully closed pose (closure = 1.0)', () {
      final pose = HandPose.fromAngle(63.0, 0.0, 63.0);
      expect(pose.closure, equals(1.0));
      expect(pose.thumbBaseAngle, equals(42.0));
      expect(pose.indexMcpAngle, closeTo(78.0, 0.1));
      expect(pose.indexPipAngle, closeTo(98.0, 0.1));
      expect(pose.indexDipAngle, closeTo(68.6, 0.1));
      expect(pose.pinkyMcpAngle, closeTo(78.0, 0.1));
      expect(pose.pinkyPipAngle, closeTo(98.0, 0.1));
    });

    test('Out of range angles are clamped safely', () {
      final poseLow = HandPose.fromAngle(-15.0, 0.0, 63.0);
      expect(poseLow.closure, equals(0.0));

      final poseHigh = HandPose.fromAngle(100.0, 0.0, 63.0);
      expect(poseHigh.closure, equals(1.0));
    });

    test('Joint angles are monotonically increasing with angle', () {
      double lastClosure = -1.0;
      double lastIndexMcp = -1.0;

      for (double a = 0.0; a <= 63.0; a += 5.0) {
        final pose = HandPose.fromAngle(a, 0.0, 63.0);
        expect(pose.closure >= lastClosure, isTrue);
        expect(pose.indexMcpAngle >= lastIndexMcp, isTrue);
        lastClosure = pose.closure;
        lastIndexMcp = pose.indexMcpAngle;
      }
    });

    test('Custom calibrated min/max limits map correctly', () {
      final pose = HandPose.fromAngle(30.0, 10.0, 50.0);
      // (30 - 10) / (50 - 10) = 20 / 40 = 0.5
      expect(pose.closure, closeTo(0.5, 0.01));
    });
  });
}
