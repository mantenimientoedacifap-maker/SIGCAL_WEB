import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const institutionalBlue = Color(0xFF0F172A);
  static const actionBlue = Color(0xFF2563EB);
  static const background = Color(0xFFF4F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF8FBFF);
  static const border = Color(0xFFD8E2F0);
  static const borderSoft = Color(0xFFEAF0F7);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFEAB308);
  static const critical = Color(0xFFF97316);
  static const danger = Color(0xFFDC2626);
  static const calibration = Color(0xFF0284C7);
  static const muted = Color(0xFF64748B);
  static const white = Color(0xFFFFFFFF);
  static const sidebar = Color(0xFF111827);
  static const sidebarSelected = Color(0xFF1E3A8A);

  static List<BoxShadow> get softShadow {
    return [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.06),
        blurRadius: 28,
        offset: const Offset(0, 16),
      ),
      BoxShadow(
        color: const Color(0xFF2563EB).withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color surfaceOf(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color surfaceSoftOf(BuildContext context) {
    return isDark(context) ? const Color(0xFF1E293B) : surfaceSoft;
  }

  static Color surfaceElevatedOf(BuildContext context) {
    return isDark(context) ? const Color(0xFF172033) : surface;
  }

  static Color topbarOf(BuildContext context) {
    return isDark(context) ? const Color(0xFF0F172A) : white;
  }

  static Color textOf(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color mutedOf(BuildContext context) {
    return isDark(context) ? const Color(0xFFCBD5E1) : muted;
  }

  static Color subduedOf(BuildContext context) {
    return isDark(context) ? const Color(0xFF94A3B8) : muted;
  }

  static Color borderOf(BuildContext context) {
    return isDark(context) ? const Color(0xFF334155) : borderSoft;
  }

  static Color tintOf(
    BuildContext context,
    Color color, {
    double lightAlpha = 0.10,
    double darkAlpha = 0.18,
  }) {
    return color.withValues(alpha: isDark(context) ? darkAlpha : lightAlpha);
  }

  static List<BoxShadow> softShadowOf(BuildContext context) {
    if (isDark(context)) {
      return [
        BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.22),
          blurRadius: 30,
          offset: const Offset(0, 18),
        ),
      ];
    }

    return softShadow;
  }
}
