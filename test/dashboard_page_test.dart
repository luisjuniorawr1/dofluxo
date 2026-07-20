import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dofluxo/core/agency/agency_context.dart';
import 'package:dofluxo/presentation/dashboard/pages/dashboard_page.dart';
import 'package:dofluxo/presentation/projects/manager/project_service.dart';

void main() {
  testWidgets('Dashboard renders reorganized wireframe zones', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AgencyContext()),
          Provider<ProjectService>(
            create: (_) => ProjectService(agencyId: 'test-agency'),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DashboardPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Postagens do dia'), findsOneWidget);
    expect(find.text('Jobs'), findsOneWidget);
    expect(find.text('Incêndio'), findsOneWidget);
    expect(find.textContaining('Produção'), findsOneWidget);
    expect(find.textContaining('Aprovação'), findsOneWidget);
    expect(find.textContaining('Concluídos'), findsOneWidget);
    expect(find.textContaining('Status do Planejamento'), findsOneWidget);
    expect(find.textContaining('Espelho · atrasados'), findsNothing);
    expect(find.text('Em breve'), findsNothing);
    expect(find.text('Novo Projeto'), findsOneWidget);
    expect(find.text('Configurações'), findsNothing);
    expect(find.textContaining('Seja bem vindo'), findsOneWidget);
    expect(find.text('Exibir:'), findsOneWidget);
  });
}
