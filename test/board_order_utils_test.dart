import 'package:dofluxo/presentation/dashboard/config/dashboard_stages.dart';
import 'package:dofluxo/presentation/dashboard/models/project_board_item.dart';
import 'package:dofluxo/presentation/dashboard/utils/board_order_utils.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBoardItem _item(String id, {double? order, int? createdAtMillis}) {
  return ProjectBoardItem(
    id: id,
    title: id,
    stageId: DashboardStageId.criacao,
    order: order,
    createdAtMillis: createdAtMillis,
  );
}

void main() {
  group('BoardOrderUtils.resolveKanbanTargetIndex', () {
    test('drop no fim da coluna visível', () {
      final visible = [_item('a'), _item('b')];
      final full = [_item('a'), _item('x'), _item('b')];

      final index = BoardOrderUtils.resolveKanbanTargetIndex(
        visibleColumn: visible,
        fullColumn: full,
        draggedProjectId: 'drag',
        visibleDropIndex: 2,
      );

      expect(index, 3);
    });

    test('drop sobre âncora vinda de outra coluna', () {
      final visible = [_item('a'), _item('b')];
      final full = [_item('a'), _item('b'), _item('c')];

      final index = BoardOrderUtils.resolveKanbanTargetIndex(
        visibleColumn: visible,
        fullColumn: full,
        draggedProjectId: 'drag',
        visibleDropIndex: 1,
      );

      expect(index, 1);
    });

    test('reorder de cima para baixo insere depois da âncora', () {
      final visible = [_item('a'), _item('b'), _item('c')];
      final full = visible;

      final index = BoardOrderUtils.resolveKanbanTargetIndex(
        visibleColumn: visible,
        fullColumn: full,
        draggedProjectId: 'a',
        visibleDropIndex: 2,
        visibleDragIndex: 0,
      );

      expect(index, 3);
    });

    test('reorder de baixo para cima insere antes da âncora', () {
      final visible = [_item('a'), _item('b'), _item('c')];
      final full = visible;

      final index = BoardOrderUtils.resolveKanbanTargetIndex(
        visibleColumn: visible,
        fullColumn: full,
        draggedProjectId: 'c',
        visibleDropIndex: 0,
        visibleDragIndex: 2,
      );

      expect(index, 0);
    });

    test('lista filtrada usa âncora visível na coluna completa', () {
      final visible = [_item('a'), _item('c')];
      final full = [_item('a'), _item('b'), _item('c')];

      final index = BoardOrderUtils.resolveKanbanTargetIndex(
        visibleColumn: visible,
        fullColumn: full,
        draggedProjectId: 'drag',
        visibleDropIndex: 1,
      );

      expect(index, 2);
    });
  });

  group('BoardOrderUtils.resolveDropPosition', () {
    test('calcula vizinhos para inserção no meio', () {
      final full = [_item('a'), _item('b'), _item('c')];

      final position = BoardOrderUtils.resolveDropPosition(
        fullColumn: full,
        draggedProjectId: 'drag',
        targetIndex: 1,
      );

      expect(position.beforeProjectId, 'a');
      expect(position.afterProjectId, 'b');
    });
  });
}
