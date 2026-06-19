import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final authProvider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(authProvider);
        return userCredential.user;
      }

      debugPrint('Login configurado apenas para Web no momento.');
      return null;
    } catch (e) {
      debugPrint('Erro no login com Google Web: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
