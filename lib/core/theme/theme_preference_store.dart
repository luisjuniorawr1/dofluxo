import 'theme_preference_store_stub.dart'
    if (dart.library.html) 'theme_preference_store_web.dart'
    as impl;

/// Persistência local da preferência claro/escuro (sobrevive a reload/deploy).
class ThemePreferenceStore {
  ThemePreferenceStore._();

  static const storageKey = 'dofluxo_theme_mode';
  static const legacySharedPreferencesKey = 'theme_mode';

  static Future<String?> read() => impl.readThemeMode();

  static Future<void> write(String value) => impl.writeThemeMode(value);
}
