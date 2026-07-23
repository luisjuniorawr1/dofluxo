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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bodyColor = Color.alphaBlend(
      column.cardColor.withValues(alpha: theme.brightness == Brightness.dark ? 0.055 : 0.045),
      colors.surfaceContainerLow,
    );
    final effectiveMove = column.acceptsDragDrop ? onMove : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bodyColor,
        borderRadius: BorderRadius.circular(KanbanConstants.columnBodyRadius),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.16 : 0.055,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(KanbanConstants.columnBodyRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 4,
              color: column.cardColor,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 0),
              child: effectiveMove == null
                  ? _ColumnHeader(column: column, itemCount: items.length)
                  : _DropTargetShell<T>(
                      columnId: column.id,
                      columnItems: items,
                      itemId: itemId,
                      dropIndex: 0,
                      highlightColor: column.cardHeaderColor,
                      onMove: effectiveMove,
                      child: _ColumnHeader(
                        column: column,
                        itemCount: items.length,
                      ),
                    ),
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
        expand: true,
        onMove: effectiveMove,
        child: _EmptyColumnHint(highlightColor: column.cardHeaderColor),
      );
    }

    return CustomScrollView(
      primary: false,
      physics: isDragging
          ? const NeverScrollableScrollPhysics()
          : isMobileCarousel
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

                final card = Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: KanbanConstants.cardVerticalGap / 2,
                  ),
                  child: IgnorePointer(
                    ignoring: isDragging && !isBeingDragged,
                    child: RepaintBoundary(
                      child: KanbanCard<T>(
                        key: ValueKey<String>('kanban-card-$id'),
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

                // Keep DropTargetShell mounted while dragging so the parent of
                // Draggable does not change mid-gesture (kills intermittent drags).
                if (effectiveMove == null) return card;

                return _DropTargetShell<T>(
                  columnId: column.id,
                  columnItems: items,
                  itemId: itemId,
                  dropIndex: index,
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
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: column.cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: column.cardColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                column.title,
                style: ThemeUtils.sectionTitle(context).copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.15,
                ),
              ),
            ),
            if (itemCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: column.cardColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: column.cardColor.withValues(alpha: 0.28),
                  ),
                ),
                child: Text(
                  '$itemCount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
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
    required this.child,
    this.expand = false,
    this.onMove,
    this.highlightColor,
  });

  final String columnId;
  final List<T> columnItems;
  final KanbanItemIdCallback<T> itemId;
  final int dropIndex;
  final Widget child;
  final bool expand;
  final KanbanMoveCallback<T>? onMove;
  final Color? highlightColor;

  bool _canAccept(KanbanDragData<T> data) {
    if (onMove == null) return false;
    if (!KanbanConstants.canAcceptDragFrom(data.fromColumnId)) return false;

    final fromIndex =
        columnItems.indexWhere((item) => itemId(item) == data.itemId);
    final isSameColumn = data.fromColumnId == columnId;
    if (isSameColumn && fromIndex != -1) {
      // Only the card's own slot is a no-op. Dropping on the next card means
      // "take that position" (insert after it) and must be accepted.
      if (dropIndex == fromIndex) return false;
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
      hitTestBehavior: HitTestBehavior.translucent,
      onWillAcceptWithDetails: (details) => _canAccept(details.data),
      onAcceptWithDetails: (details) => _handleAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHighlighted =
            highlightColor != null && candidateData.isNotEmpty;

        final content = isHighlighted
            ? AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: highlightColor!.withValues(alpha: 0.14),
                  border: Border.all(
                    color: highlightColor!.withValues(alpha: 0.85),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: child,
              )
            : child;

        if (expand) {
          return SizedBox.expand(child: content);
        }
        return content;
      },
    );
  }
}
