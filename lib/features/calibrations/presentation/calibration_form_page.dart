import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/page_header.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../../tools/data/tool_catalog_providers.dart';
import '../../tools/data/tool_detail_providers.dart';
import '../data/calibration_repository.dart';

class CalibrationFormPage extends ConsumerWidget {
  const CalibrationFormPage({
    required this.toolId,
    this.calibrationId,
    super.key,
  });

  final String toolId;

  /// Si se provee, el formulario opera en modo edición sobre esta
  /// calibración existente.
  final String? calibrationId;

  bool get isEditing => calibrationId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolState = ref.watch(toolDetailProvider(toolId));
    final catalogsState = ref.watch(toolCatalogsProvider);

    return toolState.when(
      data: (tool) {
        if (tool == null) {
          return const EmptyState(
            title: 'Herramienta no encontrada',
            message: 'No se puede registrar calibracion para este codigo.',
            icon: Icons.manage_search_outlined,
          );
        }

        return catalogsState.when(
          data: (catalogs) =>
              _CalibrationFormContent(
                tool: tool,
                catalogs: catalogs,
                isEditing: isEditing,
                calibrationId: calibrationId,
              ),
          error: (error, _) => EmptyState(
            title: 'No se pudieron cargar proveedores',
            message: error.toString(),
            icon: Icons.error_outline,
          ),
          loading: () => const SizedBox(
            height: 420,
            child: LoadingView(message: 'Cargando catalogos...'),
          ),
        );
      },
      error: (error, _) => EmptyState(
        title: 'No se pudo cargar la herramienta',
        message: error.toString(),
        icon: Icons.error_outline,
      ),
      loading: () => const SizedBox(
        height: 420,
        child: LoadingView(message: 'Cargando herramienta...'),
      ),
    );
  }
}

class _CalibrationFormContent extends ConsumerStatefulWidget {
  const _CalibrationFormContent({
    required this.tool,
    required this.catalogs,
    required this.isEditing,
    this.calibrationId,
  });

  final ToolDetailRecord tool;
  final ToolCatalogs catalogs;
  final bool isEditing;
  final String? calibrationId;

  @override
  ConsumerState<_CalibrationFormContent> createState() =>
      _CalibrationFormContentState();
}

class _CalibrationFormContentState
    extends ConsumerState<_CalibrationFormContent> {
  final _formKey = GlobalKey<FormState>();
  final _certificateController = TextEditingController();
  final _centerController = TextEditingController();
  final _observationsController = TextEditingController();
  final _quarantineNotesController = TextEditingController();
  final _validityController = TextEditingController(text: '12');
  final _dateFormat = DateFormat('yyyy-MM-dd');

  DateTime _calibrationDate = DateTime.now();
  String? _providerId;
  String _result = 'CONFORME';
  String? _quarantineReason;
  Uint8List? _certificateBytes;
  String? _certificateFileName;
  String? _certificateContentType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadExisting();
    }
  }

  void _loadExisting() {
    final cal = widget.tool.calibrations
        .where((c) => c.id == widget.calibrationId)
        .firstOrNull;
    if (cal == null) return;

    _calibrationDate = cal.calibrationDate;
    _validityController.text = cal.validityMonths.toString();
    _result = cal.result ?? 'CONFORME';
    _providerId = cal.providerId;
    _centerController.text = cal.calibrationCenter ?? '';
    _certificateController.text = cal.certificateNumber ?? '';
    _observationsController.text = cal.observations ?? '';
    // El certificado existente se conserva; no se precarga en bytes
  }

  DateTime get _expirationDate {
    final months = int.tryParse(_validityController.text.trim()) ?? 0;

    return DateTime(
      _calibrationDate.year,
      _calibrationDate.month + months,
      _calibrationDate.day,
    );
  }

  @override
  void dispose() {
    _certificateController.dispose();
    _centerController.dispose();
    _observationsController.dispose();
    _quarantineNotesController.dispose();
    _validityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedProvider = _selectedProvider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: widget.isEditing
              ? 'Editar calibracion'
              : 'Registrar calibracion',
          description:
              '${widget.tool.nomenclature} · ${widget.tool.internalCode ?? 'Sin codigo interno'}',
          actions: [
            OutlinedButton.icon(
              onPressed: _saving
                  ? null
                  : () => context.go(AppRoutes.toolDetail(widget.tool.id)),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver a ficha'),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.borderOf(context)),
            boxShadow: AppColors.softShadowOf(context),
          ),
          clipBehavior: Clip.antiAlias,
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormSectionHeader(
                    title: 'Datos metrologicos',
                    description:
                        'Registra el resultado y deja que SIGCAL calcule el vencimiento.',
                    icon: Icons.verified_outlined,
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns = constraints.maxWidth >= 860;
                      final width = twoColumns
                          ? (constraints.maxWidth - 16) / 2
                          : double.infinity;

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: width,
                            child: _DateField(
                              label: 'Fecha de calibracion',
                              value: _calibrationDate,
                              onTap: _pickCalibrationDate,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: TextFormField(
                              controller: _validityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Vigencia (meses)',
                                prefixIcon: Icon(Icons.calendar_month_outlined),
                              ),
                              validator: (value) {
                                final months = int.tryParse(
                                  value?.trim() ?? '',
                                );

                                if (months == null || months <= 0) {
                                  return 'Ingresa una vigencia valida.';
                                }

                                if (months > 120) {
                                  return 'La vigencia no debe superar 120 meses.';
                                }

                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _ReadOnlyFactField(
                              label: 'Proximo vencimiento',
                              value: _dateFormat.format(_expirationDate),
                              icon: Icons.event_available_outlined,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: DropdownButtonFormField<String>(
                              initialValue: _result,
                              decoration: const InputDecoration(
                                labelText: 'Resultado',
                                prefixIcon: Icon(Icons.fact_check_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'CONFORME',
                                  child: Text('Conforme'),
                                ),
                                DropdownMenuItem(
                                  value: 'CONDICIONADO',
                                  child: Text('Condicionado'),
                                ),
                                DropdownMenuItem(
                                  value: 'NO_CONFORME',
                                  child: Text('No conforme'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _result = value;
                                    if (value != 'NO_CONFORME') {
                                      _quarantineReason = null;
                                      _quarantineNotesController.clear();
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 26),
                  _FormSectionHeader(
                    title: 'Proveedor y certificado',
                    description:
                        'Asocia el laboratorio externo y el PDF del certificado vigente.',
                    icon: Icons.business_center_outlined,
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns = constraints.maxWidth >= 860;
                      final width = twoColumns
                          ? (constraints.maxWidth - 16) / 2
                          : double.infinity;

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: width,
                            child: DropdownButtonFormField<String>(
                              initialValue: _providerId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Proveedor de calibracion',
                                prefixIcon: Icon(Icons.apartment_outlined),
                              ),
                              items: [
                                for (final provider
                                    in widget.catalogs.providers)
                                  DropdownMenuItem(
                                    value: provider.id,
                                    child: Text(provider.name),
                                  ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _providerId = value;
                                  final provider = _selectedProvider;
                                  if (provider != null &&
                                      _centerController.text.trim().isEmpty) {
                                    _centerController.text = provider.name;
                                  }
                                });
                              },
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Selecciona un proveedor.'
                                  : null,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: TextFormField(
                              controller: _centerController,
                              decoration: const InputDecoration(
                                labelText: 'Centro/laboratorio',
                                prefixIcon: Icon(Icons.location_city_outlined),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Indica el centro de calibracion.'
                                  : null,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: TextFormField(
                              controller: _certificateController,
                              decoration: const InputDecoration(
                                labelText: 'Numero de certificado',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Indica el numero de certificado.'
                                  : null,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _CertificatePicker(
                              fileName: _certificateFileName,
                              onPick: _pickCertificate,
                              onClear: _certificateFileName == null
                                  ? null
                                  : () {
                                      setState(() {
                                        _certificateBytes = null;
                                        _certificateFileName = null;
                                        _certificateContentType = null;
                                      });
                                    },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (selectedProvider != null) ...[
                    const SizedBox(height: 14),
                    _ProviderHint(provider: selectedProvider),
                  ],
                  if (_result == 'NO_CONFORME') ...[
                    const SizedBox(height: 26),
                    _FormSectionHeader(
                      title: 'Cuarentena obligatoria',
                      description:
                          'Indica la causa formal para seguimiento, accion correctiva o baja auditada.',
                      icon: Icons.warning_amber_outlined,
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumns = constraints.maxWidth >= 860;
                        final width = twoColumns
                            ? (constraints.maxWidth - 16) / 2
                            : double.infinity;

                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: width,
                              child: DropdownButtonFormField<String>(
                                initialValue: _quarantineReason,
                                decoration: const InputDecoration(
                                  labelText: 'Causa de cuarentena',
                                  prefixIcon: Icon(
                                    Icons.report_problem_outlined,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'NO_CONFORME',
                                    child: Text('No conforme'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'IRREPARABLE',
                                    child: Text('Irreparable'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'INOPERATIVA',
                                    child: Text('Inoperativa'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'NO_CALIBRABLE',
                                    child: Text('No calibrable'),
                                  ),
                                ],
                                onChanged: (value) =>
                                    setState(() => _quarantineReason = value),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Selecciona la causa.'
                                    : null,
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: TextFormField(
                                controller: _quarantineNotesController,
                                minLines: 1,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Notas de cuarentena',
                                  prefixIcon: Icon(Icons.notes_outlined),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: _observationsController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
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
                      label: Text(
                        _saving
                            ? 'Guardando...'
                            : widget.isEditing
                                ? 'Guardar cambios'
                                : 'Guardar calibracion vigente',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  CalibrationProviderRecord? get _selectedProvider {
    final providerId = _providerId;

    if (providerId == null) {
      return null;
    }

    for (final provider in widget.catalogs.providers) {
      if (provider.id == providerId) {
        return provider;
      }
    }

    return null;
  }

  Future<void> _pickCalibrationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _calibrationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5),
    );

    if (picked != null && mounted) {
      setState(() => _calibrationDate = picked);
    }
  }

  Future<void> _pickCertificate() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );

    final file = result?.files.single;

    if (file == null || file.bytes == null) {
      return;
    }

    setState(() {
      _certificateBytes = file.bytes;
      _certificateFileName = file.name;
      _certificateContentType = 'application/pdf';
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(calibrationRepositoryProvider);
      final months = int.parse(_validityController.text.trim());

      if (widget.isEditing) {
        await repo.updateCalibration(
          calibrationId: widget.calibrationId!,
          toolId: widget.tool.id,
          calibrationDate: _calibrationDate,
          validityMonths: months,
          expirationDate: _expirationDate,
          result: _result,
          providerId: _providerId,
          calibrationCenter: _centerController.text,
          certificateNumber: _certificateController.text,
          certificateBytes: _certificateBytes,
          certificateFileName: _certificateFileName,
          certificateContentType: _certificateContentType,
          observations: _observationsController.text,
          quarantineReason: _quarantineReason,
          quarantineNotes: _quarantineNotesController.text,
        );
      } else {
        await repo.createCalibration(
          toolId: widget.tool.id,
          calibrationDate: _calibrationDate,
          validityMonths: months,
          expirationDate: _expirationDate,
          result: _result,
          providerId: _providerId,
          calibrationCenter: _centerController.text,
          certificateNumber: _certificateController.text,
          certificateBytes: _certificateBytes,
          certificateFileName: _certificateFileName,
          certificateContentType: _certificateContentType,
          observations: _observationsController.text,
          quarantineReason: _quarantineReason,
          quarantineNotes: _quarantineNotesController.text,
        );
      }

      ref.invalidate(toolDetailProvider(widget.tool.id));
      ref.invalidate(dashboardSnapshotProvider);
      ref.invalidate(quarantineToolsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Calibracion actualizada correctamente.'
                  : 'Calibracion registrada correctamente.',
            ),
          ),
        );
        context.go(AppRoutes.toolDetail(widget.tool.id));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la calibracion: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _FormSectionHeader extends StatelessWidget {
  const _FormSectionHeader({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.tintOf(context, AppColors.calibration),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppColors.calibration),
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
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.subduedOf(context),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
        ),
        child: Text(
          DateFormat('yyyy-MM-dd').format(value),
          style: TextStyle(
            color: AppColors.textOf(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyFactField extends StatelessWidget {
  const _ReadOnlyFactField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      child: Text(
        value,
        style: TextStyle(
          color: AppColors.textOf(context),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CertificatePicker extends StatelessWidget {
  const _CertificatePicker({
    required this.fileName,
    required this.onPick,
    required this.onClear,
  });

  final String? fileName;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoftOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.tintOf(context, AppColors.danger),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.picture_as_pdf_outlined,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName ?? 'Certificado PDF opcional',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fileName == null
                    ? AppColors.subduedOf(context)
                    : AppColors.textOf(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: onPick,
            tooltip: 'Seleccionar PDF',
            icon: const Icon(Icons.upload_file_outlined),
          ),
          if (onClear != null)
            IconButton(
              onPressed: onClear,
              tooltip: 'Quitar PDF',
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }
}

class _ProviderHint extends StatelessWidget {
  const _ProviderHint({required this.provider});

  final CalibrationProviderRecord provider;

  @override
  Widget build(BuildContext context) {
    final details = [
      provider.contactName,
      provider.phone,
      provider.address,
    ].where((value) => value != null && value.trim().isNotEmpty).join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tintOf(context, AppColors.actionBlue),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Text(
        details.isEmpty
            ? 'Proveedor seleccionado: ${provider.name}'
            : '${provider.name} · $details',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textOf(context),
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}
