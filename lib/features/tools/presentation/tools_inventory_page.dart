import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/i18n/translations.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/data/auth_providers.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../data/tool_catalog_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE ENTRY
// ═══════════════════════════════════════════════════════════════════════════════

class ToolsInventoryPage extends ConsumerStatefulWidget {
  const ToolsInventoryPage({
    this.showRetired = false,
    this.showQuarantine = false,
    super.key,
  });
  final bool showRetired;
  final bool showQuarantine;

  @override
  ConsumerState<ToolsInventoryPage> createState() =>
      _ToolsInventoryPageState();
}

class _ToolsInventoryPageState extends ConsumerState<ToolsInventoryPage> {
  final _sc = TextEditingController();
  String _q = '';
  String _filter = 'all';
  int _page = 0;
  static const _pageSize = 24;
  bool _gridView = true;

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _gridView = prefs.getBool('inventory_grid_view') ?? true);
  }

  Future<void> _toggleView() async {
    final next = !_gridView;
    setState(() => _gridView = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('inventory_grid_view', next);
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(currentUserProfileProvider).asData?.value;
    final canManage = p?.role.canManageOperationalData ?? false;
    final isInventory = !widget.showRetired && !widget.showQuarantine;

    if (widget.showRetired) {
      return ref.watch(retiredToolsProvider).when(
            data: (tools) => _buildPage(tools, isInventory, canManage),
            error: (e, _) =>
                EmptyState(title: 'Error', message: e.toString(), icon: Icons.error_outline),
            loading: () => const LoadingView(message: 'Cargando...'),
          );
    }
    if (widget.showQuarantine) {
      return ref.watch(quarantineToolsProvider).when(
            data: (tools) => _buildPage(tools, isInventory, canManage),
            error: (e, _) =>
                EmptyState(title: 'Error', message: e.toString(), icon: Icons.error_outline),
            loading: () => const LoadingView(message: 'Cargando...'),
          );
    }

    return ref.watch(dashboardSnapshotProvider).when(
          data: (snapshot) =>
              _buildPage(snapshot.tools, isInventory, canManage),
          error: (e, _) =>
              EmptyState(title: 'Error', message: e.toString(), icon: Icons.error_outline),
          loading: () => const LoadingView(message: 'Cargando inventario...'),
        );
  }

  Widget _buildPage(
      List<DashboardTool> tools, bool isInventory, bool canManage) {
    final list = _applyFilters(tools, _q);
    final totalPages = (list.length / _pageSize).ceil();
    final page = _page.clamp(0, totalPages > 0 ? totalPages - 1 : 0);
    final start = page * _pageSize;
    final pageItems = list.length > _pageSize
        ? list.sublist(start, (start + _pageSize).clamp(0, list.length))
        : list;

    return Column(children: [
      // ── Toolbar ──
      _ModernToolbar(
        query: _q,
        controller: _sc,
        filter: _filter,
        total: tools.length,
        visible: list.length,
        isInventory: isInventory,
        canManage: canManage,
        gridView: _gridView,
        onSearch: (v) => setState(() { _q = v; _page = 0; }),
        onFilter: (f) => setState(() { _filter = f; _page = 0; }),
        onToggleView: _toggleView,
        tools: isInventory ? list : tools,
      ),

      const SizedBox(height: 14),

      // ── Header ──
      _InventoryHeader(
        showRetired: widget.showRetired,
        showQuarantine: widget.showQuarantine,
        canManage: canManage,
        count: pageItems.length,
        totalCount: list.length,
      ),

      const SizedBox(height: 14),

      // ── Content ──
      if (pageItems.isEmpty)
        Center(
          child: EmptyState(
            title: context.t('inventory.noResults'),
            message: context.t('inventory.noResultsMsg'),
            icon: Icons.inventory_2_outlined,
          ),
        )
      else if (_gridView)
        _GridView(tools: pageItems, canManage: canManage,
            showRetired: widget.showRetired,
            showQuarantine: widget.showQuarantine)
      else
        _ListView(tools: pageItems, canManage: canManage,
            showRetired: widget.showRetired,
            showQuarantine: widget.showQuarantine),

      // ── Pagination ──
      if (totalPages > 1)
        _ModernPagination(
          page: page,
          totalPages: totalPages,
          onPage: (p) => setState(() => _page = p),
        ),
    ]);
  }

  // ── Filters (unchanged logic) ──

  List<DashboardTool> _applyFilters(List<DashboardTool> tools, String query) {
    var list = tools;

    if (!widget.showRetired && !widget.showQuarantine) {
      list = list.where((t) {
        if (t.complianceState == ComplianceState.expired) return false;
        if (t.hasQuarantineReason) return false;
        return true;
      }).toList();
    }

    if (_filter != 'all') {
      list = list.where((t) {
        return switch (_filter) {
          'compliant' =>
              t.complianceState == ComplianceState.compliant ||
                  t.complianceState == ComplianceState.grace,
          'warning' => t.complianceState == ComplianceState.warning,
          'calibrating' =>
              t.complianceState == ComplianceState.inCalibration,
          _ => true,
        };
      }).toList();
    }

    if (query.trim().isNotEmpty) {
      list = _textFilter(list, query.trim().toLowerCase());
    }

    return list;
  }

  List<DashboardTool> _textFilter(List<DashboardTool> tools, String q) {
    final tokens =
        q.split(RegExp(r'\s+')).where((v) => v.isNotEmpty).toList();
    return tools.where((t) {
      final haystack = [
        t.internalCode,
        t.displayName,
        t.category,
        t.manufacturer,
        t.currentLocation,
        SigecalDateUtils.formatDateShort(t.latestCalibration?.expirationDate),
        _statusSearchText(t),
      ].whereType<String>().join(' ').toLowerCase();
      return tokens.every((tok) => haystack.contains(tok));
    }).toList();
  }

  String _statusSearchText(DashboardTool t) => switch (t.complianceState) {
        ComplianceState.compliant => 'vigente',
        ComplianceState.grace => 'alerta',
        ComplianceState.warning => 'critico',
        ComplianceState.expired => 'vencido',
        ComplianceState.inCalibration => 'calibracion',
        ComplianceState.withoutCalibration => 'sin calibracion',
      };
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODERN TOOLBAR
// ═══════════════════════════════════════════════════════════════════════════════

class _ModernToolbar extends StatelessWidget {
  const _ModernToolbar({
    required this.query,
    required this.controller,
    required this.filter,
    required this.total,
    required this.visible,
    required this.isInventory,
    required this.canManage,
    required this.gridView,
    required this.onSearch,
    required this.onFilter,
    required this.onToggleView,
    required this.tools,
  });

  final String query, filter;
  final TextEditingController controller;
  final int total, visible;
  final bool isInventory, canManage, gridView;
  final ValueChanged<String> onSearch, onFilter;
  final VoidCallback onToggleView;
  final List<DashboardTool> tools;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppColors.softShadowOf(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search + actions row
          Row(children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoftOf(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: TextField(
                  controller: controller,
                  onChanged: onSearch,
                  style: TextStyle(color: AppColors.textOf(context), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: context.t('inventory.search'),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () { controller.clear(); onSearch(''); },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Quarantine
            if (isInventory) ...[
              _QuarantineBtn(qCount: tools.where((t) => t.isInQuarantine).length),
              const SizedBox(width: 6),
            ],
            // View toggle
            _ToolbarBtn(
              icon: gridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              tooltip: gridView ? 'Vista lista' : 'Vista grid',
              onTap: onToggleView,
            ),
            const SizedBox(width: 6),
            // New tool / Back button
            _ToolbarBtn(
              icon: isInventory ? Icons.add_rounded : Icons.arrow_back_rounded,
              tooltip: isInventory ? 'Nueva herramienta' : 'Volver a inventario',
              onTap: () => context.go(isInventory ? AppRoutes.newTool : AppRoutes.tools),
              primary: isInventory,
            ),
          ]),

          // Filter chips
          if (isInventory) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _FilterChip(
                  label: 'Todos',
                  count: total,
                  active: filter == 'all',
                  onTap: () => onFilter('all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Vigentes',
                  count: tools.where((t) =>
                      t.complianceState == ComplianceState.compliant ||
                      t.complianceState == ComplianceState.grace).length,
                  active: filter == 'compliant',
                  color: AppColors.success,
                  onTap: () => onFilter('compliant'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Críticos',
                  count: tools.where((t) =>
                      t.complianceState == ComplianceState.warning).length,
                  active: filter == 'warning',
                  color: AppColors.critical,
                  onTap: () => onFilter('warning'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'En calibración',
                  count: tools.where((t) =>
                      t.complianceState == ComplianceState.inCalibration).length,
                  active: filter == 'calibrating',
                  color: AppColors.calibration,
                  onTap: () => onFilter('calibrating'),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}




class _QuarantineBtn extends StatelessWidget {
  const _QuarantineBtn({required this.qCount});
  final int qCount;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: qCount > 0
          ? '$qCount en cuarentena'
          : 'Cuarentena',
      child: Material(
        color: qCount > 0
            ? AppColors.critical.withValues(alpha: 0.12)
            : AppColors.surfaceSoftOf(context),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.go(AppRoutes.quarantineTools),
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: qCount > 0
                    ? AppColors.critical.withValues(alpha: 0.3)
                    : AppColors.borderOf(context),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  qCount > 0
                      ? Icons.warning_amber_rounded
                      : Icons.medical_information_outlined,
                  color: qCount > 0 ? AppColors.critical : AppColors.subduedOf(context),
                  size: 22,
                ),
                if (qCount > 0)
                  Positioned(
                    top: 6, right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.critical,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        qCount > 9 ? '9+' : '$qCount',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  const _ToolbarBtn({required this.icon, this.tooltip, this.onTap, this.primary = false});
  final IconData icon;
  final String? tooltip;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: primary ? AppColors.actionBlue : AppColors.surfaceSoftOf(context),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: primary ? null : Border.all(color: AppColors.borderOf(context)),
            ),
            child: Icon(icon, size: 22,
                color: primary ? Colors.white : AppColors.textOf(context)),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label, required this.count, required this.active,
    this.color, required this.onTap,
  });
  final String label;
  final int count;
  final bool active;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.actionBlue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? c.withValues(alpha: 0.12) : AppColors.surfaceSoftOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? c.withValues(alpha: 0.5) : AppColors.borderOf(context),
            width: active ? 2 : 1,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (active)
            Icon(Icons.circle, size: 8, color: c),
          if (active) const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                color: active ? c : AppColors.subduedOf(context),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              )),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: active ? c.withValues(alpha: 0.18) : AppColors.borderOf(context).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$count',
                style: TextStyle(
                  color: active ? c : AppColors.subduedOf(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                )),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// INVENTORY HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class _InventoryHeader extends ConsumerWidget {
  const _InventoryHeader({
    required this.showRetired, required this.showQuarantine,
    required this.canManage, required this.count, required this.totalCount,
  });
  final bool showRetired, showQuarantine, canManage;
  final int count, totalCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = showRetired
        ? context.t('inventory.retired')
        : showQuarantine
            ? context.t('inventory.quarantine')
            : context.t('inventory.title');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(children: [
        Text(title,
            style: TextStyle(
              color: AppColors.textOf(context),
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.3,
            )),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.tintOf(context, AppColors.actionBlue),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count de $totalCount',
              style: TextStyle(
                color: AppColors.actionBlue,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              )),
        ),
        const Spacer(),
        if (showQuarantine || showRetired)
          TextButton.icon(
            onPressed: () => context.go(AppRoutes.tools),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Inventario'),
          ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GRID VIEW
// ═══════════════════════════════════════════════════════════════════════════════

class _GridView extends StatelessWidget {
  const _GridView({
    required this.tools, required this.canManage,
    required this.showRetired, required this.showQuarantine,
  });
  final List<DashboardTool> tools;
  final bool canManage, showRetired, showQuarantine;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final crossCount = constraints.maxWidth >= 1200 ? 4
          : constraints.maxWidth >= 900 ? 3
          : constraints.maxWidth >= 600 ? 2
          : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 220,
        ),
        itemCount: tools.length,
        itemBuilder: (_, i) => _GridCard(
          tool: tools[i],
          canManage: canManage,
          showRetired: showRetired,
          showQuarantine: showQuarantine,
        ),
      );
    });
  }
}

class _GridCard extends ConsumerWidget {
  const _GridCard({
    required this.tool, required this.canManage,
    required this.showRetired, required this.showQuarantine,
  });
  final DashboardTool tool;
  final bool canManage, showRetired, showQuarantine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = tool.complianceState;
    final accent = _accentColor(state);
    final days = tool.daysToExpiration;

    return Material(
      color: AppColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go(AppRoutes.toolDetail(tool.id)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderOf(context)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: AppColors.isDark(context) ? 0.12 : 0.04),
                blurRadius: 12, offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thumbnail + status badge
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _ToolThumbnail(tool: tool, accent: accent),
                const Spacer(),
                StatusBadge(label: _stateLabel(state, days), color: accent),
              ]),
              const SizedBox(height: 10),
              // Name + code
              Text(tool.displayName,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textOf(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 13, height: 1.3,
                  )),
              if (tool.internalCode != null) ...[
                const SizedBox(height: 2),
                Text(tool.internalCode!,
                    style: TextStyle(
                      color: AppColors.subduedOf(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    )),
              ],
              const SizedBox(height: 8),
              // Meta line compact
              Text(
                [tool.manufacturer ?? '', tool.currentLocation ?? '']
                    .where((s) => s.isNotEmpty).join(' · '),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.subduedOf(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tool.latestCalibration?.expirationDate != null
                    ? 'Vence ${SigecalDateUtils.formatDateShort(tool.latestCalibration!.expirationDate)}'
                    : 'Sin vencimiento',
                style: TextStyle(
                  color: AppColors.subduedOf(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Health bar
              _HealthBar(tool: tool, accent: accent),
              const SizedBox(height: 6),
              // Actions
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (showRetired)
                  _MiniAction(icon: Icons.open_in_new, tooltip: 'Ver ficha',
                      onTap: () => context.go(AppRoutes.toolDetail(tool.id)))
                else ...[
                  if (state != ComplianceState.inCalibration)
                    _MiniAction(icon: Icons.assignment_return_outlined, tooltip: 'Prestar',
                        onTap: () => context.go(AppRoutes.toolDetail(tool.id))),
                  if (!showQuarantine && state != ComplianceState.inCalibration)
                    _MiniAction(icon: Icons.verified_outlined, tooltip: 'Calibrar',
                        onTap: () => context.go(AppRoutes.newCalibration(tool.id))),
                  if (showQuarantine)
                    _MiniAction(icon: Icons.local_shipping_outlined, tooltip: 'Enviar',
                        onTap: () => context.go(AppRoutes.newCalibration(tool.id))),
                  _MiniAction(icon: Icons.open_in_new, tooltip: 'Ver ficha',
                      onTap: () => context.go(AppRoutes.toolDetail(tool.id))),
                  if (canManage && !showQuarantine)
                    _MiniAction(icon: Icons.archive_outlined, tooltip: 'Dar de baja',
                        color: AppColors.danger,
                        onTap: () => _confirmRetire(context, ref, tool)),
                ],
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolThumbnail extends StatelessWidget {
  const _ToolThumbnail({required this.tool, required this.accent});
  final DashboardTool tool;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: tool.photoUrl != null && tool.photoUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(tool.photoUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, a, b) => _PlaceholderIcon(accent: accent)),
            )
          : _PlaceholderIcon(accent: accent),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon({required this.accent});
  final Color accent;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.precision_manufacturing_outlined, color: accent, size: 24);
}

class _HealthBar extends StatelessWidget {
  const _HealthBar({required this.tool, required this.accent});
  final DashboardTool tool;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final days = tool.daysToExpiration;
    final pct = days != null && days > 0 ? (days / 365).clamp(0.05, 1.0) : 0.05;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: pct,
        minHeight: 3,
        color: accent,
        backgroundColor: AppColors.surfaceSoftOf(context),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LIST VIEW
// ═══════════════════════════════════════════════════════════════════════════════

class _ListView extends StatelessWidget {
  const _ListView({
    required this.tools, required this.canManage,
    required this.showRetired, required this.showQuarantine,
  });
  final List<DashboardTool> tools;
  final bool canManage, showRetired, showQuarantine;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: tools.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (_, i) => _ListRow(
        tool: tools[i],
        canManage: canManage,
        showRetired: showRetired,
        showQuarantine: showQuarantine,
      ),
    );
  }
}

class _ListRow extends ConsumerWidget {
  const _ListRow({
    required this.tool, required this.canManage,
    required this.showRetired, required this.showQuarantine,
  });
  final DashboardTool tool;
  final bool canManage, showRetired, showQuarantine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = tool.complianceState;
    final accent = _accentColor(state);
    final days = tool.daysToExpiration;

    return Material(
      color: AppColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(AppRoutes.toolDetail(tool.id)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Row(children: [
            _ToolThumbnail(tool: tool, accent: accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tool.displayName,
                      style: TextStyle(
                        color: AppColors.textOf(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text([
                    tool.internalCode ?? '',
                    tool.manufacturer ?? '',
                    tool.currentLocation ?? '',
                    if (tool.latestCalibration?.expirationDate != null)
                      'Vence ${SigecalDateUtils.formatDateShort(tool.latestCalibration!.expirationDate)}',
                  ].where((s) => s.isNotEmpty).join(' · '),
                      style: TextStyle(
                        color: AppColors.subduedOf(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(label: _stateLabel(state, days), color: accent),
                const SizedBox(height: 6),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  if (!showRetired && !showQuarantine && state != ComplianceState.inCalibration)
                    _MiniAction(
                      icon: Icons.verified_outlined,
                      tooltip: 'Calibrar',
                      onTap: () => context.go(AppRoutes.newCalibration(tool.id)),
                    ),
                  _MiniAction(
                    icon: Icons.open_in_new,
                    tooltip: 'Ver ficha',
                    onTap: () => context.go(AppRoutes.toolDetail(tool.id)),
                  ),
                  if (canManage && !showQuarantine && !showRetired)
                    _MiniAction(
                      icon: Icons.archive_outlined,
                      tooltip: 'Baja',
                      color: AppColors.danger,
                      onTap: () => _confirmRetire(context, ref, tool),
                    ),
                ]),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _MiniAction extends StatelessWidget {
  const _MiniAction({required this.icon, required this.tooltip, this.color, required this.onTap});
  final IconData icon;
  final String tooltip;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: AppColors.surfaceSoftOf(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Icon(icon, size: 18,
              color: color ?? AppColors.subduedOf(context)),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAGINATION
// ═══════════════════════════════════════════════════════════════════════════════

class _ModernPagination extends StatelessWidget {
  const _ModernPagination({required this.page, required this.totalPages, required this.onPage});
  final int page, totalPages;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _PageBtn(icon: Icons.chevron_left, enabled: page > 0, onTap: () => onPage(page - 1)),
        const SizedBox(width: 20),
        Text('Pag. ${page + 1} de $totalPages',
            style: TextStyle(
              color: AppColors.subduedOf(context),
              fontWeight: FontWeight.w700, fontSize: 13,
            )),
        const SizedBox(width: 20),
        _PageBtn(icon: Icons.chevron_right, enabled: page < totalPages - 1, onTap: () => onPage(page + 1)),
      ]),
    );
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn({required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.surfaceOf(context) : AppColors.surfaceSoftOf(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: Icon(icon, size: 20,
            color: enabled ? AppColors.textOf(context) : AppColors.subduedOf(context)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RETIRE CONFIRMATION
// ═══════════════════════════════════════════════════════════════════════════════

Future<void> _confirmRetire(
    BuildContext context, WidgetRef ref, DashboardTool tool) async {
  final rc = TextEditingController();
  final pc = TextEditingController();
  final reason = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Dar de baja herramienta'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enviara ${tool.internalCode ?? tool.displayName} a ALMACEN DE BAJAS.'),
            const SizedBox(height: 14),
            TextField(
              controller: rc, maxLines: 3,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                  labelText: 'Motivo obligatorio',
                  hintText: 'Ej. OBSOLESCENCIA, DANIO IRREPARABLE...'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pc,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                  labelText: 'Escribe DAR DE BAJA para confirmar'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
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
  ).whenComplete(() { rc.dispose(); pc.dispose(); });

  if (reason == null || reason.trim().isEmpty || !context.mounted) return;

  try {
    await ref.read(toolMutationRepositoryProvider).retireTool(toolId: tool.id, reason: reason);
    ref.invalidate(dashboardSnapshotProvider);
    ref.invalidate(retiredToolsProvider);
    ref.invalidate(quarantineToolsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Baja auditada registrada.')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPERS (unchanged)
// ═══════════════════════════════════════════════════════════════════════════════

Color _accentColor(ComplianceState s) => switch (s) {
      ComplianceState.compliant => AppColors.success,
      ComplianceState.grace => AppColors.warning,
      ComplianceState.warning => AppColors.critical,
      ComplianceState.expired => AppColors.danger,
      ComplianceState.inCalibration => AppColors.calibration,
      ComplianceState.withoutCalibration => AppColors.muted,
    };

String _stateLabel(ComplianceState s, int? days) => switch (s) {
      ComplianceState.compliant => 'VIGENTE',
      ComplianceState.grace => 'ALERTA ${days ?? "?"}d',
      ComplianceState.warning => 'CRITICO ${days ?? "?"}d',
      ComplianceState.expired => 'VENCIDO',
      ComplianceState.inCalibration => 'EN CALIBRACION',
      ComplianceState.withoutCalibration => 'SIN CALIBRAR',
    };
