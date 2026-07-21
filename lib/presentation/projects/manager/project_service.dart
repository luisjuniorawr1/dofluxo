import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/project_production_task.dart';
import '../models/project_category.dart';
import '../../dashboard/models/project_board_item.dart';
import '../../dashboard/utils/board_order_utils.dart';

class ProjectService {
  ProjectService({required this.agencyId});

  final String agencyId;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Stream<QuerySnapshot>? _projectsStreamCache;
  String? _projectsStreamAgencyId;
  bool _isMigratingOrders = false;

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
    if (_auth.currentUser == null) return;

    await _db.collection('projects').doc(projectId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProject(
    String projectId,
    Map<String, dynamic> data,
  ) async {
    if (_auth.currentUser == null) return;

    await _db.collection('projects').doc(projectId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Preenche `ordem` de documentos antigos de forma estável por coluna.
  /// Quando uma coluna tem ao menos um item sem o campo canônico, toda ela é
  /// renumerada para evitar colisões com valores antigos.
  Future<void> migrateMissingOrders(
    Map<String, List<ProjectBoardItem>> fullBoard,
  ) async {
    if (_auth.currentUser == null || agencyId.isEmpty || _isMigratingOrders) {
      return;
    }

    final columnsToNormalize = fullBoard.values
        .where((items) => items.any((item) => !item.hasCanonicalOrder))
        .toList();
    if (columnsToNormalize.isEmpty) return;

    final itemCount = columnsToNormalize.fold<int>(
      0,
      (total, items) => total + items.length,
    );
    if (itemCount > 450) {
      throw StateError(
        'Migração de ordem excede 450 projetos; execute por lotes.',
      );
    }

    _isMigratingOrders = true;
    try {
      final batch = _db.batch();
      for (final items in columnsToNormalize) {
        for (var index = 0; index < items.length; index++) {
          batch.update(_db.collection('projects').doc(items[index].id), {
            'ordem': (index + 1) * BoardOrderUtils.step,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      await batch.commit();
    } finally {
      _isMigratingOrders = false;
    }
  }

  /// Move um card em transação. O status e a ordem são gravados juntos; se a
  /// coluna perdeu espaço entre ordens, ela é renumerada na mesma transação.
  Future<void> moveProject({
    required String projectId,
    required String targetStatus,
    required List<String> targetColumnProjectIds,
    String? beforeProjectId,
    String? afterProjectId,
    String? planningStatus,
    bool updatePlanningStatus = false,
  }) async {
    if (_auth.currentUser == null || agencyId.isEmpty) {
      throw StateError('Usuário ou agência ativa não disponível.');
    }
    if (targetColumnProjectIds.length > 450) {
      throw StateError('A coluna excede o limite transacional de 450 cards.');
    }

    final projects = _db.collection('projects');
    final movingRef = projects.doc(projectId);
    final targetIds = targetColumnProjectIds.toSet()..remove(projectId);
    final targetRefs = targetIds.map(projects.doc).toList();

    await _db.runTransaction((transaction) async {
      final movingSnapshot = await transaction.get(movingRef);
      if (!movingSnapshot.exists) {
        throw StateError('Projeto não encontrado.');
      }
      final movingData = movingSnapshot.data()!;
      if (movingData['agencyId'] != agencyId) {
        throw StateError('Projeto pertence a outra agência.');
      }

      final movingPayload = <String, dynamic>{
        'status': targetStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        if (updatePlanningStatus && planningStatus != null)
          'planningStatus': planningStatus,
      };

      // Caminho normal: apenas card + até dois vizinhos (máximo 3 reads).
      final neighborIds = <String>{
        if (beforeProjectId != null && beforeProjectId != projectId)
          beforeProjectId,
        if (afterProjectId != null && afterProjectId != projectId)
          afterProjectId,
      };
      final neighborSnapshots = await Future.wait(
        neighborIds.map((id) => transaction.get(projects.doc(id))),
      );
      final neighbors = {
        for (final snapshot in neighborSnapshots)
          if (snapshot.exists && snapshot.data()?['agencyId'] == agencyId)
            snapshot.id: _TransactionOrderItem(
              id: snapshot.id,
              ref: snapshot.reference,
              data: snapshot.data()!,
            ),
      };

      final before = neighbors[beforeProjectId];
      final after = neighbors[afterProjectId];
      final beforeOrder = before == null ? null : _transactionOrder(before);
      final afterOrder = after == null ? null : _transactionOrder(after);
      final requiresNormalization =
          (before != null && before.data['ordem'] is! num) ||
          (after != null && after.data['ordem'] is! num) ||
          (beforeOrder != null &&
              afterOrder != null &&
              afterOrder - beforeOrder <= BoardOrderUtils.minimumGap);

      if (!requiresNormalization) {
        movingPayload['ordem'] = _orderBetween(beforeOrder, afterOrder);
        transaction.update(movingRef, movingPayload);
        return;
      }

      // Caminho raro: ordens antigas ou intervalo esgotado. Só então relê e
      // renumera a coluna inteira dentro da mesma transação.
      final remainingRefs = targetRefs.where(
        (ref) => !neighborIds.contains(ref.id),
      );
      final remainingSnapshots = await Future.wait(
        remainingRefs.map((ref) => transaction.get(ref)),
      );
      final allSnapshots = [...neighborSnapshots, ...remainingSnapshots];
      final current = [
        for (final snapshot in allSnapshots)
          if (snapshot.exists && snapshot.data()?['agencyId'] == agencyId)
            _TransactionOrderItem(
              id: snapshot.id,
              ref: snapshot.reference,
              data: snapshot.data()!,
            ),
      ]..sort(_compareTransactionItems);

      final insertIndex = _resolveTransactionInsertIndex(
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
            data: movingData,
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

  Stream<DocumentSnapshot<Map<String, dynamic>>> getProjectStream(
    String projectId,
  ) {
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

  static int _resolveTransactionInsertIndex(
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

  static double _orderBetween(double? before, double? after) {
    if (before == null && after == null) return BoardOrderUtils.step;
    if (before == null) return after! - BoardOrderUtils.step;
    if (after == null) return before + BoardOrderUtils.step;
    return (before + after) / 2;
  }

  static int _compareTransactionItems(
    _TransactionOrderItem a,
    _TransactionOrderItem b,
  ) {
    final byOrder = _transactionOrder(a).compareTo(_transactionOrder(b));
    if (byOrder != 0) return byOrder;
    return a.id.compareTo(b.id);
  }

  static double _transactionOrder(_TransactionOrderItem item) {
    final canonical = item.data['ordem'];
    if (canonical is num) return canonical.toDouble();
    final legacy = item.data['boardOrder'];
    if (legacy is num) return legacy.toDouble();
    final createdAt = item.data['createdAt'];
    if (createdAt is Timestamp) {
      return createdAt.millisecondsSinceEpoch.toDouble();
    }
    return 0;
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
