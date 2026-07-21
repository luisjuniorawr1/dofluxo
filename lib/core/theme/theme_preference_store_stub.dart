/// Persistência de tema fora da web (SharedPreferences).
library;

import 'package:shared_preferences/shared_preferences.dart';

import 'theme_preference_store.dart';

Future<String?> readThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(ThemePreferenceStore.storageKey) ??
      prefs.getString(ThemePreferenceStore.legacySharedPreferencesKey);
}

Future<void> writeThemeMode(String value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(ThemePreferenceStore.storageKey, value);
}
