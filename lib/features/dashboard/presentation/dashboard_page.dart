import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../loans/data/loans_providers.dart';
import '../../reports/data/pdf_report_service.dart';
import '../data/dashboard_providers.dart';
import '../../../core/i18n/translations.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotState = ref.watch(dashboardSnapshotProvider);
    return snapshotState.when(
      data: (snapshot) => _DashboardContent(snapshot: snapshot),
      error: (error, _) => _DashboardError(message: error.toString()),
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator())),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.snapshot});
  final DashboardSnapshot snapshot;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(allLoansProvider);
    final activeLoans = loansAsync.asData?.value.where((l) => l.isOpen).length ?? 0;
    final overdueLoans = loansAsync.asData?.value.where((l) => l.isOverdue).length ?? 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: context.t('dashboard.title'), description: context.t('dashboard.desc'), actions: [
        OutlinedButton.icon(onPressed: () => PdfReportService.printGeneralStatus(snapshot), icon: const Icon(Icons.file_download_outlined), label: Text(context.t('dashboard.export'))),
        FilledButton.icon(onPressed: () => context.go(AppRoutes.tools), icon: const Icon(Icons.inventory_2_outlined), label: Text(context.t('dashboard.goInventory'))),
      ]),
      _KpiStrip(snapshot: snapshot, activeLoans: activeLoans, overdueLoans: overdueLoans),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, constraints) {
        final useColumns = constraints.maxWidth >= 1000;
        final mainColumn = Column(children: [_StatusPanel(snapshot: snapshot), const SizedBox(height: 12), _ExpiringSoonPanel(tools: snapshot.expiringSoon)]);
        final sideColumn = Column(children: [_RecentActivityPanel(activities: snapshot.recentActivity), const SizedBox(height: 12), _QuickActionsPanel()]);
        if (!useColumns) return Column(children: [mainColumn, const SizedBox(height: 12), sideColumn]);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 7, child: mainColumn), const SizedBox(width: 12), SizedBox(width: 320, child: sideColumn)]);
      }),
    ]);
  }
}

class _KpiStrip extends StatelessWidget {
  const _KpiStrip({required this.snapshot, required this.activeLoans, required this.overdueLoans});
  final DashboardSnapshot snapshot; final int activeLoans, overdueLoans;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final count = constraints.maxWidth >= 960 ? 5 : constraints.maxWidth >= 680 ? 3 : constraints.maxWidth >= 420 ? 2 : 1;
      return GridView(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: count, crossAxisSpacing: 12, mainAxisSpacing: 10, mainAxisExtent: 100),
        children: [
          _KpiCard(title: context.t('dashboard.total'), value: snapshot.totalTools.toString(), icon: Icons.inventory_2_outlined, color: AppColors.actionBlue, onTap: () => context.go(AppRoutes.tools)),
          _KpiCard(title: context.t('dashboard.compliant'), value: (snapshot.compliant + snapshot.grace).toString(), icon: Icons.verified_outlined, color: AppColors.success, subtitle: '${snapshot.healthScore.round()}% ${context.t('dashboard.healthPct')}'),
          _KpiCard(title: context.t('dashboard.expiring'), value: snapshot.actionRequired.toString(), icon: Icons.warning_amber_outlined, color: snapshot.actionRequired > 0 ? AppColors.danger : AppColors.warning),
          _KpiCard(title: context.t('dashboard.inCalibration'), value: snapshot.inCalibration.toString(), icon: Icons.sync_alt_outlined, color: AppColors.calibration, onTap: () => context.go(AppRoutes.shipments)),
          _KpiCard(title: context.t('dashboard.loans'), value: activeLoans.toString(), icon: Icons.assignment_return_outlined, color: overdueLoans > 0 ? AppColors.danger : AppColors.warning, subtitle: overdueLoans > 0 ? '$overdueLoans ${context.t('dashboard.overdue')}' : context.t('dashboard.active'), onTap: () => context.go(AppRoutes.loans)),
        ],
      );
    });
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.title, required this.value, required this.icon, required this.color, this.subtitle, this.onTap});
  final String title, value; final IconData icon; final Color color; final String? subtitle; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final isClickable = onTap != null;
    return Material(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(22),
      child: InkWell(borderRadius: BorderRadius.circular(22), onTap: onTap,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.borderOf(context)), boxShadow: isClickable ? null : AppColors.softShadowOf(context)),
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.tintOf(context, color), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color)),
            const SizedBox(width: 12),
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.subduedOf(context), fontWeight: FontWeight.w800, letterSpacing: 0.4)),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.textOf(context), fontWeight: FontWeight.w900)),
              if (subtitle != null) ...[const SizedBox(height: 1), Text(subtitle!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700))],
            ])),
            if (isClickable) Icon(Icons.chevron_right, color: AppColors.subduedOf(context)),
          ]),
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.snapshot}); final DashboardSnapshot snapshot;
  @override
  Widget build(BuildContext context) {
    return _Panel(title: context.t('dashboard.compliance'), child: Column(children: [
      _StatusBar(label: context.t('dashboard.compliant'), value: snapshot.compliant + snapshot.grace, total: snapshot.totalTools, color: AppColors.success),
      _StatusBar(label: context.t('dashboard.proximos'), value: snapshot.warning, total: snapshot.totalTools, color: AppColors.warning),
      _StatusBar(label: context.t('dashboard.vencidos'), value: snapshot.expired, total: snapshot.totalTools, color: AppColors.danger),
      _StatusBar(label: context.t('dashboard.inCalibration'), value: snapshot.inCalibration, total: snapshot.totalTools, color: AppColors.calibration),
    ]));
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.label, required this.value, required this.total, required this.color});
  final String label; final int value, total; final Color color;
  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : value / total;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textOf(context), fontWeight: FontWeight.w700))), Text('$value ${context.t('common.of')} $total', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.subduedOf(context), fontWeight: FontWeight.w700))]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(minHeight: 8, value: percent.clamp(0, 1), color: color, backgroundColor: AppColors.surfaceSoftOf(context))),
    ]));
  }
}

class _ExpiringSoonPanel extends StatelessWidget {
  const _ExpiringSoonPanel({required this.tools}); final List<DashboardTool> tools;
  @override
  Widget build(BuildContext context) {
    return _Panel(title: context.t('dashboard.expiringSoon'), child: tools.isEmpty
      ? SizedBox(height: 100, child: EmptyState(title: context.t('dashboard.allGood'), message: context.t('dashboard.allGoodMsg'), icon: Icons.verified_outlined))
      : SizedBox(height: 220, child: DataTable2(minWidth: 600, columnSpacing: 12, headingRowHeight: 36, dataRowHeight: 42,
          columns: [DataColumn2(label: Text(context.t('inventory.code')), size: ColumnSize.S), DataColumn2(label: Text(context.t('inventory.tool')), size: ColumnSize.L), DataColumn2(label: Text('Vence'), size: ColumnSize.S), DataColumn2(label: Text(context.t('inventory.status')), size: ColumnSize.M)],
          rows: [for (final tool in tools) DataRow(onSelectChanged: (_) => context.go(AppRoutes.toolDetail(tool.id)), cells: [
            DataCell(Text(tool.internalCode ?? '-')), DataCell(Text(tool.displayName, overflow: TextOverflow.ellipsis)),
            DataCell(Text(SigecalDateUtils.formatDateCompact(tool.latestCalibration?.expirationDate))), DataCell(_ToolStatusBadge(tool: tool)),
          ])],
        )));
  }
}

class _RecentActivityPanel extends StatelessWidget {
  const _RecentActivityPanel({required this.activities}); final List<DashboardActivity> activities;
  @override
  Widget build(BuildContext context) {
    return _Panel(title: context.t('dashboard.recentActivity'), child: activities.isEmpty
      ? SizedBox(height: 80, child: EmptyState(title: context.t('dashboard.noActivity'), message: context.t('dashboard.noActivityMsg'), icon: Icons.history_outlined))
      : Column(children: [for (final a in activities.take(5)) _ActivityTile(activity: a)]));
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity}); final DashboardActivity activity;
  @override
  Widget build(BuildContext context) {
    final isShipment = activity.iconName == 'shipment';
    final color = isShipment ? AppColors.calibration : AppColors.success;
    final icon = isShipment ? Icons.local_shipping_outlined : Icons.verified_outlined;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 30, height: 30, decoration: BoxDecoration(color: AppColors.tintOf(context, color), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 16)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(activity.title, style: TextStyle(color: AppColors.textOf(context), fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 1),
        Text(SigecalDateUtils.formatDateCompact(activity.date), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.subduedOf(context))),
      ])),
    ]));
  }
}

class _QuickActionsPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Panel(title: context.t('dashboard.quickActions'), child: Column(children: [
      _ActionButton(icon: Icons.add_circle_outline, label: context.t('dashboard.newTool'), onTap: () => context.go(AppRoutes.newTool)),
      const SizedBox(height: 8),
      _ActionButton(icon: Icons.local_shipping_outlined, label: context.t('dashboard.newShipment'), onTap: () => context.go(AppRoutes.newShipment)),
      const SizedBox(height: 8),
      _ActionButton(icon: Icons.warning_amber_outlined, label: context.t('dashboard.quarantine'), onTap: () => context.go(AppRoutes.quarantineTools)),
    ]));
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 20), label: Text(label), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), alignment: Alignment.centerLeft)));
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child}); final String title; final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.borderOf(context)), boxShadow: AppColors.softShadowOf(context)),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 13, 16, 10), child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textOf(context), fontWeight: FontWeight.w900))),
        const Divider(height: 1),
        Padding(padding: const EdgeInsets.all(14), child: child),
      ]),
    );
  }
}

class _ToolStatusBadge extends StatelessWidget {
  const _ToolStatusBadge({required this.tool}); final DashboardTool tool;
  @override
  Widget build(BuildContext context) {
    final days = tool.daysToExpiration;
    return switch (tool.complianceState) {
      ComplianceState.expired => StatusBadge(label: 'Vencido (${days?.abs() ?? 0}d)', color: AppColors.danger),
      ComplianceState.warning => StatusBadge(label: 'Critico (${days ?? 0}d)', color: AppColors.critical),
      ComplianceState.grace => StatusBadge(label: 'Alerta (${days ?? 0}d)', color: AppColors.warning),
      ComplianceState.inCalibration => StatusBadge(label: context.t('dashboard.inCalibration'), color: AppColors.calibration),
      ComplianceState.withoutCalibration => StatusBadge(label: context.t('inventory.sinCalLabel'), color: AppColors.muted),
      ComplianceState.compliant => StatusBadge(label: context.t('inventory.vigenteLabel'), color: AppColors.success),
    };
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message}); final String message;
  @override
  Widget build(BuildContext context) => EmptyState(title: context.t('common.error'), message: message, icon: Icons.error_outline);
}
