import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/config/supabase_providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/domain/user_profile.dart';
import 'widgets/avatar_crop_dialog.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabaseInfo = ref.watch(supabaseRuntimeInfoProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Configuracion',
          description:
              'Centro para configurar dashboards, integraciones y parametros generales del sistema.',
        ),
        const _DashboardSettingsPlaceholder(),
        const SizedBox(height: 16),
        _SupabaseStatusCard(info: supabaseInfo),
      ],
    );
  }
}

class ProfileSettingsCard extends ConsumerStatefulWidget {
  const ProfileSettingsCard({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<ProfileSettingsCard> createState() =>
      _ProfileSettingsCardState();
}

class _ProfileSettingsCardState extends ConsumerState<ProfileSettingsCard> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late String _countryCode;
  Uint8List? _avatarPreview;
  Uint8List? _avatarUploadBytes;
  String? _avatarExtension;
  String? _avatarContentType;
  bool _saving = false;

  static const _countries = [
    _CountryOption('Peru', '+51'),
    _CountryOption('Estados Unidos', '+1'),
    _CountryOption('Brasil', '+55'),
    _CountryOption('Espana', '+34'),
    _CountryOption('Mexico', '+52'),
    _CountryOption('Chile', '+56'),
    _CountryOption('Colombia', '+57'),
    _CountryOption('Argentina', '+54'),
    _CountryOption('Reino Unido', '+44'),
    _CountryOption('Francia', '+33'),
  ];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.profile.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.profile.lastName ?? '',
    );
    _emailController = TextEditingController(text: widget.profile.email);
    _phoneController = TextEditingController(
      text: widget.profile.phoneNumber ?? '',
    );
    _countryCode = _resolveCountryCode(widget.profile.phoneCountryCode);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final country = _countries.firstWhere(
      (item) => item.code == _countryCode,
      orElse: () => _countries.first,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppColors.softShadowOf(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfilePhotoPicker(
                  profile: widget.profile,
                  previewBytes: _avatarPreview,
                  onPick: _pickAvatar,
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Perfil de usuario',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textOf(context),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'La foto se usara como dock superior. Si no existe, SIGCAL mostrara tus iniciales.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.subduedOf(context),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 820;
                final width = twoColumns
                    ? (constraints.maxWidth - 16) / 2
                    : double.infinity;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: width,
                      child: TextField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: TextField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Apellidos',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: TextField(
                        controller: _emailController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Correo',
                          helperText:
                              'Correo de acceso protegido por Supabase Auth.',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: twoColumns ? 220 : double.infinity,
                      child: DropdownButtonFormField<String>(
                        initialValue: _countryCode,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Pais'),
                        items: [
                          for (final item in _countries)
                            DropdownMenuItem(
                              value: item.code,
                              child: Text('${item.name} ${item.code}'),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() => _countryCode = value);
                        },
                      ),
                    ),
                    SizedBox(
                      width: twoColumns
                          ? constraints.maxWidth - width - 220 - 32
                          : double.infinity,
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Celular',
                          prefixText: '${country.code} ',
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const _PreferenceDockNote(),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Guardando...' : 'Guardar perfil'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 90,
      );

      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();

      if (!mounted) {
        return;
      }

      final croppedBytes = await showAvatarCropDialog(
        context: context,
        imageBytes: bytes,
      );

      if (croppedBytes == null || !mounted) {
        return;
      }

      setState(() {
        _avatarPreview = croppedBytes;
        _avatarUploadBytes = croppedBytes;
        _avatarExtension = 'png';
        _avatarContentType = 'image/png';
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo preparar la foto: $error')),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final repository = ref.read(authRepositoryProvider);
      String? avatarPath;

      if (_avatarUploadBytes != null) {
        avatarPath = await repository.uploadCurrentAvatar(
          bytes: _avatarUploadBytes!,
          extension: _avatarExtension ?? 'png',
          contentType: _avatarContentType ?? 'image/png',
        );
      }

      final country = _countries.firstWhere(
        (item) => item.code == _countryCode,
        orElse: () => _countries.first,
      );

      final preferences = ref.read(appPreferencesProvider);

      await repository.updateCurrentProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phoneCountryCode: country.code,
        phoneCountryName: country.name,
        phoneNumber: _phoneController.text,
        themePreference: preferences.visualMode.value,
        languagePreference: preferences.language.value,
        avatarPath: avatarPath,
      );

      ref.invalidate(currentUserProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el perfil: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _resolveCountryCode(String? code) {
    return _countries.any((item) => item.code == code)
        ? code!
        : _countries.first.code;
  }
}

class _DashboardSettingsPlaceholder extends StatelessWidget {
  const _DashboardSettingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppColors.softShadowOf(context),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.tintOf(context, AppColors.actionBlue),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.dashboard_customize_outlined,
              color: AppColors.actionBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuracion de dashboards',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textOf(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Este espacio queda reservado para parametros del sistema, vistas, integraciones y reglas operativas.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.subduedOf(context),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePhotoPicker extends StatelessWidget {
  const _ProfilePhotoPicker({
    required this.profile,
    required this.previewBytes,
    required this.onPick,
  });

  final UserProfile profile;
  final Uint8List? previewBytes;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile.avatarUrl;

    return Column(
      children: [
        Container(
          width: 118,
          height: 118,
          decoration: BoxDecoration(
            color: AppColors.surfaceSoftOf(context),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: previewBytes != null
              ? Image.memory(previewBytes!, fit: BoxFit.cover)
              : avatarUrl != null && avatarUrl.isNotEmpty
              ? Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _InitialsBlock(profile: profile),
                )
              : _InitialsBlock(profile: profile),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.crop_free_outlined),
          label: Text(previewBytes == null ? 'Cambiar foto' : 'Recorte listo'),
        ),
      ],
    );
  }
}

class _InitialsBlock extends StatelessWidget {
  const _InitialsBlock({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        profile.initials,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PreferenceDockNote extends ConsumerWidget {
  const _PreferenceDockNote();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.isDark(context)
              ? const [Color(0xFF172033), Color(0xFF0F172A)]
              : const [Color(0xFFFFFBEB), Color(0xFFEFF6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.tintOf(context, AppColors.actionBlue),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              preferences.visualMode.icon,
              color: AppColors.actionBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Modo ${preferences.visualMode.label} e idioma ${preferences.language.label}. Cambialos desde los botones compactos junto a la campana de notificaciones.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textOf(context),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupabaseStatusCard extends StatelessWidget {
  const _SupabaseStatusCard({required this.info});

  final SupabaseRuntimeInfo info;

  @override
  Widget build(BuildContext context) {
    final presentation = _presentationFor(info.status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppColors.softShadowOf(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.tintOf(context, presentation.color),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(presentation.icon, color: presentation.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Estado Supabase',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColors.textOf(context),
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          StatusBadge(
                            label: presentation.label,
                            color: presentation.color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        info.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.subduedOf(context),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _ConfigFact(
                  label: 'Proyecto',
                  value: info.projectHost,
                  icon: Icons.cloud_outlined,
                ),
                _ConfigFact(
                  label: 'URL',
                  value: info.missingEntries.contains('SUPABASE_URL')
                      ? 'Pendiente'
                      : 'Configurada',
                  icon: Icons.link_outlined,
                ),
                _ConfigFact(
                  label: 'Anon key',
                  value: info.missingEntries.contains('SUPABASE_ANON_KEY')
                      ? 'Pendiente'
                      : 'Configurada',
                  icon: Icons.key_outlined,
                ),
              ],
            ),
            if (info.error != null) ...[
              const SizedBox(height: 16),
              Text(
                info.error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.danger,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _StatusPresentation _presentationFor(SupabaseRuntimeStatus status) {
    return switch (status) {
      SupabaseRuntimeStatus.ready => const _StatusPresentation(
        label: 'Listo',
        color: AppColors.success,
        icon: Icons.check_circle_outline,
      ),
      SupabaseRuntimeStatus.failed => const _StatusPresentation(
        label: 'Error',
        color: AppColors.danger,
        icon: Icons.error_outline,
      ),
      SupabaseRuntimeStatus.notConfigured => const _StatusPresentation(
        label: 'Pendiente',
        color: AppColors.warning,
        icon: Icons.pending_outlined,
      ),
    };
  }
}

class _ConfigFact extends StatelessWidget {
  const _ConfigFact({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoftOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.actionBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.subduedOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textOf(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPresentation {
  const _StatusPresentation({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

class _CountryOption {
  const _CountryOption(this.name, this.code);

  final String name;
  final String code;
}
