import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../utils/reauth_flag.dart';
import '../utils/session_snapshot.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Garante que o login sobrevive a fechar o browser (Web).
  static Future<void> configure() async {
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Próximo login deve pedir credenciais (após "Sair" explícito).
  bool get requiresFreshSignIn => ReauthFlag.value;

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final authProvider = GoogleAuthProvider();
        if (ReauthFlag.value) {
          // Força o seletor de contas Google após logout explícito.
          authProvider.setCustomParameters({'prompt': 'select_account'});
        }

        final userCredential = await _auth.signInWithPopup(authProvider);
        ReauthFlag.value = false;

        final user = userCredential.user;
        if (user != null) {
          debugPrint(
            'DOFLUXO login: uid=${user.uid} email=${user.email ?? "—"} '
            '(anterior: uid=${SessionSnapshot.lastSignedInUid ?? "—"} '
            'email=${SessionSnapshot.lastSignedInEmail ?? "—"})',
          );
          SessionSnapshot.clear();
        }

        return user;
      }

      debugPrint('Login configurado apenas para Web no momento.');
      return null;
    } catch (e) {
      debugPrint('Erro no login com Google Web: $e');
      rethrow;
    }
  }

  /// Encerra a sessão e exige login completo na próxima entrada.
  Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user != null) {
      SessionSnapshot.remember(uid: user.uid, email: user.email);
    }

    ReauthFlag.value = true;
    await _auth.signOut();

    if (_auth.currentUser != null) {
      debugPrint('DOFLUXO signOut: usuário ainda autenticado após signOut.');
    }
  }
}
