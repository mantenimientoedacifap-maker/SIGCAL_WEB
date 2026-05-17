import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_providers.dart';
import '../domain/user_profile.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);

  return AuthRepository(client);
});

final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final repository = ref.watch(authRepositoryProvider);

  return repository.fetchCurrentProfile();
});
