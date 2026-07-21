/// Lógica pura (sem dependência de plataforma) para decidir atualização.
library;

/// Normaliza o conteúdo de `version.json` (gerado pelo build do Flutter)
/// para uma string comparável no formato `x.y.z+build`.
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

/// Decide se a versão em execução (`sessionVersion`) é diferente da publicada.
///
/// - Remota ausente/vazia → não força (falha de rede silenciosa).
/// - Sessão ausente/vazia → não força (baseline indefinida).
/// - Caso contrário, força quando diferem.
bool isUpdateRequired({
  required String? sessionVersion,
  required String? remoteVersion,
}) {
  if (remoteVersion == null || remoteVersion.trim().isEmpty) return false;
  if (sessionVersion == null || sessionVersion.trim().isEmpty) return false;
  return sessionVersion.trim() != remoteVersion.trim();
}

/// Formata um [Duration] restante como `M:SS` (ex.: `4:59`, `0:05`).
String formatCountdown(Duration remaining) {
  final totalSeconds = remaining.inSeconds < 0 ? 0 : remaining.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  final secondsPadded = seconds.toString().padLeft(2, '0');
  return '$minutes:$secondsPadded';
}
