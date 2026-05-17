import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/utils/date_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SigecalDateUtils.ensureLocales();
  await SupabaseConfig.initialize();

  runApp(const ProviderScope(child: SigecalApp()));
}
