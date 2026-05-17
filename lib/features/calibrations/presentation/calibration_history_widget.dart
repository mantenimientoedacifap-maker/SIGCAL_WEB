import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';

class CalibrationHistoryWidget extends StatelessWidget {
  const CalibrationHistoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      title: 'Sin historial de calibraciones',
      message:
          'El historial se mostrara cuando existan calibraciones registradas para el equipo seleccionado.',
      icon: Icons.history_outlined,
    );
  }
}
