import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

final supabaseRuntimeInfoProvider = Provider<SupabaseRuntimeInfo>((ref) {
  return SupabaseConfig.runtimeInfo;
});

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  return SupabaseConfig.client;
});
