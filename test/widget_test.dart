import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dofluxo/core/agency/agency_context.dart';
import 'package:dofluxo/presentation/agency/pages/agency_onboarding_page.dart';

void main() {
  testWidgets('Agency onboarding wizard smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AgencyContext(),
        child: const MaterialApp(home: AgencyOnboardingPage()),
      ),
    );

    expect(find.text('Configure sua agência'), findsOneWidget);
    expect(find.text('Criar agência'), findsOneWidget);
  });
}
