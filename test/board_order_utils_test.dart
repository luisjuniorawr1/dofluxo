import 'package:dofluxo/presentation/dashboard/models/project_board_item.dart';
import 'package:dofluxo/presentation/dashboard/utils/board_order_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoardOrderUtils', () {
    ProjectBoardItem item(String id, {double? order, int? createdAtMillis}) {
      return ProjectBoardItem(
        id: id,
        title: id,
        order: order,
        createdAtMillis: createdAtMillis,
      );
    }

    test('inserts at start before first item', () {
      final column = [item('a', order: 100), item('b', order: 200)];

      final order = BoardOrderUtils.orderForInsertIndex(
        columnItems: column,
        insertIndex: 0,
        draggedProjectId: 'x',
      );

      expect(order, lessThan(100));
    });

    test('inserts at end after last item', () {
      final column = [item('a', order: 100), item('b', order: 200)];

      final order = BoardOrderUtils.orderForInsertIndex(
        columnItems: column,
        insertIndex: 2,
        draggedProjectId: 'x',
      );

      expect(order, greaterThan(200));
    });

    test('inserts between two items using midpoint', () {
      final column = [item('a', order: 100), item('b', order: 300)];

      final order = BoardOrderUtils.orderForInsertIndex(
        columnItems: column,
        insertIndex: 1,
        draggedProjectId: 'x',
      );

      expect(order, 200);
    });

    test('reorder ignores dragged item when calculating midpoint', () {
      final column = [
        item('a', order: 100),
        item('b', order: 200),
        item('c', order: 300),
      ];

      final order = BoardOrderUtils.orderForInsertIndex(
        columnItems: column,
        insertIndex: 1,
        draggedProjectId: 'b',
      );

      expect(order, 200);
    });

    test('maps visible anchors to the complete filtered column', () {
      final fullColumn = [
        item('job-a', order: 100),
        item('hidden-planning', order: 200),
        item('job-b', order: 300),
      ];

      final position = BoardOrderUtils.resolveFullDropPosition(
        fullColumnItems: fullColumn,
        draggedProjectId: 'dragged',
        beforeVisibleProjectId: 'job-a',
        afterVisibleProjectId: 'job-b',
      );

      expect(position.insertIndex, 2);
      expect(position.beforeProjectId, 'hidden-planning');
      expect(position.afterProjectId, 'job-b');
    });

    test('same-column move uses list with dragged card removed', () {
      final fullColumn = [
        item('a', order: 100),
        item('b', order: 200),
        item('c', order: 300),
      ];

      final position = BoardOrderUtils.resolveFullDropPosition(
        fullColumnItems: fullColumn,
        draggedProjectId: 'b',
        beforeVisibleProjectId: 'c',
      );

      expect(position.insertIndex, 2);
      expect(position.beforeProjectId, 'c');
      expect(position.afterProjectId, isNull);
    });

    test('uses deterministic id tie-breaker for equal orders', () {
      final values = [item('b', order: 100), item('a', order: 100)]
        ..sort(BoardOrderUtils.compareItems);

      expect(values.map((item) => item.id), ['a', 'b']);
    });

    test('reads ordem as canonical field', () {
      final value = ProjectBoardItem.fromMap('a', {
        'title': 'A',
        'status': 'Planejamento',
        'ordem': 2048,
        'boardOrder': 999,
      });

      expect(value.order, 2048);
      expect(value.hasCanonicalOrder, isTrue);
    });

    test('reads boardOrder only as migration fallback', () {
      final value = ProjectBoardItem.fromMap('a', {
        'title': 'A',
        'status': 'Planejamento',
        'boardOrder': 999,
      });

      expect(value.order, 999);
      expect(value.hasCanonicalOrder, isFalse);
    });
  });
}
