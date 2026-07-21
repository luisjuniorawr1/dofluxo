/// Implementação web da checagem de versão publicada.
library;

import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'app_update_logic.dart';

const _kAcceptedVersionKey = 'dofluxo_accepted_version';
const _kSkipOnceKey = 'dofluxo_skip_update_once';

/// Indica se a checagem de versão é suportada nesta plataforma.
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

/// Após clicar em "Atualizar", a próxima carga da página ignora o aviso de versão.
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

/// Recarrega a página imediatamente (100% síncrono).
///
/// Antes esperávamos limpar Cache API / Service Worker — isso podia travar
/// para sempre e o overlay nunca sumia. Agora só grava o flag e navega.
void reloadApp({String? acceptedVersion}) {
  try {
    html.window.sessionStorage[_kSkipOnceKey] = '1';
    if (acceptedVersion != null && acceptedVersion.isNotEmpty) {
      html.window.sessionStorage[_kAcceptedVersionKey] = acceptedVersion;
    }
  } catch (_) {}

  final ts = DateTime.now().millisecondsSinceEpoch;
  // origin absoluto evita problemas com base href do Flutter.
  html.window.location.href = '${html.window.location.origin}/?_r=$ts';
}
