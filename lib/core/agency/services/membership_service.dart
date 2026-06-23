import 'package:cloud_firestore/cloud_firestore.dart';



import '../models/agency_role.dart';

import '../models/membership.dart';

import '../models/membership_status.dart';



class MembershipService {

  FirebaseFirestore get _db => FirebaseFirestore.instance;



  Future<List<Membership>> listActiveForUser(
    String userId, {
    bool preferServer = true,
  }) async {
    final snapshot = await _db
        .collection('memberships')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: MembershipStatus.active.firestoreValue)
        .get(
          GetOptions(
            source: preferServer ? Source.server : Source.serverAndCache,
          ),
        );

    final memberships = snapshot.docs
        .map((doc) => Membership.fromFirestore(doc.id, doc.data()))
        .where((membership) => membership.userId == userId)
        .where(
          (membership) =>
              membership.id ==
              Membership.composeId(
                agencyId: membership.agencyId,
                userId: membership.userId,
              ),
        )
        .toList();

    return _sortMemberships(memberships);
  }



  /// Lista a equipe via `agencies/{id}.activeMemberIds` + leitura individual

  /// de `memberships/{agencyId}_{userId}` — evita query em `memberships` por

  /// `agencyId`, que o Firestore rejeita com as regras atuais.

  Stream<List<Membership>> watchActiveForAgency(String agencyId) {

    return _db.collection('agencies').doc(agencyId).snapshots().asyncMap(

      (agencyDoc) async {

        if (!agencyDoc.exists || agencyDoc.data() == null) {

          return <Membership>[];

        }



        final memberIds = await _resolveActiveMemberIds(

          agencyId,

          agencyDoc.data()!,

        );



        final memberships = <Membership>[];

        for (final userId in memberIds) {

          final membership = await getForUserInAgency(

            agencyId: agencyId,

            userId: userId,

          );

          if (membership != null && membership.isActive) {

            memberships.add(membership);

          }

        }



        return _sortMemberships(memberships);

      },

    );

  }



  Future<void> updateMemberRole({

    required String agencyId,

    required String userId,

    required AgencyRole role,

  }) async {

    final id = Membership.composeId(agencyId: agencyId, userId: userId);

    await _db.collection('memberships').doc(id).update({

      'role': role.firestoreValue,

      'updatedAt': FieldValue.serverTimestamp(),

    });

  }



  Future<void> deactivateMember({

    required String agencyId,

    required String userId,

  }) async {

    final id = Membership.composeId(agencyId: agencyId, userId: userId);

    await _db.collection('memberships').doc(id).update({

      'status': MembershipStatus.removed.firestoreValue,

      'updatedAt': FieldValue.serverTimestamp(),

    });

    await _unregisterActiveMember(agencyId, userId);

  }



  Future<Membership?> getForUserInAgency({

    required String agencyId,

    required String userId,

  }) async {

    final id = Membership.composeId(agencyId: agencyId, userId: userId);

    final doc = await _db.collection('memberships').doc(id).get();

    if (!doc.exists || doc.data() == null) return null;

    return Membership.fromFirestore(doc.id, doc.data()!);

  }



  Future<void> create(Membership membership) async {

    await _db.collection('memberships').doc(membership.id).set(

          membership.toFirestore(isCreate: true),

        );

    if (membership.isActive) {

      await _registerActiveMember(membership.agencyId, membership.userId);

    }

  }



  Future<void> updateAgencyNameDenorm({

    required String agencyId,

    required String agencyName,

    required String userId,

  }) async {

    final id = Membership.composeId(agencyId: agencyId, userId: userId);

    await _db.collection('memberships').doc(id).update({

      'agencyName': agencyName.trim(),

      'updatedAt': FieldValue.serverTimestamp(),

    });

  }



  Future<Membership> createOwnerMembership({

    required String agencyId,

    required String userId,

    required String agencyName,

    required String userEmail,

    String? userDisplayName,

  }) async {

    final membership = Membership(

      id: Membership.composeId(agencyId: agencyId, userId: userId),

      agencyId: agencyId,

      userId: userId,

      role: AgencyRole.owner,

      status: MembershipStatus.active,

      agencyName: agencyName,

      userEmail: userEmail,

      userDisplayName: userDisplayName,

    );



    await create(membership);

    return membership;

  }



  Future<List<String>> _resolveActiveMemberIds(

    String agencyId,

    Map<String, dynamic> agencyData,

  ) async {

    final fromDoc = (agencyData['activeMemberIds'] as List<dynamic>?)

        ?.map((item) => item.toString())

        .where((id) => id.isNotEmpty)

        .toList();



    if (fromDoc != null && fromDoc.isNotEmpty) {

      return fromDoc;

    }



    final ownerId = agencyData['ownerId'] as String?;

    if (ownerId == null || ownerId.isEmpty) return [];



    await _db.collection('agencies').doc(agencyId).set(

      {

        'activeMemberIds': [ownerId],

        'updatedAt': FieldValue.serverTimestamp(),

      },

      SetOptions(merge: true),

    );



    return [ownerId];

  }



  Future<void> _registerActiveMember(String agencyId, String userId) async {

    await _db.collection('agencies').doc(agencyId).set(

      {

        'activeMemberIds': FieldValue.arrayUnion([userId]),

        'updatedAt': FieldValue.serverTimestamp(),

      },

      SetOptions(merge: true),

    );

  }



  Future<void> _unregisterActiveMember(String agencyId, String userId) async {

    await _db.collection('agencies').doc(agencyId).set(

      {

        'activeMemberIds': FieldValue.arrayRemove([userId]),

        'updatedAt': FieldValue.serverTimestamp(),

      },

      SetOptions(merge: true),

    );

  }



  static List<Membership> _sortMemberships(List<Membership> memberships) {

    memberships.sort((a, b) {

      final aJoined = a.joinedAt ?? a.createdAt;

      final bJoined = b.joinedAt ?? b.createdAt;

      if (aJoined == null && bJoined == null) return 0;

      if (aJoined == null) return 1;

      if (bJoined == null) return -1;

      return bJoined.compareTo(aJoined);

    });

    return memberships;

  }

}


