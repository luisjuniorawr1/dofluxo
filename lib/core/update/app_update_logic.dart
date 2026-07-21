/// Lógica pura (sem dependência de plataforma) para decidir atualização.
///
/// Testável isoladamente em `test/app_update_logic_test.dart`.
library;

/// Normaliza o conteúdo de `version.json` (gerado pelo build do Flutter)
/// para uma string comparável no formato `x.y.z+build`.
///
/// Retorna `null` se não houver campo de versão utilizável.
String? normalizeVersionJson(Map<String, dynamic> versionJson) {
  final rawVersion = versionJson['version'];
  if (rawVersion == null) return null;

  final version = rawVersion.toString().trim();
  if (version.isEmpty) return null;

  final rawBuild = versionJson['build_number'];
  final build = rawBuild?.toString().trim();
  if (build == null || build.isEmpty) return version;

  return '$version+$build';
}

/// Período de graça antes da atualização automática (web).
const Duration kUpdateGracePeriod = Duration(minutes: 5);

/// Tempo restante até a atualização automática.
Duration remainingGracePeriod({
  required DateTime detectedAt,
  required DateTime now,
  Duration gracePeriod = kUpdateGracePeriod,
}) {
  final elapsed = now.difference(detectedAt);
  final remaining = gracePeriod - elapsed;
  if (remaining.isNegative) return Duration.zero;
  return remaining;
}

/// Verdadeiro quando o período de graça expirou e a atualização deve ocorrer.
bool shouldAutoReload({
  required DateTime detectedAt,
  required DateTime now,
  Duration gracePeriod = kUpdateGracePeriod,
}) {
  return remainingGracePeriod(
        detectedAt: detectedAt,
        now: now,
        gracePeriod: gracePeriod,
      ) ==
      Duration.zero;
}

/// Formata contagem regressiva como `M:SS` (ex.: `4:32`).
String formatGraceCountdown(Duration remaining) {
  final totalSeconds = remaining.inSeconds.clamp(0, 3599);
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// Decide se a versão em execução (`sessionVersion`) é diferente da versão
/// publicada (`remoteVersion`).
///
/// Regras:
/// - Se a versão remota for desconhecida (falha de rede / ausente): não força.
/// - Se a versão de sessão for desconhecida: não força (baseline indefinida).
/// - Caso contrário, força quando as versões diferem.
bool isUpdateRequired({
  required String? sessionVersion,
  required String? remoteVersion,
}) {
  if (remoteVersion == null || remoteVersion.trim().isEmpty) return false;
  if (sessionVersion == null || sessionVersion.trim().isEmpty) return false;
  return sessionVersion.trim() != remoteVersion.trim();
}
