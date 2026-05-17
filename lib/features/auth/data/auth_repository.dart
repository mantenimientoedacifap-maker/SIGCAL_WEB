import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../domain/user_profile.dart';

class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient? _client;

  bool get isConfigured => _client != null;

  Session? get currentSession => _client?.auth.currentSession;

  User? get currentUser => _client?.auth.currentUser;

  Stream<AuthState> get authStateChanges {
    final activeClient = _client;

    if (activeClient == null) {
      return const Stream.empty();
    }

    return activeClient.auth.onAuthStateChange;
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final activeClient = _requireClient();

    await activeClient.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    final activeClient = _requireClient();

    await activeClient.auth.signOut();
  }

  Future<void> resetPasswordForEmail({
    required String email,
    String? redirectTo,
  }) async {
    final activeClient = _requireClient();

    await activeClient.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectTo,
    );
  }

  Future<void> updatePassword({required String newPassword}) async {
    final activeClient = _requireClient();

    await activeClient.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<UserProfile?> fetchCurrentProfile() async {
    final activeClient = _client;
    final user = activeClient?.auth.currentUser;

    if (activeClient == null || user == null) {
      return null;
    }

    final response = await activeClient
        .from('profiles')
        .select()
        .eq('auth_user_id', user.id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    final profile = UserProfile.fromMap(response);
    final avatarUrl = await _createAvatarSignedUrl(profile.avatarPath);

    return profile.copyWith(avatarUrl: avatarUrl);
  }

  Future<void> updateCurrentProfile({
    required String firstName,
    required String lastName,
    required String phoneCountryCode,
    required String phoneCountryName,
    required String phoneNumber,
    required String themePreference,
    required String languagePreference,
    String? avatarPath,
  }) async {
    final activeClient = _requireClient();
    final user = activeClient.auth.currentUser;

    if (user == null) {
      throw StateError('No hay una sesion activa.');
    }

    final cleanFirstName = firstName.trim();
    final cleanLastName = lastName.trim();
    final fullName = [
      cleanFirstName,
      cleanLastName,
    ].where((part) => part.isNotEmpty).join(' ');

    final payload = <String, dynamic>{
      'first_name': cleanFirstName,
      'last_name': cleanLastName,
      'full_name': fullName.isEmpty ? null : fullName,
      'phone_country_code': phoneCountryCode.trim(),
      'phone_country_name': phoneCountryName.trim(),
      'phone_number': phoneNumber.trim(),
      'theme_preference': themePreference,
      'language_preference': languagePreference,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (avatarPath != null && avatarPath.isNotEmpty) {
      payload['avatar_path'] = avatarPath;
    }

    await activeClient
        .from('profiles')
        .update(payload)
        .eq('auth_user_id', user.id);
  }

  Future<String> uploadCurrentAvatar({
    required Uint8List bytes,
    required String extension,
    required String contentType,
  }) async {
    final activeClient = _requireClient();
    final user = activeClient.auth.currentUser;

    if (user == null) {
      throw StateError('No hay una sesion activa.');
    }

    final safeExtension = extension.replaceAll(RegExp('[^a-zA-Z0-9]'), '');
    final path =
        '${user.id}/avatar-${DateTime.now().millisecondsSinceEpoch}.$safeExtension';

    await activeClient.storage
        .from('profile-avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    return path;
  }

  Future<String?> _createAvatarSignedUrl(String? avatarPath) async {
    final activeClient = _client;

    if (activeClient == null || avatarPath == null || avatarPath.isEmpty) {
      return null;
    }

    try {
      return activeClient.storage
          .from('profile-avatars')
          .createSignedUrl(avatarPath, 60 * 60);
    } on StorageException {
      return null;
    }
  }

  SupabaseClient _requireClient() {
    final activeClient = _client;

    if (activeClient == null) {
      throw StateError(SupabaseConfig.runtimeInfo.message);
    }

    return activeClient;
  }
}
