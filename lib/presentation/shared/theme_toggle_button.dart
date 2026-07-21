import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, this.iconColor});

  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return IconButton(
      tooltip: isDark ? 'Ativar tema claro' : 'Ativar tema escuro',
      onPressed: themeProvider.toggleTheme,
      icon: Icon(
        // Ícone = ação (lua para ir ao escuro, sol para ir ao claro).
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        color: iconColor,
      ),
    );
  }
}
