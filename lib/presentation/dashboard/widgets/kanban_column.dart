import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/theme_utils.dart';
import '../config/kanban_constants.dart';
import 'kanban_card.dart';

class KanbanDragData<T> {
  const KanbanDragData({
    required this.item,
    required this.itemId,
    required this.fromColumnId,
    this.visibleDragIndex,
  });

  final T item;
  final String itemId;
  final String fromColumnId;
  final int? visibleDragIndex;
}

typedef KanbanMoveCallback<T> = Future<void> Function(
  KanbanDragData<T> dragData,
  String targetColumnId,
  int visibleDropIndex,
);

typedef KanbanItemTapCallback<T> = void Function(T item);
typedef KanbanItemIdCallback<T> = String Function(T item);

typedef KanbanCardBuilder<T> = Widget Function(
  BuildContext context,
  T item, {
  bool isDragging,
  bool isPlaceholder,
});

/// Coluna Kanban com corpo scrollável e drop targets por card / fim / vazio.
///
/// Decisão travada (AGENTS.md D7): o título (`_ColumnHeader`) fica **dentro**
/// do `DecoratedBox` colorido, junto com os cards. Não colocar o header fora.
class KanbanColumn<T> extends StatelessWidget {
  const KanbanColumn({
    super.key,
    required this.column,
    required this.items,
    required this.itemId,
    required this.cardBuilder,
    required this.draggingItemId,
    this.onMove,
    this.onTap,
    this.onDragStarted,
    this.onDragEnded,
    this.isMobileCarousel = false,
  });

  final KanbanColumnConfig column;
  final List<T> items;
  final KanbanItemIdCallback<T> itemId;
  final KanbanCardBuilder<T> cardBuilder;
  final ValueListenable<String?> draggingItemId;
  final KanbanMoveCallback<T>? onMove;
  final KanbanItemTapCallback<T>? onTap;
  final ValueChanged<String>? onDragStarted;
  final VoidCallback? onDragEnded;
  final bool isMobileCarousel;

  @override
  Widget build(BuildContext context) {
    final bodyColor = KanbanConstants.columnBodyBackground(column);
    final effectiveMove = column.acceptsDragDrop ? onMove : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bodyColor,
        borderRadius: BorderRadius.circular(KanbanConstants.columnBodyRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(KanbanConstants.columnBodyRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _ColumnHeader(column: column, itemCount: items.length),
            ),
            const SizedBox(height: KanbanConstants.headerListGap),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final feedbackWidth =
                      constraints.maxWidth.clamp(120.0, 360.0);

                  return ValueListenableBuilder<String?>(
                    valueListenable: draggingItemId,
                    builder: (context, draggingId, _) {
                      return ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.trackpad,
                            PointerDeviceKind.stylus,
                          },
                        ),
                        child: _buildColumnBody(
                          context: context,
                          isDragging: draggingId != null,
                          draggingId: draggingId,
                          effectiveMove: effectiveMove,
                          feedbackWidth: feedbackWidth,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnBody({
    required BuildContext context,
    required bool isDragging,
    required String? draggingId,
    required KanbanMoveCallback<T>? effectiveMove,
    required double feedbackWidth,
  }) {
    if (items.isEmpty) {
      return _DropTargetShell<T>(
        columnId: column.id,
        columnItems: items,
        itemId: itemId,
        dropIndex: 0,
        highlightColor: column.cardHeaderColor,
        expand: true,
        onMove: effectiveMove,
        child: _EmptyColumnHint(highlightColor: column.cardHeaderColor),
      );
    }

    return CustomScrollView(
      primary: false,
      physics: isMobileCarousel
          ? const BouncingScrollPhysics()
          : const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            8,
            KanbanConstants.firstCardTopPadding,
            8,
            8,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[index];
                final id = itemId(item);
                final isBeingDragged = draggingId == id;

                if (isBeingDragged && effectiveMove == null) {
                  return const SizedBox.shrink();
                }

                final card = Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: KanbanConstants.cardVerticalGap / 2,
                  ),
                  child: IgnorePointer(
                    ignoring: isDragging && !isBeingDragged,
                    child: RepaintBoundary(
                      child: KanbanCard<T>(
                        item: item,
                        dragData: KanbanDragData<T>(
                          item: item,
                          itemId: id,
                          fromColumnId: column.id,
                          visibleDragIndex: index,
                        ),
                        feedbackWidth: feedbackWidth,
                        enableDrag: effectiveMove != null,
                        isMobileLayout: isMobileCarousel,
                        buildContent: ({isDragging = false, isPlaceholder = false}) =>
                            cardBuilder(
                          context,
                          item,
                          isDragging: isDragging,
                          isPlaceholder: isPlaceholder,
                        ),
                        onTap: onTap == null ? null : () => onTap!(item),
                        onDragStarted:
                            onDragStarted == null ? null : () => onDragStarted!(id),
                        onDragEnded: onDragEnded,
                      ),
                    ),
                  ),
                );

                if (effectiveMove == null || isBeingDragged) return card;

                return _DropTargetShell<T>(
                  columnId: column.id,
                  columnItems: items,
                  itemId: itemId,
                  dropIndex: index,
                  highlightColor: column.cardHeaderColor,
                  onMove: effectiveMove,
                  child: card,
                );
              },
              childCount: items.length,
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _DropTargetShell<T>(
              columnId: column.id,
              columnItems: items,
              itemId: itemId,
              dropIndex: items.length,
              highlightColor: column.cardHeaderColor,
              expand: true,
              onMove: effectiveMove,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({
    required this.column,
    required this.itemCount,
  });

  final KanbanColumnConfig column;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                column.title,
                style: ThemeUtils.sectionTitle(context).copyWith(
                  color: KanbanConstants.columnHeaderAccent(column),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (itemCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: column.cardHeaderColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$itemCount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: KanbanConstants.onCardColor(column.cardHeaderColor),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _EmptyColumnHint extends StatelessWidget {
  const _EmptyColumnHint({required this.highlightColor});

  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Arraste um item para cá',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: highlightColor.withValues(alpha: 0.75),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DropTargetShell<T> extends StatelessWidget {
  const _DropTargetShell({
    required this.columnId,
    required this.columnItems,
    required this.itemId,
    required this.dropIndex,
    required this.highlightColor,
    required this.child,
    this.expand = false,
    this.onMove,
  });

  final String columnId;
  final List<T> columnItems;
  final KanbanItemIdCallback<T> itemId;
  final int dropIndex;
  final Color highlightColor;
  final Widget child;
  final bool expand;
  final KanbanMoveCallback<T>? onMove;

  bool _canAccept(KanbanDragData<T> data) {
    if (onMove == null) return false;
    if (!KanbanConstants.canAcceptDragFrom(data.fromColumnId)) return false;

    final fromIndex =
        columnItems.indexWhere((item) => itemId(item) == data.itemId);
    final isSameColumn = data.fromColumnId == columnId;
    if (isSameColumn && fromIndex != -1) {
      if (dropIndex == fromIndex || dropIndex == fromIndex + 1) return false;
    }

    return true;
  }

  void _handleAccept(KanbanDragData<T> data) {
    if (!_canAccept(data)) return;
    onMove?.call(data, columnId, dropIndex);
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<KanbanDragData<T>>(
      onWillAcceptWithDetails: (details) => _canAccept(details.data),
      onAcceptWithDetails: (details) => _handleAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;

        final content = AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          decoration: isHighlighted
              ? BoxDecoration(
                  color: highlightColor.withValues(alpha: 0.14),
                  border: Border.all(
                    color: highlightColor.withValues(alpha: 0.85),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: child,
        );

        if (expand) {
          return SizedBox.expand(child: content);
        }

        return content;
      },
    );
  }
}
