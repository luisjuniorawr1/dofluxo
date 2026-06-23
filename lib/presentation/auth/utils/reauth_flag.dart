import 'reauth_flag_stub.dart' if (dart.library.html) 'reauth_flag_web.dart' as impl;

/// Indica que o usuário saiu explicitamente e o próximo login deve pedir credenciais.
class ReauthFlag {
  static bool get value => impl.readReauthFlag();

  static set value(bool next) => impl.writeReauthFlag(next);
}
