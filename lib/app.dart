import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'application/providers/theme_provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/navigation/app_router.dart';

class SyntheraProstheticApp extends ConsumerWidget {
  const SyntheraProstheticApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const MainNavigationShell(),
    );
  }
}
