import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../../tools/data/tool_catalog_providers.dart';
import '../data/loans_providers.dart';
import '../../../core/i18n/translations.dart';

class LoansPage extends ConsumerStatefulWidget {
  const LoansPage({super.key});
  @override
  ConsumerState<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends ConsumerState<LoansPage> {
  String _filter = 'todos';

  @override
  Widget build(BuildContext context) {
    final loansState = ref.watch(allLoansProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: context.t('dashboard.loans'), description: 'Control global de herramientas prestadas.'),
      loansState.when(
        data: (loans) => _LoansContent(loans: loans, filter: _filter, onFilter: (f) => setState(() => _filter = f)),
        error: (e, _) => EmptyState(title: 'Error', message: e.toString(), icon: Icons.error_outline),
        loading: () => SizedBox(height: 360, child: LoadingView(message: context.t('loans.loading'))),
      ),
    ]);
  }
}

class _LoansContent extends StatelessWidget {
  const _LoansContent({required this.loans, required this.filter, required this.onFilter});
  final List<LoanRecord> loans;
  final String filter;
  final ValueChanged<String> onFilter;

  @override
  Widget build(BuildContext context) {
    final active = loans.where((l) => l.isOpen && !l.isOverdue).toList();
    final overdue = loans.where((l) => l.isOpen && l.isOverdue).toList();
    final returned = loans.where((l) => !l.isOpen).toList();
    final visible = switch (filter) { 'activos' => active, 'vencidos' => overdue, 'devueltos' => returned, _ => loans };

    return Column(children: [
      _FilterPills(loans: loans, active: active.length, overdue: overdue.length, returned: returned.length, filter: filter, onTap: onFilter),
      const SizedBox(height: 14),
      if (visible.isEmpty)
        Card(child: SizedBox(height: 240, child: EmptyState(title: context.t('inventory.noResults'), message: 'No hay prestamos en esta categoria.', icon: Icons.assignment_return_outlined)))
      else ...[
        for (final loan in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LoanRow(
              loan: loan,
              onTap: () => context.go(AppRoutes.toolDetail(loan.toolId)),
              onReturn: () => _showReturnDialog(context, loan),
            ),
          ),
      ],
    ]);
  }
}

class _FilterPills extends StatelessWidget {
  const _FilterPills({required this.loans, required this.active, required this.overdue, required this.returned, required this.filter, required this.onTap});
  final List<LoanRecord> loans; final int active, overdue, returned; final String filter; final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.borderOf(context))),
      child: LayoutBuilder(builder: (context, constraints) {
        final count = constraints.maxWidth >= 640 ? 4 : 2;
        return GridView(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: count, crossAxisSpacing: 10, mainAxisSpacing: 10, mainAxisExtent: 68),
          children: [
            _Pill(label: 'Todos', value: loans.length, color: AppColors.actionBlue, selected: filter == 'todos', onTap: () => onTap('todos')),
            _Pill(label: context.t('dashboard.active'), value: active, color: AppColors.success, selected: filter == 'activos', onTap: () => onTap('activos')),
            _Pill(label: context.t('dashboard.vencidos'), value: overdue, color: AppColors.danger, selected: filter == context.t('dashboard.overdue'), onTap: () => onTap(context.t('dashboard.overdue'))),
            _Pill(label: 'Devueltos', value: returned, color: AppColors.muted, selected: filter == 'devueltos', onTap: () => onTap('devueltos')),
          ],
        );
      }),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value, required this.color, required this.selected, required this.onTap});
  final String label; final int value; final Color color; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 150), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.tintOf(context, color, lightAlpha: 0.1, darkAlpha: 0.2) : AppColors.surfaceSoftOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? color.withValues(alpha: 0.5) : AppColors.borderOf(context), width: selected ? 2 : 1)),
      child: Row(children: [Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$value', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: selected ? color : AppColors.textOf(context), fontWeight: FontWeight.w900)),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.subduedOf(context), fontWeight: FontWeight.w700)),
      ]))]),
    ));
  }
}

class _LoanRow extends StatelessWidget {
  const _LoanRow({required this.loan, required this.onTap, required this.onReturn});
  final LoanRecord loan; final VoidCallback onTap; final VoidCallback onReturn;
  @override
  Widget build(BuildContext context) {
    final color = !loan.isOpen ? AppColors.muted : loan.isOverdue ? AppColors.danger : AppColors.success;
    final statusLabel = !loan.isOpen ? 'Devuelto' : loan.isOverdue ? 'Vencido' : 'Activo';
    final days = loan.daysToReturn;
    final totalPeriod = loan.expectedReturnDate != null ? loan.expectedReturnDate!.difference(loan.loanDate).inDays : 14;
    final elapsed = DateTime.now().difference(loan.loanDate).inDays;
    final progress = totalPeriod > 0 ? (elapsed / totalPeriod).clamp(0.0, 1.5) : 0.0;

    return Material(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(18),
      child: InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.borderOf(context)), boxShadow: AppColors.softShadowOf(context)),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                RichText(text: TextSpan(style: TextStyle(color: AppColors.textOf(context), fontWeight: FontWeight.w800, fontSize: 14), children: [
                  if (loan.toolCode != null) TextSpan(text: '${loan.toolCode!} · ', style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: loan.toolName),
                ])),
                const SizedBox(height: 3),
                Text([loan.borrowerName, if (loan.borrowerDocument != null) 'CC ${loan.borrowerDocument}'].whereType<String>().join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.subduedOf(context))),
              ])),
              StatusBadge(label: statusLabel, color: color),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(minHeight: 6, value: progress.clamp(0, 1), color: loan.isOverdue ? AppColors.danger : color, backgroundColor: AppColors.surfaceSoftOf(context)))),
              const SizedBox(width: 10),
              Text(days != null ? '${days.abs()}d ${days >= 0 ? 'rest.' : context.t('dashboard.overdue')}' : '--', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _Meta(icon: Icons.business_outlined, text: loan.workshopName ?? '-'),
              const SizedBox(width: 16),
              _Meta(icon: Icons.event_outlined, text: 'Retiro: ${_fmt(loan.loanDate)}'),
              const SizedBox(width: 16),
              _Meta(icon: Icons.event_available_outlined, text: 'Est: ${_fmt(loan.expectedReturnDate)}'),
            ]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton.icon(onPressed: onTap, icon: const Icon(Icons.open_in_new, size: 16), label: const Text('Ficha'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8))),
              if (loan.isOpen) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(onPressed: onReturn, icon: const Icon(Icons.assignment_turned_in, size: 16), label: const Text('Devolver'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8))),
              ],
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon; final String text;
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: AppColors.subduedOf(context)),
      const SizedBox(width: 4),
      Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.subduedOf(context))),
    ]);
  }
}

Future<void> _showReturnDialog(BuildContext context, LoanRecord loan) async {
  final controller = TextEditingController();
  final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
    title: const Text('Registrar devolucion'),
    content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${loan.toolCode ?? loan.toolName}\n${loan.borrowerName ?? ''} · ${loan.workshopName ?? ''}', style: const TextStyle(height: 1.4)),
      const SizedBox(height: 14),
      TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(labelText: 'Observaciones', hintText: 'Condicion de la herramienta al retornar')),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.t('inventory.cancel'))),
      FilledButton.icon(onPressed: () => Navigator.pop(ctx, true), icon: const Icon(Icons.check_circle_outline), label: const Text('Confirmar retorno')),
    ],
  ));
  if (confirmed != true || !context.mounted) return;
  try {
    await ProviderScope.containerOf(context)
        .read(toolMutationRepositoryProvider)
        .returnLoanById(
          loanId: loan.id,
          toolId: loan.toolId,
          borrowerName: loan.borrowerName ?? loan.toolName,
          observations: controller.text,
        );
    ProviderScope.containerOf(context).invalidate(allLoansProvider);
    ProviderScope.containerOf(context).invalidate(dashboardSnapshotProvider);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Devolucion registrada.')));
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
  } finally { controller.dispose(); }
}

String _fmt(DateTime? d) {
  if (d == null) return '-';
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
