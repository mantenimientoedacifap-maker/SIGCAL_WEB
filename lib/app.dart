import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_router.dart';
import 'core/constants/app_strings.dart';
import 'core/preferences/app_preferences.dart';
import 'core/theme/app_theme.dart';

class SigecalApp extends ConsumerWidget {
  const SigecalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesProvider);
    final themeMode = switch (preferences.visualMode) {
      AppVisualMode.dark => ThemeMode.dark,
      AppVisualMode.system => ThemeMode.system,
      AppVisualMode.light => ThemeMode.light,
    };

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: preferences.language.locale,
      supportedLocales: [
        for (final language in AppLanguage.values) language.locale,
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
    );
  }
}
