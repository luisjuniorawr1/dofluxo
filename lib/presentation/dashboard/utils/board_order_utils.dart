import '../models/project_board_item.dart';

/// Calcula posição e ordem de cards no Kanban.
class BoardOrderUtils {
  BoardOrderUtils._();

  static const _step = 1024.0;

  /// Converte índice visível do drop para índice real na coluna completa.
  ///
  /// [visibleDropIndex] = insert-before na lista visível (ainda com o card
  /// arrastado). O retorno é insert-before em [fullColumn] sem o arrastado.
  static int resolveKanbanTargetIndex({
    required List<ProjectBoardItem> visibleColumn,
    required List<ProjectBoardItem> fullColumn,
    required String draggedProjectId,
    required int visibleDropIndex,
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

    return anchorFullIndex;
  }

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
