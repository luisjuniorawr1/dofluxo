import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/project_production_task.dart';
import '../models/project_category.dart';

class ProjectService {
  ProjectService({required this.agencyId});

  final String agencyId;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  StreamController<QuerySnapshot>? _projectsController;
  StreamSubscription<QuerySnapshot>? _projectsSubscription;
  Stream<QuerySnapshot>? _projectsViewStream;
  QuerySnapshot? _lastProjectsSnapshot;
  String? _projectsStreamAgencyId;

  /// Último snapshot dos projetos do usuário (mesma fonte da sidebar/Kanban).
  QuerySnapshot? get lastProjectsSnapshot => _lastProjectsSnapshot;

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

  /// Cria N docs em `projects` numa única batch (grupo de Planejamento).
  ///
  /// Retorna `null` se não autenticado; lista vazia se `projectsData` vazio.
  Future<List<String>?> addProjects(List<Map<String, dynamic>> projectsData) async {
    if (_auth.currentUser == null || agencyId.isEmpty) return null;
    if (projectsData.isEmpty) return [];

    final batch = _db.batch();
    final ids = <String>[];
    final baseOrder = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < projectsData.length; i++) {
      final data = Map<String, dynamic>.from(projectsData[i]);
      final requestedId = data['id'];
      final docRef = requestedId is String && requestedId.isNotEmpty
          ? _db.collection('projects').doc(requestedId)
          : _db.collection('projects').doc();

      final tasks = data['productionTasks'];
      final progress = tasks is List
          ? ProjectProductionTask.progressFromTasks(
              ProjectProductionTask.listFromFirestore(tasks),
            )
          : null;

      ids.add(docRef.id);
      batch.set(docRef, {
        ...data,
        'id': docRef.id,
        'agencyId': agencyId,
        'category': data['category'] ?? ProjectCategory.job.firestoreValue,
        'status': data['status'] ?? 'Planejamento',
        'boardOrder': data['boardOrder'] ?? baseOrder + i,
        'createdAt': FieldValue.serverTimestamp(),
        if (progress != null) 'progress': progress,
      });
    }

    await batch.commit();
    return ids;
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

  /// Projetos criados pelo usuário na agência (Kanban, sidebar e Novo Projeto).
  ///
  /// Guarda o último snapshot e reenvia para quem assina depois (ex.: dialog).
  /// O `asBroadcastStream()` antigo sem replay fazia o calendário grande
  /// mostrar "Nenhuma entrega" enquanto a sidebar já listava a demanda.
  Stream<QuerySnapshot> getProjectsStream() {
    try {
      if (_auth.currentUser == null || agencyId.isEmpty) {
        _clearProjectsStreamCache();
        return const Stream.empty();
      }

      _ensureProjectsBroadcast();
      return _projectsViewStream!;
    } catch (_) {
      return const Stream.empty();
    }
  }

  void _ensureProjectsBroadcast() {
    if (_projectsViewStream != null && _projectsStreamAgencyId == agencyId) {
      return;
    }

    _clearProjectsStreamCache();
    _projectsStreamAgencyId = agencyId;
    _projectsController = StreamController<QuerySnapshot>.broadcast();
    _projectsViewStream = Stream.multi((listener) {
      final last = _lastProjectsSnapshot;
      if (last != null) {
        listener.add(last);
      }
      final sub = _projectsController!.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener.onCancel = sub.cancel;
    });
    _projectsSubscription = _db
        .collection('projects')
        .where('agencyId', isEqualTo: agencyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _lastProjectsSnapshot = snapshot;
            if (!(_projectsController?.isClosed ?? true)) {
              _projectsController!.add(snapshot);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!(_projectsController?.isClosed ?? true)) {
              _projectsController!.addError(error, stackTrace);
            }
          },
        );
  }

  void dispose() {
    _clearProjectsStreamCache();
  }

  void _clearProjectsStreamCache() {
    _projectsSubscription?.cancel();
    _projectsSubscription = null;
    _projectsController?.close();
    _projectsController = null;
    _projectsViewStream = null;
    _lastProjectsSnapshot = null;
    _projectsStreamAgencyId = null;
  }
}
