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
import 'package:synthera_prosthetic_hand/domain/models/operating_mode.dart';
import 'package:synthera_prosthetic_hand/infrastructure/device/mock/mock_device_service.dart';

class CustomThemeNotifier extends ThemeModeNotifier {
  CustomThemeNotifier(ThemeMode initial) : super() {
    state = initial;
  }
}

Future<void> capturePng(
    WidgetTester tester, GlobalKey key, String outputPath) async {
  await tester.runAsync(() async {
    final renderObject =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await renderObject.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    final file = File(outputPath);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(pngBytes);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Screenshot Generation Suite (Golden Rendering)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Generate all 9 documentation screenshots',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // ── 1. Dashboard (Light Theme) ──
      final repaintKeyLight = GlobalKey();
      final mockServiceLight = MockDeviceService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceServiceProvider.overrideWithValue(mockServiceLight),
            themeModeProvider
                .overrideWith((ref) => CustomThemeNotifier(ThemeMode.light)),
          ],
          child: RepaintBoundary(
            key: repaintKeyLight,
            child: const SyntheraProstheticApp(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await capturePng(
          tester, repaintKeyLight, 'docs/screenshots/dashboard.png');
      mockServiceLight.dispose();

      // ── 2. Dashboard (Dark Theme) ──
      final repaintKeyDark = GlobalKey();
      final mockServiceDark = MockDeviceService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceServiceProvider.overrideWithValue(mockServiceDark),
            themeModeProvider
                .overrideWith((ref) => CustomThemeNotifier(ThemeMode.dark)),
          ],
          child: RepaintBoundary(
            key: repaintKeyDark,
            child: const SyntheraProstheticApp(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await capturePng(
          tester, repaintKeyDark, 'docs/screenshots/dashboard-dark.png');
      mockServiceDark.dispose();

      // ── 3. Calibration Screen ──
      final repaintKeyCalib = GlobalKey();
      final mockServiceCalib = MockDeviceService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceServiceProvider.overrideWithValue(mockServiceCalib),
            themeModeProvider
                .overrideWith((ref) => CustomThemeNotifier(ThemeMode.dark)),
          ],
          child: RepaintBoundary(
            key: repaintKeyCalib,
            child: const SyntheraProstheticApp(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      await capturePng(
          tester, repaintKeyCalib, 'docs/screenshots/calibration.png');
      mockServiceCalib.dispose();

      // ── 4. Settings Screen ──
      final repaintKeySettings = GlobalKey();
      final mockServiceSettings = MockDeviceService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceServiceProvider.overrideWithValue(mockServiceSettings),
            themeModeProvider
                .overrideWith((ref) => CustomThemeNotifier(ThemeMode.dark)),
          ],
          child: RepaintBoundary(
            key: repaintKeySettings,
            child: const SyntheraProstheticApp(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      await capturePng(
          tester, repaintKeySettings, 'docs/screenshots/settings.png');
      mockServiceSettings.dispose();

      // ── 5. Disconnected State ──
      final repaintKeyDisc = GlobalKey();
      final mockServiceDisc = MockDeviceService();
      await mockServiceDisc.disconnect();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceServiceProvider.overrideWithValue(mockServiceDisc),
            themeModeProvider
                .overrideWith((ref) => CustomThemeNotifier(ThemeMode.dark)),
          ],
          child: RepaintBoundary(
            key: repaintKeyDisc,
            child: const SyntheraProstheticApp(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await capturePng(
          tester, repaintKeyDisc, 'docs/screenshots/disconnected.png');
      mockServiceDisc.dispose();

      // ── 6. Low Battery State ──
      final repaintKeyLowBatt = GlobalKey();
      final mockServiceLowBatt = MockDeviceService();
      mockServiceLowBatt.simulatedEsp32.setBatteryPercentage(15.0);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceServiceProvider.overrideWithValue(mockServiceLowBatt),
            themeModeProvider
                .overrideWith((ref) => CustomThemeNotifier(ThemeMode.dark)),
          ],
          child: RepaintBoundary(
            key: repaintKeyLowBatt,
            child: const SyntheraProstheticApp(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await capturePng(
          tester, repaintKeyLowBatt, 'docs/screenshots/low-battery.png');
      mockServiceLowBatt.dispose();

      // ── 7. EMG Mode Screenshot ──
      final repaintKeyEmg = GlobalKey();
      final mockServiceEmg = MockDeviceService(
        initialSettings:
            const DeviceSettings(defaultOperatingMode: OperatingMode.emg),
      );
      mockServiceEmg.simulatedEsp32.triggerEmgSpike(175.0);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceServiceProvider.overrideWithValue(mockServiceEmg),
            themeModeProvider
                .overrideWith((ref) => CustomThemeNotifier(ThemeMode.dark)),
          ],
          child: RepaintBoundary(
            key: repaintKeyEmg,
            child: const SyntheraProstheticApp(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await capturePng(tester, repaintKeyEmg, 'docs/screenshots/emg-mode.png');
      mockServiceEmg.dispose();

      // ── 8. AUTO Mode Screenshot ──
      final repaintKeyAuto = GlobalKey();
      final mockServiceAuto = MockDeviceService(
        initialSettings:
            const DeviceSettings(defaultOperatingMode: OperatingMode.auto),
      );
      mockServiceAuto.simulatedEsp32.setOperatingMode(OperatingMode.auto);
      mockServiceAuto.simulatedEsp32.hand.close();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceServiceProvider.overrideWithValue(mockServiceAuto),
            themeModeProvider
                .overrideWith((ref) => CustomThemeNotifier(ThemeMode.dark)),
          ],
          child: RepaintBoundary(
            key: repaintKeyAuto,
            child: const SyntheraProstheticApp(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await capturePng(
          tester, repaintKeyAuto, 'docs/screenshots/auto-mode.png');
      mockServiceAuto.dispose();

      // ── 9. Emergency STOP Screenshot ──
      final repaintKeyStop = GlobalKey();
      final mockServiceStop = MockDeviceService();
      mockServiceStop.simulatedEsp32.hand.open();
      mockServiceStop.simulatedEsp32.hand.step(0.3); // mid-way
      await mockServiceStop.emergencyStop();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceServiceProvider.overrideWithValue(mockServiceStop),
            themeModeProvider
                .overrideWith((ref) => CustomThemeNotifier(ThemeMode.dark)),
          ],
          child: RepaintBoundary(
            key: repaintKeyStop,
            child: const SyntheraProstheticApp(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await capturePng(
          tester, repaintKeyStop, 'docs/screenshots/emergency-stop.png');
      mockServiceStop.dispose();

      expect(File('docs/screenshots/dashboard.png').existsSync(), isTrue);
      expect(File('docs/screenshots/dashboard-dark.png').existsSync(), isTrue);
      expect(File('docs/screenshots/calibration.png').existsSync(), isTrue);
      expect(File('docs/screenshots/settings.png').existsSync(), isTrue);
      expect(File('docs/screenshots/disconnected.png').existsSync(), isTrue);
      expect(File('docs/screenshots/low-battery.png').existsSync(), isTrue);
      expect(File('docs/screenshots/emg-mode.png').existsSync(), isTrue);
      expect(File('docs/screenshots/auto-mode.png').existsSync(), isTrue);
      expect(File('docs/screenshots/emergency-stop.png').existsSync(), isTrue);
    });
  });
}
