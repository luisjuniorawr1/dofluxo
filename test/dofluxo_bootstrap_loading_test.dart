import 'package:dofluxo/presentation/shared/config/bootstrap_loading_messages.dart';
import 'package:dofluxo/presentation/shared/widgets/dofluxo_bootstrap_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DofluxoBootstrapLoading exibe ícone e texto lado a lado', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DofluxoBootstrapLoading()));

    final first = BootstrapLoadingMessages.messages.first;
    expect(find.byIcon(first.icon), findsOneWidget);
    expect(find.text(first.text), findsOneWidget);
  });

  testWidgets('DofluxoBootstrapLoading avança para a próxima mensagem', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DofluxoBootstrapLoading()));

    expect(find.text('Reunindo a equipe...'), findsOneWidget);

    await tester.pump(BootstrapLoadingMessages.rotationInterval);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Organizando os briefings...'), findsOneWidget);
  });

  test('BootstrapLoadingMessages contém exatamente 6 frases', () {
    expect(BootstrapLoadingMessages.messages, hasLength(6));
    expect(
      BootstrapLoadingMessages.messages.first.text,
      'Reunindo a equipe...',
    );
    expect(
      BootstrapLoadingMessages.messages.last.text,
      'Organizando o fluxo da agência...',
    );
  });
}
