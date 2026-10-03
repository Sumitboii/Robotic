import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Loads real typography and icons for test rendering to eliminate
/// default Ahem font black boxes and missing icon glyphs.
Future<void> loadTestFonts() async {
  // 1. Material Icons
  final iconFile = File('C:/Users/ssing/.puro/shared/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (iconFile.existsSync()) {
    final iconBytes = iconFile.readAsBytesSync();
    final fontLoader = FontLoader('MaterialIcons');
    fontLoader.addFont(Future.value(ByteData.view(iconBytes.buffer)));
    await fontLoader.load();
  }

  // 2. Inter font for UI text and system fallbacks
  final interFile = File('assets/fonts/Inter-Variable.ttf');
  if (interFile.existsSync()) {
    final interBytes = interFile.readAsBytesSync();
    for (final family in ['Inter', 'Roboto', '.SF Pro Text', '.SF UI Text', 'sans-serif']) {
      final loader = FontLoader(family);
      loader.addFont(Future.value(ByteData.view(interBytes.buffer)));
      await loader.load();
    }
  }

  // 3. IBM Plex Mono for real-time telemetry readouts
  final monoFile = File('assets/fonts/IBMPlexMono-Regular.ttf');
  final monoBoldFile = File('assets/fonts/IBMPlexMono-Bold.ttf');
  if (monoFile.existsSync()) {
    final loader = FontLoader('IBMPlexMono');
    loader.addFont(Future.value(ByteData.view(monoFile.readAsBytesSync().buffer)));
    if (monoBoldFile.existsSync()) {
      loader.addFont(Future.value(ByteData.view(monoBoldFile.readAsBytesSync().buffer)));
    }
    await loader.load();
  }
}
