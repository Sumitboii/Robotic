import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synthera_prosthetic_hand/application/providers/app_update_provider.dart';
import 'package:synthera_prosthetic_hand/presentation/widgets/system_update_sheet.dart';

void main() {
  group('In-App Update Flow Test Suite', () {
    test('AppUpdateNotifier executes step-by-step update process', () async {
      final notifier = AppUpdateNotifier();
      expect(notifier.state.currentVersion, '1.3.0');
      expect(notifier.state.latestVersion, '1.3.1');
      expect(notifier.state.isUpdateAvailable, isTrue);
      expect(notifier.state.isInstalled, isFalse);

      final updateFuture = notifier.performUpdate(triggerFileDownload: false);
      expect(notifier.state.isUpdating, isTrue);

      await updateFuture;

      expect(notifier.state.isUpdating, isFalse);
      expect(notifier.state.isInstalled, isTrue);
      expect(notifier.state.currentVersion, '1.3.1');
      expect(notifier.state.isUpdateAvailable, isFalse);
      expect(notifier.state.statusMessage, contains('successfully'));
    });

    testWidgets('SystemUpdateSheet displays update info and triggers update',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SystemUpdateSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check title and version elements
      expect(find.text('SYSTEM & APP UPDATES'), findsOneWidget);
      expect(find.text('Update App Now'), findsOneWidget);
      expect(find.text('WHAT\'S NEW IN THIS UPDATE (v1.3.1):'), findsOneWidget);

      // Tap update button
      await tester.tap(find.text('Update App Now'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Updating...'), findsOneWidget);

      // Complete all simulated async steps
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('Update Applied'), findsOneWidget);
      expect(find.text('v1.3.1 ACTIVE'), findsOneWidget);
    });
  });
}
