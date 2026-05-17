import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../notifications/notification_read_store.dart';
import '../preferences/app_preferences.dart';
import '../../features/auth/data/auth_providers.dart';
import '../../features/auth/domain/user_profile.dart';
import '../../features/dashboard/data/dashboard_providers.dart';
import '../../features/loans/data/loans_providers.dart';
import '../../features/settings/presentation/settings_page.dart';

class AppTopbar extends ConsumerWidget {
  const AppTopbar({
    required this.selectedLocation,
    this.onMenuPressed,
    super.key,
  });

  final String selectedLocation;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = _titleFor(selectedLocation);
    final profileState = ref.watch(currentUserProfileProvider);

    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.topbarOf(context),
        border: Border(bottom: BorderSide(color: AppColors.borderOf(context))),
      ),
      child: Row(
        children: [
          if (onMenuPressed != null) ...[
            IconButton(
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu),
              tooltip: 'Abrir navegacion',
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textOf(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sistema de Gestion de Calibracion',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.subduedOf(context),
                  ),
                ),
              ],
            ),
          ),
          const _AlertBell(),
          const SizedBox(width: 8),
          const _ThemeCycleButton(),
          const SizedBox(width: 8),
          const _LanguageMenuButton(),
          const SizedBox(width: 10),
          _UserMenu(profileState: profileState),
        ],
      ),
    );
  }

  String _titleFor(String location) {
    if (location.contains('/calibrations/new')) {
      return 'Registro de calibracion';
    }

    if (location.startsWith('${AppRoutes.tools}/') &&
        !location.endsWith('/new')) {
      return 'Ficha tecnica de herramienta';
    }

    if (location.startsWith(AppRoutes.tools)) {
      return 'Inventario de herramientas y equipos';
    }

    if (location.startsWith(AppRoutes.shipments)) {
      return 'Envios a centro de calibracion';
    }

    if (location.startsWith(AppRoutes.reports)) {
      return 'Reportes';
    }

    if (location.startsWith(AppRoutes.users)) {
      return 'Usuarios y roles';
    }

    if (location.startsWith(AppRoutes.settings)) {
      return 'Configuracion';
    }

    return 'Panel de control SIGCAL';
  }
}

class _AlertBell extends ConsumerWidget {
  const _AlertBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotState = ref.watch(dashboardSnapshotProvider);
    final loansState = ref.watch(allLoansProvider);
    final profileState = ref.watch(currentUserProfileProvider);
    final profile = profileState.when(
      data: (value) => value,
      error: (_, _) => null,
      loading: () => null,
    );
    final ownerKey = _notificationOwnerKey(profile);
    final readNotifications = ref.watch(
      notificationReadStoreProvider(ownerKey),
    );

    final snapshot = snapshotState.asData?.value;
    final loans = loansState.asData?.value ?? const [];

    // Recolectar todas las alertas activas
    final toolAlerts = snapshot != null
        ? _toolAlertItems(snapshot)
        : const <_AlertItem>[];
    final loanAlerts = _loanAlertItems(loans);
    final allAlerts = [...toolAlerts, ...loanAlerts];

    // Auto-limpiar leídas que ya no corresponden a ninguna alerta activa
    if (snapshot != null) {
      _cleanStaleReads(ref, ownerKey, allAlerts, readNotifications);
    }

    // Solo contar no leídas
    final unreadAlerts = allAlerts.where((alert) {
      return !readNotifications.contains(alert.notificationId);
    }).toList();

    final alertCount = unreadAlerts.length;

    // Color del badge según la criticidad máxima entre las no leídas
    final maxSeverity = unreadAlerts.isEmpty
        ? 0
        : unreadAlerts.map((a) => a.severity).reduce((a, b) => a > b ? a : b);
    final badgeColor = switch (maxSeverity) {
      >= 3 => AppColors.danger,
      >= 2 => AppColors.critical,
      >= 1 => AppColors.warning,
      _ => AppColors.muted,
    };

    return Tooltip(
      message: alertCount > 0
          ? '$alertCount ${alertCount == 1 ? 'alerta' : 'alertas'} pendientes'
          : 'Centro de alertas',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showAlertsModal(context, ref),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surfaceSoftOf(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                alertCount > 0
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none_outlined,
                color: alertCount > 0
                    ? badgeColor
                    : AppColors.textOf(context),
              ),
              if (alertCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.white, width: 1.5),
                    ),
                    child: Text(
                      alertCount > 99 ? '99+' : '$alertCount',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAlertsModal(BuildContext context, WidgetRef ref) async {
    DashboardSnapshot? snapshot;
    List<LoanRecord> loans;
    UserProfile? profile;

    try {
      final results = await Future.wait<Object?>([
        ref.read(dashboardSnapshotProvider.future),
        ref.read(allLoansProvider.future).catchError((_) => <LoanRecord>[]),
        ref.read(currentUserProfileProvider.future).catchError((_) => null),
      ]);

      snapshot = results[0] as DashboardSnapshot?;
      loans = (results[1] as List<LoanRecord>?) ?? const [];
      profile = results[2] as UserProfile?;
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudieron cargar alertas: $error')),
        );
      }

      return;
    }

    if (!context.mounted || snapshot == null) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _NotificationsDialog(
        snapshot: snapshot!,
        loans: loans,
        ownerKey: _notificationOwnerKey(profile),
      ),
    );
  }
}

/// Auto-limpia notificaciones leídas que ya no están activas
void _cleanStaleReads(
  WidgetRef ref,
  String ownerKey,
  List<_AlertItem> activeAlerts,
  Set<String> readSet,
) {
  final activeIds = activeAlerts.map((a) => a.notificationId).toSet();
  final stale = readSet.where((id) => !activeIds.contains(id)).toSet();
  if (stale.isNotEmpty) {
    Future.microtask(() {
      ref
          .read(notificationReadStoreProvider(ownerKey).notifier)
          .removeStale(stale);
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ALERT ITEMS — Unified notification model
// ═══════════════════════════════════════════════════════════════════════════════

class _AlertItem {
  const _AlertItem({
    required this.notificationId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.severity,
    this.toolId,
    this.loanId,
  });

  final String notificationId;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int severity; // 0=info, 1=leve, 2=moderado, 3=crítico
  final String? toolId;
  final String? loanId;
}

List<_AlertItem> _toolAlertItems(DashboardSnapshot snapshot) {
  final items = <_AlertItem>[];

  for (final tool in snapshot.tools) {
    final days = tool.daysToExpiration;
    final state = tool.complianceState;
    final cal = tool.latestCalibration;

    // Vencido
    if (state == ComplianceState.expired) {
      final id = 'tool:${tool.id}:expired:${cal?.expirationDate?.toIso8601String().split('T').first ?? 'sin-fecha'}';
      items.add(_AlertItem(
        notificationId: id,
        title: 'Calibración vencida',
        subtitle: tool.displayName,
        icon: Icons.error_outline,
        color: AppColors.danger,
        severity: 3,
        toolId: tool.id,
      ));
    }
    // Crítico (1-15 días)
    else if (state == ComplianceState.warning) {
      final id = 'tool:${tool.id}:warning:${cal?.expirationDate?.toIso8601String().split('T').first ?? 'sin-fecha'}';
      items.add(_AlertItem(
        notificationId: id,
        title: 'Vence en ${days ?? 0} días',
        subtitle: tool.displayName,
        icon: Icons.warning_amber_outlined,
        color: AppColors.critical,
        severity: 2,
        toolId: tool.id,
      ));
    }
    // Alerta (16-30 días)
    else if (state == ComplianceState.grace) {
      final id = 'tool:${tool.id}:grace:${cal?.expirationDate?.toIso8601String().split('T').first ?? 'sin-fecha'}';
      items.add(_AlertItem(
        notificationId: id,
        title: 'Próximo a vencer (${days ?? 0}d)',
        subtitle: tool.displayName,
        icon: Icons.notifications_outlined,
        color: AppColors.warning,
        severity: 1,
        toolId: tool.id,
      ));
    }
    // Sin calibración
    else if (state == ComplianceState.withoutCalibration) {
      final id = 'tool:${tool.id}:withoutCal';
      items.add(_AlertItem(
        notificationId: id,
        title: 'Sin calibración registrada',
        subtitle: tool.displayName,
        icon: Icons.help_outline,
        color: AppColors.muted,
        severity: 1,
        toolId: tool.id,
      ));
    }

    // Con calibración pero sin certificado PDF (independiente del estado)
    if (cal != null &&
        cal.certificateNumber == null &&
        state != ComplianceState.withoutCalibration) {
      final id = 'tool:${tool.id}:noCert:${cal.calibrationDate.toIso8601String().split('T').first}';
      // Evitar duplicados si ya se generó otra alerta para esta herramienta
      if (!items.any((item) => item.toolId == tool.id && item.notificationId.contains(':noCert:'))) {
        items.add(_AlertItem(
          notificationId: id,
          title: 'Certificado PDF pendiente',
          subtitle: tool.displayName,
          icon: Icons.picture_as_pdf_outlined,
          color: AppColors.muted,
          severity: 0,
          toolId: tool.id,
        ));
      }
    }
  }

  // Ordenar por severidad descendente
  items.sort((a, b) {
    final cmp = b.severity.compareTo(a.severity);
    if (cmp != 0) return cmp;
    return a.subtitle.compareTo(b.subtitle);
  });

  return items;
}

List<_AlertItem> _loanAlertItems(List<LoanRecord> loans) {
  return loans
      .where((loan) => loan.isOverdue)
      .map((loan) => _AlertItem(
            notificationId: 'loan:${loan.id}:overdue:${loan.expectedReturnDate?.toIso8601String().split('T').first ?? 'sin-fecha'}',
            title: 'Préstamo vencido',
            subtitle: '${loan.toolName} · ${loan.borrowerName ?? ''}',
            icon: Icons.assignment_late_outlined,
            color: AppColors.danger,
            severity: 2,
            loanId: loan.id,
            toolId: loan.toolId,
          ))
      .toList()
    ..sort((a, b) => a.subtitle.compareTo(b.subtitle));
}

// ═══════════════════════════════════════════════════════════════════════════════
// ALERTS MODAL — Solo notificaciones no leídas
// ═══════════════════════════════════════════════════════════════════════════════

class _NotificationsDialog extends ConsumerWidget {
  const _NotificationsDialog({
    required this.snapshot,
    required this.loans,
    required this.ownerKey,
  });

  final DashboardSnapshot snapshot;
  final List<LoanRecord> loans;
  final String ownerKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readNotifications = ref.watch(
      notificationReadStoreProvider(ownerKey),
    );

    final toolAlerts = _toolAlertItems(snapshot);
    final loanAlerts = _loanAlertItems(loans);
    final allAlerts = [...toolAlerts, ...loanAlerts];

    // Solo mostrar no leídas
    final unreadAlerts = allAlerts.where((alert) {
      return !readNotifications.contains(alert.notificationId);
    }).toList();

    // Contar por tipo para el resumen
    final expiredCount =
        unreadAlerts.where((a) => a.severity >= 3).length;
    final warningCount =
        unreadAlerts.where((a) => a.severity == 2).length;
    final infoCount =
        unreadAlerts.where((a) => a.severity <= 1).length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: unreadAlerts.isEmpty
                          ? AppColors.tintOf(context, AppColors.success)
                          : AppColors.tintOf(context, AppColors.danger),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      unreadAlerts.isEmpty
                          ? Icons.check_circle_outline
                          : Icons.notifications_active_outlined,
                      color: unreadAlerts.isEmpty
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Centro de alertas',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: AppColors.textOf(context),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          unreadAlerts.isEmpty
                              ? 'Todo bajo control'
                              : '${unreadAlerts.length} pendientes',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.subduedOf(context),
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Resumen de severidad
              if (unreadAlerts.isNotEmpty) ...[
                Row(
                  children: [
                    if (expiredCount > 0)
                      _SeverityChip(
                        label: '$expiredCount vencidas',
                        color: AppColors.danger,
                        icon: Icons.error_outline,
                      ),
                    if (warningCount > 0) ...[
                      if (expiredCount > 0) const SizedBox(width: 8),
                      _SeverityChip(
                        label: '$warningCount urgentes',
                        color: AppColors.critical,
                        icon: Icons.warning_amber_outlined,
                      ),
                    ],
                    if (infoCount > 0) ...[
                      if (expiredCount > 0 || warningCount > 0)
                        const SizedBox(width: 8),
                      _SeverityChip(
                        label: '$infoCount avisos',
                        color: AppColors.warning,
                        icon: Icons.info_outline,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      unawaited(
                        ref
                            .read(
                              notificationReadStoreProvider(ownerKey).notifier,
                            )
                            .markManyAsRead(
                              unreadAlerts.map((a) => a.notificationId),
                            ),
                      );
                    },
                    icon: const Icon(Icons.done_all_outlined, size: 16),
                    label: const Text('Marcar todo como leído'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // Lista o vacío
              if (unreadAlerts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.tintOf(context, AppColors.success,
                        lightAlpha: 0.06, darkAlpha: 0.10),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.verified_outlined,
                          color: AppColors.success, size: 40),
                      const SizedBox(height: 10),
                      Text(
                        'Sin alertas pendientes',
                        style: TextStyle(
                          color: AppColors.textOf(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'El inventario está bajo control. Las alertas '
                        'atendidas se reflejan en el dashboard.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.subduedOf(context),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final alert = unreadAlerts[index];

                      return _NotificationTile(
                        alert: alert,
                        onTap: () {
                          // Marcar como leída
                          unawaited(
                            ref
                                .read(
                                  notificationReadStoreProvider(ownerKey)
                                      .notifier,
                                )
                                .markAsRead(alert.notificationId),
                          );

                          final router = GoRouter.of(context);
                          Navigator.of(context).pop();

                          // Navegar al destino correcto
                          if (alert.toolId != null) {
                            router.go(AppRoutes.toolDetail(alert.toolId!));
                          } else if (alert.loanId != null) {
                            router.go(AppRoutes.loans);
                          }
                        },
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemCount: unreadAlerts.length,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.alert, required this.onTap});

  final _AlertItem alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoftOf(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.tintOf(
              context,
              alert.color,
              lightAlpha: 0.36,
              darkAlpha: 0.42,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.tintOf(context, alert.color),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(alert.icon, color: alert.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: TextStyle(
                      color: AppColors.textOf(context),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    alert.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.subduedOf(context),
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.subduedOf(context)),
          ],
        ),
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.tintOf(context, color, lightAlpha: 0.10, darkAlpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

String _notificationOwnerKey(UserProfile? profile) {
  final candidates = [
    profile?.authUserId,
    profile?.id,
    profile?.email,
    'anonymous',
  ];
  return candidates.firstWhere((value) => value != null && value.isNotEmpty)!;
}

class _ThemeCycleButton extends ConsumerWidget {
  const _ThemeCycleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesProvider);
    final mode = preferences.visualMode;

    return Tooltip(
      message: 'Modo ${mode.label}. Click para cambiar.',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => ref
            .read(appPreferencesProvider.notifier)
            .setVisualMode(_nextMode(mode)),
        child: _TopbarActionShell(
          child: Icon(mode.icon, color: AppColors.textOf(context)),
        ),
      ),
    );
  }

  AppVisualMode _nextMode(AppVisualMode current) {
    return switch (current) {
      AppVisualMode.light => AppVisualMode.dark,
      AppVisualMode.dark => AppVisualMode.classic,
      AppVisualMode.classic => AppVisualMode.light,
    };
  }
}

class _LanguageMenuButton extends ConsumerWidget {
  const _LanguageMenuButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appPreferencesProvider).language;

    return PopupMenuButton<AppLanguage>(
      tooltip: 'Idioma web',
      offset: const Offset(0, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: (value) {
        ref.read(appPreferencesProvider.notifier).setLanguage(value);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Idioma: ${_languageCode(value)}'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            width: 200,
          ));
        }
      },
      itemBuilder: (context) => [
        for (final item in [AppLanguage.spanish, AppLanguage.english])
          PopupMenuItem(
            value: item,
            child: Row(
              children: [
                if (item == language)
                  const Icon(Icons.check, color: AppColors.actionBlue)
                else
                  const SizedBox(width: 24),
                const SizedBox(width: 8),
                Text(_languageCode(item)),
              ],
            ),
          ),
      ],
      child: _TopbarActionShell(
        child: Text(
          _languageCode(language),
          style: TextStyle(
            color: AppColors.textOf(context),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  String _languageCode(AppLanguage language) {
    return switch (language) {
      AppLanguage.spanish => 'ES',
      AppLanguage.english => 'EN',
      AppLanguage.portuguese => 'PT',
      AppLanguage.french => 'FR',
    };
  }
}

class _TopbarActionShell extends StatelessWidget {
  const _TopbarActionShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoftOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _UserMenu extends ConsumerWidget {
  const _UserMenu({required this.profileState});

  final AsyncValue<UserProfile?> profileState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = profileState.when(
      data: (value) => value,
      error: (_, _) => null,
      loading: () => null,
    );
    final label = profile == null
        ? 'Sesion activa'
        : '${profile.displayName} - ${profile.role.label}';

    return PopupMenuButton<String>(
      tooltip: 'Menu de usuario',
      offset: const Offset(0, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: (value) async {
        if (value == 'profile') {
          await _openProfileDialog(context, profile);
          return;
        }

        if (value != 'logout') {
          return;
        }

        await ref.read(authRepositoryProvider).signOut();

        if (context.mounted) {
          context.go(AppRoutes.login);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: _UserMenuHeader(label: label, profile: profile),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.manage_accounts_outlined),
              SizedBox(width: 10),
              Text('Mi perfil y preferencias'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_outlined),
              SizedBox(width: 10),
              Text('Cerrar sesion'),
            ],
          ),
        ),
      ],
      child: _ProfileDock(profile: profile, isLoading: profileState.isLoading),
    );
  }

  Future<void> _openProfileDialog(
    BuildContext context,
    UserProfile? profile,
  ) async {
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil aun no disponible.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ProfileSettingsCard(profile: profile),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileDock extends StatelessWidget {
  const _ProfileDock({required this.profile, required this.isLoading});

  final UserProfile? profile;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoftOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.actionBlue.withValues(
              alpha: AppColors.isDark(context) ? 0.20 : 0.10,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _AvatarContent(profile: profile, isLoading: isLoading),
      ),
    );
  }
}

class _AvatarContent extends StatelessWidget {
  const _AvatarContent({required this.profile, required this.isLoading});

  final UserProfile? profile;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final avatarUrl = profile?.avatarUrl;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return Image.network(
        avatarUrl,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _InitialsAvatar(initials: profile?.initials ?? 'U');
        },
      );
    }

    return _InitialsAvatar(initials: profile?.initials ?? 'U');
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tintOf(context, AppColors.actionBlue),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.actionBlue,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _UserMenuHeader extends StatelessWidget {
  const _UserMenuHeader({required this.label, required this.profile});

  final String label;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 42,
              height: 42,
              child: _AvatarContent(profile: profile, isLoading: false),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textOf(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
