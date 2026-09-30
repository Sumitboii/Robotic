import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synthera_prosthetic_hand/app.dart';
import 'package:synthera_prosthetic_hand/application/providers/device_providers.dart';
import 'package:synthera_prosthetic_hand/domain/models/hand_state.dart';
import 'package:synthera_prosthetic_hand/domain/models/operating_mode.dart';
import 'package:synthera_prosthetic_hand/presentation/widgets/battery_indicator.dart';
import 'package:synthera_prosthetic_hand/presentation/widgets/control_panel.dart';
import 'package:synthera_prosthetic_hand/presentation/widgets/emg_graph.dart';
import 'package:synthera_prosthetic_hand/presentation/widgets/hand_visualizer.dart';

void main() {
  group('Full Evaluator Demo Sequence Integration Test (Assignment Alignment)',
      () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Executes entire 8-step demo script end-to-end',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
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

      final deviceService = container.read(deviceServiceProvider);

      // ── Step 1: Launch & Confirm Telemetry Fields (§2) ──
      expect(find.text('SYNTHERA ROBOTICS'), findsOneWidget);
      expect(find.text('DAKSH-01'), findsOneWidget);
      expect(find.byType(HandVisualizer), findsOneWidget);
      expect(find.byType(BatteryIndicator), findsOneWidget);
      expect(find.byType(EmgGraph), findsOneWidget);
      expect(find.byType(ControlPanel), findsOneWidget);

      // ── Step 2: OPEN, CLOSE, and STOP Mid-Movement (§2 & §3) ──
      await tester.tap(find.text('OPEN'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(
          deviceService.currentTelemetry.handState == HandState.opening ||
              deviceService.currentTelemetry.handState == HandState.open ||
              deviceService.currentTelemetry.handState == HandState.holding,
          isTrue);

      await tester.tap(find.text('STOP'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
          deviceService.currentTelemetry.handState, equals(HandState.stopped));
      expect(find.text('STOPPED'), findsWidgets);

      await tester.tap(find.text('CLOSE'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(
          deviceService.currentTelemetry.handState == HandState.closing ||
              deviceService.currentTelemetry.handState == HandState.closed ||
              deviceService.currentTelemetry.handState == HandState.holding,
          isTrue);

      await tester.tap(find.text('STOP'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
          deviceService.currentTelemetry.handState, equals(HandState.stopped));

      // ── Step 3: Switch to EMG Mode & Threshold-Driven Behavior (§7) ──
      await deviceService.setOperatingMode(OperatingMode.emg);
      await tester.pump(const Duration(milliseconds: 100));
      expect(deviceService.currentTelemetry.operatingMode,
          equals(OperatingMode.emg));

      // Trigger contraction spike (+170 uV)
      await deviceService.triggerEmgSpike(170.0);
      await tester.pump(const Duration(milliseconds: 100));

      // ── Step 4: Switch to AUTO, Observe Automatic Cycle & STOP Mid-AUTO (§7) ──
      await deviceService.setOperatingMode(OperatingMode.auto);
      await tester.pump(const Duration(milliseconds: 100));
      expect(deviceService.currentTelemetry.operatingMode,
          equals(OperatingMode.auto));

      // Emergency STOP cancels AUTO immediately
      await tester.tap(find.text('STOP'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
          deviceService.currentTelemetry.handState, equals(HandState.stopped));
      expect(deviceService.currentTelemetry.operatingMode,
          equals(OperatingMode.manual));

      // ── Step 5: Change Setting, Save and Confirm Persistence (§8) ──
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('SETTINGS'), findsOneWidget);

      final nameField =
          find.widgetWithText(TextFormField, 'Device Name / Model');
      await tester.enterText(nameField, 'DAKSH-VERIFIED');
      await tester.tap(find.text('SAVE & APPLY SETTINGS'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Settings saved & synchronized to device successfully.'),
          findsOneWidget);

      // Return to Dashboard
      await tester.tap(find.byIcon(Icons.dashboard_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('DAKSH-VERIFIED'), findsOneWidget);

      // ── Step 6: 3-Step Mechanical Calibration Flow (§9) ──
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('CALIBRATION'), findsOneWidget);

      await tester.tap(find.text('START CALIBRATION SEQUENCE'));
      await tester.pump(const Duration(milliseconds: 100));

      // Move to open & wait to settle
      await tester.tap(find.text('Move to OPEN'));
      for (int i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(find.textContaining('Capture OPEN'));
      await tester.pump(const Duration(milliseconds: 300));

      // Move to close & wait to settle
      await tester.tap(find.text('Move to CLOSED'));
      for (int i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(find.textContaining('Capture CLOSED'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('SAVE & APPLY CALIBRATED LIMITS'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('Calibration Complete!'), findsOneWidget);

      // Return to Dashboard
      await tester.tap(find.byIcon(Icons.dashboard_outlined));
      await tester.pump(const Duration(milliseconds: 300));

      // ── Step 7: Disconnect & Reconnect Flow (§10) ──
      await deviceService.disconnect();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Device Disconnected'), findsOneWidget);
      expect(find.text('RECONNECT'), findsOneWidget);

      await tester.tap(find.text('RECONNECT'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Reconnecting...'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('Connected'), findsOneWidget);

      // ── Step 8: Trigger Low Battery via Demo Control (§6 & §10) ──
      await deviceService.triggerDemoBatteryDrain(15.0);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('LOW'), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.textContaining('LOW BATTERY'), findsWidgets);
    });
  });
}
