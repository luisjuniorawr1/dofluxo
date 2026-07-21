import '../models/project_board_item.dart';

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

/// Resolve posições visuais contra a coluna completa e calcula `ordem`.
class BoardOrderUtils {
  BoardOrderUtils._();

  static const step = 1024.0;
  static const minimumGap = 0.000001;

  static FullDropPosition resolveFullDropPosition({
    required List<ProjectBoardItem> fullColumnItems,
    required String draggedProjectId,
    String? beforeVisibleProjectId,
    String? afterVisibleProjectId,
  }) {
    final fullColumn =
        fullColumnItems.where((item) => item.id != draggedProjectId).toList()
          ..sort(compareItems);

    int insertIndex;
    final afterIndex = afterVisibleProjectId == null
        ? -1
        : fullColumn.indexWhere((item) => item.id == afterVisibleProjectId);
    final beforeIndex = beforeVisibleProjectId == null
        ? -1
        : fullColumn.indexWhere((item) => item.id == beforeVisibleProjectId);

    // Política com filtros: inserir imediatamente antes da próxima âncora
    // visível. Sem próxima âncora, inserir logo após a âncora anterior.
    if (afterIndex >= 0) {
      insertIndex = afterIndex;
    } else if (beforeIndex >= 0) {
      insertIndex = beforeIndex + 1;
    } else {
      insertIndex = fullColumn.length;
    }

    insertIndex = insertIndex.clamp(0, fullColumn.length);
    return FullDropPosition(
      insertIndex: insertIndex,
      beforeProjectId: insertIndex > 0 ? fullColumn[insertIndex - 1].id : null,
      afterProjectId: insertIndex < fullColumn.length
          ? fullColumn[insertIndex].id
          : null,
    );
  }

  static double orderForInsertIndex({
    required List<ProjectBoardItem> columnItems,
    required int insertIndex,
    required String draggedProjectId,
  }) {
    final column = columnItems
        .where((item) => item.id != draggedProjectId)
        .toList();

    if (column.isEmpty) {
      return step;
    }

    final safeIndex = insertIndex.clamp(0, column.length);

    if (safeIndex <= 0) {
      return orderValue(column.first) - step;
    }
    if (safeIndex >= column.length) {
      return orderValue(column.last) + step;
    }

    final beforeOrder = orderValue(column[safeIndex - 1]);
    final afterOrder = orderValue(column[safeIndex]);

    if (afterOrder - beforeOrder <= minimumGap) {
      return double.nan;
    }

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
