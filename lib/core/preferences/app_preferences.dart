import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppVisualMode {
  light('light', 'Claro', Icons.light_mode_outlined),
  dark('dark', 'Oscuro', Icons.dark_mode_outlined),
  system('system', 'Sistema', Icons.brightness_auto_outlined);

  const AppVisualMode(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;

  static AppVisualMode fromValue(String? value) {
    return AppVisualMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => AppVisualMode.light,
    );
  }
}

enum AppLanguage {
  spanish('es-PE', 'Espanol LATAM', Locale('es', 'PE')),
  english('en-US', 'English', Locale('en', 'US')),
  portuguese('pt-BR', 'Portugues', Locale('pt', 'BR')),
  french('fr-FR', 'Francais', Locale('fr', 'FR'));

  const AppLanguage(this.value, this.label, this.locale);

  final String value;
  final String label;
  final Locale locale;

  static AppLanguage fromValue(String? value) {
    return AppLanguage.values.firstWhere(
      (language) => language.value == value,
      orElse: () => AppLanguage.spanish,
    );
  }
}

class AppPreferences {
  const AppPreferences({
    this.visualMode = AppVisualMode.light,
    this.language = AppLanguage.spanish,
  });

  final AppVisualMode visualMode;
  final AppLanguage language;

  AppPreferences copyWith({AppVisualMode? visualMode, AppLanguage? language}) {
    return AppPreferences(
      visualMode: visualMode ?? this.visualMode,
      language: language ?? this.language,
    );
  }
}

final appPreferencesProvider =
    NotifierProvider<AppPreferencesController, AppPreferences>(
      AppPreferencesController.new,
    );

class AppPreferencesController extends Notifier<AppPreferences> {
  static const _themeKey = 'sigcal.theme';
  static const _languageKey = 'sigcal.language';

  @override
  AppPreferences build() {
    load();

    return const AppPreferences();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    state = AppPreferences(
      visualMode: AppVisualMode.fromValue(prefs.getString(_themeKey)),
      language: AppLanguage.fromValue(prefs.getString(_languageKey)),
    );
  }

  Future<void> setVisualMode(AppVisualMode mode) async {
    state = state.copyWith(visualMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.value);
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = state.copyWith(language: language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.value);
  }

  Future<void> sync({
    required AppVisualMode mode,
    required AppLanguage language,
  }) async {
    state = state.copyWith(visualMode: mode, language: language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.value);
    await prefs.setString(_languageKey, language.value);
  }
}
