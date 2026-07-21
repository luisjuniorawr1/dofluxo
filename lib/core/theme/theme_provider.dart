import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'theme_preference_store.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({ThemeMode initialThemeMode = ThemeMode.light})
    : _themeMode = initialThemeMode;

  Color _primaryColor = const Color(0xFFFFD700);
  String _agencyName = 'Pequi';
  ThemeMode _themeMode;

  ThemeData? _lightTheme;
  ThemeData? _darkTheme;
  Color? _themesPrimaryColor;

  Color get primaryColor => _primaryColor;
  String get agencyName =>
      _agencyName.trim().isNotEmpty ? _agencyName.trim() : 'Pequi';
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeData get lightTheme {
    _ensureThemes();
    return _lightTheme!;
  }

  ThemeData get darkTheme {
    _ensureThemes();
    return _darkTheme!;
  }

  /// Carrega preferência local de tema (sobrevive a deploy/reload).
  static Future<ThemeProvider> create() async {
    final stored = await ThemePreferenceStore.read();
    final mode = switch (stored) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    return ThemeProvider(initialThemeMode: mode);
  }

  void _ensureThemes() {
    if (_lightTheme != null && _themesPrimaryColor == _primaryColor) return;

    _themesPrimaryColor = _primaryColor;
    _lightTheme = AppTheme.build(
      primaryColor: _primaryColor,
      brightness: Brightness.light,
    );
    _darkTheme = AppTheme.build(
      primaryColor: _primaryColor,
      brightness: Brightness.dark,
    );
  }

  void _invalidateThemes() {
    _lightTheme = null;
    _darkTheme = null;
    _themesPrimaryColor = null;
  }

  Future<void> _persistThemeMode() async {
    final value = switch (_themeMode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
    };
    await ThemePreferenceStore.write(value);
  }

  void updateColor(Color newColor) {
    _primaryColor = newColor;
    _invalidateThemes();
    notifyListeners();
  }

  void updateAgencyName(String name) {
    _agencyName = name.trim().isNotEmpty ? name.trim() : 'Pequi';
    notifyListeners();
  }

  void applySettings({Color? primaryColor, String? agencyName}) {
    if (primaryColor != null) {
      _primaryColor = primaryColor.withValues(alpha: 1);
      _invalidateThemes();
    }
    if (agencyName != null) {
      _agencyName = agencyName.trim().isNotEmpty ? agencyName.trim() : 'Pequi';
    }
    notifyListeners();
  }

  /// Branding da agência ativa (`agencies/{activeAgencyId}`).
  void applyAgencyBranding({required String name, required Color color}) {
    applySettings(primaryColor: color, agencyName: name);
  }

  /// Reseta só branding (logout/troca de conta). Mantém tema claro/escuro.
  void resetToDefaults() {
    applySettings(primaryColor: const Color(0xFFFFD700), agencyName: 'Pequi');
  }

  Future<void> toggleTheme() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    await _persistThemeMode();
  }
}
