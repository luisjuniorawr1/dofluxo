import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/dashboard_stages.dart';
import '../models/project_board_item.dart';

/// Mapeia documentos Firestore para colunas do dashboard.
class DashboardBoardMapper {
  DashboardBoardMapper._();

  static Map<String, List<ProjectBoardItem>> emptyBoard() {
    return {
      for (final stage in DashboardStage.workflow) stage.storageKey: <ProjectBoardItem>[],
    };
  }

  static Map<String, List<ProjectBoardItem>> groupSnapshot(QuerySnapshot snapshot) {
    final board = emptyBoard();
    final docs = snapshot.docs.toList()
      ..sort((a, b) => _compareCreatedAtDesc(a.data(), b.data()));

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final item = ProjectBoardItem.fromFirestore(doc.id, data);
      if (item.title.isEmpty) continue;

      final stageKey = stageIdForStatus(data['status'] as String?).name;
      board[stageKey]!.add(item);
    }

    return board;
  }

  static List<ProjectBoardItem> statusPanelProjects(Map<String, List<ProjectBoardItem>> board) {
    final seen = <String>{};
    final projects = <ProjectBoardItem>[];

    for (final items in board.values) {
      for (final item in items) {
        if (seen.contains(item.id)) continue;
        seen.add(item.id);
        projects.add(item);
      }
    }

    projects.sort((a, b) {
      final aProgress = a.progress ?? -1;
      final bProgress = b.progress ?? -1;
      return bProgress.compareTo(aProgress);
    });

    return projects;
  }

  static String stageKeyForStatus(String? status) => stageIdForStatus(status).name;

  static String firestoreStatusForStage(DashboardStageId stage) {
    return switch (stage) {
      DashboardStageId.postagensDoDia => 'Postagens',
      DashboardStageId.criacao => 'Criação',
      DashboardStageId.incendios => 'Incêndios',
      DashboardStageId.captacao => 'Captação',
      DashboardStageId.edicao => 'Edição',
      DashboardStageId.aprovacao => 'Aprovação',
    };
  }

  static DashboardStageId stageIdForStatus(String? status) {
    final normalized = _normalize(status);

    if (_matchesAny(normalized, ['postagensdodia', 'postagens', 'postagem'])) {
      return DashboardStageId.postagensDoDia;
    }
    if (_matchesAny(normalized, ['criacao', 'creation'])) {
      return DashboardStageId.criacao;
    }
    if (_matchesAny(normalized, ['incendios', 'fire', 'urgente'])) {
      return DashboardStageId.incendios;
    }
    if (_matchesAny(normalized, ['captacao', 'capture', 'filmagem'])) {
      return DashboardStageId.captacao;
    }
    if (_matchesAny(normalized, ['edicao', 'editing', 'editado'])) {
      return DashboardStageId.edicao;
    }
    if (_matchesAny(normalized, ['aprovacao', 'approval', 'aprovado', 'aguardandoaprovacao'])) {
      return DashboardStageId.aprovacao;
    }

    return DashboardStageId.postagensDoDia;
  }

  static String? cardStatusLabel({
    required String? firestoreStatus,
    required DashboardStageId stage,
    required bool isCompleted,
  }) {
    if (isCompleted) {
      return switch (stage) {
        DashboardStageId.edicao => 'Editado',
        DashboardStageId.aprovacao => 'Aprovado',
        DashboardStageId.postagensDoDia => null,
        _ => null,
      };
    }

    final normalized = _normalize(firestoreStatus);

    if (stage == DashboardStageId.aprovacao ||
        _matchesAny(normalized, ['aprovacao', 'approval', 'aguardandoaprovacao'])) {
      return 'Aguardando aprovação';
    }

    if (stage == DashboardStageId.edicao) {
      return 'Status';
    }

    return null;
  }

  static bool isCompletedStatus(String? status) {
    final normalized = _normalize(status);
    return _matchesAny(normalized, ['aprovado', 'approved', 'editado', 'concluido', 'done']);
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
