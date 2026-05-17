import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sigcal/app.dart';

void main() {
  testWidgets('SIGCAL redirects unauthenticated users to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SigecalApp()));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesion'), findsOneWidget);
    expect(find.text('Sistema de Gestion de Calibracion'), findsOneWidget);
  });
}
