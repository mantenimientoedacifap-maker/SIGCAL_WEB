import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/domain/user_role.dart';
import '../data/user_management_providers.dart';

class UsersAdminPage extends ConsumerStatefulWidget {
  const UsersAdminPage({super.key});

  @override
  ConsumerState<UsersAdminPage> createState() => _UsersAdminPageState();
}

class _UsersAdminPageState extends ConsumerState<UsersAdminPage> {
  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(managedUsersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Usuarios y roles',
          description:
              'Control de perfiles, roles operativos y estado de acceso para SIGCAL.',
          actions: [
            FilledButton.icon(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Agregar usuario'),
            ),
          ],
        ),
        usersState.when(
          data: (users) => _UsersTable(users: users),
          error: (error, _) => EmptyState(
            title: 'No se pudo cargar usuarios',
            message: error.toString(),
            icon: Icons.error_outline,
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCreateDialog() async {
    final emailCtl = TextEditingController();
    final passwordCtl = TextEditingController();
    final nameCtl = TextEditingController();
    String role = 'usuario';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Crear usuario'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailCtl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electronico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passwordCtl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outlined),
                    helperText: 'Minimo 6 caracteres',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'usuario',
                      child: Text('Usuario (solo consulta)'),
                    ),
                    DropdownMenuItem(
                      value: 'administrador',
                      child: Text('Administrador (gestion operativa)'),
                    ),
                    DropdownMenuItem(
                      value: 'lider',
                      child: Text('Lider (acceso total)'),
                    ),
                  ],
                  onChanged: (v) => setDialogState(() => role = v ?? 'usuario'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Crear usuario'),
            ),
          ],
        ),
      ),
    );

    emailCtl.dispose();
    passwordCtl.dispose();
    nameCtl.dispose();

    if (confirmed != true || !mounted) return;

    final email = emailCtl.text.trim();
    final password = passwordCtl.text;
    final name = nameCtl.text.trim();

    if (email.isEmpty || password.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Correo y contraseña (min 6 caracteres) son obligatorios.'),
          ),
        );
      }
      return;
    }

    try {
      await ref.read(userManagementRepositoryProvider).createUser(
            email: email,
            password: password,
            fullName: name,
            role: role,
          );
      ref.invalidate(managedUsersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario creado correctamente.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _UsersTable extends ConsumerWidget {
  const _UsersTable({required this.users});

  final List<UserProfile> users;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (users.isEmpty) {
      return const Card(
        child: SizedBox(
          height: 320,
          child: EmptyState(
            title: 'Sin usuarios',
            message: 'Cuando existan perfiles apareceran aqui.',
            icon: Icons.people_outline,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppColors.softShadowOf(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SizedBox(
          height: 520,
          child: DataTable2(
            minWidth: 680,
            headingRowHeight: 44,
            dataRowHeight: 62,
            columns: const [
              DataColumn2(label: Text('Usuario'), size: ColumnSize.L),
              DataColumn2(label: Text('Correo'), size: ColumnSize.L),
              DataColumn2(label: Text('Rol / Estado'), size: ColumnSize.M),
              DataColumn2(label: Text(''), size: ColumnSize.M),
            ],
            rows: [
              for (final user in users)
                DataRow(
                  cells: [
                    DataCell(Text(user.displayName)),
                    DataCell(Text(user.email)),
                    DataCell(
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          StatusBadge(
                            label: user.role.label,
                            color: AppColors.actionBlue,
                          ),
                          StatusBadge(
                            label: user.active ? 'Activo' : 'Inactivo',
                            color: user.active
                                ? AppColors.success
                                : AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Wrap(
                        spacing: 6,
                        children: [
                          IconButton(
                            tooltip: 'Editar usuario',
                            onPressed: () => _showEditDialog(
                              context: context,
                              ref: ref,
                              user: user,
                            ),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: '',
                            onPressed: user.active
                                ? () => _confirmDeactivate(
                                    context: context,
                                    ref: ref,
                                    user: user,
                                  )
                                : null,
                            icon: const Icon(Icons.person_off_outlined),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeactivate({
    required BuildContext context,
    required WidgetRef ref,
    required UserProfile user,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dar de baja usuario'),
          content: Text(
            'Se desactivara el perfil de ${user.displayName}. '
            'La cuenta Auth no sera eliminada.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(''),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(''),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await ref.read(userManagementRepositoryProvider).deactivateProfile(user.id);
    ref.invalidate(managedUsersProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Usuario desactivado.')));
    }
  }

  Future<void> _showEditDialog({
    required BuildContext context,
    required WidgetRef ref,
    required UserProfile user,
  }) async {
    final fullNameController = TextEditingController(text: user.fullName ?? '');
    var selectedRole = user.role;
    var active = user.active;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Editar ${user.email}'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre visible',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<UserRole>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(labelText: 'Rol'),
                      items: [
                        for (final role in UserRole.values)
                          DropdownMenuItem(
                            value: role,
                            child: Text(role.label),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() => selectedRole = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: active,
                      title: const Text('Usuario activo'),
                      onChanged: (value) => setState(() => active = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(''),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !context.mounted) {
      fullNameController.dispose();
      return;
    }

    await ref
        .read(userManagementRepositoryProvider)
        .updateProfile(
          profileId: user.id,
          fullName: fullNameController.text,
          role: selectedRole,
          active: active,
        );
    fullNameController.dispose();
    ref.invalidate(managedUsersProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Usuario actualizado.')));
    }
  }
}
