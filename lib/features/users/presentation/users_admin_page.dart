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

class UsersAdminPage extends ConsumerWidget {
  const UsersAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              onPressed: () => _showCreateGuidance(context),
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

  void _showCreateGuidance(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar usuario'),
          content: const Text(
            'Por seguridad, la creacion de cuentas Auth no se hace desde el '
            'frontend con llaves administrativas. En esta fase se crea el '
            'usuario en Supabase Auth y luego se gestiona su rol aqui. '
            'En una fase posterior agregaremos una funcion backend segura '
            'para automatizar este paso.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
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
