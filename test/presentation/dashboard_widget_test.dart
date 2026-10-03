import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synthera_prosthetic_hand/app.dart';
import 'package:synthera_prosthetic_hand/application/providers/device_providers.dart';
import 'package:synthera_prosthetic_hand/domain/models/hand_state.dart';
import 'package:synthera_prosthetic_hand/presentation/widgets/control_panel.dart';
import 'package:synthera_prosthetic_hand/presentation/widgets/emg_graph.dart';
import 'package:synthera_prosthetic_hand/presentation/widgets/hand_visualizer.dart';

void main() {
  group('UI & Widget Integration Test Suite (Assignment §2 & §10)', () {
    testWidgets(
        'Dashboard renders key telemetry and primary controls (§2 Parity)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: SyntheraProstheticApp(),
        ),
      );

      // Initial pump
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify App Title & Branding
      expect(find.text('SYNTHERA ROBOTICS'), findsOneWidget);
      expect(find.text('Prosthetic Hand Simulator'), findsOneWidget);

      // 2. Verify Hand Visualizer widget
      expect(find.byType(HandVisualizer), findsOneWidget);

      // 3. Verify EMG Graph widget
      expect(find.byType(EmgGraph), findsOneWidget);

      // 4. Verify Control Panel with OPEN, STOP, CLOSE buttons
      expect(find.byType(ControlPanel), findsOneWidget);
      expect(find.text('OPEN'), findsOneWidget);
      expect(find.text('STOP'), findsOneWidget);
      expect(find.text('CLOSE'), findsOneWidget);

      // 5. Verify Navigation bar destinations
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Calibration'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets(
        'OPEN and CLOSE change position and state, STOP halts movement and shows STOPPED',
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

      // 1. Tap OPEN button
      await tester.tap(find.text('OPEN'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(
          deviceService.currentTelemetry.handState == HandState.opening ||
              deviceService.currentTelemetry.handState == HandState.open ||
              deviceService.currentTelemetry.handState == HandState.holding,
          isTrue);

      // 2. Tap STOP button
      await tester.tap(find.text('STOP'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
          deviceService.currentTelemetry.handState, equals(HandState.stopped));
      expect(find.text('STOPPED'), findsWidgets);

      // 3. Tap CLOSE button
      await tester.tap(find.text('CLOSE'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(
          deviceService.currentTelemetry.handState == HandState.closing ||
              deviceService.currentTelemetry.handState == HandState.closed ||
              deviceService.currentTelemetry.handState == HandState.holding,
          isTrue);

      // 4. Emergency STOP halts immediately
      await tester.tap(find.text('STOP'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
          deviceService.currentTelemetry.handState, equals(HandState.stopped));
      expect(find.text('STOPPED'), findsWidgets);
    });

    testWidgets(
        'Prominent low battery banner appears at threshold and disappears above (§10)',
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

      // Above threshold: no banner
      expect(find.textContaining('LOW BATTERY'), findsNothing);

      // Drain to 18% (at or below 20%)
      await deviceService.triggerDemoBatteryDrain(18.0);
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('LOW BATTERY'), findsWidgets);
      expect(find.textContaining('LOW BATTERY  Battery: 18%'), findsOneWidget);

      // Recharge to 100%
      await deviceService.triggerDemoBatteryDrain(100.0);
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('LOW BATTERY'), findsNothing);
    });

    testWidgets(
        'Simulate EMG sensor fault displays UNAVAILABLE and recovers automatically (§10)',
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

      // Toggle EMG fault on
      await deviceService.toggleEmgSensorFault(true);
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('EMG SENSOR UNAVAILABLE'), findsOneWidget);
      expect(find.text('UNAVAILABLE'), findsWidgets);

      // Toggle EMG fault off -> recovers
      await deviceService.toggleEmgSensorFault(false);
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('EMG SENSOR UNAVAILABLE'), findsNothing);
    });

    testWidgets(
        'Connection failure flow shows Connection Failed banner and retry succeeds (§10)',
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

      // Disconnect and arm failure on next reconnect
      await deviceService.disconnect();
      await deviceService.setFailNextReconnect(true);
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Device Disconnected'), findsOneWidget);

      // Tap Reconnect -> fails
      await tester.tap(find.text('RECONNECT'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Connection Failed'), findsOneWidget);
      expect(find.text('RECONNECT'), findsOneWidget);

      // Retry -> succeeds
      await tester.tap(find.text('RECONNECT'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Connected'), findsOneWidget);
    });
  });
}
