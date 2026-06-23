import 'dart:async' show unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../exceptions/invite_code_exceptions.dart';
import '../models/agency_invite_code.dart';
import '../models/agency_role.dart';
import '../models/invite_code_status.dart';
import '../models/membership.dart';
import '../models/membership_status.dart';
import '../utils/invite_code_generator.dart';

class InviteCodeRedeemResult {
  const InviteCodeRedeemResult({
    required this.invite,
    required this.membership,
  });

  final AgencyInviteCode invite;
  final Membership membership;
}

class InviteCodeService {
  InviteCodeService({
    FirebaseFirestore? firestore,
    InviteCodeGenerator? generator,
    Duration? defaultValidity,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _generator = generator ?? InviteCodeGenerator(),
        _defaultValidity = defaultValidity ?? const Duration(days: 7);

  final FirebaseFirestore _db;
  final InviteCodeGenerator _generator;
  final Duration _defaultValidity;

  static const _collection = 'agency_invite_codes';

  Future<AgencyInviteCode> generate({
    required String agencyId,
    required String agencyName,
    required AgencyRole role,
    required String createdBy,
  }) async {
    if (role == AgencyRole.owner) {
      throw ArgumentError('Convites não podem atribuir função de dono.');
    }

    await _ensureCreatorCanManageAgency(
      agencyId: agencyId,
      agencyName: agencyName,
      userId: createdBy,
    );

    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _generator.generate();
      final ref = _db.collection(_collection).doc(code);
      final existing = await ref.get();
      if (existing.exists) continue;

      final now = DateTime.now();
      final invite = AgencyInviteCode(
        code: code,
        agencyId: agencyId,
        agencyName: agencyName,
        role: role,
        status: InviteCodeStatus.active,
        createdBy: createdBy,
        createdAt: now,
        expiresAt: now.add(_defaultValidity),
      );

      final batch = _db.batch();
      batch.set(ref, invite.toFirestore(isCreate: true));
      batch.set(
        _db.collection('agencies').doc(agencyId),
        {
          'activeInviteCodes': FieldValue.arrayUnion([code]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await batch.commit();

      return invite;
    }

    throw StateError('Não foi possível gerar um código único. Tente novamente.');
  }

  Future<AgencyInviteCode?> getByCode(String rawCode) async {
    final code = normalizeInviteCode(rawCode);
    if (!isValidInviteCodeFormat(code)) return null;

    final doc = await _db.collection(_collection).doc(code).get();
    if (!doc.exists || doc.data() == null) return null;
    return AgencyInviteCode.fromFirestore(doc.id, doc.data()!);
  }

  Stream<List<AgencyInviteCode>> watchActiveForAgency(String agencyId) {
    return _db.collection('agencies').doc(agencyId).snapshots().asyncMap(
      (agencyDoc) async {
        if (!agencyDoc.exists || agencyDoc.data() == null) {
          return <AgencyInviteCode>[];
        }

        final codes = _readStringList(agencyDoc.data()!['activeInviteCodes']);
        final now = DateTime.now();
        final invites = <AgencyInviteCode>[];
        final staleCodes = <String>[];

        for (final code in codes) {
          final invite = await getByCode(code);
          if (invite == null ||
              invite.agencyId != agencyId ||
              !invite.isActive ||
              invite.isExpiredAt(now)) {
            staleCodes.add(code);
            continue;
          }
          invites.add(invite);
        }

        if (staleCodes.isNotEmpty) {
          unawaited(_unregisterActiveInviteCodes(agencyId, staleCodes));
        }

        invites.sort((a, b) {
          final aCreated = a.createdAt;
          final bCreated = b.createdAt;
          if (aCreated == null && bCreated == null) return 0;
          if (aCreated == null) return 1;
          if (bCreated == null) return -1;
          return bCreated.compareTo(aCreated);
        });

        return invites;
      },
    );
  }

  Future<void> revoke(String rawCode) async {
    final code = normalizeInviteCode(rawCode);
    final invite = await getByCode(code);
    await _db.collection(_collection).doc(code).update({
      'status': InviteCodeStatus.revoked.firestoreValue,
    });
    if (invite != null) {
      await _unregisterActiveInviteCode(invite.agencyId, code);
    }
  }

  Future<InviteCodeRedeemResult> redeem({
    required String rawCode,
    required User user,
  }) async {
    final code = normalizeInviteCode(rawCode);
    if (!isValidInviteCodeFormat(code)) {
      throw const InviteCodeNotFoundException();
    }

    final inviteRef = _db.collection(_collection).doc(code);

    try {
      final inviteSnap = await inviteRef.get();
      if (!inviteSnap.exists || inviteSnap.data() == null) {
        throw const InviteCodeNotFoundException();
      }

      final invite = AgencyInviteCode.fromFirestore(inviteSnap.id, inviteSnap.data()!);
      _validateInviteForRedeem(invite);

      final resolvedMembershipId = Membership.composeId(
        agencyId: invite.agencyId,
        userId: user.uid,
      );
      final membershipRef = _db.collection('memberships').doc(resolvedMembershipId);
      final membershipSnap = await membershipRef.get();

      if (membershipSnap.exists && membershipSnap.data() != null) {
        final existing = Membership.fromFirestore(
          membershipSnap.id,
          membershipSnap.data()!,
        );
        if (existing.isActive) {
          throw const AlreadyAgencyMemberException();
        }
      }

      final membership = Membership(
        id: resolvedMembershipId,
        agencyId: invite.agencyId,
        userId: user.uid,
        role: invite.role,
        status: MembershipStatus.active,
        agencyName: invite.agencyName,
        userEmail: user.email ?? '',
        userDisplayName: user.displayName,
      );

      final membershipPayload = {
        ...membership.toFirestore(isCreate: !membershipSnap.exists),
        'inviteCode': code,
      };

      if (membershipSnap.exists) {
        await membershipRef.update(membershipPayload);
      } else {
        await membershipRef.set(membershipPayload);
      }

      await inviteRef.update({
        'status': InviteCodeStatus.used.firestoreValue,
        'usedBy': user.uid,
        'usedAt': FieldValue.serverTimestamp(),
      });

      final result = InviteCodeRedeemResult(invite: invite, membership: membership);
      unawaited(_tryAddUserToAgencyIndex(result.invite.agencyId, user.uid));
      return result;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw StateError(
          'Permissão negada ao resgatar convite.\n\n'
          'Publique as rules no Firebase CLI Win:\n'
          'cd C:\\Users\\Junior\\developer\\dofluxo\n'
          'firebase deploy --only firestore:rules\n\n'
          'Projeto: dofluxo-organizer',
        );
      }
      rethrow;
    }
  }

  Future<void> _tryAddUserToAgencyIndex(String agencyId, String userId) async {
    try {
      await _db.collection('agencies').doc(agencyId).set(
        {
          'activeMemberIds': FieldValue.arrayUnion([userId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('DOFLUXO: índice activeMemberIds não atualizado ($e).');
    }
  }

  /// Garante doc memberships/{agencyId}_{uid} para o dono — exigido pelas rules.
  Future<void> _ensureCreatorCanManageAgency({
    required String agencyId,
    required String agencyName,
    required String userId,
  }) async {
    final membershipId = Membership.composeId(agencyId: agencyId, userId: userId);
    final membershipRef = _db.collection('memberships').doc(membershipId);
    final existing = await membershipRef.get();

    if (existing.exists && existing.data() != null) {
      final status = existing.data()!['status'] as String?;
      final role = existing.data()!['role'] as String?;
      if (status == MembershipStatus.active.firestoreValue &&
          (role == AgencyRole.owner.firestoreValue ||
              role == AgencyRole.admin.firestoreValue)) {
        return;
      }
    }

    final agencySnap = await _db.collection('agencies').doc(agencyId).get();
    if (!agencySnap.exists || agencySnap.data() == null) {
      throw StateError('Agência não encontrada.');
    }

    if (agencySnap.data()!['ownerId'] != userId) {
      throw StateError('Sem permissão para gerar convites nesta agência.');
    }

    final user = FirebaseAuth.instance.currentUser;
    final membership = Membership(
      id: membershipId,
      agencyId: agencyId,
      userId: userId,
      role: AgencyRole.owner,
      status: MembershipStatus.active,
      agencyName: agencyName,
      userEmail: user?.email ?? '',
      userDisplayName: user?.displayName,
    );

    final batch = _db.batch();
    batch.set(membershipRef, membership.toFirestore(isCreate: true));
    batch.set(
      _db.collection('agencies').doc(agencyId),
      {
        'activeMemberIds': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  void _validateInviteForRedeem(AgencyInviteCode invite) {
    switch (invite.status) {
      case InviteCodeStatus.used:
        throw const InviteCodeAlreadyUsedException();
      case InviteCodeStatus.revoked:
        throw const InviteCodeRevokedException();
      case InviteCodeStatus.active:
        break;
    }

    if (invite.isExpiredAt(DateTime.now())) {
      throw const InviteCodeExpiredException();
    }

    if (invite.role == AgencyRole.owner) {
      throw const InviteCodeInvalidRoleException();
    }
  }

  Future<void> _unregisterActiveInviteCode(String agencyId, String code) async {
    await _unregisterActiveInviteCodes(agencyId, [code]);
  }

  Future<void> _unregisterActiveInviteCodes(
    String agencyId,
    List<String> codes,
  ) async {
    if (codes.isEmpty) return;
    await _db.collection('agencies').doc(agencyId).set(
      {
        'activeInviteCodes': FieldValue.arrayRemove(codes),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
  }
}
