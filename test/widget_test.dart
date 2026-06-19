import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dofluxo/core/theme/theme_provider.dart';
import 'package:dofluxo/main.dart';

void main() {
  testWidgets('Login page smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const DofluxoApp(),
      ),
    );

    expect(find.text('Continuar com Google'), findsOneWidget);
  });
}
