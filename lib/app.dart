import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'application/providers/theme_provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/navigation/app_router.dart';

class SyntheraProstheticApp extends ConsumerWidget {
  final Widget Function(BuildContext, Widget?)? builder;
  final Locale? locale;

  const SyntheraProstheticApp({
    super.key,
    this.builder,
    this.locale,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      builder: builder,
      home: const MainNavigationShell(),
    );
  }
}
