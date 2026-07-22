/// Implementação web da checagem de versão publicada.
library;

import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'app_update_logic.dart';

const _kAcceptedVersionKey = 'dofluxo_accepted_version';
const _kSkipOnceKey = 'dofluxo_skip_update_once';

StreamSubscription<html.MouseEvent>? _clickSub;
StreamSubscription<html.KeyboardEvent>? _keySub;
StreamSubscription<html.Event>? _focusSub;

bool get versionCheckSupported => true;

String? readAcceptedVersion() {
  try {
    return html.window.sessionStorage[_kAcceptedVersionKey];
  } catch (_) {
    return null;
  }
}

void clearAcceptedVersion() {
  try {
    html.window.sessionStorage.remove(_kAcceptedVersionKey);
  } catch (_) {}
}

/// Após "Atualizar agora" / auto-reload, a próxima carga ignora o aviso.
bool shouldSkipUpdateOnce() {
  try {
    return html.window.sessionStorage[_kSkipOnceKey] == '1';
  } catch (_) {
    return false;
  }
}

void clearSkipUpdateOnce() {
  try {
    html.window.sessionStorage.remove(_kSkipOnceKey);
  } catch (_) {}
}

/// URL canônica: `origin/` — sem query, hash ou path extra.
String get _canonicalUrl => '${html.window.location.origin}/';

bool get _urlIsDirty {
  try {
    final loc = html.window.location;
    final path = loc.pathname ?? '/';
    final search = loc.search ?? '';
    final hash = loc.hash ?? '';
    return path != '/' || search.isNotEmpty || hash.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// Limpa a barra de endereço via replaceState (sem reload).
void cleanBrowserUrl() {
  try {
    if (!_urlIsDirty) return;
    html.window.history.replaceState(null, '', _canonicalUrl);
  } catch (_) {}
}

/// Limpa no boot e de novo em qualquer interação do usuário.
void registerUrlCleaningTriggers() {
  cleanBrowserUrl();
  _clickSub ??= html.document.onClick.listen((_) => cleanBrowserUrl());
  _keySub ??= html.document.onKeyDown.listen((_) => cleanBrowserUrl());
  _focusSub ??= html.window.onFocus.listen((_) => cleanBrowserUrl());
}

Future<String?> fetchRemoteAppVersion() async {
  try {
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    final response = await html.HttpRequest.request(
      '/version.json?t=$cacheBuster&r=${html.window.performance.now().round()}',
      method: 'GET',
      requestHeaders: const {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Accept': 'application/json',
      },
    );

    if (response.status != 200) return null;

    final body = response.responseText;
    if (body == null || body.isEmpty) return null;

    final trimmed = body.trimLeft();
    if (trimmed.startsWith('<')) return null;

    final decoded = jsonDecode(body);
    if (decoded is! Map) return null;

    return normalizeVersionJson(Map<String, dynamic>.from(decoded));
  } catch (_) {
    return null;
  }
}

void registerRevalidationTriggers(void Function() onTrigger) {
  html.window.onFocus.listen((_) => onTrigger());
  html.document.onVisibilityChange.listen((_) {
    if (html.document.visibilityState == 'visible') {
      onTrigger();
    }
  });
}

/// Recarrega a página na URL limpa (sem ?_r=). Bust via headers no-cache.
void reloadApp({String? acceptedVersion}) {
  try {
    html.window.sessionStorage[_kSkipOnceKey] = '1';
    if (acceptedVersion != null && acceptedVersion.isNotEmpty) {
      html.window.sessionStorage[_kAcceptedVersionKey] = acceptedVersion;
    }
  } catch (_) {}

  html.window.location.replace(_canonicalUrl);
}
