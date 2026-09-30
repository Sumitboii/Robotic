import 'package:flutter/material.dart';

/// Clinical Typography System for Synthera Prosthetic Platform.
///
/// Uses Inter for UI text and IBM Plex Mono for real-time telemetry numbers.
/// All numeric styles enforce tabular figures [FontFeature.tabularFigures]
/// to prevent visual jitter during high-frequency telemetry updates (20Hz).
class AppTypography {
  AppTypography._();

  static const String uiFontFamily = 'Inter';
  static const List<String> uiFontFallbacks = [
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'sans-serif',
  ];

  static const String monoFontFamily = 'IBMPlexMono';
  static const List<String> monoFontFallbacks = [
    'JetBrains Mono',
    'Roboto Mono',
    'SF Mono',
    'monospace',
  ];

  // ── Display Styles ──
  static TextStyle displayLarge({required Color color}) => TextStyle(
        fontFamily: uiFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: color,
        height: 1.2,
      );

  static TextStyle displayMedium({required Color color}) => TextStyle(
        fontFamily: uiFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: color,
        height: 1.25,
      );

  // ── Title & Header Styles ──
  static TextStyle titleLarge({required Color color}) => TextStyle(
        fontFamily: uiFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: color,
        height: 1.3,
      );

  static TextStyle titleMedium({required Color color}) => TextStyle(
        fontFamily: uiFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        color: color,
        height: 1.35,
      );

  static TextStyle titleSmall({required Color color}) => TextStyle(
        fontFamily: uiFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: color,
        height: 1.4,
      );

  // ── Body Styles ──
  static TextStyle bodyLarge({required Color color}) => TextStyle(
        fontFamily: uiFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: color,
        height: 1.5,
      );

  static TextStyle bodyMedium({required Color color}) => TextStyle(
        fontFamily: uiFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: color,
        height: 1.45,
      );

  static TextStyle bodySmall({required Color color}) => TextStyle(
        fontFamily: uiFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: color,
        height: 1.4,
      );

  // ── Label & Badge Styles ──
  static TextStyle labelLarge({required Color color}) => TextStyle(
        fontFamily: uiFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: color,
      );

  static TextStyle labelMedium({required Color color}) => TextStyle(
        fontFamily: uiFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: color,
      );

  static TextStyle labelSmall({required Color color}) => TextStyle(
        fontFamily: uiFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: color,
      );

  // ── Monospaced Numeric Telemetry Styles (Tabular Non-Jittering) ──
  static TextStyle monoHero({required Color color}) => TextStyle(
        fontFamily: monoFontFamily,
        fontFamilyFallback: monoFontFallbacks,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: color,
        height: 1.1,
      );

  static TextStyle monoValueLarge({required Color color}) => TextStyle(
        fontFamily: monoFontFamily,
        fontFamilyFallback: monoFontFallbacks,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: color,
        height: 1.15,
      );

  static TextStyle monoValueMedium({required Color color}) => TextStyle(
        fontFamily: monoFontFamily,
        fontFamilyFallback: monoFontFallbacks,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color,
        height: 1.2,
      );

  static TextStyle monoValueSmall({required Color color}) => TextStyle(
        fontFamily: monoFontFamily,
        fontFamilyFallback: monoFontFallbacks,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        color: color,
        height: 1.2,
      );
}
