import 'user_role.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.authUserId,
    required this.email,
    required this.role,
    required this.active,
    this.fullName,
    this.firstName,
    this.lastName,
    this.phoneCountryCode,
    this.phoneCountryName,
    this.phoneNumber,
    this.avatarPath,
    this.avatarUrl,
    this.themePreference = 'light',
    this.languagePreference = 'es-PE',
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, {String? avatarUrl}) {
    return UserProfile(
      id: map['id'] as String? ?? '',
      authUserId: map['auth_user_id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String?,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      phoneCountryCode: map['phone_country_code'] as String?,
      phoneCountryName: map['phone_country_name'] as String?,
      phoneNumber: map['phone_number'] as String?,
      avatarPath: map['avatar_path'] as String?,
      avatarUrl: avatarUrl,
      themePreference: map['theme_preference'] as String? ?? 'light',
      languagePreference: map['language_preference'] as String? ?? 'es-PE',
      role: UserRole.fromDatabase(map['role'] as String?),
      active: map['active'] as bool? ?? false,
    );
  }

  final String id;
  final String authUserId;
  final String email;
  final String? fullName;
  final String? firstName;
  final String? lastName;
  final String? phoneCountryCode;
  final String? phoneCountryName;
  final String? phoneNumber;
  final String? avatarPath;
  final String? avatarUrl;
  final String themePreference;
  final String languagePreference;
  final UserRole role;
  final bool active;

  UserProfile copyWith({
    String? email,
    String? fullName,
    String? firstName,
    String? lastName,
    String? phoneCountryCode,
    String? phoneCountryName,
    String? phoneNumber,
    String? avatarPath,
    String? avatarUrl,
    String? themePreference,
    String? languagePreference,
    UserRole? role,
    bool? active,
  }) {
    return UserProfile(
      id: id,
      authUserId: authUserId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneCountryCode: phoneCountryCode ?? this.phoneCountryCode,
      phoneCountryName: phoneCountryName ?? this.phoneCountryName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarPath: avatarPath ?? this.avatarPath,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      themePreference: themePreference ?? this.themePreference,
      languagePreference: languagePreference ?? this.languagePreference,
      role: role ?? this.role,
      active: active ?? this.active,
    );
  }

  String get displayName {
    final splitName = [firstName, lastName]
        .where((part) => part != null && part.trim().isNotEmpty)
        .map((part) => part!.trim())
        .join(' ');

    if (splitName.isNotEmpty) {
      return splitName;
    }

    final cleanFullName = fullName?.trim();

    if (cleanFullName != null && cleanFullName.isNotEmpty) {
      return cleanFullName;
    }

    return email;
  }

  String get initials {
    final source = displayName == email ? email.split('@').first : displayName;
    final parts = source
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
