class AppConfig {
  const AppConfig._();

  static const appName = 'SIGCAL';
  static const appFullName = 'Sistema de Gestion de Calibracion';

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get hasSupabaseConfig =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  static Uri? get supabaseUri => Uri.tryParse(supabaseUrl);

  static String get supabaseProjectHost {
    final host = supabaseUri?.host ?? '';

    return host.isEmpty ? 'No configurado' : host;
  }

  static List<String> get missingSupabaseEntries {
    return [
      if (supabaseUrl.trim().isEmpty) 'SUPABASE_URL',
      if (supabaseAnonKey.trim().isEmpty) 'SUPABASE_ANON_KEY',
    ];
  }
}
