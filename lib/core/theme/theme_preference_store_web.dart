/// Persistencia de tema na web via localStorage (sem shared_preferences).
library;

import 'dart:convert';

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'theme_preference_store.dart';

String? _readLocalStorageKey(String key) {
  try {
    return html.window.localStorage[key];
  } catch (_) {
    return null;
  }
}

String? _readLegacySharedPreferencesValue(String key) {
  final raw = _readLocalStorageKey('flutter.$key');
  if (raw == null || raw.isEmpty) return null;

  try {
    final decoded = jsonDecode(raw);
    if (decoded is String && decoded.isNotEmpty) return decoded;
  } catch (_) {
    return raw;
  }

  return null;
}

Future<String?> readThemeMode() async {
  final stored = _readLocalStorageKey(ThemePreferenceStore.storageKey);
  if (stored == 'dark' || stored == 'light' || stored == 'system') {
    return stored;
  }

  final legacy = _readLegacySharedPreferencesValue(
    ThemePreferenceStore.legacySharedPreferencesKey,
  );
  if (legacy == 'dark' || legacy == 'light' || legacy == 'system') {
    return legacy;
  }

  return null;
}

Future<void> writeThemeMode(String value) async {
  html.window.localStorage[ThemePreferenceStore.storageKey] = value;
}
