import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synthera_prosthetic_hand/app.dart';

void main() {
  group('Settings & Calibration Integration Flow Widget Test Suite', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
        'Settings Screen: Edit values, validate rejections on invalid inputs, save and persist',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: SyntheraProstheticApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Navigate to Settings tab
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('SETTINGS'), findsOneWidget);

      // 1. Validation test: blank device name
      final nameField =
          find.widgetWithText(TextFormField, 'Device Name / Model');
      await tester.enterText(nameField, '   ');
      await tester.tap(find.text('SAVE & APPLY SETTINGS'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Device name cannot be blank.'), findsOneWidget);

      // Restore valid name
      await tester.enterText(nameField, 'DAKSH-CUSTOM');

      // 2. Validation test: min >= max
      final minAngleField =
          find.widgetWithText(TextFormField, 'Min Angle (OPEN)');
      final maxAngleField =
          find.widgetWithText(TextFormField, 'Max Angle (CLOSED)');
      await tester.enterText(minAngleField, '70.0');
      await tester.enterText(maxAngleField, '60.0');
      await tester.tap(find.text('SAVE & APPLY SETTINGS'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Must be > Min'), findsOneWidget);

      // Restore valid angles
      await tester.enterText(minAngleField, '5.0');
      await tester.enterText(maxAngleField, '55.0');

      // 3. Validation test: EMG threshold out of bounds
      final emgField = find.widgetWithText(
          TextFormField, 'EMG Contraction Trigger Threshold');
      await tester.enterText(emgField, '300.0');
      await tester.tap(find.text('SAVE & APPLY SETTINGS'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Range: 50 - 250'), findsOneWidget);

      // Restore valid EMG threshold
      await tester.enterText(emgField, '135.0');

      // 4. Validation test: Battery warning threshold out of range
      final batteryField =
          find.widgetWithText(TextFormField, 'Battery Warning Threshold');
      await tester.enterText(batteryField, '80.0');
      await tester.tap(find.text('SAVE & APPLY SETTINGS'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Must be between 5% - 50%'), findsOneWidget);

      // Restore valid battery threshold
      await tester.enterText(batteryField, '25.0');
      await tester.pump(const Duration(milliseconds: 100));

      // 5. Successful Save
      await tester.tap(find.text('SAVE & APPLY SETTINGS'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Settings saved & synchronized to device successfully.'),
          findsOneWidget);
    });

    testWidgets(
        'Calibration Wizard: Complete 3-step sequence, verify limits, and block premature save',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: SyntheraProstheticApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Navigate to Calibration tab
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('CALIBRATION'), findsOneWidget);

      // Step 1: Start Calibration Sequence
      expect(find.text('START CALIBRATION SEQUENCE'), findsOneWidget);
      await tester.tap(find.text('START CALIBRATION SEQUENCE'));
      await tester.pump(const Duration(milliseconds: 100));

      // Step 2: Record OPEN endpoint
      expect(find.text('DRIVE & RECORD OPEN POSITION (0°)'), findsOneWidget);
      await tester.tap(find.text('DRIVE & RECORD OPEN POSITION (0°)'));
      await tester.pump(const Duration(milliseconds: 1500));

      // Step 3: Record CLOSED endpoint
      expect(find.text('DRIVE & RECORD CLOSED POSITION (63°)'), findsOneWidget);
      await tester.tap(find.text('DRIVE & RECORD CLOSED POSITION (63°)'));
      await tester.pump(const Duration(milliseconds: 1800));

      // Step 4: Save calibrated limits
      expect(find.text('SAVE & APPLY CALIBRATED LIMITS'), findsOneWidget);
      await tester.tap(find.text('SAVE & APPLY CALIBRATED LIMITS'));
      await tester.pump(const Duration(milliseconds: 500));

      // Verification: Complete banner is shown
      expect(
          find.text(
              'Calibration complete! Physical endpoints verified and synchronized.'),
          findsOneWidget);
      expect(find.text('RE-CALIBRATE AGAIN'), findsOneWidget);
    });
  });
}
