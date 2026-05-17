import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/supabase_providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/i18n/translations.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/data/auth_providers.dart';
import '../../calibrations/data/calibration_repository.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../../loans/data/loans_providers.dart';
import '../../reports/data/pdf_report_service.dart';
import '../data/tool_catalog_providers.dart';
import '../data/tool_detail_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE ENTRY
// ═══════════════════════════════════════════════════════════════════════════════

class ToolDetailPage extends ConsumerWidget {
  const ToolDetailPage({required this.toolId, super.key});
  final String toolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(toolDetailProvider(toolId));
    return d.when(
      data: (t) => t == null
          ? const EmptyState(
              title: 'Herramienta no encontrada',
              message: 'El registro solicitado no existe.',
              icon: Icons.manage_search_outlined)
          : _Ficha(tool: t),
      error: (e, _) => EmptyState(
          title: 'Error', message: e.toString(), icon: Icons.error_outline),
      loading: () => SizedBox(
          height: 480, child: LoadingView(message: context.t('tool.loading'))),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN CONTENT
// ═══════════════════════════════════════════════════════════════════════════════

class _Ficha extends ConsumerWidget {
  const _Ficha({required this.tool});
  final ToolDetailRecord tool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(currentUserProfileProvider).asData?.value;
    final canManage = p?.role.canManageOperationalData ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBar(tool: tool, canManage: canManage),
          const SizedBox(height: 20),
          _IdentityCard(tool: tool),
          const SizedBox(height: 18),
          _ActionGrid(tool: tool, canManage: canManage),
          const SizedBox(height: 18),
          _LastCalibrationCard(calibration: tool.latestCalibration, tool: tool),
          const SizedBox(height: 18),
          _LoanCard(tool: tool),
          const SizedBox(height: 18),
          _TechnicalReports(tool: tool),
          const SizedBox(height: 18),
          _TraceabilityTimeline(tool: tool),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TOP BAR — Back / Title / More menu
// ═══════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({required this.tool, required this.canManage});
  final ToolDetailRecord tool;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _PillIcon(
        icon: Icons.arrow_back_rounded,
        onTap: () => context.go(AppRoutes.tools),
        tooltip: 'Volver',
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tool.nomenclature,
              style: TextStyle(
                color: AppColors.textOf(context),
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -0.3,
              ),
            ),
            if (tool.internalCode != null)
              Text(
                tool.internalCode!,
                style: TextStyle(
                  color: AppColors.subduedOf(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      _PillIcon(
        icon: Icons.edit_outlined,
        onTap: () => context.go(AppRoutes.editTool(tool.id)),
        tooltip: 'Editar',
      ),
      const SizedBox(width: 8),
      PopupMenuButton<String>(
        offset: const Offset(0, 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'calibrate',
            child: Row(children: [
              Icon(Icons.verified_outlined, size: 20),
              SizedBox(width: 10),
              Text('Registrar calibracion'),
            ]),
          ),
          const PopupMenuItem(
            value: 'pdf',
            child: Row(children: [
              Icon(Icons.picture_as_pdf_outlined, size: 20),
              SizedBox(width: 10),
              Text('Exportar PDF de estatus'),
            ]),
          ),
          const PopupMenuItem(
            value: 'qr',
            child: Row(children: [
              Icon(Icons.qr_code_2_outlined, size: 20),
              SizedBox(width: 10),
              Text('Imprimir etiqueta QR'),
            ]),
          ),
          if (tool.activeLoan != null)
            const PopupMenuItem(
              value: 'voucher',
              child: Row(children: [
                Icon(Icons.receipt_long_outlined, size: 20),
                SizedBox(width: 10),
                Text('Imprimir vale de prestamo'),
              ]),
            ),
          if (canManage && !tool.isRetired) ...[
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'retire',
              child: Row(children: [
                Icon(Icons.archive_outlined,
                    size: 20, color: AppColors.danger),
                SizedBox(width: 10),
                Text('Dar de baja',
                    style: TextStyle(color: AppColors.danger)),
              ]),
            ),
          ],
        ],
        onSelected: (v) => _handleMenuAction(context, v),
        child: _PillIconShell(
          child: Icon(Icons.more_horiz, color: AppColors.textOf(context)),
        ),
      ),
    ]);
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'calibrate':
        context.go(AppRoutes.newCalibration(tool.id));
      case 'pdf':
        PdfReportService.printToolStatus(tool);
      case 'qr':
        PdfReportService.printToolQrLabel(tool);
      case 'voucher':
        if (tool.activeLoan != null) {
          PdfReportService.printLoanVoucher(tool: tool, loan: tool.activeLoan!);
        }
      case 'retire':
        _confirmRetire(context, tool);
    }
  }
}

class _PillIcon extends StatelessWidget {
  const _PillIcon({required this.icon, required this.onTap, this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: _PillIconShell(
          child: Icon(icon, color: AppColors.textOf(context), size: 22),
        ),
      ),
    );
  }
}

class _PillIconShell extends StatelessWidget {
  const _PillIconShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppColors.softShadowOf(context),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// IDENTITY CARD — Photo + Specs + Health Ring + Manual + QR
// ═══════════════════════════════════════════════════════════════════════════════

class _IdentityCard extends ConsumerWidget {
  const _IdentityCard({required this.tool});
  final ToolDetailRecord tool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = tool.healthScore.round();
    final days = tool.daysToExpiration;
    final state = tool.complianceState;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: _csColor(state).withValues(alpha: AppColors.isDark(context) ? 0.15 : 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header strip ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.isDark(context)
                    ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                    : const [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
              ),
            ),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.actionBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fingerprint_outlined,
                    color: AppColors.actionBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'IDENTITY CARD',
                style: TextStyle(
                  color: AppColors.subduedOf(context),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              _ComplianceBadge(state: state),
            ]),
          ),
          // ── Body ──
          Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(builder: (ctx, constraints) {
              final wide = constraints.maxWidth >= 720;
              final photoSection = _PhotoBlock(tool: tool, height: wide ? 240 : 200);
              final specsSection = _SpecsBlock(tool: tool);
              final healthSection = _HealthRing(
                  health: health, days: days, state: state, isLarge: wide);

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 240, child: photoSection),
                    const SizedBox(width: 20),
                    Expanded(child: specsSection),
                    const SizedBox(width: 16),
                    SizedBox(width: 160, child: healthSection),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  photoSection,
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: specsSection),
                      const SizedBox(width: 16),
                      SizedBox(width: 140, child: healthSection),
                    ],
                  ),
                ],
              );
            }),
          ),
          const Divider(height: 1),
          // ── Manual row ──
          _ManualRow(tool: tool),
          const Divider(height: 1),
          // ── QR row ──
          _QrRow(tool: tool),
        ],
      ),
    );
  }
}

// ── Photo Block ──

class _PhotoBlock extends StatelessWidget {
  const _PhotoBlock({required this.tool, required this.height});
  final ToolDetailRecord tool;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderOf(context)),
        color: AppColors.surfaceSoftOf(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: tool.photoUrl != null && tool.photoUrl!.isNotEmpty
          ? Image.network(tool.photoUrl!, fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _Placeholder())
          : _Placeholder(),
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.precision_manufacturing_outlined,
            color: AppColors.subduedOf(context), size: 52),
        const SizedBox(height: 8),
        Text('Sin fotografia',
            style: TextStyle(
                color: AppColors.subduedOf(context), fontSize: 12)),
      ]),
    );
  }
}

// ── Specs Block ──

class _SpecsBlock extends StatelessWidget {
  const _SpecsBlock({required this.tool});
  final ToolDetailRecord tool;

  @override
  Widget build(BuildContext context) {
    final items = <_SpecItem>[
      _SpecItem('Serie', tool.serialNumber),
      _SpecItem('Codigo interno', tool.internalCode),
      _SpecItem('Parte', tool.partNumber),
      _SpecItem('Ubicacion', tool.currentLocation),
      _SpecItem('Fabricante', tool.manufacturer),
      _SpecItem('Modelo', tool.model),
      _SpecItem('Categoria', tool.category),
      _SpecItem('Alta', tool.acquisitionDate != null
          ? SigecalDateUtils.formatDateFull(tool.acquisitionDate)
          : null),
    ].where((e) => e.value != null && e.value!.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items) ...[
          _SpecRow(label: item.label, value: item.value!),
          const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _SpecItem {
  const _SpecItem(this.label, this.value);
  final String label;
  final String? value;
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.subduedOf(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppColors.textOf(context),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Health Ring ──

class _HealthRing extends StatelessWidget {
  const _HealthRing({
    required this.health,
    required this.days,
    required this.state,
    required this.isLarge,
  });
  final int health;
  final int? days;
  final ComplianceState state;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final color = _csColor(state);
    final size = isLarge ? 140.0 : 120.0;
    final stroke = isLarge ? 10.0 : 8.0;

    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: health / 100,
            color: color,
            strokeWidth: stroke,
            bgColor: AppColors.surfaceSoftOf(context),
          ),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$health%',
                  style: TextStyle(
                    color: AppColors.textOf(context),
                    fontWeight: FontWeight.w900,
                    fontSize: isLarge ? 28 : 24,
                  )),
              Text('SALUD',
                  style: TextStyle(
                    color: AppColors.subduedOf(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                    letterSpacing: 1.5,
                  )),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 10),
      if (days != null) ...[
        Text(
          (days ?? 0) > 0 ? 'Vence en' : 'Vencido hace',
          style: TextStyle(color: AppColors.subduedOf(context), fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          '${days!.abs()} dias',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ],
    ]);
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.bgColor,
  });
  final double progress;
  final Color color;
  final double strokeWidth;
  final Color bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, bgPaint);

    // Progress
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        rect, -math.pi / 2, 2 * math.pi * progress.clamp(0.0, 1.0), false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      progress != old.progress || color != old.color;
}

// ── Manual Row ──

class _ManualRow extends ConsumerStatefulWidget {
  const _ManualRow({required this.tool});
  final ToolDetailRecord tool;

  @override
  ConsumerState<_ManualRow> createState() => _ManualRowState();
}

class _ManualRowState extends ConsumerState<_ManualRow> {
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final hasManual =
        tool.dataSheetUrl != null && tool.dataSheetUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.menu_book_outlined,
              color: AppColors.warning, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: hasManual
              ? InkWell(
                  onTap: () => _openFile(context, ref, tool.dataSheetUrl!,
                      documentType: 'MANUAL'),
                  borderRadius: BorderRadius.circular(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manual tecnico del fabricante',
                        style: TextStyle(
                          color: AppColors.textOf(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Tocar para descargar',
                        style: TextStyle(
                          color: AppColors.subduedOf(context),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                )
              : Text(
                  'Sin archivo adjunto',
                  style: TextStyle(
                    color: AppColors.subduedOf(context),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
        if (_uploading)
          const Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (hasManual)
          Icon(Icons.chevron_right, color: AppColors.subduedOf(context))
        else
          TextButton.icon(
            onPressed: _pickAndUpload,
            icon: const Icon(Icons.upload_outlined, size: 18),
            label: const Text('Subir manual'),
          ),
      ]),
    );
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );

    final file = result?.files.single;
    if (file == null || file.bytes == null || !mounted) return;

    setState(() => _uploading = true);

    try {
      await ref
          .read(toolMutationRepositoryProvider)
          .uploadManual(
            toolId: widget.tool.id,
            bytes: file.bytes!,
            fileName: file.name,
          );
      ref.invalidate(toolDetailProvider(widget.tool.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Manual subido correctamente.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}

// ── QR Row ──

class _QrRow extends StatelessWidget {
  const _QrRow({required this.tool});
  final ToolDetailRecord tool;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.actionBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.qr_code_2_outlined,
              color: AppColors.actionBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tool.qrCode ?? 'QR pendiente de generacion',
                style: TextStyle(
                  color: AppColors.textOf(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => PdfReportService.printToolQrLabel(tool),
          icon: const Icon(Icons.print_outlined, size: 18),
          label: const Text('Imprimir etiqueta'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// COMPLIANCE BADGE (inline chip)
// ═══════════════════════════════════════════════════════════════════════════════

class _ComplianceBadge extends StatelessWidget {
  const _ComplianceBadge({required this.state});
  final ComplianceState state;

  @override
  Widget build(BuildContext context) {
    final c = _csColor(state);
    final l = _sl(state);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(l,
          style: TextStyle(
              color: c, fontWeight: FontWeight.w900, fontSize: 11)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ACTION GRID — What can you do with this tool?
// ═══════════════════════════════════════════════════════════════════════════════

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.tool, required this.canManage});
  final ToolDetailRecord tool;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[
      if (!tool.isRetired && tool.currentStatus != 'EN_CALIBRACION')
        _QuickAction(
          icon: Icons.verified_user_outlined,
          label: 'Registrar\ncalibracion',
          color: AppColors.success,
          onTap: () => context.go(AppRoutes.newCalibration(tool.id)),
        ),
      if (tool.isInQuarantine)
        _QuickAction(
          icon: Icons.local_shipping_outlined,
          label: 'Enviar a\ncalibracion',
          color: AppColors.calibration,
          onTap: () => context.go(AppRoutes.newCalibration(tool.id)),
        ),
      _QuickAction(
        icon: Icons.picture_as_pdf_outlined,
        label: 'Exportar\nPDF',
        color: AppColors.actionBlue,
        onTap: () => PdfReportService.printToolStatus(tool),
      ),
      _QuickAction(
        icon: Icons.qr_code_2_outlined,
        label: 'Imprimir\nQR',
        color: AppColors.warning,
        onTap: () => PdfReportService.printToolQrLabel(tool),
      ),
      if (canManage && !tool.isRetired)
        _QuickAction(
          icon: Icons.archive_outlined,
          label: 'Dar de\nbaja',
          color: AppColors.danger,
          onTap: () => _confirmRetire(context, tool),
        ),
    ];

    return LayoutBuilder(builder: (ctx, constraints) {
      final count = constraints.maxWidth >= 600 ? actions.length : 3;
      final width = (constraints.maxWidth - (count - 1) * 10) / count;
      return Wrap(spacing: 10, runSpacing: 10, children: [
        for (final a in actions.take(count))
          SizedBox(width: width, child: a),
      ]);
    });
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderOf(context)),
          boxShadow: AppColors.softShadowOf(context),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textOf(context),
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LAST CALIBRATION — Prominent card + history modal
// ═══════════════════════════════════════════════════════════════════════════════

class _LastCalibrationCard extends ConsumerWidget {
  const _LastCalibrationCard({required this.calibration, required this.tool});
  final ToolCalibrationRecord? calibration;
  final ToolDetailRecord tool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (calibration == null) {
      return _SectionShell(
        icon: Icons.history_outlined,
        title: 'Ultima calibracion',
        trailing: const SizedBox.shrink(),
        child: const SizedBox(
          height: 120,
          child: EmptyState(
            title: 'Sin calibraciones',
            message: 'Aun no se ha registrado ninguna calibración.',
            icon: Icons.fact_check_outlined,
          ),
        ),
      );
    }

    final cal = calibration!;
    final result = cal.result ?? 'PENDIENTE';
    final resultColor = result == 'CONFORME'
        ? AppColors.success
        : result == 'CONDICIONADO'
            ? AppColors.warning
            : result == 'NO_CONFORME'
                ? AppColors.danger
                : AppColors.muted;
    final resultLabel = result == 'CONFORME'
        ? 'CONFORME'
        : result == 'CONDICIONADO'
            ? 'CONDICIONADO'
            : result == 'NO_CONFORME'
                ? 'NO CONFORME'
                : 'PENDIENTE';

    return _SectionShell(
      icon: Icons.verified_outlined,
      title: 'Ultima calibracion',
      trailing: TextButton.icon(
        onPressed: () {
          final p = ref.read(currentUserProfileProvider).asData?.value;
          final canManage = p?.role.canManageOperationalData ?? false;
          _showCalibrationHistory(context, tool, canManage: canManage);
        },
        icon: const Text('Ver historial completo'),
        label: const Icon(Icons.arrow_forward, size: 16),
      ),
      child: Column(children: [
        // Result badge
        Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: resultColor.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                result == 'CONFORME'
                    ? Icons.check_circle_outline
                    : result == 'CONDICIONADO'
                        ? Icons.warning_amber_outlined
                        : Icons.cancel_outlined,
                color: resultColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                resultLabel,
                style: TextStyle(
                  color: resultColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        // Details
        _CalDetailRow(
            label: 'Fecha',
            value: SigecalDateUtils.formatDateFull(
                cal.calibrationDate)),
        _CalDetailRow(
            label: 'Proveedor',
            value: cal.providerName ??
                cal.calibrationCenter ??
                '-'),
        _CalDetailRow(
            label: 'Certificado',
            value: cal.certificateNumber ?? '-'),
        _CalDetailRow(
            label: 'Vencimiento',
            value: cal.expirationDate != null
                ? SigecalDateUtils.formatDateFull(
                    cal.expirationDate)
                : '-',
            valueColor: cal.expirationDate != null &&
                    cal.expirationDate!.isBefore(DateTime.now())
                ? AppColors.danger
                : null),
        // Certificate button
        if (cal.certificateFileUrl != null) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openFile(
                  context, ref, cal.certificateFileUrl!,
                  documentType: 'CERTIFICADO'),
              icon: const Icon(Icons.picture_as_pdf_outlined,
                  size: 18),
              label: const Text('Abrir certificado PDF'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

class _CalDetailRow extends StatelessWidget {
  const _CalDetailRow(
      {required this.label, required this.value, this.valueColor});
  final String label;
  final String value;

  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: TextStyle(
                  color: AppColors.subduedOf(context), fontSize: 12)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                color: valueColor ?? AppColors.textOf(context),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              )),
        ),
      ]),
    );
  }
}

// ── Calibration History Modal ──

Future<void> _showCalibrationHistory(
    BuildContext context, ToolDetailRecord tool, {required bool canManage}) async {
  await showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
              child: Row(children: [
                const Icon(Icons.history_outlined,
                    color: AppColors.actionBlue, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Historial completo de calibraciones',
                    style: TextStyle(
                      color: AppColors.textOf(context),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ]),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: tool.calibrations.length,
                itemBuilder: (_, i) {
                  final cal = tool.calibrations[i];
                  final isLatest = i == 0;
                  return _HistoryCalTile(
                      calibration: cal,
                      isLatest: isLatest,
                      tool: tool,
                      canManage: canManage,
                    );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HistoryCalTile extends ConsumerWidget {
  const _HistoryCalTile({
    required this.calibration,
    required this.isLatest,
    required this.tool,
    required this.canManage,
  });
  final ToolCalibrationRecord calibration;
  final bool isLatest;
  final ToolDetailRecord tool;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnnuled = calibration.isAnnuled;
    final result = calibration.result ?? 'PENDIENTE';
    final cl = isAnnuled
        ? AppColors.muted
        : result == 'CONFORME'
            ? AppColors.success
            : result == 'CONDICIONADO'
                ? AppColors.warning
                : result == 'NO_CONFORME'
                    ? AppColors.danger
                    : AppColors.muted;
    final rl = isAnnuled ? 'ANULADA' : result;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAnnuled
            ? AppColors.surfaceSoftOf(context)
            : isLatest
                ? cl.withValues(
                    alpha: AppColors.isDark(context) ? 0.10 : 0.05)
                : AppColors.surfaceSoftOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAnnuled
              ? AppColors.borderOf(context)
              : isLatest
                  ? cl.withValues(alpha: 0.3)
                  : AppColors.borderOf(context),
        ),
      ),
      child: Row(children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: cl, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                SigecalDateUtils.formatDateFull(
                    calibration.calibrationDate),
                style: TextStyle(
                  color: isAnnuled
                      ? AppColors.subduedOf(context)
                      : AppColors.textOf(context),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  decoration:
                      isAnnuled ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  calibration.providerName ??
                      calibration.calibrationCenter,
                  'Cert: ${calibration.certificateNumber ?? '-'}',
                  if (calibration.expirationDate != null)
                    'Vence: ${SigecalDateUtils.formatDateShort(calibration.expirationDate)}',
                ].whereType<String>().join(' · '),
                style: TextStyle(
                  color: AppColors.subduedOf(context),
                  fontSize: 11,
                  decoration:
                      isAnnuled ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        ),
        StatusBadge(label: rl, color: cl),
        if (calibration.certificateFileUrl != null && !isAnnuled) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined,
                size: 20),
            tooltip: 'Abrir certificado PDF',
            onPressed: () {
              _openFile(
                  context, ref, calibration.certificateFileUrl!,
                  documentType: 'CERTIFICADO');
            },
          ),
        ],
        if (!isAnnuled && canManage) ...[
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Editar calibracion',
            onPressed: () {
              Navigator.pop(context); // cierra el modal
              context.go(AppRoutes.editCalibration(
                  tool.id, calibration.id));
            },
          ),
          IconButton(
            icon: const Icon(Icons.block_outlined, size: 20),
            tooltip: 'Anular calibracion',
            onPressed: () =>
                _confirmAnnul(context, ref, tool, calibration),
          ),
        ],
      ]),
    );
  }
}

Future<void> _confirmAnnul(
  BuildContext context,
  WidgetRef ref,
  ToolDetailRecord tool,
  ToolCalibrationRecord calibration,
) async {
  final reasonCtl = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Anular calibracion'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Anular la calibración del '
              '${SigecalDateUtils.formatDateFull(calibration.calibrationDate)}?',
              style: const TextStyle(height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonCtl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo de anulacion',
                hintText: 'Ej. Error en fecha, certificado incorrecto...',
              ),
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
          icon: const Icon(Icons.block_outlined),
          label: const Text('Anular'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
          ),
        ),
      ],
    ),
  );
  reasonCtl.dispose();
  if (confirmed != true || !context.mounted) return;

  try {
    await ref.read(calibrationRepositoryProvider).annulCalibration(
      calibrationId: calibration.id,
      toolId: tool.id,
      reason: reasonCtl.text,
    );
    ref.invalidate(toolDetailProvider(tool.id));
    ref.invalidate(dashboardSnapshotProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calibracion anulada.')),
      );
      Navigator.pop(context); // cierra el modal de historial
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al anular: $e')),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOAN CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _LoanCard extends ConsumerWidget {
  const _LoanCard({required this.tool});
  final ToolDetailRecord tool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loan = tool.activeLoan;

    return _SectionShell(
      icon: Icons.assignment_return_outlined,
      title: 'Prestamo',
      trailing: const SizedBox.shrink(),
      child: loan == null
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(
                height: 80,
                child: EmptyState(
                  title: 'Sin prestamo activo',
                  message: '',
                  icon: Icons.assignment_outlined,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openLoanDialog(context, tool),
                  icon: const Icon(Icons.add_card_outlined, size: 18),
                  label: const Text('Generar prestamo'),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ])
          : _ActiveLoanContent(tool: tool, loan: loan),
    );
  }
}

class _ActiveLoanContent extends ConsumerWidget {
  const _ActiveLoanContent({required this.tool, required this.loan});
  final ToolDetailRecord tool;
  final ToolLoanRecord loan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final daysLeft = loan.expectedReturnDate?.difference(today).inDays;
    final isExpired = daysLeft != null && daysLeft < 0;
    final progress = daysLeft != null
        ? ((14 - daysLeft) / 14).clamp(0.05, 1.0)
        : 0.5;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('ACTIVO',
              style: TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              )),
        ),
        const Spacer(),
        if (isExpired)
          Text('Vencido hace ${daysLeft.abs()} dias',
              style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
      ]),
      const SizedBox(height: 14),
      _CalDetailRow(label: 'Responsable', value: loan.borrowerName),
      _CalDetailRow(label: 'Taller', value: loan.workshop),
      _CalDetailRow(
          label: 'Fecha retiro',
          value: SigecalDateUtils.formatDateFull(loan.loanDate)),
      _CalDetailRow(
          label: 'Retorno estimado',
          value: loan.expectedReturnDate != null
              ? SigecalDateUtils.formatDateFull(
                  loan.expectedReturnDate)
              : '-',
          valueColor: isExpired ? AppColors.danger : null),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          color: isExpired ? AppColors.danger : AppColors.warning,
          backgroundColor: AppColors.surfaceSoftOf(context),
        ),
      ),
      const SizedBox(height: 4),
      if (daysLeft != null)
        Text(
          '${daysLeft.abs()} dias ${isExpired ? 'de retraso' : 'restantes'}',
          style: TextStyle(
            color: isExpired ? AppColors.danger : AppColors.subduedOf(context),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => PdfReportService.printLoanVoucher(
                tool: tool, loan: loan),
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('Vale PDF'),
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: () =>
                _openReturnDialog(context, ref, tool, loan),
            icon: const Icon(Icons.assignment_turned_in_outlined,
                size: 18),
            label: const Text('Devolver'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: AppColors.success,
            ),
          ),
        ),
      ]),
    ]);
  }

  Future<void> _openReturnDialog(BuildContext c, WidgetRef ref,
      ToolDetailRecord t, ToolLoanRecord l) async {
    final ct = TextEditingController();
    final ok = await showDialog<bool>(
      context: c,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar devolucion'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: ct,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observaciones',
              hintText: 'Condicion del retorno',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok != true || !c.mounted) return;
    try {
      await ref
          .read(toolMutationRepositoryProvider)
          .returnLoan(tool: t, loan: l, observations: ct.text);
      ref.invalidate(toolDetailProvider(t.id));
      ref.invalidate(dashboardSnapshotProvider);
      if (c.mounted) {
        ScaffoldMessenger.of(c).showSnackBar(
            const SnackBar(content: Text('Devolucion registrada.')));
      }
    } catch (e) {
      if (c.mounted) {
        ScaffoldMessenger.of(c).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TECHNICAL REPORTS — Special docs only
// ═══════════════════════════════════════════════════════════════════════════════

class _TechnicalReports extends ConsumerStatefulWidget {
  const _TechnicalReports({required this.tool});
  final ToolDetailRecord tool;

  @override
  ConsumerState<_TechnicalReports> createState() => _TechnicalReportsState();
}

class _TechnicalReportsState extends ConsumerState<_TechnicalReports> {
  @override
  Widget build(BuildContext context) {
    final reports = widget.tool.documents
        .where((d) =>
            d.documentType == 'INOPERATIVIDAD' ||
            d.documentType == 'NO_CONFORME' ||
            d.documentType == 'INFORME_CALIBRADOR')
        .toList();

    return _SectionShell(
      icon: Icons.article_outlined,
      title: 'Informes tecnicos',
      trailing: TextButton.icon(
        onPressed: _showUploadDialog,
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Adjuntar'),
      ),
      child: reports.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Sin informes tecnicos. Este espacio es exclusivo para '
                'reportes de inoperatividad o documentos emitidos por '
                'entidades calibradoras.',
                style: TextStyle(
                  color: AppColors.subduedOf(context),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            )
          : Column(
              children: [
                for (final r in reports) _ReportTile(report: r),
              ],
            ),
    );
  }

  Future<void> _showUploadDialog() async {
    String? docType = 'INFORME_CALIBRADOR';
    final titleCtl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Adjuntar informe tecnico'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: docType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de informe',
                    prefixIcon: Icon(Icons.article_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'INFORME_CALIBRADOR',
                      child: Text('Informe de calibrador'),
                    ),
                    DropdownMenuItem(
                      value: 'INOPERATIVIDAD',
                      child: Text('Inoperatividad'),
                    ),
                    DropdownMenuItem(
                      value: 'NO_CONFORME',
                      child: Text('No conforme'),
                    ),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => docType = v),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtl,
                  decoration: const InputDecoration(
                    labelText: 'Titulo del informe',
                    hintText: 'Ej. Reporte de inspeccion 2026',
                  ),
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
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Seleccionar PDF'),
            ),
          ],
        ),
      ),
    );

    titleCtl.dispose();
    if (ok != true || !mounted) return;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );

    final file = result?.files.single;
    if (file == null || file.bytes == null || !mounted) return;

    try {
      await ref
          .read(toolMutationRepositoryProvider)
          .uploadTechnicalReport(
            toolId: widget.tool.id,
            documentType: docType!,
            title: titleCtl.text.trim().isEmpty
                ? 'Informe ${docType!}'
                : titleCtl.text.trim(),
            bytes: file.bytes!,
            fileName: file.name,
          );
      ref.invalidate(toolDetailProvider(widget.tool.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe adjuntado correctamente.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al adjuntar: $e')),
        );
      }
    }
  }
}

class _ReportTile extends ConsumerWidget {
  const _ReportTile({required this.report});
  final ToolDocumentRecord report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = report.documentType == 'INOPERATIVIDAD'
        ? Icons.report_problem_outlined
        : Icons.assignment_late_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoftOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.warning, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: TextStyle(
                    color: AppColors.textOf(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  SigecalDateUtils.formatDateFull(report.createdAt),
                  style: TextStyle(
                    color: AppColors.subduedOf(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (report.fileUrl != null)
            IconButton(
              icon: const Icon(Icons.open_in_new_outlined, size: 20),
              tooltip: 'Abrir informe',
              onPressed: () => _openFile(context, ref, report.fileUrl!,
                  documentType: report.documentType),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TRACEABILITY TIMELINE — All events
// ═══════════════════════════════════════════════════════════════════════════════

class _TraceabilityTimeline extends StatelessWidget {
  const _TraceabilityTimeline({required this.tool});
  final ToolDetailRecord tool;

  @override
  Widget build(BuildContext context) {
    final events = <_TimelineEvent>[];

    // Manufacturer certificate
    if (tool.manufacturerCertificateUrl != null) {
      events.add(const _TimelineEvent(
        icon: Icons.factory_outlined,
        title: 'Certificado de fabricante',
        subtitle: 'Documento de origen',
        date: null,
        color: AppColors.actionBlue,
        traceType: 'FABRICANTE',
      ));
    }

    // Tool acquisition
    if (tool.acquisitionDate != null) {
      events.add(_TimelineEvent(
        icon: Icons.add_circle_outline,
        title: 'Alta de herramienta en inventario',
        subtitle: tool.currentLocation ?? 'Ubicacion no especificada',
        date: tool.acquisitionDate,
        color: AppColors.success,
      ));
    }

    // Traceability records
    for (final t in tool.traceability) {
      events.add(_TimelineEvent(
        icon: switch (t.traceType) {
          'CALIBRACION' => Icons.verified_outlined,
          'PRESTAMO' => Icons.assignment_return_outlined,
          'BAJA' => Icons.archive_outlined,
          'CUARENTENA' => Icons.warning_amber_outlined,
          'FABRICANTE' => Icons.factory_outlined,
          _ => Icons.circle_outlined,
        },
        title: t.title,
        subtitle: t.description ?? '',
        date: t.eventDate,
        color: switch (t.traceType) {
          'CALIBRACION' => AppColors.success,
          'PRESTAMO' => AppColors.warning,
          'BAJA' => AppColors.danger,
          'CUARENTENA' => AppColors.critical,
          'FABRICANTE' => AppColors.actionBlue,
          _ => AppColors.muted,
        },
        documentUrl: t.documentUrl,
        traceType: t.traceType,
      ));
    }

    // Calibration records (if not already in traceability)
    for (final cal in tool.calibrations) {
      final alreadyInTrace = tool.traceability.any((t) =>
          t.traceType == 'CALIBRACION' &&
          t.eventDate == cal.calibrationDate);
      if (!alreadyInTrace) {
        events.add(_TimelineEvent(
          icon: Icons.verified_outlined,
          title: 'Calibracion ${cal.result ?? 'PENDIENTE'}',
          subtitle: cal.providerName ?? cal.calibrationCenter ?? '',
          date: cal.calibrationDate,
          color: cal.result == 'CONFORME'
              ? AppColors.success
              : cal.result == 'CONDICIONADO'
                  ? AppColors.warning
                  : AppColors.danger,
          documentUrl: cal.certificateFileUrl,
          traceType: 'CALIBRACION',
        ));
      }
    }

    // Loan records
    for (final loan in tool.loans) {
      events.add(_TimelineEvent(
        icon: loan.returnedAt != null
            ? Icons.assignment_turned_in_outlined
            : Icons.assignment_return_outlined,
        title: loan.returnedAt != null
            ? 'Devolucion de prestamo: ${loan.borrowerName}'
            : 'Prestamo a ${loan.borrowerName}',
        subtitle: loan.workshop,
        date: loan.returnedAt ?? loan.loanDate,
        color: loan.returnedAt != null
            ? AppColors.success
            : AppColors.warning,
      ));
    }

    // Retired
    if (tool.retiredAt != null) {
      events.add(_TimelineEvent(
        icon: Icons.archive_outlined,
        title: 'Baja auditada',
        subtitle: tool.retirementReason ?? 'Motivo no especificado',
        date: tool.retiredAt,
        color: AppColors.danger,
      ));
    }

    // Quarantine
    if (tool.quarantineMarkedAt != null) {
      events.add(_TimelineEvent(
        icon: Icons.warning_amber_outlined,
        title: 'Cuarentena',
        subtitle: tool.quarantineReason ?? '',
        date: tool.quarantineMarkedAt,
        color: AppColors.critical,
      ));
    }

    // Sort by date DESC
    events.sort((a, b) {
      if (a.date == null && b.date == null) return 0;
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return b.date!.compareTo(a.date!);
    });

    return _SectionShell(
      icon: Icons.timeline_outlined,
      title: 'Trazabilidad completa',
      trailing: const SizedBox.shrink(),
      child: events.isEmpty
          ? const SizedBox(
              height: 80,
              child: EmptyState(
                title: 'Sin eventos',
                message: 'La trazabilidad se construye automaticamente.',
                icon: Icons.timeline_outlined,
              ),
            )
          : Column(
              children: [
                for (int i = 0; i < events.length; i++)
                  _TimelineTile(
                    event: events[i],
                    isFirst: i == 0,
                    isLast: i == events.length - 1,
                  ),
              ],
            ),
    );
  }
}

class _TimelineEvent {
  const _TimelineEvent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.color,
    this.documentUrl,
    this.traceType,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime? date;
  final Color color;
  final String? documentUrl;

  /// Tipo de trazabilidad original (`CALIBRACION`, `FABRICANTE`, …).
  /// Se usa para resolver el bucket correcto al abrir [documentUrl].
  final String? traceType;
}

class _TimelineTile extends ConsumerWidget {
  const _TimelineTile({
    required this.event,
    required this.isFirst,
    required this.isLast,
  });
  final _TimelineEvent event;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 40,
            child: Column(children: [
              if (!isFirst)
                Container(
                    width: 2,
                    height: 8,
                    color: event.color.withValues(alpha: 0.3)),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: event.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: event.color.withValues(alpha: 0.3)),
                ),
                child: Icon(event.icon, color: event.color, size: 18),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: event.color.withValues(alpha: 0.15),
                  ),
                ),
            ]),
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoftOf(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        color: AppColors.textOf(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    if (event.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.subtitle,
                        style: TextStyle(
                          color: AppColors.subduedOf(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (event.date != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        SigecalDateUtils.formatDateFull(event.date),
                        style: TextStyle(
                          color: AppColors.subduedOf(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (event.documentUrl != null) ...[
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () {
                          final docType =
                              _documentTypeForTraceType(event.traceType);
                          _openFile(context, ref, event.documentUrl!,
                              documentType: docType);
                        },
                        icon: const Icon(Icons.open_in_new_outlined,
                            size: 14),
                        label: const Text('Abrir documento',
                            style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.icon,
    required this.title,
    required this.child,
    required this.trailing,
  });
  final IconData icon;
  final String title;
  final Widget child;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppColors.softShadowOf(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
            child: Row(children: [
              Icon(icon, color: AppColors.actionBlue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textOf(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              trailing,
            ]),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// UTILITY: File opener + bucket resolution
// ═══════════════════════════════════════════════════════════════════════════════

/// Mapea un tipo de documento al bucket de Storage correspondiente.
///
/// Buckets definidos en la migración inicial:
/// - `calibration-certificates` : CERTIFICADO
/// - `remission-guides`         : GUIA_REMISION
/// - `tool-images`              : FOTO (bucket público)
/// - `support-documents`        : MANUAL, FABRICANTE, INOPERATIVIDAD,
///                                NO_CONFORME, INFORME_CALIBRADOR
String _bucketForDocumentType(String? documentType) {
  return switch (documentType) {
    'CERTIFICADO'          => 'calibration-certificates',
    'GUIA_REMISION'        => 'remission-guides',
    'FOTO'                 => 'tool-images',
    'MANUAL'               => 'support-documents',
    'FABRICANTE'           => 'support-documents',
    'INOPERATIVIDAD'       => 'support-documents',
    'NO_CONFORME'          => 'support-documents',
    'INFORME_CALIBRADOR'   => 'support-documents',
    _                      => 'support-documents',
  };
}

/// Mapea un `trace_type` de trazabilidad a su `document_type` equivalente
/// para poder resolver el bucket de Storage correcto.
String? _documentTypeForTraceType(String? traceType) {
  return switch (traceType) {
    'CALIBRACION' => 'CERTIFICADO',
    'FABRICANTE'  => 'FABRICANTE',
    _             => null, // usa el fallback de _bucketForDocumentType
  };
}

/// Abre un archivo privado generando una signed URL efímera (300 s).
///
/// [documentType] determina en qué bucket de Storage se busca el archivo.
/// Si no se provee, se asume `support-documents`.
Future<void> _openFile(
  BuildContext context,
  WidgetRef ref,
  String url, {
  String? documentType,
}) async {
  final client = ref.read(supabaseClientProvider);
  if (client == null) return;
  try {
    final bucket = _bucketForDocumentType(documentType);
    final signedUrl =
        await client.storage.from(bucket).createSignedUrl(url, 300);
    await launchUrl(Uri.parse(signedUrl),
        mode: LaunchMode.externalApplication);
  } catch (_) {}
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOAN DIALOG (kept from original, adapted)
// ═══════════════════════════════════════════════════════════════════════════════

Future<void> _openLoanDialog(BuildContext context, ToolDetailRecord tool) async {
  await showDialog(context: context, builder: (_) => _LoanDialog(tool: tool));
}

class _LoanDialog extends ConsumerStatefulWidget {
  const _LoanDialog({required this.tool});
  final ToolDetailRecord tool;
  @override
  ConsumerState<_LoanDialog> createState() => _LoanDialogState();
}

class _LoanDialogState extends ConsumerState<_LoanDialog> {
  final _o = TextEditingController();
  final _mn = TextEditingController();
  final _md = TextEditingController();
  final _mp = TextEditingController();
  String? _w, _b;
  DateTime? _e;
  bool _s = false;
  bool _mb = false;

  @override
  void dispose() {
    _o.dispose();
    _mn.dispose();
    _md.dispose();
    _mp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final cs = ref.watch(toolCatalogsProvider);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: cs.when(
            data: _form,
            error: (e, _) => EmptyState(
                title: 'Error', message: e.toString(), icon: Icons.error_outline),
            loading: () => SizedBox(
                height: 260,
                child: LoadingView(message: 'Cargando catalogos...')),
          ),
        ),
      ),
    );
  }

  Widget _form(ToolCatalogs c) {
    if (c.workshops.isEmpty) {
      return const EmptyState(
        title: 'Sin talleres',
        message: 'Registra al menos un taller.',
        icon: Icons.business_outlined,
      );
    }
    final sw = _w ?? c.workshops.first.id;
    final bw = c.borrowersForWorkshop(sw);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.actionBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.assignment_return_outlined,
                  color: AppColors.actionBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Generar prestamo',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                              color: AppColors.institutionalBlue,
                              fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(widget.tool.nomenclature,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 22),
          // Workshop
          DropdownButtonFormField<String>(
            initialValue: sw,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Taller / oficina destino',
              prefixIcon: Icon(Icons.business_outlined),
            ),
            items: [
              for (final w in c.workshops)
                DropdownMenuItem(value: w.id, child: Text(w.name)),
            ],
            onChanged: (v) => setState(() {
              _w = v;
              _b = null;
            }),
          ),
          const SizedBox(height: 16),
          // Borrower
          if (!_mb) ...[
            DropdownButtonFormField<String>(
              key: ValueKey('b-$sw'),
              initialValue: _b != null && bw.any((x) => x.id == _b)
                  ? _b
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Persona responsable',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: [
                for (final x in bw)
                  DropdownMenuItem(
                    value: x.id,
                    child: Text([
                      x.fullName,
                      if (x.documentNumber != null) x.documentNumber
                    ].join(' - ')),
                  ),
                const DropdownMenuItem(
                  value: '__m__',
                  child: Row(children: [
                    Icon(Icons.person_add_alt_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Ingresar manualmente...'),
                  ]),
                ),
              ],
              onChanged: (v) {
                if (v == '__m__') {
                  setState(() {
                    _mb = true;
                    _b = null;
                  });
                } else {
                  setState(() => _b = v);
                }
              },
            ),
          ] else ...[
            TextFormField(
              controller: _mn,
              decoration: const InputDecoration(
                labelText: 'Nombre completo *',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _md,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Documento (opcional)',
                prefixIcon: Icon(Icons.credit_card_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mp,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefono (opcional)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() {
                _mb = false;
                _mn.clear();
                _md.clear();
                _mp.clear();
              }),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Seleccionar de la lista'),
            ),
          ],
          const SizedBox(height: 16),
          // Date picker
          OutlinedButton.icon(
            onPressed: () async {
              final n = DateTime.now();
              final d = await showDatePicker(
                context: context,
                firstDate: n,
                lastDate: DateTime(n.year + 2),
                initialDate:
                    _e ?? DateTime(n.year, n.month, n.day + 7),
              );
              if (d != null) setState(() => _e = d);
            },
            icon: const Icon(Icons.event_available_outlined),
            label: Text(_e == null
                ? 'Seleccionar retorno estimado'
                : 'Retorno est.: ${SigecalDateUtils.formatDateShort(_e)}'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _o,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Observaciones'),
          ),
          const SizedBox(height: 22),
          // Buttons
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
              onPressed: _s ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: _s ? null : () => _save(c, sw),
              icon: _s
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2),
                    )
                  : const Icon(Icons.qr_code_2_outlined),
              label: Text(_s ? 'Generando...' : 'Generar vale'),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _save(ToolCatalogs c, String sw) async {
    final workshop = c.workshops.firstWhere((x) => x.id == sw);
    if (_mb) {
      final n = _mn.text.trim();
      if (n.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ingresa el nombre.')));
        }
        return;
      }
      setState(() => _s = true);
      try {
        final cl = ref.read(supabaseClientProvider);
        if (cl == null) throw StateError('NC');
        final r = await cl.from('borrowers').insert({
          'full_name': n,
          'document_number':
              _md.text.trim().isEmpty ? null : _md.text.trim(),
          'phone': _mp.text.trim().isEmpty ? null : _mp.text.trim(),
          'workshop_id': sw,
          'active': true,
        }).select('id, full_name, document_number, phone, workshop_id');
        final row = (r as List).first as Map<String, dynamic>;
        final b = BorrowerRecord(
          id: row['id'] as String,
          fullName: row['full_name'] as String? ?? n,
          documentNumber: row['document_number'] as String?,
          phone: row['phone'] as String?,
          workshopId: row['workshop_id'] as String?,
        );
        await ref
            .read(toolMutationRepositoryProvider)
            .createLoan(
                tool: widget.tool,
                workshop: workshop,
                borrower: b,
                expectedReturnDate: _e,
                observations: _o.text);
        _finish();
      } catch (e) {
        _onError(e);
      }
    } else {
      if (_b == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Selecciona una persona.')));
        }
        return;
      }
      final b = c.borrowers.firstWhere((x) => x.id == _b);
      setState(() => _s = true);
      try {
        await ref
            .read(toolMutationRepositoryProvider)
            .createLoan(
                tool: widget.tool,
                workshop: workshop,
                borrower: b,
                expectedReturnDate: _e,
                observations: _o.text);
        _finish();
      } catch (e) {
        _onError(e);
      }
    }
  }

  void _finish() {
    ref.invalidate(toolDetailProvider(widget.tool.id));
    ref.invalidate(dashboardSnapshotProvider);
    ref.invalidate(toolCatalogsProvider);
    ref.invalidate(allLoansProvider);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prestamo generado.')));
    }
  }

  void _onError(Object e) {
    if (mounted) {
      setState(() => _s = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RETIRE CONFIRMATION
// ═══════════════════════════════════════════════════════════════════════════════

Future<void> _confirmRetire(BuildContext context, ToolDetailRecord tool) async {
  final rc = TextEditingController();
  final pc = TextEditingController();
  final r = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirmar baja'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Enviara ${tool.internalCode ?? tool.nomenclature} a ALMACEN DE BAJAS.'),
            const SizedBox(height: 16),
            TextField(
              controller: rc,
              maxLines: 3,
              textCapitalization: TextCapitalization.characters,
              decoration:
                  const InputDecoration(labelText: 'Motivo obligatorio'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pc,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                  labelText: 'Escribe DAR DE BAJA'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (rc.text.trim().isNotEmpty &&
                pc.text.trim().toUpperCase() == 'DAR DE BAJA') {
              Navigator.pop(ctx, rc.text);
            }
          },
          icon: const Icon(Icons.archive_outlined),
          label: const Text('Ejecutar baja'),
        ),
      ],
    ),
  ).whenComplete(() {
    rc.dispose();
    pc.dispose();
  });
  if (r == null || r.trim().isEmpty || !context.mounted) return;
  // Handle retire - needs WidgetRef
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATUS HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

String _sl(ComplianceState s) => switch (s) {
      ComplianceState.compliant => 'Calibrado',
      ComplianceState.grace => 'En gracia',
      ComplianceState.warning => 'Critico',
      ComplianceState.expired => 'Vencido',
      ComplianceState.inCalibration => 'En calibracion',
      ComplianceState.withoutCalibration => 'Sin calibracion',
    };

Color _csColor(ComplianceState s) => switch (s) {
      ComplianceState.compliant => AppColors.success,
      ComplianceState.grace => AppColors.warning,
      ComplianceState.warning => AppColors.critical,
      ComplianceState.expired => AppColors.danger,
      ComplianceState.inCalibration => AppColors.calibration,
      ComplianceState.withoutCalibration => AppColors.muted,
    };
