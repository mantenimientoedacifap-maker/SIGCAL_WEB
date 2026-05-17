import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/page_header.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../data/tool_catalog_providers.dart';
import '../data/tool_detail_providers.dart';

class ToolFormPage extends ConsumerStatefulWidget {
  const ToolFormPage({this.toolId, super.key});

  final String? toolId;

  @override
  ConsumerState<ToolFormPage> createState() => _ToolFormPageState();
}

class _ToolFormPageState extends ConsumerState<ToolFormPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _saving = false;
  Uint8List? _photoBytes;
  String? _photoUrlOverride;
  bool _photoLoaded = false;

  bool get isEditing => widget.toolId != null && widget.toolId!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final catalogsState = ref.watch(toolCatalogsProvider);
    final detailState = isEditing
        ? ref.watch(toolDetailProvider(widget.toolId!))
        : const AsyncValue<ToolDetailRecord?>.data(null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: isEditing ? 'Editar herramienta/equipo' : '',
          description: isEditing
              ? 'Actualiza los datos actuales de la ficha sin perder historial, QR ni trazabilidad.'
              : 'Registra una herramienta con categoria, ubicacion, data sheet y QR unico generado por Supabase.',
          actions: [
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.tools),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Inventario'),
            ),
          ],
        ),
        catalogsState.when(
          data: (catalogs) => detailState.when(
            data: (tool) {
              if (isEditing && tool == null) {
                return const EmptyState(
                  title: 'Registro no encontrado',
                  message: 'No se encontro la herramienta que intentas editar.',
                  icon: Icons.manage_search_outlined,
                );
              }

              return _ToolFormCard(
                key: ValueKey(tool?.id ?? 'new-tool'),
                catalogs: catalogs,
                initialTool: tool,
                formKey: _formKey,
                saving: _saving,
                photoBytes: _photoBytes,
                photoUrlOverride: _photoUrlOverride,
                photoLoaded: _photoLoaded,
                onPickPhoto: _pickPhoto,
                onSetPhotoUrl: _setPhotoUrl,
                onSave: () => _save(catalogs),
              );
            },
            error: (error, _) => EmptyState(
              title: 'No se pudo cargar la ficha',
              message: error.toString(),
              icon: Icons.error_outline,
            ),
            loading: () => const SizedBox(
              height: 420,
              child: LoadingView(message: 'Cargando datos actuales...'),
            ),
          ),
          error: (error, _) => EmptyState(
            title: 'No se pudieron cargar catalogos',
            message: error.toString(),
            icon: Icons.error_outline,
          ),
          loading: () => const SizedBox(
            height: 420,
            child: LoadingView(message: 'Cargando catalogos...'),
          ),
        ),
      ],
    );
  }

  Future<void> _save(ToolCatalogs catalogs) async {
    final formState = _formKey.currentState;

    if (formState == null || !formState.saveAndValidate()) {
      return;
    }

    setState(() => _saving = true);

    try {
      final values = formState.value;
      final location = _valueAsString(values['current_location']);
      final repository = ref.read(toolMutationRepositoryProvider);
      final payload = <String, dynamic>{
        'nomenclature': _valueAsString(values['nomenclature']),
        'category_id': _valueAsString(values['category_id']),
        'manufacturer_id': _valueAsString(values['manufacturer_id']),
        'model': _valueAsString(values['model']),
        'serial_number': _valueAsString(values['serial_number']),
        'part_number': _valueAsString(values['part_number']),
        'description': _valueAsString(values['description']),
        'current_location': location ?? _firstWorkshopName(catalogs),
        'current_status': _valueAsString(values['current_status']),
        'data_sheet_url': _valueAsString(values['data_sheet_url']),
        'manufacturer_certificate_url': _valueAsString(
          values['manufacturer_certificate_url'],
        ),
        'acquisition_date': _dateOnly(values['acquisition_date'] as DateTime?),
        'traceability_notes': _valueAsString(values['traceability_notes']),
      };

      if (_photoUrlOverride != null) {
        payload['photo_url'] = _photoUrlOverride;
      }

      final id = await repository.saveTool(
        toolId: isEditing ? widget.toolId : null,
        payload: payload,
      );

      if (_photoBytes != null) {
        final publicUrl = await repository.uploadToolImage(
          toolId: id,
          bytes: _photoBytes!,
          contentType: 'image/png',
        );
        await repository.updateToolPhotoUrl(toolId: id, photoUrl: publicUrl);
      }

      ref.invalidate(dashboardSnapshotProvider);
      ref.invalidate(toolCatalogsProvider);
      if (isEditing) {
        ref.invalidate(toolDetailProvider(widget.toolId!));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Ficha actualizada correctamente.'
                  : 'Herramienta registrada con QR unico.',
            ),
          ),
        );
        context.go(AppRoutes.toolDetail(id));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo guardar: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );

    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    final resized = await _resizeImage(bytes, maxWidth: 1280);

    if (!mounted) {
      return;
    }

    setState(() {
      _photoBytes = resized;
      _photoUrlOverride = null;
      _photoLoaded = true;
    });
  }

  Future<void> _setPhotoUrl() async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cargar foto desde URL'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'URL de imagen',
              hintText: 'https://...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(''),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Usar foto'),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);

    final clean = _valueAsString(url);

    if (clean == null || !mounted) {
      return;
    }

    setState(() {
      _photoUrlOverride = clean;
      _photoBytes = null;
      _photoLoaded = true;
    });
  }
}

class _ToolFormCard extends ConsumerWidget {
  const _ToolFormCard({
    required this.catalogs,
    required this.formKey,
    required this.saving,
    required this.photoLoaded,
    required this.onPickPhoto,
    required this.onSetPhotoUrl,
    required this.onSave,
    this.photoBytes,
    this.photoUrlOverride,
    this.initialTool,
    super.key,
  });

  final ToolCatalogs catalogs;
  final ToolDetailRecord? initialTool;
  final GlobalKey<FormBuilderState> formKey;
  final bool saving;
  final bool photoLoaded;
  final Uint8List? photoBytes;
  final String? photoUrlOverride;
  final VoidCallback onPickPhoto;
  final VoidCallback onSetPhotoUrl;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppColors.softShadowOf(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: FormBuilder(
          key: formKey,
          initialValue: _initialValues(initialTool),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final sideBySide = constraints.maxWidth >= 1040;
                  final formWidth = sideBySide
                      ? constraints.maxWidth - 354
                      : constraints.maxWidth;

                  final form = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle(
                        title: 'Datos generales',
                        subtitle:
                            'Identificacion, categoria y datos tecnicos principales.',
                      ),
                      const SizedBox(height: 18),
                      _ResponsiveFields(
                        maxWidth: formWidth,
                        children: [
                          FormBuilderTextField(
                            name: 'nomenclature',
                            inputFormatters: [_UpperCaseTextFormatter()],
                            decoration: const InputDecoration(
                              labelText: 'Nomenclatura',
                              prefixIcon: Icon(Icons.build_outlined),
                            ),
                            validator: FormBuilderValidators.required(
                              errorText: 'Campo obligatorio',
                            ),
                          ),
                          FormBuilderDropdown<String>(
                            name: 'category_id',
                            decoration: const InputDecoration(
                              labelText: 'Categoria',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: [
                              if (initialTool?.categoryId != null &&
                                  !catalogs.categories.any(
                                    (item) =>
                                        item.id == initialTool!.categoryId,
                                  ))
                                DropdownMenuItem(
                                  value: initialTool!.categoryId,
                                  child: Text(
                                    initialTool!.category ?? 'Categoria actual',
                                  ),
                                ),
                              for (final item in catalogs.categories)
                                DropdownMenuItem(
                                  value: item.id,
                                  child: Text(
                                    item.typeCode == null
                                        ? item.name
                                        : '${item.name} (${item.typeCode})',
                                  ),
                                ),
                            ],
                          ),
                          FormBuilderDropdown<String>(
                            name: 'manufacturer_id',
                            decoration: InputDecoration(
                              labelText: 'Fabricante',
                              prefixIcon: const Icon(Icons.factory_outlined),
                              suffixIcon: IconButton(
                                tooltip: 'Agregar fabricante',
                                onPressed: () =>
                                    _createManufacturer(context, ref),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ),
                            items: [
                              if (initialTool?.manufacturerId != null &&
                                  !catalogs.manufacturers.any(
                                    (item) =>
                                        item.id == initialTool!.manufacturerId,
                                  ))
                                DropdownMenuItem(
                                  value: initialTool!.manufacturerId,
                                  child: Text(
                                    initialTool!.manufacturer ??
                                        'Fabricante actual',
                                  ),
                                ),
                              for (final item in catalogs.manufacturers)
                                DropdownMenuItem(
                                  value: item.id,
                                  child: Text(item.name),
                                ),
                            ],
                          ),
                          FormBuilderTextField(
                            name: 'model',
                            inputFormatters: [_UpperCaseTextFormatter()],
                            decoration: const InputDecoration(
                              labelText: 'Modelo',
                              prefixIcon: Icon(Icons.memory_outlined),
                            ),
                          ),
                          FormBuilderTextField(
                            name: 'serial_number',
                            inputFormatters: [_UpperCaseTextFormatter()],
                            decoration: const InputDecoration(
                              labelText: 'Numero de serie',
                              prefixIcon: Icon(
                                Icons.confirmation_number_outlined,
                              ),
                            ),
                          ),
                          FormBuilderTextField(
                            name: 'part_number',
                            inputFormatters: [_UpperCaseTextFormatter()],
                            decoration: const InputDecoration(
                              labelText: 'Numero de parte',
                              prefixIcon: Icon(Icons.numbers_outlined),
                            ),
                          ),
                          FormBuilderDropdown<String>(
                            name: 'current_status',
                            decoration: const InputDecoration(
                              labelText: 'Estado fisico',
                              prefixIcon: Icon(Icons.verified_outlined),
                            ),
                            validator: FormBuilderValidators.required(
                              errorText: 'Campo obligatorio',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'DISPONIBLE',
                                child: Text('Disponible'),
                              ),
                              DropdownMenuItem(
                                value: 'EN_USO',
                                child: Text('En uso'),
                              ),
                              DropdownMenuItem(
                                value: 'EN_CALIBRACION',
                                child: Text(''),
                              ),
                              DropdownMenuItem(
                                value: 'FUERA_DE_SERVICIO',
                                child: Text('Fuera de servicio'),
                              ),
                              DropdownMenuItem(
                                value: 'BAJA',
                                child: Text('Baja'),
                              ),
                              DropdownMenuItem(
                                value: 'EXTRAVIADO',
                                child: Text('Extraviado'),
                              ),
                            ],
                          ),
                          FormBuilderDropdown<String>(
                            name: 'current_location',
                            decoration: InputDecoration(
                              labelText: 'Taller / oficina actual',
                              prefixIcon: const Icon(
                                Icons.location_on_outlined,
                              ),
                              suffixIcon: IconButton(
                                tooltip: 'Agregar taller/oficina',
                                onPressed: () => _createWorkshop(context, ref),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ),
                            items: [
                              if (initialTool?.currentLocation != null &&
                                  !catalogs.workshops.any(
                                    (item) =>
                                        item.name ==
                                        initialTool!.currentLocation,
                                  ))
                                DropdownMenuItem(
                                  value: initialTool!.currentLocation,
                                  child: Text(initialTool!.currentLocation!),
                                ),
                              for (final workshop in catalogs.workshops)
                                DropdownMenuItem(
                                  value: workshop.name,
                                  child: Text(workshop.name),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title: 'Trazabilidad y documentos',
                        subtitle:
                            'El QR mostrara certificado vigente y data sheet registrada.',
                      ),
                      const SizedBox(height: 18),
                      _ResponsiveFields(
                        maxWidth: formWidth,
                        twoColumnsOnly: true,
                        children: [
                          FormBuilderDateTimePicker(
                            name: 'acquisition_date',
                            inputType: InputType.date,
                            decoration: const InputDecoration(
                              labelText: 'Fecha de adquisicion',
                              prefixIcon: Icon(Icons.event_available_outlined),
                            ),
                          ),
                          FormBuilderTextField(
                            name: 'data_sheet_url',
                            decoration: const InputDecoration(
                              labelText: 'URL data sheet',
                              prefixIcon: Icon(Icons.description_outlined),
                            ),
                          ),
                          FormBuilderTextField(
                            name: 'manufacturer_certificate_url',
                            decoration: const InputDecoration(
                              labelText: 'URL certificado fabricante',
                              prefixIcon: Icon(
                                Icons.workspace_premium_outlined,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'description',
                        maxLines: 3,
                        inputFormatters: [_UpperCaseTextFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Descripcion / observaciones',
                        ),
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'traceability_notes',
                        maxLines: 3,
                        inputFormatters: [_UpperCaseTextFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Notas de trazabilidad inicial',
                        ),
                      ),
                    ],
                  );

                  final preview = _ToolPreviewPanel(
                    initialTool: initialTool,
                    photoBytes: photoBytes,
                    photoUrl: photoUrlOverride ?? initialTool?.photoUrl,
                    photoLoaded: photoLoaded,
                    onPickPhoto: onPickPhoto,
                    onSetPhotoUrl: onSetPhotoUrl,
                  );

                  if (!sideBySide) {
                    return Column(
                      children: [preview, const SizedBox(height: 20), form],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: form),
                      const SizedBox(width: 22),
                      SizedBox(width: 332, child: preview),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              _QrNote(initialTool: initialTool),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: saving ? null : onSave,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    saving
                        ? 'Guardando...'
                        : initialTool == null
                        ? 'Registrar herramienta'
                        : 'Guardar cambios',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _initialValues(ToolDetailRecord? tool) {
    return {
      'internal_code': tool?.internalCode,
      'nomenclature': tool?.nomenclature,
      'category_id': tool?.categoryId,
      'manufacturer_id': tool?.manufacturerId,
      'model': tool?.model,
      'serial_number': tool?.serialNumber,
      'part_number': tool?.partNumber,
      'description': tool?.description,
      'current_location': tool?.currentLocation,
      'current_status': tool?.currentStatus ?? 'DISPONIBLE',
      'photo_url': tool?.photoUrl,
      'data_sheet_url': tool?.dataSheetUrl,
      'manufacturer_certificate_url': tool?.manufacturerCertificateUrl,
      'acquisition_date': tool?.acquisitionDate,
      'traceability_notes': tool?.traceabilityNotes,
    };
  }
}

class _QrNote extends StatelessWidget {
  const _QrNote({required this.initialTool});

  final ToolDetailRecord? initialTool;

  @override
  Widget build(BuildContext context) {
    final qr = initialTool?.qrCode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoftOf(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_2_outlined, color: AppColors.actionBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              qr == null || qr.isEmpty
                  ? 'Al guardar, Supabase generara un QR unico para imprimir y pegar en la herramienta fisica.'
                  : 'QR asignado: $qr. Puedes imprimir la etiqueta desde la ficha de herramienta.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textOf(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.tintOf(context, AppColors.actionBlue),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.tune_outlined, color: AppColors.actionBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textOf(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.subduedOf(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolPreviewPanel extends StatelessWidget {
  const _ToolPreviewPanel({
    required this.initialTool,
    required this.photoLoaded,
    required this.onPickPhoto,
    required this.onSetPhotoUrl,
    this.photoBytes,
    this.photoUrl,
  });

  final ToolDetailRecord? initialTool;
  final Uint8List? photoBytes;
  final String? photoUrl;
  final bool photoLoaded;
  final VoidCallback onPickPhoto;
  final VoidCallback onSetPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final code = initialTool?.internalCode ?? 'AUTO';
    final image = photoBytes != null
        ? Image.memory(photoBytes!, fit: BoxFit.cover)
        : photoUrl != null && photoUrl!.isNotEmpty
        ? Image.network(photoUrl!, fit: BoxFit.cover)
        : const Icon(Icons.precision_manufacturing_outlined, size: 64);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoftOf(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Vista previa',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textOf(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tintOf(context, AppColors.actionBlue),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    color: AppColors.actionBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderOf(context)),
              ),
              clipBehavior: Clip.antiAlias,
              child: image,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: onPickPhoto,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Archivo'),
              ),
              OutlinedButton.icon(
                onPressed: onSetPhotoUrl,
                icon: const Icon(Icons.link_outlined),
                label: const Text('URL'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                photoLoaded ||
                        (initialTool?.photoUrl != null &&
                            initialTool!.photoUrl!.isNotEmpty)
                    ? Icons.check_circle
                    : Icons.info_outline,
                color: photoLoaded ? AppColors.success : AppColors.muted,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  photoLoaded ||
                          (initialTool?.photoUrl != null &&
                              initialTool!.photoUrl!.isNotEmpty)
                      ? 'Foto cargada'
                      : 'Sin foto de referencia',
                  style: TextStyle(
                    color: AppColors.subduedOf(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PreviewInfo(
            icon: Icons.qr_code_2_outlined,
            text: initialTool?.qrCode ?? 'QR unico al guardar',
          ),
          const SizedBox(height: 8),
          _PreviewInfo(
            icon: Icons.lock_outline,
            text: initialTool == null
                ? 'Codigo automatico inmutable'
                : 'Codigo conservado e inmutable',
          ),
        ],
      ),
    );
  }
}

class _PreviewInfo extends StatelessWidget {
  const _PreviewInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.actionBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.textOf(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({
    required this.children,
    required this.maxWidth,
    this.twoColumnsOnly = false,
  });

  final List<Widget> children;
  final double maxWidth;
  final bool twoColumnsOnly;

  @override
  Widget build(BuildContext context) {
    final columns = maxWidth >= 820 ? (twoColumnsOnly ? 2 : 3) : 1;
    final width = columns == 1
        ? double.infinity
        : (maxWidth - (16 * (columns - 1))) / columns;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final child in children) SizedBox(width: width, child: child),
      ],
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

Future<void> _createManufacturer(BuildContext context, WidgetRef ref) async {
  final name = await _textInputDialog(
    context,
    title: 'Agregar fabricante',
    label: 'Nombre del fabricante',
  );

  if (name == null || name.trim().isEmpty) {
    return;
  }

  try {
    await ref.read(toolMutationRepositoryProvider).createManufacturer(name);
    ref.invalidate(toolCatalogsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fabricante agregado al catalogo.')),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo agregar fabricante: $error')),
      );
    }
  }
}

Future<void> _createWorkshop(BuildContext context, WidgetRef ref) async {
  final name = await _textInputDialog(
    context,
    title: 'Agregar taller u oficina',
    label: 'Nombre del taller/oficina',
  );

  if (name == null || name.trim().isEmpty) {
    return;
  }

  try {
    await ref.read(toolMutationRepositoryProvider).createWorkshop(name: name);
    ref.invalidate(toolCatalogsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicacion agregada al catalogo.')),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo agregar ubicacion: $error')),
      );
    }
  }
}

Future<String?> _textInputDialog(
  BuildContext context, {
  required String title,
  required String label,
}) {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          inputFormatters: [_UpperCaseTextFormatter()],
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(''),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Agregar'),
          ),
        ],
      );
    },
  ).whenComplete(controller.dispose);
}

Future<Uint8List> _resizeImage(Uint8List bytes, {required int maxWidth}) async {
  if (bytes.lengthInBytes < 900000) {
    return bytes;
  }

  final codec = await ui.instantiateImageCodec(bytes, targetWidth: maxWidth);
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);

  return data?.buffer.asUint8List() ?? bytes;
}

String? _valueAsString(Object? value) {
  if (value == null) {
    return null;
  }

  final clean = value.toString().trim();

  return clean.isEmpty ? null : clean;
}

String? _dateOnly(DateTime? value) {
  if (value == null) {
    return null;
  }

  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

String? _firstWorkshopName(ToolCatalogs catalogs) {
  return catalogs.workshops.isEmpty ? null : catalogs.workshops.first.name;
}
