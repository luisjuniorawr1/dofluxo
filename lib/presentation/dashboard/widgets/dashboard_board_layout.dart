import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../config/dashboard_layout_breakpoints.dart';
import '../config/dashboard_zones.dart';
import '../config/kanban_constants.dart';
import '../models/project_board_item.dart';
import '../utils/board_order_utils.dart';
import 'kanban_column.dart';
import 'project_board_card.dart';

typedef ProjectMoveCallback = Future<void> Function(
  String projectId,
  DashboardZoneId targetZone,
  int insertIndex,
  double boardOrder,
);

typedef ProjectTapCallback = void Function(String projectId);

/// Layout do wireframe: espelhos | gap | workflow | status.
class DashboardBoardLayout extends StatefulWidget {
  const DashboardBoardLayout({
    super.key,
    required this.itemsByZone,
    required this.fullItemsByZone,
    this.onProjectMove,
    this.onProjectTap,
  });

  /// Lista visível (respeita filtros Job / Planejamento).
  final Map<String, List<ProjectBoardItem>> itemsByZone;

  /// Lista completa (sem filtro) para calcular ordem real no backend.
  final Map<String, List<ProjectBoardItem>> fullItemsByZone;
  final ProjectMoveCallback? onProjectMove;
  final ProjectTapCallback? onProjectTap;

  @override
  State<DashboardBoardLayout> createState() => _DashboardBoardLayoutState();
}

class _DashboardBoardLayoutState extends State<DashboardBoardLayout> {
  late final PageController _pageController;
  final ValueNotifier<String?> _draggingItemId = ValueNotifier(null);
  final ValueNotifier<bool> _isDragging = ValueNotifier(false);
  final Set<String> _movingProjectIds = {};
  int _currentPage = 0;

  /// Estado otimista: posiciona o card no destino na hora do drop, antes de o
  /// Firestore confirmar (evita o card "sumir e reaparecer").
  Map<String, List<ProjectBoardItem>>? _optimisticBoard;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: DashboardLayoutBreakpoints.mobileColumnViewportFraction,
    );
  }

  @override
  void didUpdateWidget(covariant DashboardBoardLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.itemsByZone, widget.itemsByZone)) {
      _optimisticBoard = null;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _draggingItemId.dispose();
    _isDragging.dispose();
    super.dispose();
  }

  Map<String, List<ProjectBoardItem>> get _displayedBoard =>
      _optimisticBoard ?? widget.itemsByZone;

  void _onDragStarted(String itemId) {
    _draggingItemId.value = itemId;
    _isDragging.value = true;
  }

  void _onDragEnded() {
    _draggingItemId.value = null;
    _isDragging.value = false;
  }

  void _applyOptimisticMove(
    ProjectBoardItem item,
    String targetColumnId,
    int insertIndex,
  ) {
    final base = _displayedBoard;
    final clone = <String, List<ProjectBoardItem>>{
      for (final entry in base.entries)
        entry.key: List<ProjectBoardItem>.from(entry.value),
    };

    for (final column in KanbanConstants.allZones) {
      if (column.isMirror) continue;
      clone[column.id]?.removeWhere((i) => i.id == item.id);
    }

    final target = clone[targetColumnId];
    if (target != null) {
      final idx = insertIndex.clamp(0, target.length);
      target.insert(idx, item);
    }

    setState(() => _optimisticBoard = clone);
  }

  Future<void> _handleMove(
    KanbanDragData<ProjectBoardItem> dragData,
    String targetColumnId,
    int visibleDropIndex,
  ) async {
    final onMove = widget.onProjectMove;
    if (onMove == null) return;

    final item = dragData.item;
    if (_movingProjectIds.contains(item.id)) return;

    final zone = KanbanConstants.findById(targetColumnId)?.zoneId;
    if (zone == null || !zone.acceptsDragDrop) return;

    final visibleColumn = _displayedBoard[targetColumnId] ?? const [];
    final fullColumn = widget.fullItemsByZone[targetColumnId] ?? const [];

    final visibleDragIndex = dragData.fromColumnId == targetColumnId
        ? dragData.visibleDragIndex
        : null;

    final realIndex = BoardOrderUtils.resolveKanbanTargetIndex(
      visibleColumn: visibleColumn,
      fullColumn: fullColumn,
      draggedProjectId: item.id,
      visibleDropIndex: visibleDropIndex,
      visibleDragIndex: visibleDragIndex,
    );

    final sourceZone = KanbanConstants.findById(dragData.fromColumnId)?.zoneId;
    if (sourceZone == zone) {
      final fromFullIndex = fullColumn.indexWhere((entry) => entry.id == item.id);
      // Insert index is in the list WITHOUT the dragged item. Same place =
      // fromFullIndex only (fromFullIndex+1 is a real one-step move down).
      if (fromFullIndex >= 0 && realIndex == fromFullIndex) {
        return;
      }
    }

    final boardOrder = BoardOrderUtils.orderForInsertIndex(
      columnItems: fullColumn,
      insertIndex: realIndex,
      draggedProjectId: item.id,
    );

    // Same-column down: drop on a card = insert after it → visibleDropIndex
    // already matches the post-removal insert index. Up/cross: insert-before.
    final optimisticIndex = visibleDropIndex;
    _applyOptimisticMove(item, targetColumnId, optimisticIndex);
    _onDragEnded();

    _movingProjectIds.add(item.id);
    try {
      await onMove(item.id, zone, realIndex, boardOrder);
    } finally {
      _movingProjectIds.remove(item.id);
    }
  }

  Widget _buildCard(
    BuildContext context,
    KanbanColumnConfig column,
    ProjectBoardItem item, {
    bool isDragging = false,
    bool isPlaceholder = false,
  }) {
    return ProjectBoardCard(
      item: item,
      zoneCardColor: column.cardHeaderColor,
      isDragging: isDragging,
      isPlaceholder: isPlaceholder,
      interactive: !isPlaceholder && !isDragging,
    );
  }

  KanbanColumn<ProjectBoardItem> _buildZone(
    KanbanColumnConfig column, {
    bool isMobileCarousel = false,
  }) {
    return KanbanColumn<ProjectBoardItem>(
      column: column,
      items: _displayedBoard[column.id] ?? const [],
      itemId: (item) => item.id,
      cardBuilder: (context, item, {isDragging = false, isPlaceholder = false}) =>
          _buildCard(
        context,
        column,
        item,
        isDragging: isDragging,
        isPlaceholder: isPlaceholder,
      ),
      draggingItemId: _draggingItemId,
      onMove: widget.onProjectMove == null ? null : _handleMove,
      onTap: widget.onProjectTap == null ? null : (item) => widget.onProjectTap!(item.id),
      onDragStarted: _onDragStarted,
      onDragEnded: _onDragEnded,
      isMobileCarousel: isMobileCarousel,
    );
  }

  Widget _buildStackedGroup(DashboardColumnGroup group, {bool isMobileCarousel = false}) {
    final zones = group.zones;
    if (zones.length == 1) {
      return _buildZone(zones.first.column, isMobileCarousel: isMobileCarousel);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < zones.length; i++) ...[
          if (i > 0) const SizedBox(height: KanbanConstants.stackedZoneGap),
          Expanded(
            flex: zones[i].column.stackFlex,
            child: _buildZone(zones[i].column, isMobileCarousel: isMobileCarousel),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < DashboardLayoutBreakpoints.mobileCarousel;

          if (isMobile) {
            return _MobileCarousel(
              pageController: _pageController,
              currentPage: _currentPage,
              isDragging: _isDragging,
              onPageChanged: (index) => setState(() => _currentPage = index),
              onGoToPage: (index) {
                if (index < 0 || index >= KanbanConstants.mobileZones.length) return;
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                );
              },
              buildZone: (column) => _buildZone(column, isMobileCarousel: true),
            );
          }

          final layout = KanbanConstants.desktopLayout;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < layout.length; i++) ...[
                Expanded(
                  flex: layout[i].flex,
                  child: _buildStackedGroup(layout[i]),
                ),
                if (i < layout.length - 1)
                  SizedBox(
                    width: layout[i].gapAfter > 0
                        ? layout[i].gapAfter
                        : KanbanConstants.columnSpacing,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MobileCarousel extends StatelessWidget {
  const _MobileCarousel({
    required this.pageController,
    required this.currentPage,
    required this.isDragging,
    required this.onPageChanged,
    required this.onGoToPage,
    required this.buildZone,
  });

  final PageController pageController;
  final int currentPage;
  final ValueNotifier<bool> isDragging;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onGoToPage;
  final Widget Function(KanbanColumnConfig column) buildZone;

  @override
  Widget build(BuildContext context) {
    final zones = KanbanConstants.mobileZones;
    final canGoBack = currentPage > 0;
    final canGoForward = currentPage < zones.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: canGoBack ? () => onGoToPage(currentPage - 1) : null,
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: 'Área anterior',
            ),
            const Spacer(),
            IconButton(
              onPressed: canGoForward ? () => onGoToPage(currentPage + 1) : null,
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'Próxima área',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: isDragging,
            builder: (context, dragging, _) {
              return PageView.builder(
                controller: pageController,
                padEnds: false,
                physics: dragging
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                onPageChanged: onPageChanged,
                itemCount: zones.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : DashboardLayoutBreakpoints.mobileColumnSpacing / 2,
                      right: DashboardLayoutBreakpoints.mobileColumnSpacing,
                    ),
                    child: buildZone(zones[index]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
