/// Implementação no-op para plataformas não-web (Android/iOS/desktop).
library;

bool get versionCheckSupported => false;

Future<String?> fetchRemoteAppVersion() async => null;

String? readAcceptedVersion() => null;

void clearAcceptedVersion() {}

bool shouldSkipUpdateOnce() => false;

void clearSkipUpdateOnce() {}

void registerRevalidationTriggers(void Function() onTrigger) {}

void stripReloadBustFromUrl() {}

void reloadApp({String? acceptedVersion}) {}
