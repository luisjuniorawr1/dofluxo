import 'session_snapshot_stub.dart'
    if (dart.library.html) 'session_snapshot_web.dart' as impl;

/// Guarda o último usuário autenticado para detectar re-login na mesma conta.
class SessionSnapshot {
  static String? get lastSignedInUid => impl.readLastUid();
  static String? get lastSignedInEmail => impl.readLastEmail();

  static void remember({required String uid, String? email}) {
    impl.writeLastSession(uid: uid, email: email);
  }

  static void clear() {
    impl.clearLastSession();
  }
}
