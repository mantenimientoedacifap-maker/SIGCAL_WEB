import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class RouteLoadingGate extends StatefulWidget {
  const RouteLoadingGate({
    required this.routeKey,
    required this.child,
    super.key,
  });

  final String routeKey;
  final Widget child;

  @override
  State<RouteLoadingGate> createState() => _RouteLoadingGateState();
}

class _RouteLoadingGateState extends State<RouteLoadingGate> {
  Timer? _timer;
  bool _loading = false;

  @override
  void didUpdateWidget(covariant RouteLoadingGate oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.routeKey == widget.routeKey) {
      return;
    }

    _timer?.cancel();
    setState(() => _loading = true);
    _timer = Timer(const Duration(milliseconds: 360), () {
      if (!mounted) {
        return;
      }

      setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return currentChild ?? const SizedBox.shrink();
      },
      child: _loading
          ? const _TransitionLoadingCard(key: ValueKey('route-loading'))
          : KeyedSubtree(key: ValueKey(widget.routeKey), child: widget.child),
    );
  }
}

class _TransitionLoadingCard extends StatelessWidget {
  const _TransitionLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 420),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppColors.softShadowOf(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.tintOf(context, AppColors.actionBlue),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.actionBlue),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Preparando tablero...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textOf(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sincronizando vista y datos del modulo.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.subduedOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
