import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/agency_theme_colors.dart';
import '../config/dashboard_layout_breakpoints.dart';
import '../config/dashboard_stages.dart';
import '../../../core/utils/theme_utils.dart';
import '../models/project_board_item.dart';
import '../utils/board_order_utils.dart';
import 'project_board_card.dart';

bool _useImmediateDrag() {
  return kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}

typedef ProjectMoveCallback = Future<void> Function(
  String projectId,
  DashboardStageId targetStage,
  int insertIndex,
  double boardOrder,
);

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

class WorkflowColumn extends StatelessWidget {
  const WorkflowColumn({
    super.key,
    required this.stage,
    required this.items,
    required this.draggingProjectId,
    this.onProjectMove,
    this.onProjectTap,
    this.onDragStarted,
    this.onDragEnded,
    this.isMobileCarousel = false,
  });

  final DashboardStage stage;
  final List<ProjectBoardItem> items;
  final ValueListenable<String?> draggingProjectId;
  final ProjectMoveCallback? onProjectMove;
  final ProjectTapCallback? onProjectTap;
  final ProjectDragStartedCallback? onDragStarted;
  final ProjectDragEndedCallback? onDragEnded;
  final bool isMobileCarousel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final columnColor = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : stage.columnBackground;

    return LayoutBuilder(
      builder: (context, constraints) {
        final feedbackWidth =
            constraints.maxWidth > 0 ? constraints.maxWidth - 24 : stage.columnWidth;

        return Container(
          width: constraints.maxWidth > 0 ? constraints.maxWidth : null,
          decoration: BoxDecoration(
            color: columnColor,
            borderRadius: BorderRadius.circular(20),
            border: stage.isPriority
                ? Border.all(
                    color: isDark ? const Color(0xFFE74C4C) : const Color(0xFFDC2626),
                    width: 2.5,
                  )
                : null,
            boxShadow: stage.isPriority
                ? [
                    BoxShadow(
                      color: const Color(0xFFE74C4C).withValues(alpha: isDark ? 0.25 : 0.12),
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
                      stage.title,
                      style: ThemeUtils.sectionTitle(context).copyWith(
                        color: stage.isPriority && !isDark
                            ? const Color(0xFFB91C1C)
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (items.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${items.length}',
                        style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
              if (stage.isPriority) ...[
                const SizedBox(height: 4),
                Text(
                  'Prioridade máxima',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Expanded(
                child: ValueListenableBuilder<String?>(
                  valueListenable: draggingProjectId,
                  builder: (context, draggingId, _) {
                    final isDragging = draggingId != null;
                    final visibleItems = draggingId == null
                        ? items
                        : items.where((item) => item.id != draggingId).toList();

                    if (visibleItems.isEmpty) {
                      return _CardDropSlot(
                        insertIndex: 0,
                        stage: stage,
                        columnItems: items,
                        isDragging: isDragging,
                        isExpandedEmpty: true,
                        onProjectMove: onProjectMove,
                      );
                    }

                    return CustomScrollView(
                      physics: isMobileCarousel
                          ? const BouncingScrollPhysics()
                          : const ClampingScrollPhysics(),
                      slivers: [
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index.isEven) {
                                return _CardDropSlot(
                                  insertIndex: index ~/ 2,
                                  stage: stage,
                                  columnItems: items,
                                  isDragging: isDragging,
                                  onProjectMove: onProjectMove,
                                );
                              }

                              final item = visibleItems[index ~/ 2];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 1),
                                child: RepaintBoundary(
                                  child: _DraggableProjectCard(
                                    item: item,
                                    stage: stage,
                                    feedbackWidth: feedbackWidth,
                                    onProjectMove: onProjectMove,
                                    onProjectTap: onProjectTap,
                                    onDragStarted: onDragStarted,
                                    onDragEnded: onDragEnded,
                                    isMobileCarousel: isMobileCarousel,
                                  ),
                                ),
                              );
                            },
                            childCount: visibleItems.length * 2 + 1,
                          ),
                        ),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _CardDropSlot(
                            insertIndex: visibleItems.length,
                            stage: stage,
                            columnItems: items,
                            isDragging: isDragging,
                            fillRemaining: true,
                            onProjectMove: onProjectMove,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardDropSlot extends StatelessWidget {
  const _CardDropSlot({
    required this.insertIndex,
    required this.stage,
    required this.columnItems,
    required this.isDragging,
    this.isExpandedEmpty = false,
    this.fillRemaining = false,
    this.onProjectMove,
  });

  final int insertIndex;
  final DashboardStage stage;
  final List<ProjectBoardItem> columnItems;
  final bool isDragging;
  final bool isExpandedEmpty;
  final bool fillRemaining;
  final ProjectMoveCallback? onProjectMove;

  void _handleAccept(ProjectDragData data) {
    final fromIndex = columnItems.indexWhere((item) => item.id == data.projectId);
    final isSameColumn = data.fromStageId == stage.id;

    if (isSameColumn && fromIndex != -1) {
      if (insertIndex == fromIndex || insertIndex == fromIndex + 1) return;
    }

    final boardOrder = BoardOrderUtils.orderForInsertIndex(
      columnItems: columnItems,
      insertIndex: insertIndex,
      draggedProjectId: data.projectId,
    );

    onProjectMove?.call(data.projectId, stage.id, insertIndex, boardOrder);
  }

  Widget _buildIndicator(BuildContext context, Color accent, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      height: 3,
      margin: EdgeInsets.symmetric(horizontal: fullWidth ? 8 : 4),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AgencyThemeColors.of(context).contentAccent;

    return DragTarget<ProjectDragData>(
      onWillAcceptWithDetails: (_) => onProjectMove != null,
      onAcceptWithDetails: (details) => _handleAccept(details.data),
      builder: (context, candidate, rejected) {
        final isActive = candidate.isNotEmpty;

        if (isExpandedEmpty) {
          return SizedBox.expand(
            child: Center(
              child: isActive
                  ? _buildIndicator(context, accent, fullWidth: true)
                  : Text(
                      'Vazio',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
          );
        }

        if (fillRemaining) {
          return SizedBox.expand(
            child: Align(
              alignment: isActive ? Alignment.topCenter : Alignment.center,
              child: isActive
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _buildIndicator(context, accent, fullWidth: true),
                    )
                  : const SizedBox.shrink(),
            ),
          );
        }

        final slotHeight = isActive
            ? 14.0
            : isDragging
                ? 10.0
                : 1.0;

        return SizedBox(
          height: slotHeight,
          child: isActive
              ? Center(child: _buildIndicator(context, accent))
              : const SizedBox.shrink(),
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
    final isMobileLayout = isMobileCarousel ||
        MediaQuery.sizeOf(context).width < DashboardLayoutBreakpoints.mobileCarousel;

    void openProject() => onProjectTap?.call(item.id);

    Widget buildTappable(Widget child) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onProjectTap != null ? openProject : null,
          borderRadius: BorderRadius.circular(16),
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

    final feedback = RepaintBoundary(
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: feedbackWidth,
          child: ProjectBoardCard(item: item, compact: true),
        ),
      ),
    );

    void startDrag() => onDragStarted?.call(item.id);
    void endDrag([DraggableDetails? _]) => onDragEnded?.call();

    if (isMobileLayout || !_useImmediateDrag()) {
      return LongPressDraggable<ProjectDragData>(
        data: dragData,
        feedback: feedback,
        delay: const Duration(milliseconds: 120),
        hapticFeedbackOnStart: false,
        onDragStarted: startDrag,
        onDragCompleted: endDrag,
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
        maxSimultaneousDrags: 1,
        onDragStarted: startDrag,
        onDragCompleted: endDrag,
        onDragEnd: endDrag,
        onDraggableCanceled: (_, _) => endDrag(),
        child: buildTappable(card),
      ),
    );
  }
}
