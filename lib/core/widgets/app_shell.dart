import 'package:flutter/material.dart';

import 'app_sidebar.dart';
import 'app_topbar.dart';
import 'route_loading_gate.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.child,
    required this.selectedLocation,
    super.key,
  });

  final Widget child;
  final String selectedLocation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;

        return Scaffold(
          drawer: isDesktop
              ? null
              : Drawer(child: AppSidebar(selectedLocation: selectedLocation)),
          body: Builder(
            builder: (context) {
              return Row(
                children: [
                  if (isDesktop)
                    SizedBox(
                      width: 286,
                      child: AppSidebar(selectedLocation: selectedLocation),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        AppTopbar(
                          selectedLocation: selectedLocation,
                          onMenuPressed: isDesktop
                              ? null
                              : () => Scaffold.of(context).openDrawer(),
                        ),
                        Expanded(
                          child: ColoredBox(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 24 : 16,
                                vertical: isDesktop ? 16 : 14,
                              ),
                              child: RouteLoadingGate(
                                routeKey: selectedLocation,
                                child: child,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
