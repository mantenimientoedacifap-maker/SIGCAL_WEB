import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_providers.dart';
import '../config/supabase_config.dart';
import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../constants/app_strings.dart';
import '../i18n/translations.dart';
import '../preferences/app_preferences.dart';

class AppSidebar extends ConsumerWidget {
  const AppSidebar({required this.selectedLocation, super.key});
  final String selectedLocation;

  static const _items = [
    _SidebarItem(key: 'nav.dashboard', route: AppRoutes.dashboard, icon: Icons.dashboard_outlined),
    _SidebarItem(key: 'nav.inventory', route: AppRoutes.tools, icon: Icons.inventory_2_outlined),
    _SidebarItem(key: 'nav.shipments', route: AppRoutes.shipments, icon: Icons.local_shipping_outlined),
    _SidebarItem(key: 'nav.loans', route: AppRoutes.loans, icon: Icons.assignment_return_outlined),
    _SidebarItem(key: 'nav.statistics', route: AppRoutes.reports, icon: Icons.analytics_outlined),
    _SidebarItem(key: 'nav.dashboard', route: AppRoutes.users, icon: Icons.people_outline),
    _SidebarItem(key: 'nav.settings', route: AppRoutes.settings, icon: Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appPreferencesProvider.select((p) => p.language));

    return Material(
      color: AppColors.sidebar,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BrandBlock(),
              const SizedBox(height: 28),
              Expanded(
                child: ListView.separated(
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final selected = _isSelected(item.route);
                    return _SidebarTile(item: item, selected: selected, onTap: () => context.go(item.route));
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemCount: _items.length,
                ),
              ),
              const _SidebarFooter(),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSelected(String route) {
    if (route == AppRoutes.dashboard) return selectedLocation == route;
    return selectedLocation.startsWith(route);
  }
}

class _BrandBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.actionBlue, borderRadius: BorderRadius.circular(16)), alignment: Alignment.center,
        child: const Icon(Icons.precision_manufacturing_outlined, color: AppColors.white)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(AppStrings.appName, style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(context.t('app.tagline'), style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
      ])),
    ]);
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({required this.item, required this.selected, required this.onTap});
  final _SidebarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      onTap: onTap,
      leading: Icon(item.icon),
      title: Text(context.t(item.key)),
      iconColor: selected ? AppColors.white : const Color(0xFFCBD5E1),
      textColor: selected ? AppColors.white : const Color(0xFFCBD5E1),
      selectedTileColor: AppColors.sidebarSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _SidebarFooter extends ConsumerWidget {
  const _SidebarFooter();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = SupabaseConfig.runtimeInfo;
    final ready = info.isReady;
    final profile = ref.watch(currentUserProfileProvider).asData?.value;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF0B1220), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1F2937))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: ready ? AppColors.success : AppColors.danger, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(ready ? context.t('footer.version') : context.t('footer.offline'), style: const TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.w800, fontSize: 13)),
        ]),
        if (profile != null) ...[
          const SizedBox(height: 8),
          Text(profile.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          const SizedBox(height: 4),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.actionBlue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
            child: Text(profile.role.label, style: const TextStyle(color: AppColors.actionBlue, fontWeight: FontWeight.w800, fontSize: 10))),
        ],
      ]),
    );
  }
}

class _SidebarItem {
  const _SidebarItem({required this.key, required this.route, required this.icon});
  final String key;
  final String route;
  final IconData icon;
}
