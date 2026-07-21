import '../models/project_board_item.dart';

/// Resolve posição visível do drop contra a coluna completa (com filtros).
class BoardOrderUtils {
  BoardOrderUtils._();

  static const step = 1024.0;
  static const minimumGap = 0.000001;

  /// Converte índice visível → índice real na coluna completa.
  ///
  /// [visibleDragIndex] é o índice do card arrastado na lista visível da coluna
  /// de origem, ou null se veio de outra coluna.
  static int resolveKanbanTargetIndex({
    required List<ProjectBoardItem> visibleColumn,
    required List<ProjectBoardItem> fullColumn,
    required String draggedProjectId,
    required int visibleDropIndex,
    int? visibleDragIndex,
  }) {
    final fullWithoutDragged =
        fullColumn.where((item) => item.id != draggedProjectId).toList();

    if (visibleDropIndex >= visibleColumn.length) {
      return fullWithoutDragged.length;
    }

    final anchor = visibleColumn[visibleDropIndex];
    final anchorFullIndex =
        fullWithoutDragged.indexWhere((item) => item.id == anchor.id);
    if (anchorFullIndex < 0) return fullWithoutDragged.length;

    if (visibleDragIndex != null &&
        visibleDragIndex >= 0 &&
        visibleDragIndex < visibleDropIndex) {
      return anchorFullIndex + 1;
    }

    return anchorFullIndex;
  }

  static FullDropPosition resolveDropPosition({
    required List<ProjectBoardItem> fullColumn,
    required String draggedProjectId,
    required int targetIndex,
  }) {
    final column =
        fullColumn.where((item) => item.id != draggedProjectId).toList();
    final index = targetIndex.clamp(0, column.length);

    return FullDropPosition(
      insertIndex: index,
      beforeProjectId: index > 0 ? column[index - 1].id : null,
      afterProjectId: index < column.length ? column[index].id : null,
    );
  }

  static double orderForInsertIndex({
    required List<ProjectBoardItem> columnItems,
    required int insertIndex,
    required String draggedProjectId,
  }) {
    final column =
        columnItems.where((item) => item.id != draggedProjectId).toList();

    if (column.isEmpty) return step;

    final safeIndex = insertIndex.clamp(0, column.length);

    if (safeIndex <= 0) return orderValue(column.first) - step;
    if (safeIndex >= column.length) return orderValue(column.last) + step;

    final beforeOrder = orderValue(column[safeIndex - 1]);
    final afterOrder = orderValue(column[safeIndex]);

    if (afterOrder - beforeOrder <= minimumGap) return double.nan;

    return (beforeOrder + afterOrder) / 2;
  }

  static double orderValue(ProjectBoardItem item) {
    return item.order ?? item.createdAtMillis?.toDouble() ?? 0;
  }

  static int compareItems(ProjectBoardItem a, ProjectBoardItem b) {
    final aOrder = a.order;
    final bOrder = b.order;

    if (aOrder != null && bOrder != null) {
      final byOrder = aOrder.compareTo(bOrder);
      if (byOrder != 0) return byOrder;
    } else if (aOrder != null) {
      return -1;
    } else if (bOrder != null) {
      return 1;
    }

    final byCreatedAt = (b.createdAtMillis ?? 0).compareTo(
      a.createdAtMillis ?? 0,
    );
    if (byCreatedAt != 0) return byCreatedAt;
    return a.id.compareTo(b.id);
  }
}

class FullDropPosition {
  const FullDropPosition({
    required this.insertIndex,
    this.beforeProjectId,
    this.afterProjectId,
  });

  final int insertIndex;
  final String? beforeProjectId;
  final String? afterProjectId;
}
