import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/date_format_utils.dart';
import '../../projects/models/planning_status.dart';
import '../../projects/models/project_category.dart';
import '../config/dashboard_stages.dart';
import '../config/dashboard_zones.dart';
import '../models/project_board_item.dart';
import 'board_order_utils.dart';

/// Mapeia documentos Firestore para as zonas do dashboard reorganizado.
class DashboardBoardMapper {
  DashboardBoardMapper._();

  static Map<String, List<ProjectBoardItem>> emptyBoard() {
    return {
      for (final zone in DashboardZoneId.values) zone.storageKey: <ProjectBoardItem>[],
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
    final today = DateFormatUtils.dateOnly(DateTime.now());

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final isPlanning = isPlanejamentoProject(data);

      if (isPlanning && !includePlanning) continue;
      if (!isPlanning && !includeJobs) continue;

      final item = ProjectBoardItem.fromFirestore(doc.id, data);
      if (item.title.isEmpty) continue;

      final workflowZone = workflowZoneForItem(data, item);
      board[workflowZone.storageKey]!.add(item);

      if (shouldMirrorInPostagensDoDia(data, item, today)) {
        board[DashboardZoneId.postagensDoDia.storageKey]!.add(item);
      }
      if (shouldMirrorInIncendio(data, item, today)) {
        board[DashboardZoneId.incendio.storageKey]!.add(item);
      }
    }

    for (final items in board.values) {
      items.sort(BoardOrderUtils.compareItems);
    }

    return board;
  }

  /// Zona de workflow onde o card “mora” (arrastável). Data não move o card.
  static DashboardZoneId workflowZoneForItem(
    Map<String, dynamic> data,
    ProjectBoardItem item,
  ) {
    final isPlanning = isPlanejamentoProject(data);
    final stage = stageIdForStatus(data['status'] as String?, data: data);

    if (isProjectConcluded(data, item)) return DashboardZoneId.concluidos;

    return _workflowZoneForStage(stage, isPlanning: isPlanning);
  }

  static bool shouldMirrorInPostagensDoDia(
    Map<String, dynamic> data,
    ProjectBoardItem item,
    DateTime today,
  ) {
    if (isProjectConcluded(data, item)) return false;
    final scheduledDay = DateFormatUtils.projectDeliveryDate(data);
    return scheduledDay != null && DateFormatUtils.isSameDay(scheduledDay, today);
  }

  static bool shouldMirrorInIncendio(
    Map<String, dynamic> data,
    ProjectBoardItem item,
    DateTime today,
  ) {
    if (isProjectConcluded(data, item)) return false;
    final scheduledDay = DateFormatUtils.projectDeliveryDate(data);
    return scheduledDay != null && scheduledDay.isBefore(today);
  }

  /// Card finalizado — nunca entra em Postagens do dia / Incêndio por data.
  static bool isProjectConcluded(Map<String, dynamic> data, ProjectBoardItem item) {
    if (item.isCompleted) return true;
    return isProjectConcludedFromData(data);
  }

  static bool isProjectConcludedFromData(Map<String, dynamic> data) {
    if (data['isCompleted'] == true) return true;

    final status = data['status'] as String?;
    if (isCompletedStatus(status)) return true;
    if (stageIdForStatus(status, data: data) == DashboardStageId.concluido) return true;

    if (isPlanejamentoProject(data)) {
      final planning = PlanningStatus.fromFirestore(data['planningStatus'] as String?);
      if (planning.id == PlanningStatusId.publicado) return true;
    }

    return false;
  }

  static DashboardZoneId _workflowZoneForStage(
    DashboardStageId stage, {
    required bool isPlanning,
  }) {
    return switch (stage) {
      DashboardStageId.producao => DashboardZoneId.producao,
      DashboardStageId.aprovacao => DashboardZoneId.aprovacao,
      DashboardStageId.concluido => DashboardZoneId.concluidos,
      _ when !isPlanning => DashboardZoneId.jobs,
      _ => DashboardZoneId.statusPlanejamento,
    };
  }

  static String firestoreStatusForZone(DashboardZoneId zone) {
    return switch (zone) {
      DashboardZoneId.postagensDoDia => 'Postagens',
      DashboardZoneId.jobs => 'Planejamento',
      DashboardZoneId.incendio => 'Incêndios',
      DashboardZoneId.producao => 'Produção',
      DashboardZoneId.aprovacao => 'Aprovação',
      DashboardZoneId.concluidos => 'Concluído',
      DashboardZoneId.statusPlanejamento => 'Planejamento',
    };
  }

  static DashboardStageId stageIdForZone(DashboardZoneId zone) {
    return switch (zone) {
      DashboardZoneId.postagensDoDia => DashboardStageId.planejamento,
      DashboardZoneId.jobs => DashboardStageId.planejamento,
      DashboardZoneId.incendio => DashboardStageId.incendios,
      DashboardZoneId.producao => DashboardStageId.producao,
      DashboardZoneId.aprovacao => DashboardStageId.aprovacao,
      DashboardZoneId.concluidos => DashboardStageId.concluido,
      DashboardZoneId.statusPlanejamento => DashboardStageId.planejamento,
    };
  }

  static String stageKeyForStatus(String? status, {Map<String, dynamic>? data}) =>
      stageIdForStatus(status, data: data).name;

  static String firestoreStatusForStage(DashboardStageId stage) {
    return switch (stage) {
      DashboardStageId.incendios => 'Incêndios',
      DashboardStageId.planejamento => 'Planejamento',
      DashboardStageId.producao => 'Produção',
      DashboardStageId.aprovacao => 'Aprovação',
      DashboardStageId.concluido => 'Concluído',
    };
  }

  static DashboardStageId stageIdForStatus(String? status, {Map<String, dynamic>? data}) {
    final normalized = _normalize(status);

    if (_matchesAny(normalized, ['incendios', 'incendio', 'urgente', 'fire'])) {
      return DashboardStageId.incendios;
    }
    if (_matchesAny(normalized, ['planejamento', 'postagens', 'postagem', 'postagensdodia', 'pendente'])) {
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
    if (_matchesAny(normalized, ['aprovacao', 'approval', 'aguardandoaprovacao', 'pronto', 'agendado'])) {
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

  static String? planningStatusForZone(DashboardZoneId zone) {
    return planningStatusForStage(stageIdForZone(zone));
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
    if (isPlanejamento && planningStatusLabel != null && planningStatusLabel.isNotEmpty) {
      return planningStatusLabel;
    }

    if (isCompleted || stage == DashboardStageId.concluido) {
      return 'Concluído';
    }

    final normalized = _normalize(firestoreStatus);

    if (stage == DashboardStageId.aprovacao ||
        _matchesAny(normalized, ['aprovacao', 'approval', 'aguardandoaprovacao'])) {
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
    return candidates.any((candidate) => normalized == candidate || normalized.contains(candidate));
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
