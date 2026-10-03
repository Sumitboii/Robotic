import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synthera_prosthetic_hand/app.dart';
import 'package:synthera_prosthetic_hand/application/providers/device_providers.dart';
import 'package:synthera_prosthetic_hand/application/providers/theme_provider.dart';
import 'package:synthera_prosthetic_hand/domain/models/device_settings.dart';
import 'package:synthera_prosthetic_hand/domain/models/hand_state.dart';
import 'package:synthera_prosthetic_hand/domain/models/operating_mode.dart';
import 'package:synthera_prosthetic_hand/infrastructure/device/mock/mock_device_service.dart';
import 'package:synthera_prosthetic_hand/presentation/preview/phone_frame.dart';
import 'package:synthera_prosthetic_hand/presentation/widgets/hand_visualizer.dart';
import '../helpers/test_font_loader.dart';

class CustomThemeNotifier extends ThemeModeNotifier {
  CustomThemeNotifier(ThemeMode initial) : super() {
    state = initial;
  }
}

Future<void> capturePng(
    WidgetTester tester, GlobalKey key, String outputPath) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      final pngBytes = byteData.buffer.asUint8List();
      final file = File(outputPath);
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(pngBytes);
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 8 Phone Frame & Robotic Hand Screenshot Generation', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await loadTestFonts();
    });

    // ═══════════════════════════════════════════════════════
    // ── 1. ROBOTIC HAND VECTOR CLOSE-UPS ──
    // ═══════════════════════════════════════════════════════
    final handAngles = <String, double>{
      'open': 0.0,
      'half': 31.5,
      'closed': 63.0,
    };

    for (final angleEntry in handAngles.entries) {
      final name = angleEntry.key;
      final angle = angleEntry.value;

      for (final isDark in [true, false]) {
        final themeName = isDark ? 'dark' : 'light';

        testWidgets('Render hand-$name-$themeName.png',
            (WidgetTester tester) async {
          tester.view.physicalSize = const Size(400, 360);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          final repaintKey = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              theme: isDark ? ThemeData.dark() : ThemeData.light(),
              home: Scaffold(
                backgroundColor:
                    isDark ? const Color(0xFF0F141C) : const Color(0xFFF1F5F9),
                body: Center(
                  child: RepaintBoundary(
                    key: repaintKey,
                    child: SizedBox(
                      width: 360,
                      height: 320,
                      child: HandVisualizer(
                        currentAngle: angle,
                        handState: angle == 0.0
                            ? HandState.open
                            : (angle == 63.0
                                ? HandState.closed
                                : HandState.holding),
                        height: 320,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          await capturePng(tester, repaintKey,
              'docs/screenshots/hand/hand-$name-$themeName.png');
        });
      }
    }

    // ═══════════════════════════════════════════════════════
    // ── 2. IPHONE 18 PRO & PRO MAX PHONE FRAME SCREENSHOTS ──
    // ═══════════════════════════════════════════════════════
    testWidgets('Generate iPhone 18 Pro & Pro Max documentation screenshots',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 1. iPhone 18 Pro Dashboard Dark
      final key18ProDark = GlobalKey();
      final mock1 = MockDeviceService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceServiceProvider.overrideWithValue(mock1),
            themeModeProvider
                .overrideWith((ref) => CustomThemeNotifier(ThemeMode.dark)),
          ],
          child: Center(
            child: RepaintBoundary(
              key: key18ProDark,
              child: const PhoneFrame(
                profile: PhoneProfile.iphone18Pro,
                isDark: true,
                child: SyntheraProstheticApp(),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await capturePng(tester, key18ProDark,
          'docs/screenshots/phone/iphone18pro-dashboard-dark.png');
      mock1.dispose();

      // 2. iPhone 18 Pro Dashboard Light
      final key18ProLight = GlobalKey();
      final mock2 = MockDeviceService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceServiceProvider.overrideWithValue(mock2),
            themeModeProvider
                .overrideWith((ref) => CustomThemeNotifier(ThemeMode.light)),
          ],
          child: Center(
            child: RepaintBoundary(
              key: key18ProLight,
              child: const PhoneFrame(
                profile: PhoneProfile.iphone18Pro,
                isDark: false,
                child: SyntheraProstheticApp(),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await capturePng(tester, key18ProLight,
          'docs/screenshots/phone/iphone18pro-dashboard-light.png');
      mock2.dispose();

      // 3. iPhone 18 Pro Calibration
      final key18ProCalib = GlobalKey();
      final mock3 = MockDeviceService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceServiceProvider.overrideWithValue(mock3),
            themeModeProvider
                .overrideWith((ref) => CustomThemeNotifier(ThemeMode.dark)),
          ],
          child: Center(
            child: RepaintBoundary(
              key: key18ProCalib,
              child: const PhoneFrame(
                profile: PhoneProfile.iphone18Pro,
                isDark: true,
                child: SyntheraProstheticApp(),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      await capturePng(tester, key18ProCalib,
          'docs/screenshots/phone/iphone18pro-calibration.png');
      mock3.dispose();

      // 4. iPhone 18 Pro Settings
      final key18ProSettings = GlobalKey();
      final mock4 = MockDeviceService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceServiceProvider.overrideWithValue(mock4),
            themeModeProvider
                .overrideWith((ref) => CustomThemeNotifier(ThemeMode.dark)),
          ],
          child: Center(
            child: RepaintBoundary(
              key: key18ProSettings,
              child: const PhoneFrame(
                profile: PhoneProfile.iphone18Pro,
                isDark: true,
                child: SyntheraProstheticApp(),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      await capturePng(tester, key18ProSettings,
          'docs/screenshots/phone/iphone18pro-settings.png');
      mock4.dispose();

      // 5. iPhone 18 Pro EMG Mode
      final key18ProEmg = GlobalKey();
      final mock5 = MockDeviceService(
        initialSettings:
            const DeviceSettings(defaultOperatingMode: OperatingMode.emg),
      );
      mock5.simulatedEsp32.triggerEmgSpike(170.0);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceServiceProvider.overrideWithValue(mock5),
            themeModeProvider
                .overrideWith((ref) => CustomThemeNotifier(ThemeMode.dark)),
          ],
          child: Center(
            child: RepaintBoundary(
              key: key18ProEmg,
              child: const PhoneFrame(
                profile: PhoneProfile.iphone18Pro,
                isDark: true,
                child: SyntheraProstheticApp(),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await capturePng(tester, key18ProEmg,
          'docs/screenshots/phone/iphone18pro-emg-mode.png');
      mock5.dispose();

      // 6. iPhone 18 Pro Low Battery
      final key18ProLowBatt = GlobalKey();
      final mock6 = MockDeviceService();
      mock6.simulatedEsp32.setBatteryPercentage(18.0);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceServiceProvider.overrideWithValue(mock6),
            themeModeProvider
                .overrideWith((ref) => CustomThemeNotifier(ThemeMode.dark)),
          ],
          child: Center(
            child: RepaintBoundary(
              key: key18ProLowBatt,
              child: const PhoneFrame(
                profile: PhoneProfile.iphone18Pro,
                isDark: true,
                child: SyntheraProstheticApp(),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await capturePng(tester, key18ProLowBatt,
          'docs/screenshots/phone/iphone18pro-low-battery.png');
      mock6.dispose();

      // 7. iPhone 18 Pro Max Dashboard
      final key18ProMax = GlobalKey();
      final mock7 = MockDeviceService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceServiceProvider.overrideWithValue(mock7),
            themeModeProvider
                .overrideWith((ref) => CustomThemeNotifier(ThemeMode.dark)),
          ],
          child: Center(
            child: RepaintBoundary(
              key: key18ProMax,
              child: const PhoneFrame(
                profile: PhoneProfile.iphone18ProMax,
                isDark: true,
                child: SyntheraProstheticApp(),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await capturePng(tester, key18ProMax,
          'docs/screenshots/phone/iphone18promax-dashboard.png');
      mock7.dispose();

      // Verify all screenshots exist
      expect(
          File('docs/screenshots/phone/iphone18pro-dashboard-dark.png')
              .existsSync(),
          isTrue);
      expect(
          File('docs/screenshots/phone/iphone18pro-dashboard-light.png')
              .existsSync(),
          isTrue);
      expect(
          File('docs/screenshots/phone/iphone18pro-calibration.png')
              .existsSync(),
          isTrue);
      expect(
          File('docs/screenshots/phone/iphone18pro-settings.png').existsSync(),
          isTrue);
      expect(
          File('docs/screenshots/phone/iphone18pro-emg-mode.png').existsSync(),
          isTrue);
      expect(
          File('docs/screenshots/phone/iphone18pro-low-battery.png')
              .existsSync(),
          isTrue);
      expect(
          File('docs/screenshots/phone/iphone18promax-dashboard.png')
              .existsSync(),
          isTrue);
    });
  });
}
