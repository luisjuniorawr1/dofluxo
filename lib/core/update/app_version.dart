/// Versao compilada no build web (`--dart-define=APP_VERSION=x.y.z+N`).
///
/// Usada como baseline da sessao para detectar deploy novo enquanto a aba
/// permanece aberta com JS antigo.
const String kCompiledAppVersion = String.fromEnvironment('APP_VERSION');
