import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/project_production_task.dart';
import '../models/project_category.dart';

class ProjectService {
  ProjectService({required this.agencyId});

  final String agencyId;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Stream<QuerySnapshot>? _projectsStreamCache;
  String? _projectsStreamAgencyId;

  Future<String?> addProject(Map<String, dynamic> projectData) async {
    if (_auth.currentUser == null || agencyId.isEmpty) return null;

    final tasks = projectData['productionTasks'];
    final progress = tasks is List
        ? ProjectProductionTask.progressFromTasks(
            ProjectProductionTask.listFromFirestore(tasks),
          )
        : null;

    final doc = await _db.collection('projects').add({
      ...projectData,
      'agencyId': agencyId,
      'category': projectData['category'] ?? ProjectCategory.job.firestoreValue,
      'status': projectData['status'] ?? 'Planejamento',
      'boardOrder': projectData['boardOrder'] ?? DateTime.now().millisecondsSinceEpoch,
      'createdAt': FieldValue.serverTimestamp(),
      if (progress != null) 'progress': progress,
    });
    return doc.id;
  }

  Future<void> updateProjectStatus(String projectId, String newStatus) async {
    if (_auth.currentUser == null) return;

    await _db.collection('projects').doc(projectId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProject(String projectId, Map<String, dynamic> data) async {
    if (_auth.currentUser == null) return;

    await _db.collection('projects').doc(projectId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getProjectStream(String projectId) {
    return _db.collection('projects').doc(projectId).snapshots();
  }

  /// Stream compartilhado de projetos da agência ativa (uma query Firestore).
  Stream<QuerySnapshot> getProjectsStream() {
    try {
      if (_auth.currentUser == null || agencyId.isEmpty) {
        _clearProjectsStreamCache();
        return const Stream.empty();
      }

      if (_projectsStreamCache != null && _projectsStreamAgencyId == agencyId) {
        return _projectsStreamCache!;
      }

      _projectsStreamAgencyId = agencyId;
      _projectsStreamCache = _db
          .collection('projects')
          .where('agencyId', isEqualTo: agencyId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .asBroadcastStream();
      return _projectsStreamCache!;
    } catch (_) {
      return const Stream.empty();
    }
  }

  void dispose() {
    _clearProjectsStreamCache();
  }

  void _clearProjectsStreamCache() {
    _projectsStreamCache = null;
    _projectsStreamAgencyId = null;
  }
}
