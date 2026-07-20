import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/theme_utils.dart';
import '../config/kanban_constants.dart';
import 'kanban_card.dart';

class KanbanDragData<T> {
  const KanbanDragData({
    required this.item,
    required this.itemId,
    required this.fromColumnId,
  });

  final T item;
  final String itemId;
  final String fromColumnId;
}

typedef KanbanMoveCallback<T> = Future<void> Function(
  T item,
  String targetColumnId,
  int targetIndex,
);

typedef KanbanItemTapCallback<T> = void Function(T item);
typedef KanbanItemIdCallback<T> = String Function(T item);

/// Coluna Kanban com corpo scrollável e drop targets invisíveis por índice.
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
  final Widget Function(BuildContext context, T item) cardBuilder;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ColumnHeader(column: column, itemCount: items.length),
        const SizedBox(height: KanbanConstants.headerListGap),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bodyColor,
              borderRadius: BorderRadius.circular(KanbanConstants.columnBodyRadius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(KanbanConstants.columnBodyRadius),
              child: ValueListenableBuilder<String?>(
                valueListenable: draggingItemId,
                builder: (context, draggingId, _) {
                  return _buildColumnBody(
                    context: context,
                    isDragging: draggingId != null,
                    draggingId: draggingId,
                    effectiveMove: effectiveMove,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColumnBody({
    required BuildContext context,
    required bool isDragging,
    required String? draggingId,
    required KanbanMoveCallback<T>? effectiveMove,
  }) {
    if (items.isEmpty) {
      return _InvisibleDropSlot<T>(
        insertIndex: 0,
        columnId: column.id,
        columnItems: items,
        itemId: itemId,
        expand: true,
        onMove: effectiveMove,
      );
    }

    return CustomScrollView(
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
                        ),
                        enableDrag: effectiveMove != null,
                        isMobileLayout: isMobileCarousel,
                        onTap: onTap == null ? null : () => onTap!(item),
                        onDragStarted:
                            onDragStarted == null ? null : () => onDragStarted!(id),
                        onDragEnded: onDragEnded,
                        child: cardBuilder(context, item),
                      ),
                    ),
                  ),
                );

                if (effectiveMove == null) return card;

                return _CardDropSlot<T>(
                  index: index,
                  columnId: column.id,
                  columnItems: items,
                  itemId: itemId,
                  indicatorColor: column.cardHeaderColor,
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
            child: _InvisibleDropSlot<T>(
              insertIndex: items.length,
              columnId: column.id,
              columnItems: items,
              itemId: itemId,
              expand: true,
              onMove: effectiveMove,
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

class _InvisibleDropSlot<T> extends StatelessWidget {
  const _InvisibleDropSlot({
    required this.insertIndex,
    required this.columnId,
    required this.columnItems,
    required this.itemId,
    this.expand = false,
    this.onMove,
  });

  final int insertIndex;
  final String columnId;
  final List<T> columnItems;
  final KanbanItemIdCallback<T> itemId;
  final bool expand;
  final KanbanMoveCallback<T>? onMove;

  void _handleAccept(KanbanDragData<T> data) {
    final fromIndex = columnItems.indexWhere((item) => itemId(item) == data.itemId);
    final isSameColumn = data.fromColumnId == columnId;

    if (isSameColumn && fromIndex != -1) {
      if (insertIndex == fromIndex || insertIndex == fromIndex + 1) return;
    }

    onMove?.call(data.item, columnId, insertIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (expand) {
      return DragTarget<KanbanDragData<T>>(
        onWillAcceptWithDetails: (details) =>
            onMove != null && KanbanConstants.canAcceptDragFrom(details.data.fromColumnId),
        onAcceptWithDetails: (details) => _handleAccept(details.data),
        builder: (context, candidate, rejected) => const SizedBox.expand(),
      );
    }

    return DragTarget<KanbanDragData<T>>(
      onWillAcceptWithDetails: (details) =>
          onMove != null && KanbanConstants.canAcceptDragFrom(details.data.fromColumnId),
      onAcceptWithDetails: (details) => _handleAccept(details.data),
      builder: (context, candidate, rejected) {
        return SizedBox(
          height: KanbanConstants.dropSlotHeight,
          width: double.infinity,
        );
      },
    );
  }
}

/// Envolve um card com um alvo de drop preciso: detecta metade superior/inferior
/// para decidir o índice de inserção e mostra uma linha indicadora.
class _CardDropSlot<T> extends StatefulWidget {
  const _CardDropSlot({
    required this.index,
    required this.columnId,
    required this.columnItems,
    required this.itemId,
    required this.indicatorColor,
    required this.onMove,
    required this.child,
  });

  final int index;
  final String columnId;
  final List<T> columnItems;
  final KanbanItemIdCallback<T> itemId;
  final Color indicatorColor;
  final KanbanMoveCallback<T>? onMove;
  final Widget child;

  @override
  State<_CardDropSlot<T>> createState() => _CardDropSlotState<T>();
}

class _CardDropSlotState<T> extends State<_CardDropSlot<T>> {
  final GlobalKey _cardKey = GlobalKey();
  bool _hoverTop = false;
  bool _hoverBottom = false;

  bool _canAccept(KanbanDragData<T> data) {
    return widget.onMove != null &&
        KanbanConstants.canAcceptDragFrom(data.fromColumnId);
  }

  bool _isTopHalf(Offset globalOffset) {
    final box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return true;
    final local = box.globalToLocal(globalOffset);
    return local.dy < box.size.height / 2;
  }

  void _updateHover(Offset globalOffset) {
    final top = _isTopHalf(globalOffset);
    if (top != _hoverTop || top == _hoverBottom) {
      setState(() {
        _hoverTop = top;
        _hoverBottom = !top;
      });
    }
  }

  void _clearHover() {
    if (_hoverTop || _hoverBottom) {
      setState(() {
        _hoverTop = false;
        _hoverBottom = false;
      });
    }
  }

  void _accept(KanbanDragData<T> data, Offset globalOffset) {
    final insertIndex =
        _isTopHalf(globalOffset) ? widget.index : widget.index + 1;
    _clearHover();

    final fromIndex =
        widget.columnItems.indexWhere((item) => widget.itemId(item) == data.itemId);
    final isSameColumn = data.fromColumnId == widget.columnId;
    if (isSameColumn && fromIndex != -1) {
      if (insertIndex == fromIndex || insertIndex == fromIndex + 1) return;
    }

    widget.onMove?.call(data.item, widget.columnId, insertIndex);
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<KanbanDragData<T>>(
      onWillAcceptWithDetails: (details) => _canAccept(details.data),
      onMove: (details) {
        if (_canAccept(details.data)) _updateHover(details.offset);
      },
      onLeave: (_) => _clearHover(),
      onAcceptWithDetails: (details) => _accept(details.data, details.offset),
      builder: (context, candidate, rejected) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DropIndicator(visible: _hoverTop, color: widget.indicatorColor),
            KeyedSubtree(key: _cardKey, child: widget.child),
            _DropIndicator(visible: _hoverBottom, color: widget.indicatorColor),
          ],
        );
      },
    );
  }
}

class _DropIndicator extends StatelessWidget {
  const _DropIndicator({required this.visible, required this.color});

  final bool visible;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      height: visible ? 4 : 0,
      margin: EdgeInsets.symmetric(horizontal: 6, vertical: visible ? 3 : 0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
