import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';

class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable() {
    final client = SupabaseConfig.client;

    _subscription = client?.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  StreamSubscription<AuthState>? _subscription;

  bool get isAuthenticated {
    return SupabaseConfig.client?.auth.currentSession != null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
