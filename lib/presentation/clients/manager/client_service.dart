import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addClient(Map<String, dynamic> clientData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('clients').add({
      ...clientData,
      'agencyId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateClient(String docId, Map<String, dynamic> clientData) async {
    final user = _auth.currentUser;
    if (user == null) return;

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
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('clients')
        .where('agencyId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteClient(String docId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('clients').doc(docId).delete();
  }
}
