import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/agency_theme_colors.dart';
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

typedef ProjectMoveCallback = Future<void> Function(String projectId, DashboardStageId targetStage);
typedef ProjectTapCallback = void Function(String projectId);

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

/// Coluna Criação + INCÊNDIOS empilhadas (referência Pequi).
class WorkflowCriacaoIncendiosColumn extends StatelessWidget {
  const WorkflowCriacaoIncendiosColumn({
    super.key,
    required this.criacaoStage,
    required this.incendiosStage,
    required this.criacaoItems,
    required this.incendiosItems,
    this.onProjectMove,
    this.onProjectTap,
    this.onDragStarted,
    this.onDragEnded,
  });

  final DashboardStage criacaoStage;
  final DashboardStage incendiosStage;
  final List<ProjectBoardItem> criacaoItems;
  final List<ProjectBoardItem> incendiosItems;
  final ProjectMoveCallback? onProjectMove;
  final ProjectTapCallback? onProjectTap;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: WorkflowColumn(
            stage: criacaoStage,
            items: criacaoItems,
            onProjectMove: onProjectMove,
            onProjectTap: onProjectTap,
            onDragStarted: onDragStarted,
            onDragEnded: onDragEnded,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          flex: 2,
          child: WorkflowColumn(
            stage: incendiosStage,
            items: incendiosItems,
            onProjectMove: onProjectMove,
            onProjectTap: onProjectTap,
            onDragStarted: onDragStarted,
            onDragEnded: onDragEnded,
          ),
        ),
      ],
    );
  }
}

class WorkflowColumn extends StatelessWidget {
  const WorkflowColumn({
    super.key,
    required this.stage,
    required this.items,
    this.onProjectMove,
    this.onProjectTap,
    this.onDragStarted,
    this.onDragEnded,
    this.isMobileCarousel = false,
  });

  final DashboardStage stage;
  final List<ProjectBoardItem> items;
  final ProjectMoveCallback? onProjectMove;
  final ProjectTapCallback? onProjectTap;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;
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
        final feedbackWidth = constraints.maxWidth > 0 ? constraints.maxWidth - 24 : stage.columnWidth;

        return Container(
          width: constraints.maxWidth > 0 ? constraints.maxWidth : null,
          decoration: BoxDecoration(
            color: columnColor,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stage.title,
                style: ThemeUtils.sectionTitle(context),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: DragTarget<ProjectDragData>(
                  onWillAcceptWithDetails: (details) {
                    if (onProjectMove == null) return false;
                    return details.data.fromStageId != stage.id;
                  },
                  onAcceptWithDetails: (details) {
                    onProjectMove?.call(details.data.projectId, stage.id);
                  },
                  builder: (context, candidate, rejected) {
                    final isHighlighted = candidate.isNotEmpty;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: isHighlighted
                            ? Border.all(color: AgencyThemeColors.of(context).contentAccent, width: 2)
                            : null,
                      ),
                      child: items.isEmpty
                          ? Center(
                              child: Text(
                                isHighlighted ? 'Solte aqui' : 'Vazio',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : stage.compactGrid
                              ? _IncendiosGrid(
                                  items: items,
                                  stage: stage,
                                  feedbackWidth: feedbackWidth,
                                  onProjectMove: onProjectMove,
                                  onProjectTap: onProjectTap,
                                  onDragStarted: onDragStarted,
                                  onDragEnded: onDragEnded,
                                  isMobileCarousel: isMobileCarousel,
                                )
                              : ListView.separated(
                                  physics: isMobileCarousel
                                      ? const BouncingScrollPhysics()
                                      : const ClampingScrollPhysics(),
                                  itemCount: items.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    return _DraggableProjectCard(
                                      item: items[index],
                                      stage: stage,
                                      feedbackWidth: feedbackWidth,
                                      onProjectMove: onProjectMove,
                                      onProjectTap: onProjectTap,
                                      onDragStarted: onDragStarted,
                                      onDragEnded: onDragEnded,
                                      isMobileCarousel: isMobileCarousel,
                                    );
                                  },
                                ),
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

class _DraggableProjectCard extends StatelessWidget {
  const _DraggableProjectCard({
    required this.item,
    required this.stage,
    required this.feedbackWidth,
    this.onProjectMove,
    this.onProjectTap,
    this.onDragStarted,
    this.onDragEnded,
    this.compact = false,
    this.isMobileCarousel = false,
  });

  final ProjectBoardItem item;
  final DashboardStage stage;
  final double feedbackWidth;
  final ProjectMoveCallback? onProjectMove;
  final ProjectTapCallback? onProjectTap;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;
  final bool compact;
  final bool isMobileCarousel;

  @override
  Widget build(BuildContext context) {
    final card = ProjectBoardCard(item: item, stage: stage, compact: compact);
    final isMobileLayout = isMobileCarousel ||
        MediaQuery.sizeOf(context).width < DashboardLayoutBreakpoints.mobileCarousel;

    void openProject() => onProjectTap?.call(item.id);

    Widget buildTappable(Widget child) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onProjectTap != null ? openProject : null,
          borderRadius: BorderRadius.circular(compact ? 12 : 16),
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
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: feedbackWidth,
        child: Opacity(opacity: 0.92, child: card),
      ),
    );

    final childWhenDragging = Opacity(opacity: 0.35, child: buildTappable(card));

    void endDrag([DraggableDetails? _]) => onDragEnded?.call();

    if (isMobileLayout || !_useImmediateDrag()) {
      return LongPressDraggable<ProjectDragData>(
        data: dragData,
        feedback: feedback,
        childWhenDragging: childWhenDragging,
        onDragStarted: onDragStarted,
        onDragEnd: endDrag,
        onDraggableCanceled: (_, __) => endDrag(),
        child: buildTappable(card),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<ProjectDragData>(
        data: dragData,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: feedback,
        childWhenDragging: childWhenDragging,
        onDragStarted: onDragStarted,
        onDragEnd: endDrag,
        onDraggableCanceled: (_, __) => endDrag(),
        child: buildTappable(card),
      ),
    );
  }
}

class _IncendiosGrid extends StatelessWidget {
  const _IncendiosGrid({
    required this.items,
    required this.stage,
    required this.feedbackWidth,
    this.onProjectMove,
    this.onProjectTap,
    this.onDragStarted,
    this.onDragEnded,
    this.isMobileCarousel = false,
  });

  final List<ProjectBoardItem> items;
  final DashboardStage stage;
  final double feedbackWidth;
  final ProjectMoveCallback? onProjectMove;
  final ProjectTapCallback? onProjectTap;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;
  final bool isMobileCarousel;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: isMobileCarousel
          ? const BouncingScrollPhysics()
          : const ClampingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _DraggableProjectCard(
          item: items[index],
          stage: stage,
          feedbackWidth: feedbackWidth / 2,
          onProjectMove: onProjectMove,
          onProjectTap: onProjectTap,
          onDragStarted: onDragStarted,
          onDragEnded: onDragEnded,
          compact: true,
          isMobileCarousel: isMobileCarousel,
        );
      },
    );
  }
}
