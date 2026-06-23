import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

class UserService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<UserProfile?> getById(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromFirestore(doc.id, doc.data()!);
  }

  /// Busca usuário por e-mail (conta já existente no DOFLUXO).
  Future<UserProfile?> findByEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return null;

    for (final candidate in {trimmed, trimmed.toLowerCase()}) {
      final snapshot = await _db
          .collection('users')
          .where('email', isEqualTo: candidate)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return UserProfile.fromFirestore(doc.id, doc.data());
      }
    }
    return null;
  }

  /// Cria ou atualiza perfil a partir do usuário autenticado.
  Future<UserProfile> upsertFromAuth(
    User user, {
    bool preferServer = false,
  }) async {
    final ref = _db.collection('users').doc(user.uid);
    final existing = await ref.get(
      GetOptions(
        source: preferServer ? Source.server : Source.serverAndCache,
      ),
    );

    final existingData = existing.data();
    final profile = UserProfile(
      id: user.uid,
      displayName: user.displayName?.trim() ?? '',
      email: user.email?.trim() ?? '',
      photoUrl: user.photoURL,
      activeAgencyId: existingData?['activeAgencyId'] as String?,
      createdAt: _readTimestamp(existingData?['createdAt']),
    );

    await ref.set(
      profile.toFirestore(isCreate: !existing.exists),
      SetOptions(merge: true),
    );

    return profile;
  }

  Future<void> setActiveAgencyId(String userId, String agencyId) async {
    await _db.collection('users').doc(userId).set(
      {
        'activeAgencyId': agencyId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> clearActiveAgencyId(String userId) async {
    await _db.collection('users').doc(userId).update({
      'activeAgencyId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
