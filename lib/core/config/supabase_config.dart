import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

enum SupabaseRuntimeStatus { notConfigured, ready, failed }

class SupabaseRuntimeInfo {
  const SupabaseRuntimeInfo({
    required this.status,
    required this.message,
    required this.projectHost,
    this.missingEntries = const [],
    this.error,
  });

  factory SupabaseRuntimeInfo.notConfigured(List<String> missingEntries) {
    return SupabaseRuntimeInfo(
      status: SupabaseRuntimeStatus.notConfigured,
      message:
          'Supabase no esta configurado. Ejecuta la app con SUPABASE_URL y SUPABASE_ANON_KEY.',
      projectHost: AppConfig.supabaseProjectHost,
      missingEntries: missingEntries,
    );
  }

  factory SupabaseRuntimeInfo.ready() {
    return SupabaseRuntimeInfo(
      status: SupabaseRuntimeStatus.ready,
      message: 'Cliente Supabase inicializado correctamente.',
      projectHost: AppConfig.supabaseProjectHost,
    );
  }

  factory SupabaseRuntimeInfo.failed(Object error) {
    return SupabaseRuntimeInfo(
      status: SupabaseRuntimeStatus.failed,
      message: 'No se pudo inicializar Supabase. Revisa URL y anon key.',
      projectHost: AppConfig.supabaseProjectHost,
      error: error.toString(),
    );
  }

  final SupabaseRuntimeStatus status;
  final String message;
  final String projectHost;
  final List<String> missingEntries;
  final String? error;

  bool get isReady => status == SupabaseRuntimeStatus.ready;
}

class SupabaseConfig {
  SupabaseConfig._();

  static bool _initialized = false;
  static SupabaseRuntimeInfo _runtimeInfo = SupabaseRuntimeInfo.notConfigured(
    AppConfig.missingSupabaseEntries,
  );

  static bool get isInitialized => _initialized;

  static SupabaseRuntimeInfo get runtimeInfo => _runtimeInfo;

  static SupabaseClient? get client {
    if (!_initialized) {
      return null;
    }

    return Supabase.instance.client;
  }

  static SupabaseClient requireClient() {
    final activeClient = client;

    if (activeClient == null) {
      throw StateError(
        'Supabase no esta inicializado. Configura SUPABASE_URL y SUPABASE_ANON_KEY.',
      );
    }

    return activeClient;
  }

  static Future<SupabaseRuntimeInfo> initialize() async {
    if (_initialized) {
      return _runtimeInfo;
    }

    if (!AppConfig.hasSupabaseConfig) {
      _runtimeInfo = SupabaseRuntimeInfo.notConfigured(
        AppConfig.missingSupabaseEntries,
      );
      return _runtimeInfo;
    }

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      _initialized = true;
      _runtimeInfo = SupabaseRuntimeInfo.ready();
    } on Object catch (error) {
      _initialized = false;
      _runtimeInfo = SupabaseRuntimeInfo.failed(error);
    }

    return _runtimeInfo;
  }
}
