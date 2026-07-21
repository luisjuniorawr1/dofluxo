import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
    required this.visibleDropIndex,
    this.visibleDragIndex,
  });

  final String projectId;
  final DashboardStageId targetStage;
  final int visibleDropIndex;
  final int? visibleDragIndex;
}

typedef ProjectMoveCallback = Future<void> Function(ProjectMoveIntent intent);
typedef ProjectTapCallback = void Function(String projectId);
typedef ProjectDragStartedCallback = void Function(String projectId);
typedef ProjectDragEndedCallback = void Function(String projectId);

class ProjectDragData {
  const ProjectDragData({
    required this.projectId,
    required this.fromStageId,
    required this.item,
    required this.visibleDragIndex,
  });

  final String projectId;
  final DashboardStageId fromStageId;
  final ProjectBoardItem item;
  final int? visibleDragIndex;
}

/// Coluna Criação + INCÊNDIOS empilhadas (referência Pequi).
class WorkflowCriacaoIncendiosColumn extends StatelessWidget {
  const WorkflowCriacaoIncendiosColumn({
    super.key,
    required this.criacaoStage,
    required this.incendiosStage,
    required this.criacaoItems,
    required this.incendiosItems,
    this.draggingProjectId,
    this.onProjectMove,
    this.onProjectTap,
    this.onDragStarted,
    this.onDragEnded,
  });

  final DashboardStage criacaoStage;
  final DashboardStage incendiosStage;
  final List<ProjectBoardItem> criacaoItems;
  final List<ProjectBoardItem> incendiosItems;
  final ValueListenable<String?>? draggingProjectId;
  final ProjectMoveCallback? onProjectMove;
  final ProjectTapCallback? onProjectTap;
  final ProjectDragStartedCallback? onDragStarted;
  final ProjectDragEndedCallback? onDragEnded;

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
            draggingProjectId: draggingProjectId,
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
            draggingProjectId: draggingProjectId,
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

  void _acceptDrop(ProjectDragData data, int visibleDropIndex) {
    onProjectMove?.call(
      ProjectMoveIntent(
        projectId: data.projectId,
        targetStage: stage.id,
        visibleDropIndex: visibleDropIndex,
        visibleDragIndex: data.fromStageId == stage.id ? data.visibleDragIndex : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final columnColor = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : stage.columnBackground;
    final accent = stage.cardBackground;

    return LayoutBuilder(
      builder: (context, constraints) {
        final feedbackWidth = _feedbackWidth(constraints.maxWidth, stage.columnWidth);

        Widget buildBody(String? draggingId) {
          if (items.isEmpty) {
            return _DropTargetSlot(
              accent: accent,
              columnColor: columnColor,
              enabled: onProjectMove != null,
              fill: true,
              onAccept: (data) => _acceptDrop(data, 0),
              child: Center(
                child: Text(
                  'Arraste um item para cá',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          if (stage.compactGrid) {
            return _IncendiosGrid(
              items: items,
              stage: stage,
              accent: accent,
              columnColor: columnColor,
              feedbackWidth: feedbackWidth,
              draggingId: draggingId,
              onProjectMove: onProjectMove,
              onProjectTap: onProjectTap,
              onDragStarted: onDragStarted,
              onDragEnded: onDragEnded,
              onAcceptDrop: _acceptDrop,
              isMobileCarousel: isMobileCarousel,
            );
          }

          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: CustomScrollView(
              primary: false,
              physics: isMobileCarousel
                  ? const BouncingScrollPhysics()
                  : const ClampingScrollPhysics(),
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = items[index];
                    final card = _KanbanDraggableCard(
                      item: item,
                      stage: stage,
                      index: index,
                      feedbackWidth: feedbackWidth,
                      onProjectMove: onProjectMove,
                      onProjectTap: onProjectTap,
                      onDragStarted: onDragStarted,
                      onDragEnded: onDragEnded,
                      isMobileCarousel: isMobileCarousel,
                    );

                    if (draggingId == item.id) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: card,
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DropTargetSlot(
                        accent: accent,
                        columnColor: columnColor,
                        enabled: onProjectMove != null,
                        onAccept: (data) => _acceptDrop(data, index),
                        onWillAccept: (data) => data.projectId != item.id,
                        child: card,
                      ),
                    );
                  }, childCount: items.length),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _DropTargetSlot(
                    accent: accent,
                    columnColor: columnColor,
                    enabled: onProjectMove != null,
                    fill: true,
                    onAccept: (data) => _acceptDrop(data, items.length),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          );
        }

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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      stage.title,
                      style: ThemeUtils.sectionTitle(context),
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
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: draggingProjectId == null
                    ? buildBody(null)
                    : ValueListenableBuilder<String?>(
                        valueListenable: draggingProjectId!,
                        builder: (context, draggingId, _) => buildBody(draggingId),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _feedbackWidth(double maxWidth, double fallback) {
    final base = maxWidth > 0 ? maxWidth - 24 : fallback;
    return base.clamp(120.0, 360.0);
  }
}

class _DropTargetSlot extends StatelessWidget {
  const _DropTargetSlot({
    required this.accent,
    required this.columnColor,
    required this.enabled,
    required this.onAccept,
    required this.child,
    this.fill = false,
    this.onWillAccept,
  });

  final Color accent;
  final Color columnColor;
  final bool enabled;
  final void Function(ProjectDragData data) onAccept;
  final Widget child;
  final bool fill;
  final bool Function(ProjectDragData data)? onWillAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<ProjectDragData>(
      onWillAcceptWithDetails: (details) {
        if (!enabled) return false;
        return onWillAccept?.call(details.data) ?? true;
      },
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidate, rejected) {
        final highlighted = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: fill ? double.infinity : null,
          height: fill ? double.infinity : null,
          decoration: highlighted
              ? BoxDecoration(
                  color: columnColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.85),
                    width: 2,
                  ),
                )
              : null,
          child: child,
        );
      },
    );
  }
}

class _KanbanDraggableCard extends StatefulWidget {
  const _KanbanDraggableCard({
    required this.item,
    required this.stage,
    required this.index,
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
  final int index;
  final double feedbackWidth;
  final ProjectMoveCallback? onProjectMove;
  final ProjectTapCallback? onProjectTap;
  final ProjectDragStartedCallback? onDragStarted;
  final ProjectDragEndedCallback? onDragEnded;
  final bool compact;
  final bool isMobileCarousel;

  @override
  State<_KanbanDraggableCard> createState() => _KanbanDraggableCardState();
}

class _KanbanDraggableCardState extends State<_KanbanDraggableCard> {
  bool _isDragging = false;
  bool _suppressTap = false;

  void _handleTap() {
    if (_isDragging || _suppressTap || widget.onProjectTap == null) return;
    widget.onProjectTap!.call(widget.item.id);
  }

  void _handleDragStarted() {
    setState(() => _isDragging = true);
    widget.onDragStarted?.call(widget.item.id);
  }

  void _handleDragEnd(DraggableDetails details) {
    if (details.wasAccepted) {
      _suppressTap = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _suppressTap = false);
      });
    }
    setState(() => _isDragging = false);
    widget.onDragEnded?.call(widget.item.id);
  }

  void _handleDragCanceled() {
    setState(() => _isDragging = false);
    widget.onDragEnded?.call(widget.item.id);
  }

  @override
  Widget build(BuildContext context) {
    final card = ProjectBoardCard(
      item: widget.item,
      stage: widget.stage,
      compact: widget.compact,
      isDragging: _isDragging,
      isPlaceholder: _isDragging,
      onTap: widget.onProjectTap == null ? null : _handleTap,
    );

    if (widget.onProjectMove == null) return card;

    final dragData = ProjectDragData(
      projectId: widget.item.id,
      fromStageId: widget.stage.id,
      item: widget.item,
      visibleDragIndex: widget.index,
    );

    final feedback = Material(
      color: Colors.transparent,
      elevation: 10,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: widget.feedbackWidth,
        child: ProjectBoardCard(
          item: widget.item,
          stage: widget.stage,
          compact: widget.compact,
          isDragging: true,
        ),
      ),
    );

    final placeholder = ProjectBoardCard(
      item: widget.item,
      stage: widget.stage,
      compact: widget.compact,
      isPlaceholder: true,
    );

    final isMobileLayout = widget.isMobileCarousel ||
        MediaQuery.sizeOf(context).width < DashboardLayoutBreakpoints.mobileCarousel;

    if (isMobileLayout || !_useImmediateDrag()) {
      return LongPressDraggable<ProjectDragData>(
        data: dragData,
        feedback: feedback,
        childWhenDragging: placeholder,
        maxSimultaneousDrags: 1,
        delay: const Duration(milliseconds: 120),
        hapticFeedbackOnStart: false,
        onDragStarted: _handleDragStarted,
        onDragEnd: _handleDragEnd,
        onDraggableCanceled: (_, __) => _handleDragCanceled(),
        child: card,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<ProjectDragData>(
        data: dragData,
        feedback: feedback,
        childWhenDragging: placeholder,
        maxSimultaneousDrags: 1,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: _handleDragStarted,
        onDragEnd: _handleDragEnd,
        onDraggableCanceled: (_, __) => _handleDragCanceled(),
        child: card,
      ),
    );
  }
}

class _IncendiosGrid extends StatelessWidget {
  const _IncendiosGrid({
    required this.items,
    required this.stage,
    required this.accent,
    required this.columnColor,
    required this.feedbackWidth,
    required this.draggingId,
    this.onProjectMove,
    this.onProjectTap,
    this.onDragStarted,
    this.onDragEnded,
    required this.onAcceptDrop,
    this.isMobileCarousel = false,
  });

  final List<ProjectBoardItem> items;
  final DashboardStage stage;
  final Color accent;
  final Color columnColor;
  final double feedbackWidth;
  final String? draggingId;
  final ProjectMoveCallback? onProjectMove;
  final ProjectTapCallback? onProjectTap;
  final ProjectDragStartedCallback? onDragStarted;
  final ProjectDragEndedCallback? onDragEnded;
  final void Function(ProjectDragData data, int visibleDropIndex) onAcceptDrop;
  final bool isMobileCarousel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            primary: false,
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
              final item = items[index];
              final card = _KanbanDraggableCard(
                item: item,
                stage: stage,
                index: index,
                feedbackWidth: feedbackWidth / 2,
                onProjectMove: onProjectMove,
                onProjectTap: onProjectTap,
                onDragStarted: onDragStarted,
                onDragEnded: onDragEnded,
                compact: true,
                isMobileCarousel: isMobileCarousel,
              );

              if (draggingId == item.id) return card;

              return _DropTargetSlot(
                accent: accent,
                columnColor: columnColor,
                enabled: onProjectMove != null,
                onAccept: (data) => onAcceptDrop(data, index),
                onWillAccept: (data) => data.projectId != item.id,
                child: card,
              );
            },
          ),
        ),
        _DropTargetSlot(
          accent: accent,
          columnColor: columnColor,
          enabled: onProjectMove != null,
          onAccept: (data) => onAcceptDrop(data, items.length),
          child: const SizedBox(height: 24, width: double.infinity),
        ),
      ],
    );
  }
}
