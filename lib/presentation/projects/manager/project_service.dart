import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/project_production_task.dart';
import '../../dashboard/utils/board_order_utils.dart';

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
      'ordem':
          projectData['ordem'] ??
          projectData['boardOrder'] ??
          DateTime.now().millisecondsSinceEpoch.toDouble(),
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

  /// Move card entre colunas e/ou reordena dentro da coluna.
  Future<void> moveProject({
    required String projectId,
    required String targetStatus,
    required List<String> targetColumnProjectIds,
    String? beforeProjectId,
    String? afterProjectId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }
    if (targetColumnProjectIds.length > 450) {
      throw StateError('Coluna excede limite transacional de 450 cards.');
    }

    final projects = _db.collection('projects');
    final movingRef = projects.doc(projectId);
    final neighborIds = <String>{
      if (beforeProjectId != null && beforeProjectId != projectId)
        beforeProjectId,
      if (afterProjectId != null && afterProjectId != projectId) afterProjectId,
    };
    final targetIds = targetColumnProjectIds.toSet()..remove(projectId);
    final targetRefs = targetIds.map(projects.doc).toList();

    await _db.runTransaction((transaction) async {
      final movingSnapshot = await transaction.get(movingRef);
      if (!movingSnapshot.exists) {
        throw StateError('Projeto não encontrado.');
      }

      final movingPayload = <String, dynamic>{
        'status': targetStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final neighborSnapshots = await Future.wait(
        neighborIds.map((id) => transaction.get(projects.doc(id))),
      );
      final neighbors = {
        for (final snapshot in neighborSnapshots)
          if (snapshot.exists) snapshot.id: snapshot.data()!,
      };

      final beforeOrder = beforeProjectId == null
          ? null
          : _readOrder(neighbors[beforeProjectId]);
      final afterOrder =
          afterProjectId == null ? null : _readOrder(neighbors[afterProjectId]);

      final needsNormalization = (beforeOrder != null &&
              afterOrder != null &&
              afterOrder - beforeOrder <= BoardOrderUtils.minimumGap) ||
          (beforeProjectId != null &&
              neighbors[beforeProjectId]?['ordem'] is! num) ||
          (afterProjectId != null && neighbors[afterProjectId]?['ordem'] is! num);

      if (!needsNormalization) {
        movingPayload['ordem'] = _orderBetween(beforeOrder, afterOrder);
        transaction.update(movingRef, movingPayload);
        return;
      }

      final remainingRefs =
          targetRefs.where((ref) => !neighborIds.contains(ref.id));
      final remainingSnapshots = await Future.wait(
        remainingRefs.map((ref) => transaction.get(ref)),
      );
      final current = [
        for (final snapshot in [...neighborSnapshots, ...remainingSnapshots])
          if (snapshot.exists)
            _TransactionOrderItem(
              id: snapshot.id,
              ref: snapshot.reference,
              data: snapshot.data()!,
            ),
      ]..sort(_compareTransactionItems);

      final insertIndex = _resolveInsertIndex(
        current,
        beforeProjectId: beforeProjectId,
        afterProjectId: afterProjectId,
      ).clamp(0, current.length);

      final arranged = [...current]
        ..insert(
          insertIndex,
          _TransactionOrderItem(
            id: projectId,
            ref: movingRef,
            data: movingSnapshot.data()!,
          ),
        );

      for (var index = 0; index < arranged.length; index++) {
        final payload = <String, dynamic>{
          'ordem': (index + 1) * BoardOrderUtils.step,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (arranged[index].id == projectId) payload.addAll(movingPayload);
        transaction.update(arranged[index].ref, payload);
      }
    });
  }

  double? _readOrder(Map<String, dynamic>? data) {
    if (data == null) return null;
    final raw = data['ordem'] ?? data['boardOrder'];
    return raw is num ? raw.toDouble() : null;
  }

  double _orderBetween(double? before, double? after) {
    if (before == null && after == null) return BoardOrderUtils.step;
    if (before == null) return after! - BoardOrderUtils.step;
    if (after == null) return before + BoardOrderUtils.step;
    return (before + after) / 2;
  }

  int _resolveInsertIndex(
    List<_TransactionOrderItem> items, {
    String? beforeProjectId,
    String? afterProjectId,
  }) {
    if (afterProjectId != null) {
      final index = items.indexWhere((item) => item.id == afterProjectId);
      if (index >= 0) return index;
    }
    if (beforeProjectId != null) {
      final index = items.indexWhere((item) => item.id == beforeProjectId);
      if (index >= 0) return index + 1;
    }
    return items.length;
  }

  int _compareTransactionItems(_TransactionOrderItem a, _TransactionOrderItem b) {
    final aOrder = _readOrder(a.data) ?? 0;
    final bOrder = _readOrder(b.data) ?? 0;
    final byOrder = aOrder.compareTo(bOrder);
    if (byOrder != 0) return byOrder;
    return a.id.compareTo(b.id);
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

class _TransactionOrderItem {
  const _TransactionOrderItem({
    required this.id,
    required this.ref,
    required this.data,
  });

  final String id;
  final DocumentReference<Map<String, dynamic>> ref;
  final Map<String, dynamic> data;
}
