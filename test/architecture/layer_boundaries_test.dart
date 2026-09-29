import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Architecture Layer Boundaries & Dependency Rule Enforcement', () {
    test('lib/domain must have ZERO Flutter or outer layer imports', () {
      final domainDir = Directory('lib/domain');
      if (!domainDir.existsSync()) return;

      final domainFiles = domainDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String>[];

      for (final file in domainFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');

        for (int i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('import ') || line.startsWith('export ')) {
            if (line.contains('package:flutter/') ||
                line.contains('package:flutter_riverpod/') ||
                line.contains('application/') ||
                line.contains('infrastructure/') ||
                line.contains('presentation/')) {
              violations.add('${file.path}:${i + 1} -> $line');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Domain layer must be pure Dart and have zero dependencies on Flutter or outer layers.',
      );
    });

    test('lib/presentation must NOT import concrete simulation models', () {
      final presentationDir = Directory('lib/presentation');
      if (!presentationDir.existsSync()) return;

      final presentationFiles = presentationDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String>[];

      for (final file in presentationFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');

        for (int i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('import ')) {
            if (line.contains('simulated_esp32.dart') ||
                line.contains('simulated_prosthetic_hand.dart') ||
                line.contains('mock_device_service.dart')) {
              violations.add('${file.path}:${i + 1} -> $line');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Presentation layer must interact strictly with DeviceService abstraction, not concrete simulation hardware.',
      );
    });

    test('lib/application must interact with DeviceService abstraction', () {
      final applicationDir = Directory('lib/application');
      if (!applicationDir.existsSync()) return;

      final applicationFiles = applicationDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String>[];

      // Composition root exception: device_providers.dart wires the default MockDeviceService instance
      const allowedCompositionRoot = 'device_providers.dart';

      for (final file in applicationFiles) {
        final isCompositionRoot = file.path.endsWith(allowedCompositionRoot);
        final content = file.readAsStringSync();
        final lines = content.split('\n');

        for (int i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('import ')) {
            if (line.contains('simulated_esp32.dart') ||
                line.contains('simulated_prosthetic_hand.dart')) {
              violations.add('${file.path}:${i + 1} -> $line');
            } else if (line.contains('mock_device_service.dart') &&
                !isCompositionRoot) {
              violations.add('${file.path}:${i + 1} -> $line');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Application layer controllers must depend on DeviceService interface, with only the composition root ($allowedCompositionRoot) instantiating MockDeviceService.',
      );
    });
  });
}
