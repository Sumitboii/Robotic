import 'package:flutter_test/flutter_test.dart';
import 'package:synthera_prosthetic_hand/core/constants/app_constants.dart';
import 'package:synthera_prosthetic_hand/domain/models/hand_state.dart';
import 'package:synthera_prosthetic_hand/infrastructure/device/mock/simulated_prosthetic_hand.dart';

void main() {
  group('SimulatedProstheticHand Kinematics Test Suite', () {
    late SimulatedProstheticHand hand;

    setUp(() {
      hand = SimulatedProstheticHand(
        initialAngle: 45.0,
        minAngle: 0.0,
        maxAngle: 63.0,
        speedDegPerSec: 45.0,
      );
    });

    test('Initial state parameters', () {
      expect(hand.currentAngle, equals(45.0));
      expect(hand.minAngle, equals(0.0));
      expect(hand.maxAngle, equals(63.0));
      expect(hand.state, equals(HandState.holding));
      expect(hand.isMoving, isFalse);
    });

    test('OPEN initiates movement towards minAngle and completes smoothly', () {
      hand.open();
      expect(hand.state, equals(HandState.opening));
      expect(hand.isMoving, isTrue);

      // Step physics 0.5s (45°/s * 0.5s = 22.5° movement)
      hand.step(0.5);
      expect(hand.currentAngle, closeTo(22.5, 0.5));
      expect(hand.state, equals(HandState.opening));

      // Step physics another 0.6s -> reaches 0.0°
      hand.step(0.6);
      expect(hand.currentAngle, equals(0.0));
      expect(hand.state, equals(HandState.open));
      expect(hand.isMoving, isFalse);
    });

    test('CLOSE initiates movement towards maxAngle and completes smoothly',
        () {
      hand = SimulatedProstheticHand(
          initialAngle: 0.0, minAngle: 0.0, maxAngle: 63.0);
      hand.close();
      expect(hand.state, equals(HandState.closing));
      expect(hand.isMoving, isTrue);

      // Step physics 1.0s (45° movement)
      hand.step(1.0);
      expect(hand.currentAngle, closeTo(45.0, 0.5));
      expect(hand.state, equals(HandState.closing));

      // Step physics 0.5s -> reaches 63.0°
      hand.step(0.5);
      expect(hand.currentAngle, equals(63.0));
      expect(hand.state, equals(HandState.closed));
      expect(hand.isMoving, isFalse);
    });

    test('STOP immediately halts movement and freezes position', () {
      hand.open();
      hand.step(0.3);
      final stoppedPos = hand.currentAngle;

      hand.stop();
      expect(hand.state, equals(HandState.stopped));
      expect(hand.isMoving, isFalse);

      // Subsequent steps should not change angle
      hand.step(0.5);
      expect(hand.currentAngle, equals(stoppedPos));
    });

    test('updateLimits adjusts mechanical constraints safely', () {
      hand.updateLimits(minAngle: 10.0, maxAngle: 50.0);
      expect(hand.minAngle, equals(10.0));
      expect(hand.maxAngle, equals(50.0));
      expect(hand.currentAngle, equals(45.0));

      // Test clamping when angle is outside new limits
      final outOfBoundHand = SimulatedProstheticHand(initialAngle: 60.0);
      outOfBoundHand.updateLimits(minAngle: 5.0, maxAngle: 40.0);
      expect(outOfBoundHand.currentAngle, equals(40.0));
    });

    test('closureRatio calculation', () {
      hand = SimulatedProstheticHand(
          initialAngle: 0.0, minAngle: 0.0, maxAngle: 100.0);
      expect(hand.closureRatio, equals(0.0));

      hand.moveToAngle(50.0);
      hand.step(2.0); // reach 50.0
      expect(hand.closureRatio, equals(0.5));

      hand.moveToAngle(100.0);
      hand.step(2.0); // reach 100.0
      expect(hand.closureRatio, equals(1.0));
    });

    test(
        'Position clamping: step beyond limits is clamped and out-of-bound position is clamped on limit update',
        () {
      // 1. Moving beyond absolute bounds is clamped
      hand.moveToAngle(999.0);
      expect(hand.targetAngle, equals(AppConstants.absoluteMaxAngle)); // 180.0
      hand.step(10.0);
      expect(hand.currentAngle, equals(AppConstants.absoluteMaxAngle));

      hand.moveToAngle(-999.0);
      expect(hand.targetAngle, equals(AppConstants.absoluteMinAngle)); // 0.0
      hand.step(10.0);
      expect(hand.currentAngle, equals(AppConstants.absoluteMinAngle));

      // 2. Out-of-bounds current position is clamped when limits change
      final customHand = SimulatedProstheticHand(
        initialAngle: 50.0,
        minAngle: 0.0,
        maxAngle: 63.0,
      );
      expect(customHand.currentAngle, equals(50.0));

      // Narrow upper limit below current angle -> clamped to new max
      customHand.updateLimits(minAngle: 0.0, maxAngle: 35.0);
      expect(customHand.currentAngle, equals(35.0));
      expect(customHand.targetAngle, equals(35.0));

      // Narrow lower limit above current angle -> clamped to new min
      customHand.updateLimits(minAngle: 40.0, maxAngle: 60.0);
      expect(customHand.currentAngle, equals(40.0));
      expect(customHand.targetAngle, equals(40.0));
    });
  });
}
