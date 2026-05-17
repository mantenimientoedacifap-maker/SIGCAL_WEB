import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({this.message = 'Cargando informacion...', super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.actionBlue),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }
}
