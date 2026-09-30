import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'presentation/preview/phone_frame.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: PhonePreviewContainer(
        child: SyntheraProstheticApp(),
      ),
    ),
  );
}
