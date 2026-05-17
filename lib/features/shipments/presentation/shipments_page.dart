import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../data/shipment_providers.dart';
import '../../../core/i18n/translations.dart';

class ShipmentsPage extends ConsumerWidget {
  const ShipmentsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(shipmentsProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(
        title: 'Envios a centro de calibracion',
        description: 'KPIs, tablero operativo y cierre de retornos.',
        actions: [
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.newShipment),
            icon: const Icon(Icons.add_road_outlined),
            label: const Text('Nuevo envio'),
          ),
        ],
      ),
      s.when(
        data: (d) => _Content(shipments: d),
        error: (e, _) => EmptyState(
          title: 'Error', message: e.toString(), icon: Icons.error_outline),
        loading: () => SizedBox(
          height: 420, child: LoadingView(message: context.t('common.loading'))),
      ),
    ]);
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.shipments});
  final List<ShipmentRecord> shipments;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = shipments.where((x) => x.isOpen).toList();
    final ret = shipments.where((x) => !x.isOpen).toList();
    final ov = open.where((x) {
      final d = x.daysToReturn;
      return d != null && d < 0;
    }).length;
    if (shipments.isEmpty) {
      return const Card(
        child: SizedBox(
          height: 360,
          child: EmptyState(
            title: 'Sin envios',
            message: 'Registra un envio.',
            icon: Icons.local_shipping_outlined,
          ),
        ),
      );
    }
    return Column(children: [
      LayoutBuilder(builder: (ctx, c) {
        final w = c.maxWidth >= 920
            ? (c.maxWidth - 36) / 4
            : c.maxWidth >= 560
                ? (c.maxWidth - 12) / 2
                : double.infinity;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          _K(w: w, l: 'Abiertos', v: open.length),
          _K(w: w, l: 'Retornados', v: ret.length, cl: AppColors.success),
          _K(w: w, l: context.t('dashboard.vencidos'), v: ov, cl: AppColors.danger),
          _K(
            w: w,
            l: 'Total',
            v: shipments.length,
            cl: AppColors.actionBlue,
          ),
        ]);
      }),
      const SizedBox(height: 16),
      _Kanban(shipments: open),
      const SizedBox(height: 16),
      _Tbl(shipments: shipments, onStatus: (s, st) async {
        await ref
            .read(shipmentRepositoryProvider)
            .updateShipmentStatus(shipment: s, status: st);
        ref.invalidate(shipmentsProvider);
        ref.invalidate(dashboardSnapshotProvider);
        ref.invalidate(quarantineToolsProvider);
      }),
    ]);
  }
}

class _K extends StatelessWidget {
  const _K({
    required this.w,
    required this.l,
    required this.v,
    this.cl = AppColors.calibration,
  });
  final double w;
  final String l;
  final int v;
  final Color cl;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context)
        .textTheme
        .headlineSmall
        ?.copyWith(
          color: AppColors.textOf(context),
          fontWeight: FontWeight.w900,
        );
    final labelStyle = TextStyle(
      color: AppColors.subduedOf(context),
      fontWeight: FontWeight.w800,
    );
    return SizedBox(
      width: w,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.borderOf(context)),
          boxShadow: AppColors.softShadowOf(context),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.tintOf(context, cl),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.local_shipping_outlined, color: cl),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$v', style: textStyle),
                Text(l, style: labelStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Kanban extends StatelessWidget {
  const _Kanban({required this.shipments});
  final List<ShipmentRecord> shipments;

  @override
  Widget build(BuildContext context) {
    const st = [
      'ENVIADO',
      'RECIBIDO_POR_PROVEEDOR',
      'EN_PROCESO',
      'LISTO_PARA_RECOJO',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppColors.softShadowOf(context),
      ),
      child: LayoutBuilder(builder: (ctx, c) {
        final w = c.maxWidth >= 900
            ? (c.maxWidth - 36) / 4
            : c.maxWidth >= 520
                ? (c.maxWidth - 12) / 2
                : double.infinity;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final s in st)
              SizedBox(
                width: w,
                child: _Col(
                  title: _sl(s),
                  shipments:
                      shipments.where((x) => x.status == s).toList(),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _Col extends StatelessWidget {
  const _Col({required this.title, required this.shipments});
  final String title;
  final List<ShipmentRecord> shipments;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 170),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoftOf(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title (${shipments.length})',
            style: TextStyle(
              color: AppColors.textOf(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          for (final s in shipments.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _Mc(s: s),
            ),
          if (shipments.length > 3)
            Text(
              '+${shipments.length - 3} mas',
              style: TextStyle(color: AppColors.subduedOf(context)),
            ),
        ],
      ),
    );
  }
}

class _Mc extends StatelessWidget {
  const _Mc({required this.s});
  final ShipmentRecord s;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.toolCode ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(
            s.toolName ?? s.calibrationCenter,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.subduedOf(context)),
          ),
        ],
      ),
    );
  }
}

class _Tbl extends StatelessWidget {
  const _Tbl({required this.shipments, required this.onStatus});
  final List<ShipmentRecord> shipments;
  final Future<void> Function(ShipmentRecord, String) onStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppColors.softShadowOf(context),
      ),
      child: SizedBox(
        height: 460,
        child: DataTable2(
          minWidth: 920,
          columnSpacing: 14,
          headingRowHeight: 46,
          dataRowHeight: 66,
          columns: [
            DataColumn2(label: Text(context.t('inventory.tool')), size: ColumnSize.L),
            DataColumn2(label: Text('Proveedor'), size: ColumnSize.M),
            DataColumn2(label: Text('Envio'), size: ColumnSize.S),
            DataColumn2(label: Text('Retorno est.'), size: ColumnSize.S),
            DataColumn2(label: Text(context.t('inventory.status')), size: ColumnSize.M),
            DataColumn2(label: Text('Accion'), size: ColumnSize.M),
          ],
          rows: [
            for (final s in shipments)
              DataRow(cells: [
                DataCell(Text(
                  '${s.toolCode ?? '-'} / ${s.toolName ?? '-'}',
                  overflow: TextOverflow.ellipsis,
                )),
                DataCell(Text(s.providerName ?? s.calibrationCenter)),
                DataCell(Text(SigecalDateUtils.formatDateShort(
                    s.shipmentDate))),
                DataCell(Text(SigecalDateUtils.formatDateShort(
                    s.estimatedReturnDate))),
                DataCell(_SB(s: s)),
                DataCell(_SA(s: s, onStatus: onStatus)),
              ]),
          ],
        ),
      ),
    );
  }
}

class _SA extends StatelessWidget {
  const _SA({required this.s, required this.onStatus});
  final ShipmentRecord s;
  final Future<void> Function(ShipmentRecord, String) onStatus;

  @override
  Widget build(BuildContext context) {
    if (!s.isOpen) return const Text('Cerrado');
    return PopupMenuButton<String>(
      tooltip: 'Actualizar',
      onSelected: (st) => onStatus(s, st),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'RECIBIDO_POR_PROVEEDOR',
          child: Text('Recibido por proveedor'),
        ),
        PopupMenuItem(
            value: 'EN_PROCESO', child: Text('En proceso')),
        PopupMenuItem(
          value: 'LISTO_PARA_RECOJO',
          child: Text('Listo para recojo'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
            value: 'RETORNADO', child: Text('Marcar retornado')),
      ],
      child: const Chip(
        avatar: Icon(Icons.sync_outlined, size: 16),
        label: Text('Actualizar'),
      ),
    );
  }
}

class _SB extends StatelessWidget {
  const _SB({required this.s});
  final ShipmentRecord s;

  @override
  Widget build(BuildContext context) {
    if (!s.isOpen) {
      return const StatusBadge(
          label: 'Retornado', color: AppColors.success);
    }
    return switch (s.urgency) {
      ComplianceState.expired => const StatusBadge(
          label: 'Retorno vencido', color: AppColors.danger),
      ComplianceState.warning => StatusBadge(
          label: '${_sl(s.status)} / urgente',
          color: AppColors.warning),
      _ => StatusBadge(
          label: _sl(s.status), color: AppColors.calibration),
    };
  }
}

String _sl(String s) => switch (s) {
      'PENDIENTE_ENVIO' => 'Pendiente',
      'ENVIADO' => 'Enviado',
      'RECIBIDO_POR_PROVEEDOR' => 'Recibido',
      'EN_PROCESO' => 'En proceso',
      'LISTO_PARA_RECOJO' => 'Listo',
      'RETORNADO' => 'Retornado',
      'OBSERVADO' => 'Observado',
      _ => s,
    };
