import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synthera_prosthetic_hand/app.dart';
import 'package:synthera_prosthetic_hand/application/providers/theme_provider.dart';

void main() {
  group('Responsive Viewport & Overflow QA Test Matrix', () {
    final viewports = <String, Size>{
      '360x640 (Small Phone)': const Size(360, 640),
      '412x915 (Pixel / Modern Phone)': const Size(412, 915),
      '768x1024 (Tablet Portrait)': const Size(768, 1024),
      '1280x800 (Wide Screen / Tablet Landscape)': const Size(1280, 800),
    };

    for (final entry in viewports.entries) {
      final name = entry.key;
      final size = entry.value;

      testWidgets(
          'Renders Dashboard, Calibration, and Settings on $name in Dark and Light Modes',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
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

        // 1. Check Dashboard (Dark Mode)
        expect(tester.takeException(), isNull);
        expect(find.text('SYNTHERA ROBOTICS'), findsOneWidget);

        // 2. Navigate to Calibration (Dark Mode)
        await tester.tap(find.byIcon(Icons.tune_outlined));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('CALIBRATION'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // 3. Navigate to Settings (Dark Mode)
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('SETTINGS'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // 4. Switch to Light Mode and verify Settings
        container
            .read(themeModeProvider.notifier)
            .setThemeMode(ThemeMode.light);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('SETTINGS'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // 5. Navigate to Calibration (Light Mode)
        await tester.tap(find.byIcon(Icons.tune_outlined));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('CALIBRATION'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // 6. Navigate to Dashboard (Light Mode)
        await tester.tap(find.byIcon(Icons.dashboard_outlined));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('SYNTHERA ROBOTICS'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
        'Renders with Accessibility Text Scale Factor 1.3x without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(1.3),
          ),
          child: ProviderScope(
            child: SyntheraProstheticApp(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Dashboard with 1.3x text scale
      expect(tester.takeException(), isNull);
      expect(find.text('SYNTHERA ROBOTICS'), findsOneWidget);

      // 2. Calibration with 1.3x text scale
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('CALIBRATION'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 3. Settings with 1.3x text scale
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
