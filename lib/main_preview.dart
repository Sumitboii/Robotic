import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

/// Dedicated Demo-Phone Preview Entrypoint for Synthera Prosthetic Platform.
///
/// Wraps the production [SyntheraProstheticApp] root inside [DevicePreview]
/// without polluting production bundles (main.dart has zero device_preview dependencies).
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    DevicePreview(
      enabled: true,
      isToolbarVisible: true,
      defaultDevice: Devices.android.samsungGalaxyS20,
      devices: [
        Devices.android
            .samsungGalaxyS20, // Pixel-class / Modern Android (~412x915)
        Devices.android.samsungGalaxyA50, // Small/Medium Android (~360x640)
        Devices.ios.iPhoneSE, // iPhone SE (375x667)
        Devices.ios.iPhone13ProMax, // Modern Large iOS (~393x852)
        Devices.ios.iPad, // Tablet Portrait / Landscape (768x1024)
      ],
      builder: (context) => ProviderScope(
        child: SyntheraProstheticApp(
          locale: DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,
        ),
      ),
    ),
  );
}
