import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_providers.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/domain/user_role.dart';

final userManagementRepositoryProvider = Provider<UserManagementRepository>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);

  return UserManagementRepository(client);
});

final managedUsersProvider = FutureProvider.autoDispose<List<UserProfile>>((
  ref,
) async {
  final repository = ref.watch(userManagementRepositoryProvider);

  return repository.fetchProfiles();
});

class UserManagementRepository {
  const UserManagementRepository(this._client);

  final SupabaseClient? _client;

  Future<List<UserProfile>> fetchProfiles() async {
    final client = _requireClient();
    final response = await client
        .from('profiles')
        .select()
        .order('role')
        .order('email');

    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(UserProfile.fromMap)
        .toList();
  }

  Future<void> updateProfile({
    required String profileId,
    required String fullName,
    required UserRole role,
    required bool active,
  }) async {
    final client = _requireClient();

    await client
        .from('profiles')
        .update({
          'full_name': fullName.trim().isEmpty ? null : fullName.trim(),
          'role': role.databaseValue,
          'active': active,
        })
        .eq('id', profileId);
  }

  Future<void> deactivateProfile(String profileId) async {
    final client = _requireClient();

    await client.from('profiles').update({'active': false}).eq('id', profileId);
  }

  /// Crea un usuario nuevo llamando a la Edge Function `create-user`.
  /// La función usa `service_role_key` del lado del servidor, sin exponerla
  /// al frontend.
  Future<void> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final client = _requireClient();

    final response = await client.functions.invoke('create-user', body: {
      'email': email,
      'password': password,
      'fullName': fullName,
      'role': role,
    });

    // response.data puede ser String (JSON crudo) o Map ya decodificado
    final dynamic raw = response.data;
    if (raw == null) {
      throw Exception('Sin respuesta del servidor');
    }

    final Map<String, dynamic> data =
        raw is String ? jsonDecode(raw) as Map<String, dynamic> : raw as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Error desconocido al crear usuario');
    }
  }

  SupabaseClient _requireClient() {
    final client = _client;

    if (client == null) {
      throw StateError('Supabase no esta configurado.');
    }

    return client;
  }
}
