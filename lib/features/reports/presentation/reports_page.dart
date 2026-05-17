import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../../shipments/data/shipment_providers.dart';
import '../data/pdf_report_service.dart';
import '../../../core/i18n/translations.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});
  @override ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  DateTime? _selectedMonth;
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(dashboardSnapshotProvider);
    final sh = ref.watch(shipmentsProvider);
    final r = ref.watch(retiredToolsProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: 'Estadisticas', description: 'Analisis de cumplimiento, distribucion y vencimientos programados.', actions: [
        s.maybeWhen(data: (d) => OutlinedButton.icon(onPressed: () => PdfReportService.printGeneralStatus(d), icon: const Icon(Icons.file_download_outlined), label: const Text('Exportar PDF')), orElse: () => const SizedBox.shrink()),
      ]),
      s.when(data: (d) => sh.when(data: (sd) => r.when(data: (rd) => _StatsContent(snapshot: d, shipments: sd, retiredCount: rd.length, selectedMonth: _selectedMonth, onMonthSelected: (m) => setState(() => _selectedMonth = m)), error: (e, _) => _err(e.toString()), loading: () => _load), error: (e, _) => _err(e.toString()), loading: () => _load), error: (e, _) => _err(e.toString()), loading: () => _load),
    ]);
  }
  Widget _err(String m) => EmptyState(title: 'Error', message: m, icon: Icons.error_outline);
  Widget get _load => SizedBox(height: 360, child: LoadingView(message: context.t('common.loading')));
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.snapshot, required this.shipments, required this.retiredCount, required this.selectedMonth, required this.onMonthSelected});
  final DashboardSnapshot snapshot; final List<ShipmentRecord> shipments; final int retiredCount; final DateTime? selectedMonth; final ValueChanged<DateTime> onMonthSelected;
  @override
  Widget build(BuildContext context) {
    final as = shipments.where((s) => s.isOpen).length;
    final wc = snapshot.tools.where((t) => t.latestCalibration?.certificateNumber != null).length;
    return Column(children: [
      _SummaryStrip(total: snapshot.totalTools, compliant: snapshot.compliant + snapshot.grace, expired: snapshot.expired, inCalibration: snapshot.inCalibration, retired: retiredCount, activeShipments: as, withCertificate: wc),
      const SizedBox(height: 14),
      LayoutBuilder(builder: (ctx, c) {
        final two = c.maxWidth >= 1000;
        final left = _ExpirationTimeline(tools: snapshot.tools, selectedMonth: selectedMonth, onMonthSelected: onMonthSelected);
        final right = Column(children: [_CatDist(tools: snapshot.tools), const SizedBox(height: 12), _LocDist(tools: snapshot.tools)]);
        if (!two) return Column(children: [left, const SizedBox(height: 12), right]);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 6, child: left), const SizedBox(width: 12), SizedBox(width: 320, child: right)]);
      }),
    ]);
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.total, required this.compliant, required this.expired, required this.inCalibration, required this.retired, required this.activeShipments, required this.withCertificate});
  final int total, compliant, expired, inCalibration, retired, activeShipments, withCertificate;
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.borderOf(context))),
      child: LayoutBuilder(builder: (ctx, c) {
        final n = c.maxWidth >= 900 ? 7 : c.maxWidth >= 560 ? 4 : 3;
        return GridView(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: n, crossAxisSpacing: 10, mainAxisSpacing: 10, mainAxisExtent: 64),
          children: [
            _M(label: 'Total', v: total, i: Icons.inventory_2_outlined, cl: AppColors.actionBlue),
            _M(label: context.t('dashboard.compliant'), v: compliant, i: Icons.verified_outlined, cl: AppColors.success),
            _M(label: context.t('dashboard.vencidos'), v: expired, i: Icons.event_busy_outlined, cl: AppColors.danger),
            _M(label: 'En cal.', v: inCalibration, i: Icons.sync_alt_outlined, cl: AppColors.calibration),
            _M(label: 'Bajas', v: retired, i: Icons.archive_outlined, cl: AppColors.muted),
            _M(label: 'Envios', v: activeShipments, i: Icons.local_shipping_outlined, cl: AppColors.warning),
            _M(label: 'Certif.', v: withCertificate, i: Icons.workspace_premium_outlined, cl: AppColors.actionBlue),
          ]);
      }),
    );
  }
}

class _M extends StatelessWidget {
  const _M({required this.label, required this.v, required this.i, required this.cl});
  final String label; final int v; final IconData i; final Color cl;
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: AppColors.surfaceSoftOf(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderOf(context))),
      child: Row(children: [Icon(i, size: 20, color: cl), const SizedBox(width: 8), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$v', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textOf(context), fontWeight: FontWeight.w900)),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.subduedOf(context), fontWeight: FontWeight.w700))]))]));
  }
}

class _ExpirationTimeline extends StatefulWidget {
  const _ExpirationTimeline({required this.tools, required this.selectedMonth, required this.onMonthSelected});
  final List<DashboardTool> tools; final DateTime? selectedMonth; final ValueChanged<DateTime> onMonthSelected;
  @override State<_ExpirationTimeline> createState() => _ExpirationTimelineState();
}

class _ExpirationTimelineState extends State<_ExpirationTimeline> {
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now(); final td = DateTime(today.year, today.month, today.day);
    final buckets = <DateTime, _MB>{};
    for (final t in widget.tools) { final ed = t.latestCalibration?.expirationDate; if (ed == null) continue;
      final mk = DateTime(ed.year, ed.month, 1); buckets.putIfAbsent(mk, () => _MB(m: mk)); buckets[mk]!.add(t, ed.difference(td).inDays); }
    final months = buckets.keys.toList()..sort();
    final future = months.where((m) => !DateTime(m.year, m.month + 1, 0).isBefore(td)).take(12).toList();
    final sel = widget.selectedMonth ?? (future.isNotEmpty ? future.first : null);
    return _SP(title: 'Cronograma de vencimientos', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (future.isEmpty) const Padding(padding: EdgeInsets.all(20), child: EmptyState(title: 'Sin vencimientos', message: 'No hay fechas de vencimiento.', icon: Icons.event_busy_outlined))
      else ...[
        SizedBox(height: 104, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: future.length, separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (ctx, i) { final m = future[i]; final b = buckets[m]!; return _MPill(m: m, b: b, sel: sel == m, onTap: () => widget.onMonthSelected(m)); })),
        if (sel != null) ...[const SizedBox(height: 14), _MDetail(m: sel, b: buckets[sel]!)],
      ],
    ]));
  }
}

class _MB { _MB({required this.m}); final DateTime m; final List<_ET> tools = []; int cr = 0, wr = 0, up = 0;
  void add(DashboardTool t, int d) { tools.add(_ET(t: t, d: d)); if (d <= 15) {
    cr++;
  } else if (d <= 30) wr++; else up++; }
  Color get dc => cr > 0 ? AppColors.danger : wr > 0 ? AppColors.warning : AppColors.success;
  String get ml { const n = ['ENE','FEB','MAR','ABR','MAY','JUN','JUL','AGO','SEP','OCT','NOV','DIC']; return n[m.month - 1]; }
  int get total => tools.length;
}
class _ET { const _ET({required this.t, required this.d}); final DashboardTool t; final int d; }

class _MPill extends StatelessWidget {
  const _MPill({required this.m, required this.b, required this.sel, required this.onTap});
  final DateTime m; final _MB b; final bool sel; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 180), width: 80, padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: sel ? AppColors.tintOf(context, b.dc, lightAlpha: 0.12, darkAlpha: 0.22) : AppColors.surfaceSoftOf(context), borderRadius: BorderRadius.circular(18), border: Border.all(color: sel ? b.dc.withValues(alpha: 0.5) : AppColors.borderOf(context), width: sel ? 2 : 1)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(b.ml, style: TextStyle(color: sel ? b.dc : AppColors.textOf(context), fontWeight: FontWeight.w900, fontSize: 13)),
        const SizedBox(height: 2), Text('${b.total}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: sel ? b.dc : AppColors.textOf(context), fontWeight: FontWeight.w900)),
        const SizedBox(height: 4), Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _D(c: AppColors.danger, a: b.cr > 0), const SizedBox(width: 3), _D(c: AppColors.warning, a: b.wr > 0), const SizedBox(width: 3), _D(c: AppColors.success, a: b.up > 0)]),
      ])));
  }
}
class _D extends StatelessWidget { const _D({required this.c, required this.a}); final Color c; final bool a;
  @override Widget build(BuildContext context) => Container(width: 6, height: 6, decoration: BoxDecoration(color: a ? c : AppColors.subduedOf(context).withValues(alpha: 0.2), shape: BoxShape.circle)); }

class _MDetail extends StatelessWidget {
  const _MDetail({required this.m, required this.b}); final DateTime m; final _MB b;
  @override
  Widget build(BuildContext context) {
    final mn = DateFormat('MMMM yyyy', 'es').format(m); final cap = '${mn[0].toUpperCase()}${mn.substring(1)}';
    final s = List<_ET>.from(b.tools)..sort((a, b) => a.d.compareTo(b.d));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text('$cap · ${b.total} herramientas', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textOf(context), fontWeight: FontWeight.w900)), const Spacer(),
        _LC(c: AppColors.danger, l: 'Critico <15d'), const SizedBox(width: 6), _LC(c: AppColors.warning, l: 'Alerta 16-30d')]),
      const SizedBox(height: 10), ...s.map((e) => _ETile(e: e)),
    ]);
  }
}
class _LC extends StatelessWidget { const _LC({required this.c, required this.l}); final Color c; final String l;
  @override Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)), const SizedBox(width: 4), Text(l, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.subduedOf(context), fontWeight: FontWeight.w700))]); }

class _ETile extends StatelessWidget {
  const _ETile({required this.e}); final _ET e;
  @override
  Widget build(BuildContext context) {
    final u = e.d <= 15 ? AppColors.danger : e.d <= 30 ? AppColors.warning : AppColors.success;
    final lb = e.d <= 15 ? 'Critico' : e.d <= 30 ? 'Alerta' : 'Proximo';
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Material(color: AppColors.surfaceSoftOf(context), borderRadius: BorderRadius.circular(14),
      child: InkWell(borderRadius: BorderRadius.circular(14), onTap: () => context.go(AppRoutes.toolDetail(e.t.id)),
        child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderOf(context))),
          child: Row(children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.tintOf(context, u), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.event_outlined, color: u, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [if (e.t.internalCode != null) ...[Text(e.t.internalCode!, style: TextStyle(color: AppColors.subduedOf(context), fontWeight: FontWeight.w800, fontSize: 11)), const SizedBox(width: 6)], Expanded(child: Text(e.t.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textOf(context), fontWeight: FontWeight.w800, fontSize: 13)))]),
              const SizedBox(height: 4),
              Row(children: [StatusBadge(label: lb, color: u), const SizedBox(width: 8), Text('${e.d} dias', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.subduedOf(context), fontWeight: FontWeight.w700)), const Spacer(), Icon(Icons.chevron_right, size: 18, color: AppColors.subduedOf(context))]),
            ])),
          ])))));
  }
}

class _CatDist extends StatelessWidget {
  const _CatDist({required this.tools}); final List<DashboardTool> tools;
  @override Widget build(BuildContext context) {
    final m = <String, List<int>>{};
    for (final t in tools) { final c = t.category ?? 'Sin categoria'; m.putIfAbsent(c, () => [0, 0]); m[c]![0]++; if (t.complianceState == ComplianceState.compliant || t.complianceState == ComplianceState.grace) m[c]![1]++; }
    final e = m.entries.toList()..sort((a, b) => b.value[0].compareTo(a.value[0]));
    return _SP(title: 'Por categoria', child: e.isEmpty ? const SizedBox(height: 80, child: EmptyState(title: 'Sin datos', message: '', icon: Icons.category_outlined)) : Column(children: [
      for (final en in e.take(6)) _DBar(label: en.key, value: en.value[0], total: tools.length, subtitle: en.value[0] > 0 && en.value[1] > 0 ? '${(en.value[1] / en.value[0] * 100).round()}% vigentes' : null, color: en.value[0] > 0 && en.value[1] > 0 ? AppColors.success : AppColors.warning),
    ]));
  }
}

class _LocDist extends StatelessWidget {
  const _LocDist({required this.tools}); final List<DashboardTool> tools;
  @override Widget build(BuildContext context) {
    final m = <String, int>{}; for (final t in tools) { final l = t.currentLocation ?? 'Sin ubicacion'; m[l] = (m[l] ?? 0) + 1; }
    final e = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return _SP(title: 'Por ubicacion', child: e.isEmpty ? const SizedBox(height: 80, child: EmptyState(title: 'Sin datos', message: '', icon: Icons.location_on_outlined)) : Column(children: [
      for (final en in e.take(6)) _DBar(label: en.key, value: en.value, total: tools.length, color: AppColors.calibration),
    ]));
  }
}

class _DBar extends StatelessWidget {
  const _DBar({required this.label, required this.value, required this.total, required this.color, this.subtitle});
  final String label; final int value, total; final Color color; final String? subtitle;
  @override Widget build(BuildContext context) {
    final p = total == 0 ? 0.0 : value / total;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textOf(context), fontWeight: FontWeight.w700))), Text('$value (${(p * 100).toStringAsFixed(0)}%)', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.subduedOf(context), fontWeight: FontWeight.w700))]),
      if (subtitle != null) ...[const SizedBox(height: 1), Text(subtitle!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600))],
      const SizedBox(height: 5), ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(minHeight: 6, value: p.clamp(0, 1), color: color, backgroundColor: AppColors.surfaceSoftOf(context))),
    ]));
  }
}

class _SP extends StatelessWidget {
  const _SP({required this.title, required this.child}); final String title; final Widget child;
  @override Widget build(BuildContext context) {
    return Container(decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.borderOf(context)), boxShadow: AppColors.softShadowOf(context)), clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 13, 16, 10), child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textOf(context), fontWeight: FontWeight.w900))),
        const Divider(height: 1), Padding(padding: const EdgeInsets.all(14), child: child),
      ]));
  }
}
