import 'package:cloud_firestore/cloud_firestore.dart';
import '../../projects/models/planning_status.dart';
import '../../projects/models/project_category.dart';
import '../config/dashboard_stages.dart';
import '../models/project_board_item.dart';
import 'board_order_utils.dart';

/// Mapeia documentos Firestore para colunas do dashboard Kanban unificado.
class DashboardBoardMapper {
  DashboardBoardMapper._();

  static Map<String, List<ProjectBoardItem>> emptyBoard() {
    return {
      for (final stage in DashboardStage.workflow)
        stage.storageKey: <ProjectBoardItem>[],
    };
  }

  static Map<String, List<ProjectBoardItem>> groupSnapshot(
    QuerySnapshot snapshot, {
    bool includeJobs = true,
    bool includePlanning = true,
  }) {
    final board = emptyBoard();
    final docs = snapshot.docs.toList()
      ..sort((a, b) => _compareCreatedAtDesc(a.data(), b.data()));

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final isPlanning = isPlanejamentoProject(data);

      if (isPlanning && !includePlanning) continue;
      if (!isPlanning && !includeJobs) continue;

      final item = ProjectBoardItem.fromFirestore(doc.id, data);
      if (item.title.isEmpty) continue;

      final stageKey = stageIdForStatus(
        data['status'] as String?,
        data: data,
      ).name;
      board[stageKey]!.add(item);
    }

    for (final items in board.values) {
      items.sort(BoardOrderUtils.compareItems);
    }

    return board;
  }

  /// Deriva o board visível sem perder a ordenação completa usada no drop.
  static Map<String, List<ProjectBoardItem>> filterBoard(
    Map<String, List<ProjectBoardItem>> fullBoard, {
    bool includeJobs = true,
    bool includePlanning = true,
  }) {
    return {
      for (final stage in DashboardStage.workflow)
        stage.storageKey: [
          for (final item in fullBoard[stage.storageKey] ?? const [])
            if ((item.isPlanejamento && includePlanning) ||
                (!item.isPlanejamento && includeJobs))
              item,
        ],
    };
  }

  static String stageKeyForStatus(
    String? status, {
    Map<String, dynamic>? data,
  }) => stageIdForStatus(status, data: data).name;

  static String firestoreStatusForStage(DashboardStageId stage) {
    return switch (stage) {
      DashboardStageId.incendios => 'Incêndios',
      DashboardStageId.planejamento => 'Planejamento',
      DashboardStageId.producao => 'Produção',
      DashboardStageId.aprovacao => 'Aprovação',
      DashboardStageId.concluido => 'Concluído',
    };
  }

  static DashboardStageId stageIdForStatus(
    String? status, {
    Map<String, dynamic>? data,
  }) {
    final normalized = _normalize(status);

    if (_matchesAny(normalized, ['incendios', 'incendio', 'urgente', 'fire'])) {
      return DashboardStageId.incendios;
    }
    if (_matchesAny(normalized, [
      'planejamento',
      'postagens',
      'postagem',
      'postagensdodia',
      'pendente',
    ])) {
      return DashboardStageId.planejamento;
    }
    if (_matchesAny(normalized, [
      'producao',
      'production',
      'criacao',
      'creation',
      'captacao',
      'capture',
      'filmagem',
      'edicao',
      'editing',
      'editado',
      'emproducao',
    ])) {
      return DashboardStageId.producao;
    }
    if (_matchesAny(normalized, [
      'aprovacao',
      'approval',
      'aguardandoaprovacao',
      'pronto',
      'agendado',
    ])) {
      return DashboardStageId.aprovacao;
    }
    if (_matchesAny(normalized, [
      'concluido',
      'concluído',
      'done',
      'aprovado',
      'approved',
      'publicado',
      'finalizado',
    ])) {
      return DashboardStageId.concluido;
    }

    if (data != null && isPlanejamentoProject(data)) {
      return _stageFromPlanningStatus(data['planningStatus'] as String?);
    }

    return DashboardStageId.planejamento;
  }

  static DashboardStageId _stageFromPlanningStatus(String? planningStatus) {
    final status = PlanningStatus.fromFirestore(planningStatus);
    return switch (status.id) {
      PlanningStatusId.pendente => DashboardStageId.planejamento,
      PlanningStatusId.emProducao => DashboardStageId.producao,
      PlanningStatusId.pronto => DashboardStageId.aprovacao,
      PlanningStatusId.agendado => DashboardStageId.aprovacao,
      PlanningStatusId.publicado => DashboardStageId.concluido,
    };
  }

  /// Sincroniza planningStatus ao mover card de planejamento no Kanban.
  static String? planningStatusForStage(DashboardStageId stage) {
    return switch (stage) {
      DashboardStageId.incendios => PlanningStatusId.pendente.name,
      DashboardStageId.planejamento => PlanningStatusId.pendente.name,
      DashboardStageId.producao => PlanningStatusId.emProducao.name,
      DashboardStageId.aprovacao => PlanningStatusId.pronto.name,
      DashboardStageId.concluido => PlanningStatusId.publicado.name,
    };
  }

  static String? cardStatusLabel({
    required String? firestoreStatus,
    required DashboardStageId stage,
    required bool isCompleted,
    bool isPlanejamento = false,
    String? planningStatusLabel,
  }) {
    if (isPlanejamento &&
        planningStatusLabel != null &&
        planningStatusLabel.isNotEmpty) {
      return planningStatusLabel;
    }

    if (isCompleted || stage == DashboardStageId.concluido) {
      return 'Concluído';
    }

    final normalized = _normalize(firestoreStatus);

    if (stage == DashboardStageId.aprovacao ||
        _matchesAny(normalized, [
          'aprovacao',
          'approval',
          'aguardandoaprovacao',
        ])) {
      return 'Aguardando aprovação';
    }

    if (stage == DashboardStageId.incendios) {
      return 'Prioridade';
    }

    return null;
  }

  static bool isCompletedStatus(String? status) {
    final normalized = _normalize(status);
    return _matchesAny(normalized, [
      'concluido',
      'concluído',
      'aprovado',
      'approved',
      'editado',
      'done',
      'publicado',
      'finalizado',
    ]);
  }

  static String _normalize(String? value) {
    return (value ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâã]'), 'a')
        .replaceAll(RegExp(r'[éèê]'), 'e')
        .replaceAll(RegExp(r'[íìî]'), 'i')
        .replaceAll(RegExp(r'[óòôõ]'), 'o')
        .replaceAll(RegExp(r'[úùû]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static bool _matchesAny(String normalized, List<String> candidates) {
    return candidates.any(
      (candidate) => normalized == candidate || normalized.contains(candidate),
    );
  }

  static int _compareCreatedAtDesc(Object? aData, Object? bData) {
    final aTs = (aData as Map<String, dynamic>?)?['createdAt'] as Timestamp?;
    final bTs = (bData as Map<String, dynamic>?)?['createdAt'] as Timestamp?;
    if (aTs == null && bTs == null) return 0;
    if (aTs == null) return 1;
    if (bTs == null) return -1;
    return bTs.compareTo(aTs);
  }
}
