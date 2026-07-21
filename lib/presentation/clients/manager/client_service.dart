import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientService {
  ClientService({required this.agencyId});

  final String agencyId;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addClient(Map<String, dynamic> clientData) async {
    if (_auth.currentUser == null) {
      throw StateError('Usuário não autenticado.');
    }
    if (agencyId.isEmpty) {
      throw StateError('Agência ativa não definida.');
    }

    await _db.collection('clients').add({
      ...clientData,
      'agencyId': agencyId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateClient(
    String docId,
    Map<String, dynamic> clientData,
  ) async {
    if (_auth.currentUser == null) return;

    await _db.collection('clients').doc(docId).update({
      'name': clientData['name'],
      'email': clientData['email'],
      'phone': clientData['phone'],
      'sector': clientData['sector'],
      'responsible': clientData['responsible'],
      'address': clientData['address'],
      'socialLinks': clientData['socialLinks'] ?? [],
    });
  }

  Stream<QuerySnapshot> getClientsStream() {
    if (_auth.currentUser == null || agencyId.isEmpty) {
      return const Stream.empty();
    }

    return _db
        .collection('clients')
        .where('agencyId', isEqualTo: agencyId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteClient(String docId) async {
    if (_auth.currentUser == null) return;

    await _db.collection('clients').doc(docId).delete();
  }
}
