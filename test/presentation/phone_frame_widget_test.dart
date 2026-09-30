import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synthera_prosthetic_hand/app.dart';
import 'package:synthera_prosthetic_hand/presentation/preview/phone_frame.dart';

void main() {
  group('PhoneFrame & Preview Container Widget Test Suite (Phase 8)', () {
    testWidgets(
        'App inside PhoneFrame lays out at exactly 402x874 for iPhone 18 Pro',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Size? innerSize;
      EdgeInsets? innerPadding;
      TargetPlatform? innerPlatform;

      await tester.pumpWidget(
        MaterialApp(
          home: PhoneFrame(
            profile: PhoneProfile.iphone18Pro,
            isDark: true,
            child: Builder(
              builder: (context) {
                final media = MediaQuery.of(context);
                innerSize = media.size;
                innerPadding = media.padding;
                innerPlatform = Theme.of(context).platform;
                return const Scaffold(
                  body: Center(child: Text('Inside iPhone 18 Pro')),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(innerSize, equals(const Size(402, 874)));
      expect(innerPadding, equals(const EdgeInsets.only(top: 62, bottom: 34)));
      expect(innerPlatform, equals(TargetPlatform.iOS));
      expect(find.text('9:41'), findsOneWidget);
    });

    testWidgets(
        'Profile switch changes layout size to 440x956 for iPhone 18 Pro Max',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Size? innerSize;

      await tester.pumpWidget(
        MaterialApp(
          home: PhoneFrame(
            profile: PhoneProfile.iphone18ProMax,
            isDark: false,
            child: Builder(
              builder: (context) {
                innerSize = MediaQuery.of(context).size;
                return const Scaffold(body: SizedBox());
              },
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(innerSize, equals(const Size(440, 956)));
    });

    testWidgets(
        'Renders full SyntheraProstheticApp inside PhonePreviewContainer without overflows',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: PhonePreviewContainer(
            child: SyntheraProstheticApp(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Controls and Phone frame are rendered
      expect(find.text('DEVICE PREVIEW'), findsOneWidget);
      expect(find.textContaining('Layout preview of a 402×874 pt screen'),
          findsOneWidget);
      expect(find.text('SYNTHERA ROBOTICS'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Navigate to Calibration
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('CALIBRATION'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Navigate to Settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
