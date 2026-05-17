import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    return _build(
      seed: AppColors.actionBlue,
      primary: AppColors.actionBlue,
      surface: AppColors.white,
      background: AppColors.background,
      text: AppColors.institutionalBlue,
      muted: AppColors.muted,
      brightness: Brightness.light,
    );
  }

  static ThemeData get dark {
    return _build(
      seed: const Color(0xFF38BDF8),
      primary: const Color(0xFF38BDF8),
      surface: const Color(0xFF111827),
      background: const Color(0xFF020617),
      text: const Color(0xFFE5E7EB),
      muted: const Color(0xFF94A3B8),
      brightness: Brightness.dark,
    );
  }

  static ThemeData get classic {
    return _build(
      seed: const Color(0xFFB45309),
      primary: const Color(0xFFB45309),
      surface: const Color(0xFFFFFBEB),
      background: const Color(0xFFF7F0DD),
      text: const Color(0xFF1F2937),
      muted: const Color(0xFF6B7280),
      brightness: Brightness.light,
    );
  }

  static ThemeData _build({
    required Color seed,
    required Color primary,
    required Color surface,
    required Color background,
    required Color text,
    required Color muted,
    required Brightness brightness,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      primary: primary,
      secondary: AppColors.calibration,
      surface: surface,
      error: AppColors.danger,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;
    final softSurface = isDark
        ? const Color(0xFF1E293B)
        : AppColors.surfaceSoft;
    final outline = isDark
        ? const Color(0xFF334155)
        : colorScheme.outlineVariant;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Aptos',
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: surface,
        elevation: 0,
        shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: outline),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: TextStyle(color: muted, height: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: DividerThemeData(color: outline),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.4),
        ),
        filled: true,
        fillColor: isDark ? softSurface : surface,
        labelStyle: TextStyle(color: muted),
        helperStyle: TextStyle(color: muted),
        hintStyle: TextStyle(color: muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(
            color: primary.withValues(alpha: isDark ? 0.42 : 0.28),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(
          primary.withValues(
            alpha: brightness == Brightness.dark ? 0.18 : 0.08,
          ),
        ),
        headingTextStyle: TextStyle(color: text, fontWeight: FontWeight.w700),
        dataTextStyle: TextStyle(color: text),
      ),
      textTheme: ThemeData(
        brightness: brightness,
      ).textTheme.apply(bodyColor: text, displayColor: text),
      iconTheme: IconThemeData(color: muted),
      listTileTheme: ListTileThemeData(
        textColor: text,
        iconColor: muted,
        selectedColor: text,
      ),
    );
  }
}
