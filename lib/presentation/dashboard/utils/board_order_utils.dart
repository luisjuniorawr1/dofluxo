import '../models/project_board_item.dart';

/// Calcula valores de `boardOrder` para inserir cards entre posições existentes.
class BoardOrderUtils {
  BoardOrderUtils._();

  static const _step = 1024.0;

  static double orderForInsertIndex({
    required List<ProjectBoardItem> columnItems,
    required int insertIndex,
    required String draggedProjectId,
  }) {
    final column = columnItems.where((item) => item.id != draggedProjectId).toList();

    if (column.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch.toDouble();
    }

    final safeIndex = insertIndex.clamp(0, column.length);

    if (safeIndex <= 0) {
      return _orderValue(column.first) - _step;
    }
    if (safeIndex >= column.length) {
      return _orderValue(column.last) + _step;
    }

    final beforeOrder = _orderValue(column[safeIndex - 1]);
    final afterOrder = _orderValue(column[safeIndex]);

    if (beforeOrder >= afterOrder) {
      return beforeOrder + 1;
    }

    return (beforeOrder + afterOrder) / 2;
  }

  static double _orderValue(ProjectBoardItem item) {
    return item.boardOrder ?? item.createdAtMillis?.toDouble() ?? 0;
  }

  static int compareItems(ProjectBoardItem a, ProjectBoardItem b) {
    final aOrder = a.boardOrder;
    final bOrder = b.boardOrder;

    if (aOrder != null && bOrder != null) {
      final byOrder = aOrder.compareTo(bOrder);
      if (byOrder != 0) return byOrder;
    } else if (aOrder != null) {
      return -1;
    } else if (bOrder != null) {
      return 1;
    }

    return (b.createdAtMillis ?? 0).compareTo(a.createdAtMillis ?? 0);
  }
}
