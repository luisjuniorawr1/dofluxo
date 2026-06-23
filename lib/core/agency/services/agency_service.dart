import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';



import '../models/agency.dart';



class AgencyService {

  FirebaseFirestore get _db => FirebaseFirestore.instance;



  Future<Agency?> getById(
    String agencyId, {
    bool preferServer = false,
  }) async {
    final doc = await _db.collection('agencies').doc(agencyId).get(
          GetOptions(
            source: preferServer ? Source.server : Source.serverAndCache,
          ),
        );

    if (!doc.exists || doc.data() == null) return null;

    return Agency.fromFirestore(doc.id, doc.data()!);

  }



  Future<void> create(Agency agency) async {

    await _db.collection('agencies').doc(agency.id).set(

          agency.toFirestore(isCreate: true),

        );

  }



  Future<void> updateBranding({

    required String agencyId,

    required String name,

    required Color primaryColor,

    String? logoUrl,

  }) async {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {

      throw StateError('Usuário não autenticado.');

    }



    final ref = _db.collection('agencies').doc(agencyId);

    final existing = await ref.get();



    final brandingPayload = {

      'name': name.trim(),

      'primaryColor': primaryColor.withValues(alpha: 1).toARGB32().toString(),

      if (logoUrl != null) 'logoUrl': logoUrl,

      'updatedAt': FieldValue.serverTimestamp(),

    };



    if (existing.exists) {

      await ref.update(brandingPayload);

      return;

    }



    await ref.set({

      ...brandingPayload,

      'ownerId': user.uid,

      'createdBy': user.uid,

      'createdAt': FieldValue.serverTimestamp(),

    });

  }

}


