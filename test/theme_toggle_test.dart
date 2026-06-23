import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dofluxo/core/theme/theme_provider.dart';
import 'package:dofluxo/presentation/shared/theme_toggle_button.dart';

void main() {
  testWidgets('Theme toggle switches between light and dark mode', (tester) async {
    final themeProvider = ThemeProvider();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeProvider.themeMode,
        home: ChangeNotifierProvider.value(
          value: themeProvider,
          child: const Scaffold(
            body: ThemeToggleButton(),
          ),
        ),
      ),
    );

    expect(themeProvider.isDarkMode, isFalse);
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(themeProvider.isDarkMode, isTrue);
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
  });
}
