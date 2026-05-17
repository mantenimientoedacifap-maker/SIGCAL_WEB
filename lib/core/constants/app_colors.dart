import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // ── Base premium (blanco y negro) ──────────────────────────
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF0A0A0A);
  static const surfaceDark = Color(0xFF141414);
  static const surfaceLight = Color(0xFFFFFFFF);

  // ── Escala de grises (proporciones bajas) ──────────────────
  static const gray50 = Color(0xFFFAFAFA);
  static const gray100 = Color(0xFFF5F5F5);
  static const gray200 = Color(0xFFE5E5E5);
  static const gray300 = Color(0xFFD4D4D4);
  static const gray400 = Color(0xFFA3A3A3);
  static const gray500 = Color(0xFF737373);
  static const gray600 = Color(0xFF525252);
  static const gray700 = Color(0xFF404040);
  static const gray800 = Color(0xFF262626);
  static const gray900 = Color(0xFF171717);

  // ── Dorado premium (logo y acentos) ────────────────────────
  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFF5D061);

  // ── Colores funcionales (alertas y gráficas) ───────────────
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFEAB308);
  static const critical = Color(0xFFF97316);
  static const danger = Color(0xFFDC2626);
  static const calibration = Color(0xFF0284C7);

  // ── Sidebar ────────────────────────────────────────────────
  static const sidebar = Color(0xFF0A0A0A);
  static const sidebarSelected = Color(0xFF262626);

  // ── Aliases (compatibilidad hacia atrás) ────────────────────
  static const actionBlue = gray800;
  static const institutionalBlue = black;
  static const muted = gray500;

  // ── Sombras ────────────────────────────────────────────────
  static List<BoxShadow> get softShadow {
    return [
      BoxShadow(
        color: const Color(0xFF000000).withValues(alpha: 0.06),
        blurRadius: 28,
        offset: const Offset(0, 16),
      ),
    ];
  }

  // ── Helpers de contexto ────────────────────────────────────
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color surfaceOf(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color surfaceSoftOf(BuildContext context) {
    return isDark(context) ? gray800 : gray50;
  }

  static Color surfaceElevatedOf(BuildContext context) {
    return isDark(context) ? gray800 : white;
  }

  static Color topbarOf(BuildContext context) {
    return isDark(context) ? black : white;
  }

  static Color textOf(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color mutedOf(BuildContext context) {
    return isDark(context) ? gray400 : gray600;
  }

  static Color subduedOf(BuildContext context) {
    return isDark(context) ? gray500 : gray400;
  }

  static Color borderOf(BuildContext context) {
    return isDark(context) ? gray700 : gray200;
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
          color: const Color(0xFF000000).withValues(alpha: 0.32),
          blurRadius: 30,
          offset: const Offset(0, 18),
        ),
      ];
    }
    return softShadow;
  }
}
