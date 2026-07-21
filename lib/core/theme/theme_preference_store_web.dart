/// Persistência de tema na web via localStorage (escrita síncrona).
library;

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:shared_preferences/shared_preferences.dart';

import 'theme_preference_store.dart';

Future<String?> readThemeMode() async {
  try {
    final stored = html.window.localStorage[ThemePreferenceStore.storageKey];
    if (stored == 'dark' || stored == 'light' || stored == 'system') {
      return stored;
    }
  } catch (_) {}

  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(ThemePreferenceStore.storageKey) ??
      prefs.getString(ThemePreferenceStore.legacySharedPreferencesKey);
}

Future<void> writeThemeMode(String value) async {
  try {
    html.window.localStorage[ThemePreferenceStore.storageKey] = value;
  } catch (_) {}

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(ThemePreferenceStore.storageKey, value);
}
