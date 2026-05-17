import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    return _build(
      brightness: Brightness.light,
    );
  }

  static ThemeData get dark {
    return _build(
      brightness: Brightness.dark,
    );
  }

  static ThemeData _build({
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final background = isDark ? AppColors.black : AppColors.gray50;
    final text = isDark ? AppColors.white : AppColors.black;
    final mutedColor = isDark ? AppColors.gray400 : AppColors.gray500;
    final outline = isDark ? AppColors.gray700 : AppColors.gray200;
    final primary = isDark ? AppColors.white : AppColors.black;
    final softSurface = isDark ? AppColors.gray800 : AppColors.gray50;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: AppColors.gold,
      surface: surface,
      error: AppColors.danger,
      brightness: brightness,
      onPrimary: isDark ? AppColors.black : AppColors.white,
      onSurface: text,
      onError: AppColors.white,
      outline: outline,
    );

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
        shadowColor: const Color(0xFF000000).withValues(alpha: 0.08),
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
        contentTextStyle: TextStyle(color: mutedColor, height: 1.4),
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
        labelStyle: TextStyle(color: mutedColor),
        helperStyle: TextStyle(color: mutedColor),
        hintStyle: TextStyle(color: mutedColor),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark ? AppColors.black : AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(
          isDark ? AppColors.gray800 : AppColors.gray100,
        ),
        headingTextStyle: TextStyle(color: text, fontWeight: FontWeight.w700),
        dataTextStyle: TextStyle(color: text),
      ),
      textTheme: ThemeData(brightness: brightness)
          .textTheme
          .apply(bodyColor: text, displayColor: text),
      iconTheme: IconThemeData(color: mutedColor),
      listTileTheme: ListTileThemeData(
        textColor: text,
        iconColor: mutedColor,
        selectedColor: text,
      ),
    );
  }
}
