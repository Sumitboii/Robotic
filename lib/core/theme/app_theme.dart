import 'package:flutter/material.dart';

class AppTheme {
  // Cybernetics Palette
  static const Color cyan = Color(0xFF00E5FF);
  static const Color blue = Color(0xFF2979FF);
  static const Color crimson = Color(0xFFFF1744);
  static const Color amber = Color(0xFFFFAB00);
  static const Color mint = Color(0xFF00E676);

  // Dark Palette
  static const Color darkBg = Color(0xFF0B0E14);
  static const Color darkSurface = Color(0xFF141923);
  static const Color darkCard = Color(0xFF1B2230);
  static const Color darkBorder = Color(0xFF263248);

  // Light Palette
  static const Color lightBg = Color(0xFFF4F6F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFE9ECEF);
  static const Color lightBorder = Color(0xFFCFD8DC);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: cyan,
        onPrimary: Colors.black,
        secondary: blue,
        onSecondary: Colors.white,
        error: crimson,
        onError: Colors.white,
        surface: darkSurface,
        onSurface: Color(0xFFECEFF1),
      ),
      cardTheme: CardTheme(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: cyan.withAlpha(51),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: cyan,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            );
          }
          return const TextStyle(color: Color(0xFF90A4AE), fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: cyan);
          }
          return const IconThemeData(color: Color(0xFF90A4AE));
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: crimson),
        ),
        labelStyle: const TextStyle(color: Color(0xFFB0BEC5)),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0091EA),
        onPrimary: Colors.white,
        secondary: blue,
        onSecondary: Colors.white,
        error: crimson,
        onError: Colors.white,
        surface: lightSurface,
        onSurface: Color(0xFF263238),
      ),
      cardTheme: CardTheme(
        color: lightSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        elevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF263238),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        indicatorColor: const Color(0xFF0091EA).withAlpha(51),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Color(0xFF0091EA),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            );
          }
          return const TextStyle(color: Color(0xFF78909C), fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF0091EA));
          }
          return const IconThemeData(color: Color(0xFF78909C));
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0091EA), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: crimson),
        ),
      ),
    );
  }
}
