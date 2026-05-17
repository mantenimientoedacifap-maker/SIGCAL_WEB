enum UserRole {
  lider,
  administrador,
  usuario;

  static UserRole fromDatabase(String? value) {
    return switch (value) {
      'lider' => UserRole.lider,
      'administrador' => UserRole.administrador,
      _ => UserRole.usuario,
    };
  }

  String get databaseValue {
    return switch (this) {
      UserRole.lider => 'lider',
      UserRole.administrador => 'administrador',
      UserRole.usuario => 'usuario',
    };
  }

  String get label {
    return switch (this) {
      UserRole.lider => 'Lider',
      UserRole.administrador => 'Administrador',
      UserRole.usuario => 'Usuario',
    };
  }

  bool get canManageOperationalData {
    return this == UserRole.lider || this == UserRole.administrador;
  }
}
