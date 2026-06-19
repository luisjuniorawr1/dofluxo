import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dofluxo/presentation/dashboard/pages/dashboard_page.dart';

void main() {
  testWidgets('Dashboard renders workflow columns from reference layout', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: DashboardPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Postagens do dia'), findsOneWidget);
    expect(find.text('Criação'), findsOneWidget);
    expect(find.text('INCÊNDIOS'), findsOneWidget);
    expect(find.text('Captação'), findsOneWidget);
    expect(find.text('Edição'), findsOneWidget);
    expect(find.text('Aprovação'), findsOneWidget);
    expect(find.text('Status do Projeto'), findsOneWidget);
    expect(find.text('Novo Projeto'), findsOneWidget);
    expect(find.text('Configurações'), findsOneWidget);
    expect(find.textContaining('Seja bem vindo'), findsOneWidget);
  });
}
