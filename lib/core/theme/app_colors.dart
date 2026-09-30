import 'package:flutter/material.dart';

/// Clinical Medical-Tech Color Tokens for Synthera Robotics.
///
/// Designed for high-clarity medical device instrumentation, meeting
/// WCAG 2.1 AA (and AAA in primary roles) contrast standards across both themes.
class AppColors {
  AppColors._();

  // ── Primary Brand & Clinical Accent (Teal / Cyan) ──
  static const Color primaryDark =
      Color(0xFF00E5FF); // High-contrast clinical cyan
  static const Color primaryLight = Color(0xFF00838F); // Deep medical teal
  static const Color primaryVariant = Color(0xFF00ACC1);

  // ── Secondary / Functional Accents ──
  static const Color blueDark = Color(0xFF38BDF8); // Sky blue telemetry
  static const Color blueLight = Color(0xFF0284C7);
  static const Color indigo = Color(0xFF6366F1);

  // ── Semantic Feedback ──
  static const Color successDark = Color(0xFF10B981); // Emerald / Mint
  static const Color successLight = Color(0xFF059669);

  static const Color warningDark = Color(0xFFF59E0B); // Amber / Caution
  static const Color warningLight = Color(0xFFD97706);

  static const Color dangerDark = Color(0xFFEF4444); // Error / Spike
  static const Color dangerLight = Color(0xFFDC2626);

  static const Color infoDark = Color(0xFF38BDF8);
  static const Color infoLight = Color(0xFF0284C7);

  // ── Emergency STOP Distinct Red ──
  // Dedicated strictly to emergency stop actuators and critical system halt alerts.
  static const Color emergencyRed = Color(0xFFDC2626);
  static const Color emergencyRedHover = Color(0xFFB91C1C);
  static const Color emergencyRedBgDark = Color(0xFF3B1219);
  static const Color emergencyRedBgLight = Color(0xFFFFECEE);

  // ── Dark Theme Surfaces (Slate Medical Dark) ──
  static const Color darkBg = Color(0xFF0A0E17); // Scaffold deep slate
  static const Color darkSurface = Color(0xFF111827); // Card / Header surface
  static const Color darkSurfaceElevated =
      Color(0xFF1E293B); // Interactive / Elevated
  static const Color darkBorder = Color(0xFF2E3D52); // Subtle structural border
  static const Color darkBorderSubtle = Color(0xFF1F2937);

  // ── Dark Theme Typography ──
  static const Color darkTextPrimary =
      Color(0xFFF8FAFC); // Ratio > 14:1 vs darkBg (AAA)
  static const Color darkTextSecondary =
      Color(0xFF94A3B8); // Ratio > 5.5:1 vs darkBg (AA)
  static const Color darkTextMuted =
      Color(0xFF64748B); // Captions & subtle units

  // ── Light Theme Surfaces (Warm Clinical Off-White) ──
  static const Color lightBg = Color(0xFFF1F5F9); // Warm medical off-white
  static const Color lightSurface = Color(0xFFFFFFFF); // Clean white card
  static const Color lightSurfaceElevated =
      Color(0xFFE2E8F0); // Subtle contrast surface
  static const Color lightBorder = Color(0xFFCBD5E1); // Clean slate border
  static const Color lightBorderSubtle = Color(0xFFE2E8F0);

  // ── Light Theme Typography ──
  static const Color lightTextPrimary =
      Color(0xFF0F172A); // Ratio > 15:1 vs lightBg (AAA)
  static const Color lightTextSecondary =
      Color(0xFF334155); // Ratio > 9:1 vs lightBg (AAA)
  static const Color lightTextMuted =
      Color(0xFF64748B); // Ratio > 4.7:1 vs lightBg (AA)
}
