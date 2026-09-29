import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synthera_prosthetic_hand/app.dart';
import 'package:synthera_prosthetic_hand/application/providers/device_providers.dart';
import 'package:synthera_prosthetic_hand/domain/models/hand_state.dart';
import 'package:synthera_prosthetic_hand/domain/models/operating_mode.dart';
import 'package:synthera_prosthetic_hand/presentation/widgets/battery_indicator.dart';
import 'package:synthera_prosthetic_hand/presentation/widgets/connection_banner.dart';
import 'package:synthera_prosthetic_hand/presentation/widgets/control_panel.dart';
import 'package:synthera_prosthetic_hand/presentation/widgets/emg_graph.dart';
import 'package:synthera_prosthetic_hand/presentation/widgets/hand_visualizer.dart';

void main() {
  group('UI & Widget Integration Test Suite', () {
    testWidgets('Dashboard renders key telemetry and primary controls',
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
        'Navigation switches between Dashboard, Calibration, and Settings',
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

      // Navigate to Calibration screen
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('CALIBRATION'), findsOneWidget);

      // Navigate to Settings screen
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('SETTINGS'), findsOneWidget);

      // Navigate back to Dashboard
      await tester.tap(find.byIcon(Icons.dashboard_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('SYNTHERA ROBOTICS'), findsOneWidget);
    });

    testWidgets('Simulate disconnect and reconnect flow via ConnectionBanner',
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

      // Disconnect simulated device
      final deviceService = container.read(deviceServiceProvider);
      await deviceService.disconnect();
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Confirm "Device Disconnected" and RECONNECT button appear
      expect(find.text('Device Disconnected'), findsOneWidget);
      expect(find.text('RECONNECT'), findsOneWidget);

      // 2. Tap RECONNECT button
      await tester.tap(find.text('RECONNECT'));
      await tester.pump(const Duration(milliseconds: 100));

      // 3. Confirm state progresses to "Reconnecting..."
      expect(find.text('Reconnecting...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 4. Wait for reconnection to complete (700ms simulation delay)
      await tester.pump(const Duration(milliseconds: 800));

      // 5. Confirm final state is "Connected"
      expect(find.text('Connected'), findsOneWidget);
      expect(find.byType(ConnectionBanner), findsOneWidget);
    });

    testWidgets('Low battery warning renders badge and changes status',
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

      // Trigger low battery (15%)
      final deviceService = container.read(deviceServiceProvider);
      await deviceService.triggerDemoBatteryDrain(15.0);
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(BatteryIndicator), findsOneWidget);
      expect(find.text('LOW'), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);
    });

    testWidgets(
        'Repeated navigation between screens during active AUTO simulation runs cleanly without leaks or exceptions',
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
      await deviceService.setOperatingMode(OperatingMode.auto);
      await tester.pump(const Duration(milliseconds: 100));

      // Repeated rapid navigation while timers and streams are actively firing
      for (int cycle = 0; cycle < 3; cycle++) {
        await tester.tap(find.byIcon(Icons.tune_outlined));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('CALIBRATION'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('SETTINGS'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byIcon(Icons.dashboard_outlined));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('SYNTHERA ROBOTICS'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
