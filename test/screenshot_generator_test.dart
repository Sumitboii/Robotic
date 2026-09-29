import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synthera_prosthetic_hand/app.dart';
import 'package:synthera_prosthetic_hand/application/providers/device_providers.dart';
import 'package:synthera_prosthetic_hand/domain/models/device_settings.dart';
import 'package:synthera_prosthetic_hand/domain/models/operating_mode.dart';
import 'package:synthera_prosthetic_hand/infrastructure/device/mock/mock_device_service.dart';

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

    testWidgets('Generate emg-mode.png, auto-mode.png, and emergency-stop.png',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // ── 1. EMG Mode Screenshot ──
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

      // ── 2. AUTO Mode Screenshot ──
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

      // ── 3. Emergency STOP Screenshot ──
      final repaintKeyStop = GlobalKey();
      final mockServiceStop = MockDeviceService();
      mockServiceStop.simulatedEsp32.hand.open();
      mockServiceStop.simulatedEsp32.hand.step(0.3); // mid-way
      await mockServiceStop.emergencyStop();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceServiceProvider.overrideWithValue(mockServiceStop),
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

      expect(File('docs/screenshots/emg-mode.png').existsSync(), isTrue);
      expect(File('docs/screenshots/auto-mode.png').existsSync(), isTrue);
      expect(File('docs/screenshots/emergency-stop.png').existsSync(), isTrue);
    });
  });
}
