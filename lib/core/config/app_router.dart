import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_refresh_listenable.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/reset_password_page.dart';
import '../../features/calibrations/presentation/calibration_form_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/loans/presentation/loans_page.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/shipments/presentation/shipment_form_page.dart';
import '../../features/shipments/presentation/shipments_page.dart';
import '../../features/tools/presentation/tool_detail_page.dart';
import '../../features/tools/presentation/tool_form_page.dart';
import '../../features/tools/presentation/tools_inventory_page.dart';
import '../../features/users/presentation/users_admin_page.dart';
import '../constants/app_routes.dart';
import '../widgets/app_shell.dart';
import 'supabase_config.dart';

final AuthRefreshListenable _authRefreshListenable = AuthRefreshListenable();

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.dashboard,
  refreshListenable: _authRefreshListenable,
  redirect: (BuildContext context, GoRouterState state) {
    final isLoginRoute = state.uri.path == AppRoutes.login;
    final isResetPasswordRoute =
        state.uri.path == AppRoutes.resetPassword;
    final isSupabaseReady = SupabaseConfig.runtimeInfo.isReady;
    final isAuthenticated = _authRefreshListenable.isAuthenticated;

    if (!isSupabaseReady) {
      return isLoginRoute || isResetPasswordRoute ? null : AppRoutes.login;
    }

    if (!isAuthenticated) {
      return isLoginRoute || isResetPasswordRoute ? null : AppRoutes.login;
    }

    if (isLoginRoute) {
      return AppRoutes.dashboard;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (BuildContext context, GoRouterState state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.resetPassword,
      builder: (BuildContext context, GoRouterState state) =>
          const ResetPasswordPage(),
    ),
    GoRoute(
      path: AppRoutes.home,
      redirect: (BuildContext context, GoRouterState state) =>
          AppRoutes.dashboard,
    ),
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return AppShell(selectedLocation: state.uri.path, child: child);
      },
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (BuildContext context, GoRouterState state) =>
              const DashboardPage(),
        ),
        GoRoute(
          path: AppRoutes.tools,
          builder: (BuildContext context, GoRouterState state) =>
              const ToolsInventoryPage(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (BuildContext context, GoRouterState state) =>
                  const ToolFormPage(),
            ),
            GoRoute(
              path: 'retired',
              builder: (BuildContext context, GoRouterState state) =>
                  const ToolsInventoryPage(showRetired: true),
            ),
            GoRoute(
              path: 'quarantine',
              builder: (BuildContext context, GoRouterState state) =>
                  const ToolsInventoryPage(showQuarantine: true),
            ),
            GoRoute(
              path: ':id',
              builder: (BuildContext context, GoRouterState state) {
                final id = state.pathParameters['id'] ?? '';
                return ToolDetailPage(toolId: id);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (BuildContext context, GoRouterState state) {
                    final id = state.pathParameters['id'] ?? '';
                    return ToolFormPage(toolId: id);
                  },
                ),
                GoRoute(
                  path: 'calibrations/new',
                  builder: (BuildContext context, GoRouterState state) {
                    final id = state.pathParameters['id'] ?? '';
                    return CalibrationFormPage(toolId: id);
                  },
                ),
                GoRoute(
                  path: 'calibrations/:calibrationId/edit',
                  builder: (BuildContext context, GoRouterState state) {
                    final toolId = state.pathParameters['id'] ?? '';
                    final calibrationId =
                        state.pathParameters['calibrationId'] ?? '';
                    return CalibrationFormPage(
                      toolId: toolId,
                      calibrationId: calibrationId,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.shipments,
          builder: (BuildContext context, GoRouterState state) =>
              const ShipmentsPage(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (BuildContext context, GoRouterState state) =>
                  const ShipmentFormPage(),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.loans,
          builder: (BuildContext context, GoRouterState state) =>
              const LoansPage(),
        ),
        GoRoute(
          path: AppRoutes.reports,
          builder: (BuildContext context, GoRouterState state) =>
              const ReportsPage(),
        ),
        GoRoute(
          path: AppRoutes.users,
          builder: (BuildContext context, GoRouterState state) =>
              const UsersAdminPage(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (BuildContext context, GoRouterState state) =>
              const SettingsPage(),
        ),
      ],
    ),
  ],
);
