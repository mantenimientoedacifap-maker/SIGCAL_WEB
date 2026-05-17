import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/page_header.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../../tools/data/tool_catalog_providers.dart';
import '../data/shipment_providers.dart';

class ShipmentFormPage extends ConsumerStatefulWidget {
  const ShipmentFormPage({super.key});

  @override
  ConsumerState<ShipmentFormPage> createState() => _ShipmentFormPageState();
}

class _ShipmentFormPageState extends ConsumerState<ShipmentFormPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _saving = false;
  Uint8List? _guideBytes;
  String? _guideFileName;

  @override
  Widget build(BuildContext context) {
    final snapshotState = ref.watch(dashboardSnapshotProvider);
    final catalogsState = ref.watch(toolCatalogsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Registrar envio',
          description:
              'Envia una herramienta a proveedor, cambia su estado a EN CALIBRACION y conserva trazabilidad.',
          actions: [
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.shipments),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Envios'),
            ),
          ],
        ),
        snapshotState.when(
          data: (snapshot) => catalogsState.when(
            data: (catalogs) => _ShipmentFormCard(
              formKey: _formKey,
              tools: snapshot.tools
                  .where((tool) => tool.currentStatus != 'EN_CALIBRACION')
                  .toList(),
              catalogs: catalogs,
              saving: _saving,
              guideFileName: _guideFileName,
              onSave: () => _save(catalogs),
              onCreateProvider: () => _createProvider(context),
              onPickGuide: _pickGuide,
              onClearGuide: _clearGuide,
            ),
            error: (error, _) => EmptyState(
              title: 'No se pudieron cargar catalogos',
              message: error.toString(),
              icon: Icons.error_outline,
            ),
            loading: () => const SizedBox(
              height: 420,
              child: LoadingView(message: 'Cargando proveedores...'),
            ),
          ),
          error: (error, _) => EmptyState(
            title: 'No se pudieron cargar herramientas',
            message: error.toString(),
            icon: Icons.error_outline,
          ),
          loading: () => const SizedBox(
            height: 420,
            child: LoadingView(message: ''),
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
      final providerId = _valueAsString(values['provider_id']);
      final matchingProviders = catalogs.providers
          .where((item) => item.id == providerId)
          .toList();
      final provider = matchingProviders.isEmpty
          ? null
          : matchingProviders.first;
      final center =
          provider?.name ?? _valueAsString(values['calibration_center']) ?? '';

      await ref
          .read(shipmentRepositoryProvider)
          .createShipment(
            toolId: _valueAsString(values['tool_id'])!,
            providerId: providerId,
            calibrationCenter: center,
            shipmentDate: values['shipment_date'] as DateTime,
            estimatedReturnDate: values['estimated_return_date'] as DateTime?,
            remissionGuideNumber: _valueAsString(
              values['remission_guide_number'],
            ),
            observations: _valueAsString(values['observations']),
            remissionGuideBytes: _guideBytes,
            remissionGuideFileName: _guideFileName,
          );

      ref.invalidate(shipmentsProvider);
      ref.invalidate(dashboardSnapshotProvider);
      ref.invalidate(quarantineToolsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Envio registrado correctamente.')),
        );
        context.go(AppRoutes.shipments);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo registrar envio: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickGuide() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    final file = result?.files.single;
    if (file == null || file.bytes == null || !mounted) return;

    setState(() {
      _guideBytes = file.bytes;
      _guideFileName = file.name;
    });
  }

  void _clearGuide() {
    setState(() {
      _guideBytes = null;
      _guideFileName = null;
    });
  }

  Future<void> _createProvider(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar proveedor'),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Empresa de calibracion',
            ),
            onChanged: (value) {
              final upper = value.toUpperCase();
              if (upper != value) {
                controller.value = TextEditingValue(
                  text: upper,
                  selection: TextSelection.collapsed(offset: upper.length),
                );
              }
            },
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

    if (name == null || name.trim().isEmpty) {
      return;
    }

    try {
      await ref.read(toolMutationRepositoryProvider).createProvider(name: name);
      ref.invalidate(toolCatalogsProvider);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo agregar proveedor: $error')),
        );
      }
    }
  }
}

class _ShipmentFormCard extends StatelessWidget {
  const _ShipmentFormCard({
    required this.formKey,
    required this.tools,
    required this.catalogs,
    required this.saving,
    required this.onSave,
    required this.onCreateProvider,
    required this.onPickGuide,
    required this.onClearGuide,
    this.guideFileName,
  });

  final GlobalKey<FormBuilderState> formKey;
  final List<DashboardTool> tools;
  final ToolCatalogs catalogs;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onCreateProvider;
  final VoidCallback onPickGuide;
  final VoidCallback onClearGuide;
  final String? guideFileName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppColors.softShadowOf(context),
      ),
      child: FormBuilder(
        key: formKey,
        initialValue: {'shipment_date': DateTime.now()},
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 760;
            final width = twoColumns
                ? (constraints.maxWidth - 16) / 2
                : double.infinity;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: width,
                      child: FormBuilderDropdown<String>(
                        name: 'tool_id',
                        decoration: const InputDecoration(
                          labelText: 'Herramienta / equipo',
                          prefixIcon: Icon(Icons.build_outlined),
                        ),
                        validator: FormBuilderValidators.required(
                          errorText: 'Selecciona una herramienta',
                        ),
                        items: [
                          for (final tool in tools)
                            DropdownMenuItem(
                              value: tool.id,
                              child: Text(
                                '${tool.internalCode ?? '-'} / ${tool.displayName}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: FormBuilderDropdown<String>(
                        name: 'provider_id',
                        decoration: InputDecoration(
                          labelText: 'Proveedor de calibracion',
                          prefixIcon: const Icon(Icons.business_outlined),
                          suffixIcon: IconButton(
                            tooltip: 'Agregar proveedor',
                            onPressed: onCreateProvider,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ),
                        items: [
                          for (final provider in catalogs.providers)
                            DropdownMenuItem(
                              value: provider.id,
                              child: Text(provider.name),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: FormBuilderTextField(
                        name: 'calibration_center',
                        decoration: const InputDecoration(
                          labelText: 'Centro de calibracion manual',
                          prefixIcon: Icon(Icons.edit_location_alt_outlined),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: FormBuilderTextField(
                        name: 'remission_guide_number',
                        decoration: const InputDecoration(
                          labelText: 'Numero de guia de remision',
                          prefixIcon: Icon(Icons.receipt_long_outlined),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: FormBuilderDateTimePicker(
                        name: 'shipment_date',
                        inputType: InputType.date,
                        decoration: const InputDecoration(
                          labelText: 'Fecha de envio',
                          prefixIcon: Icon(Icons.outbound_outlined),
                        ),
                        validator: FormBuilderValidators.required(
                          errorText: 'Campo obligatorio',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: FormBuilderDateTimePicker(
                        name: 'estimated_return_date',
                        inputType: InputType.date,
                        decoration: const InputDecoration(
                          labelText: 'Retorno estimado',
                          prefixIcon: Icon(Icons.event_repeat_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'observations',
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones operativas',
                  ),
                ),
                const SizedBox(height: 18),
                // ── Guía de remisión ──
                _GuidePicker(
                  fileName: guideFileName,
                  onPick: onPickGuide,
                  onClear: guideFileName == null
                      ? null
                      : onClearGuide,
                ),
                if (guideFileName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Archivo seleccionado: $guideFileName',
                    style: TextStyle(
                      color: AppColors.subduedOf(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
                        : const Icon(Icons.local_shipping_outlined),
                    label: Text(saving ? 'Guardando...' : 'Registrar envio'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String? _valueAsString(Object? value) {
  final clean = value?.toString().trim();

  return clean == null || clean.isEmpty ? null : clean;
}

// ── Guía de remisión picker widget ──

class _GuidePicker extends StatelessWidget {
  const _GuidePicker({
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
              color: AppColors.tintOf(context, AppColors.actionBlue),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.actionBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName ?? 'Guia de remision (PDF/JPG/PNG)',
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
            tooltip: 'Seleccionar archivo',
            icon: const Icon(Icons.upload_file_outlined),
          ),
          if (onClear != null)
            IconButton(
              onPressed: onClear,
              tooltip: 'Quitar archivo',
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }
}
