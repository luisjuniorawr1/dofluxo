import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/dashboard_layout_breakpoints.dart';
import '../config/dashboard_stages.dart';
import '../../../core/utils/theme_utils.dart';
import '../models/project_board_item.dart';
import 'project_board_card.dart';

bool _useImmediateDrag() {
  return kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}

class ProjectMoveIntent {
  const ProjectMoveIntent({
    required this.projectId,
    required this.targetStage,
    required this.targetInsertIndex,
    this.beforeVisibleProjectId,
    this.afterVisibleProjectId,
  });

  final String projectId;
  final DashboardStageId targetStage;
  final int targetInsertIndex;
  final String? beforeVisibleProjectId;
  final String? afterVisibleProjectId;
}

typedef ProjectMoveCallback = Future<void> Function(ProjectMoveIntent intent);
typedef ProjectTapCallback = void Function(String projectId);
typedef ProjectDragStartedCallback = void Function(String projectId);
typedef ProjectDragEndedCallback = VoidCallback;

class ProjectDragData {
  const ProjectDragData({
    required this.projectId,
    required this.fromStageId,
    required this.item,
    required this.stage,
  });

  final String projectId;
  final DashboardStageId fromStageId;
  final ProjectBoardItem item;
  final DashboardStage stage;
}

class WorkflowColumn extends StatefulWidget {
  const WorkflowColumn({
    super.key,
    required this.stage,
    required this.items,
    this.draggingProjectId,
    this.onProjectMove,
    this.onProjectTap,
    this.onDragStarted,
    this.onDragEnded,
    this.isMobileCarousel = false,
  });

  final DashboardStage stage;
  final List<ProjectBoardItem> items;
  final ValueListenable<String?>? draggingProjectId;
  final ProjectMoveCallback? onProjectMove;
  final ProjectTapCallback? onProjectTap;
  final ProjectDragStartedCallback? onDragStarted;
  final ProjectDragEndedCallback? onDragEnded;
  final bool isMobileCarousel;

  @override
  State<WorkflowColumn> createState() => _WorkflowColumnState();
}

class _WorkflowColumnState extends State<WorkflowColumn> {
  final _cardKeys = <String, GlobalObjectKey>{};

  /// Sem setState durante o drag (setState no Web quebra/trava o Draggable).
  final ValueNotifier<int?> _hoverInsertIndex = ValueNotifier<int?>(null);

  @override
  void dispose() {
    _hoverInsertIndex.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WorkflowColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentIds = widget.items.map((item) => item.id).toSet();
    _cardKeys.removeWhere((id, _) => !currentIds.contains(id));
  }

  GlobalObjectKey _cardKey(String id) =>
      _cardKeys.putIfAbsent(id, () => GlobalObjectKey(id));

  int _resolveInsertIndex({
    required Offset globalOffset,
    required String draggedProjectId,
  }) {
    final pointerY = globalOffset.dy + 12;
    var insertIndex = 0;

    for (final item in widget.items) {
      if (item.id == draggedProjectId) continue;

      final ctx = _cardKey(item.id).currentContext;
      final box = ctx?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        insertIndex++;
        continue;
      }

      final top = box.localToGlobal(Offset.zero).dy;
      final mid = top + box.size.height / 2;
      if (pointerY < mid) return insertIndex;
      insertIndex++;
    }
    return insertIndex;
  }

  void _handleMove(DragTargetDetails<ProjectDragData> details) {
    final index = _resolveInsertIndex(
      globalOffset: details.offset,
      draggedProjectId: details.data.projectId,
    );
    if (_hoverInsertIndex.value != index) {
      _hoverInsertIndex.value = index;
    }
  }

  void _emitMove({
    required ProjectDragData data,
    required int insertIndex,
  }) {
    final column =
        widget.items.where((item) => item.id != data.projectId).toList();
    final index = insertIndex.clamp(0, column.length);
    widget.onProjectMove?.call(
      ProjectMoveIntent(
        projectId: data.projectId,
        targetStage: widget.stage.id,
        targetInsertIndex: index,
        beforeVisibleProjectId: index > 0 ? column[index - 1].id : null,
        afterVisibleProjectId:
            index < column.length ? column[index].id : null,
      ),
    );
  }

  void _handleDrop(DragTargetDetails<ProjectDragData> details) {
    if (widget.onProjectMove == null) return;
    final insertIndex = _hoverInsertIndex.value ??
        _resolveInsertIndex(
          globalOffset: details.offset,
          draggedProjectId: details.data.projectId,
        );
    _hoverInsertIndex.value = null;
    _emitMove(data: details.data, insertIndex: insertIndex);
  }

  Widget _buildPlaceholder(ThemeData theme) {
    final accent = theme.colorScheme.primary;
    return Padding(
      key: const ValueKey('drop-placeholder'),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCardList({
    required double feedbackWidth,
    required String? draggingId,
  }) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<int?>(
      valueListenable: _hoverInsertIndex,
      builder: (context, hoverIndex, _) {
        final children = <Widget>[];
        var insertSlot = 0;

        for (final item in widget.items) {
          final isDragged = item.id == draggingId;

          if (draggingId != null &&
              hoverIndex != null &&
              !isDragged &&
              insertSlot == hoverIndex) {
            children.add(_buildPlaceholder(theme));
          }

          if (isDragged) {
            // Fantasma: preserva altura para os outros cards não subirem.
            children.add(
              Padding(
                key: _cardKey(item.id),
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.3,
                    child: ProjectBoardCard(item: item),
                  ),
                ),
              ),
            );
            continue;
          }

          children.add(
            Padding(
              key: _cardKey(item.id),
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: IgnorePointer(
                // Durante drag, deixa o DragTarget receber o ponteiro.
                ignoring: draggingId != null,
                child: RepaintBoundary(
                  child: _DraggableProjectCard(
                    item: item,
                    stage: widget.stage,
                    feedbackWidth: feedbackWidth,
                    onProjectMove: widget.onProjectMove,
                    onProjectTap: widget.onProjectTap,
                    onDragStarted: widget.onDragStarted,
                    onDragEnded: widget.onDragEnded,
                    isMobileCarousel: widget.isMobileCarousel,
                  ),
                ),
              ),
            ),
          );
          insertSlot++;
        }

        if (draggingId != null &&
            hoverIndex != null &&
            hoverIndex >= insertSlot) {
          children.add(_buildPlaceholder(theme));
        }

        if (widget.items.isEmpty) {
          return Center(
            child: Text(
              'Vazio',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return ListView(
          physics: widget.isMobileCarousel
              ? const BouncingScrollPhysics()
              : const ClampingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: children,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final columnColor = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : widget.stage.columnBackground;

    return LayoutBuilder(
      builder: (context, constraints) {
        final feedbackWidth = constraints.maxWidth > 0
            ? constraints.maxWidth - 24
            : widget.stage.columnWidth;

        return DragTarget<ProjectDragData>(
          onWillAcceptWithDetails: (_) => widget.onProjectMove != null,
          onMove: _handleMove,
          onLeave: (_) => _hoverInsertIndex.value = null,
          onAcceptWithDetails: _handleDrop,
          builder: (context, candidate, rejected) {
            final highlighted = candidate.isNotEmpty;
            return Container(
              width: constraints.maxWidth > 0 ? constraints.maxWidth : null,
              decoration: BoxDecoration(
                color: columnColor,
                borderRadius: BorderRadius.circular(8),
                border: widget.stage.isPriority
                    ? Border.all(
                        color: isDark
                            ? const Color(0xFFE74C4C)
                            : const Color(0xFFDC2626),
                        width: 2.5,
                      )
                    : highlighted
                        ? Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.35,
                            ),
                            width: 1.5,
                          )
                        : null,
                boxShadow: widget.stage.isPriority
                    ? [
                        BoxShadow(
                          color: const Color(0xFFE74C4C)
                              .withValues(alpha: isDark ? 0.25 : 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.stage.title,
                          style: ThemeUtils.sectionTitle(context).copyWith(
                            color: widget.stage.isPriority && !isDark
                                ? const Color(0xFFB91C1C)
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (widget.items.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.items.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (widget.stage.isPriority) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Prioridade máxima',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFFB91C1C),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Expanded(
                    child: widget.draggingProjectId == null
                        ? _buildCardList(
                            feedbackWidth: feedbackWidth,
                            draggingId: null,
                          )
                        : ValueListenableBuilder<String?>(
                            valueListenable: widget.draggingProjectId!,
                            builder: (context, draggingId, _) {
                              return _buildCardList(
                                feedbackWidth: feedbackWidth,
                                draggingId: draggingId,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DraggableProjectCard extends StatelessWidget {
  const _DraggableProjectCard({
    required this.item,
    required this.stage,
    required this.feedbackWidth,
    this.onProjectMove,
    this.onProjectTap,
    this.onDragStarted,
    this.onDragEnded,
    this.isMobileCarousel = false,
  });

  final ProjectBoardItem item;
  final DashboardStage stage;
  final double feedbackWidth;
  final ProjectMoveCallback? onProjectMove;
  final ProjectTapCallback? onProjectTap;
  final ProjectDragStartedCallback? onDragStarted;
  final ProjectDragEndedCallback? onDragEnded;
  final bool isMobileCarousel;

  @override
  Widget build(BuildContext context) {
    final card = ProjectBoardCard(item: item);
    final isMobileLayout =
        isMobileCarousel ||
        MediaQuery.sizeOf(context).width <
            DashboardLayoutBreakpoints.mobileCarousel;

    Widget buildTappable(Widget child) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onProjectTap != null ? () => onProjectTap!(item.id) : null,
          borderRadius: BorderRadius.circular(6),
          child: child,
        ),
      );
    }

    if (onProjectMove == null) return buildTappable(card);

    final dragData = ProjectDragData(
      projectId: item.id,
      fromStageId: stage.id,
      item: item,
      stage: stage,
    );

    final feedback = Material(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: feedbackWidth,
        child: ProjectBoardCard(item: item, compact: true),
      ),
    );

    void startDrag() => onDragStarted?.call(item.id);
    void endDrag([DraggableDetails? _]) => onDragEnded?.call();

    if (isMobileLayout || !_useImmediateDrag()) {
      return LongPressDraggable<ProjectDragData>(
        data: dragData,
        feedback: feedback,
        childWhenDragging: const SizedBox.shrink(),
        delay: const Duration(milliseconds: 120),
        hapticFeedbackOnStart: false,
        onDragStarted: startDrag,
        onDragEnd: endDrag,
        onDraggableCanceled: (_, _) => endDrag(),
        child: buildTappable(card),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<ProjectDragData>(
        data: dragData,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: feedback,
        childWhenDragging: const SizedBox.shrink(),
        maxSimultaneousDrags: 1,
        onDragStarted: startDrag,
        onDragEnd: endDrag,
        onDraggableCanceled: (_, _) => endDrag(),
        child: buildTappable(card),
      ),
    );
  }
}
