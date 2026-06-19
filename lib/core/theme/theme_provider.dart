import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  Color _primaryColor = const Color(0xFFFFD700);
  String _agencyName = 'Pequi';
  ThemeMode _themeMode = ThemeMode.light;

  Color get primaryColor => _primaryColor;
  String get agencyName => _agencyName.trim().isNotEmpty ? _agencyName.trim() : 'Pequi';
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void updateColor(Color newColor) {
    _primaryColor = newColor;
    notifyListeners();
  }

  void updateAgencyName(String name) {
    _agencyName = name.trim().isNotEmpty ? name.trim() : 'Pequi';
    notifyListeners();
  }

  void applySettings({Color? primaryColor, String? agencyName}) {
    if (primaryColor != null) _primaryColor = primaryColor;
    if (agencyName != null) {
      _agencyName = agencyName.trim().isNotEmpty ? agencyName.trim() : 'Pequi';
    }
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
