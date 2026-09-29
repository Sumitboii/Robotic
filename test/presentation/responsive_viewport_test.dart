import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synthera_prosthetic_hand/app.dart';
import 'package:synthera_prosthetic_hand/application/providers/theme_provider.dart';

void main() {
  group('Responsive Viewport & Overflow QA Test Suite', () {
    testWidgets(
        'Renders Dashboard, Calibration, and Settings without overflow on 360x640 phone',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: SyntheraProstheticApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Check Dashboard on small screen
      expect(tester.takeException(), isNull);

      // 2. Navigate to Calibration on small screen
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('CALIBRATION'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 3. Navigate to Settings on small screen
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Renders Dashboard, Calibration, and Settings on 360x640 in Light Mode',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          child: Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return const SyntheraProstheticApp();
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Dashboard Light 360x640
      expect(tester.takeException(), isNull);
      expect(find.text('SYNTHERA ROBOTICS'), findsOneWidget);

      // 2. Calibration Light 360x640
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('CALIBRATION'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 3. Settings Light 360x640
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Renders Dashboard, Calibration, and Settings on 412x915 in Dark and Light Modes',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          child: Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return const SyntheraProstheticApp();
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Dashboard Dark 412x915
      expect(tester.takeException(), isNull);

      // Calibration Dark 412x915
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('CALIBRATION'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Settings Dark 412x915
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Switch to Light Mode on 412x915
      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });
}
