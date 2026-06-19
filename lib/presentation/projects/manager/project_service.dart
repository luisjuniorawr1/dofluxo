import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/project_production_task.dart';

class ProjectService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Future<String?> addProject(Map<String, dynamic> projectData) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final tasks = projectData['productionTasks'];
    final progress = tasks is List
        ? ProjectProductionTask.progressFromTasks(
            ProjectProductionTask.listFromFirestore(tasks),
          )
        : null;

    final doc = await _db.collection('projects').add({
      ...projectData,
      'agencyId': user.uid,
      'status': projectData['status'] ?? 'Postagens',
      'createdAt': FieldValue.serverTimestamp(),
      if (progress != null) 'progress': progress,
    });
    return doc.id;
  }

  Future<void> updateProjectStatus(String projectId, String newStatus) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('projects').doc(projectId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProject(String projectId, Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('projects').doc(projectId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getProjectStream(String projectId) {
    return _db.collection('projects').doc(projectId).snapshots();
  }

  Stream<QuerySnapshot> getProjectsStream() {
    try {
      final user = _auth.currentUser;
      if (user == null) return const Stream.empty();

      return _db
          .collection('projects')
          .where('agencyId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (_) {
      return const Stream.empty();
    }
  }
}
