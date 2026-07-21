import 'package:dofluxo/presentation/dashboard/models/project_board_item.dart';
import 'package:dofluxo/presentation/dashboard/utils/board_order_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoardOrderUtils', () {
    ProjectBoardItem item(String id, {double? boardOrder, int? createdAtMillis}) {
      return ProjectBoardItem(
        id: id,
        title: id,
        boardOrder: boardOrder,
        createdAtMillis: createdAtMillis,
      );
    }

    test('inserts at start before first item', () {
      final column = [
        item('a', boardOrder: 100),
        item('b', boardOrder: 200),
      ];

      final order = BoardOrderUtils.orderForInsertIndex(
        columnItems: column,
        insertIndex: 0,
        draggedProjectId: 'x',
      );

      expect(order, lessThan(100));
    });

    test('inserts at end after last item', () {
      final column = [
        item('a', boardOrder: 100),
        item('b', boardOrder: 200),
      ];

      final order = BoardOrderUtils.orderForInsertIndex(
        columnItems: column,
        insertIndex: 2,
        draggedProjectId: 'x',
      );

      expect(order, greaterThan(200));
    });

    test('inserts between two items using midpoint', () {
      final column = [
        item('a', boardOrder: 100),
        item('b', boardOrder: 300),
      ];

      final order = BoardOrderUtils.orderForInsertIndex(
        columnItems: column,
        insertIndex: 1,
        draggedProjectId: 'x',
      );

      expect(order, 200);
    });

    test('reorder ignores dragged item when calculating midpoint', () {
      final column = [
        item('a', boardOrder: 100),
        item('b', boardOrder: 200),
        item('c', boardOrder: 300),
      ];

      final order = BoardOrderUtils.orderForInsertIndex(
        columnItems: column,
        insertIndex: 1,
        draggedProjectId: 'b',
      );

      expect(order, 200);
    });

    test('resolveKanbanTargetIndex appends when drop is after visible list', () {
      final visible = [item('a'), item('b')];
      final full = [item('a'), item('b'), item('c'), item('d')];

      final index = BoardOrderUtils.resolveKanbanTargetIndex(
        visibleColumn: visible,
        fullColumn: full,
        draggedProjectId: 'x',
        visibleDropIndex: 2,
      );

      expect(index, 4);
    });

    test('resolveKanbanTargetIndex maps visible anchor to full column', () {
      final visible = [item('a'), item('c')];
      final full = [item('a'), item('b'), item('c'), item('d')];

      final index = BoardOrderUtils.resolveKanbanTargetIndex(
        visibleColumn: visible,
        fullColumn: full,
        draggedProjectId: 'x',
        visibleDropIndex: 1,
      );

      expect(index, 2);
    });

    test('resolveKanbanTargetIndex insert-after when dragging down onto a card', () {
      final visible = [item('a'), item('b'), item('c')];
      final full = [item('a'), item('b'), item('c')];

      // Drop on c while dragging a → insert after c in [b,c] = 2 ([b, c, a]).
      final index = BoardOrderUtils.resolveKanbanTargetIndex(
        visibleColumn: visible,
        fullColumn: full,
        draggedProjectId: 'a',
        visibleDropIndex: 2,
        visibleDragIndex: 0,
      );

      expect(index, 2);
    });

    test('resolveKanbanTargetIndex one-step down onto next card', () {
      final visible = [item('a'), item('b'), item('c')];
      final full = [item('a'), item('b'), item('c')];

      // Drop on c while dragging b → insert after c in [a,c] = 2 ([a, c, b]).
      final index = BoardOrderUtils.resolveKanbanTargetIndex(
        visibleColumn: visible,
        fullColumn: full,
        draggedProjectId: 'b',
        visibleDropIndex: 2,
        visibleDragIndex: 1,
      );

      expect(index, 2);
    });

    test('resolveKanbanTargetIndex insert-before when dragging up onto a card', () {
      final visible = [item('a'), item('b'), item('c')];
      final full = [item('a'), item('b'), item('c')];

      final index = BoardOrderUtils.resolveKanbanTargetIndex(
        visibleColumn: visible,
        fullColumn: full,
        draggedProjectId: 'c',
        visibleDropIndex: 0,
        visibleDragIndex: 2,
      );

      expect(index, 0);
    });
  });
}
