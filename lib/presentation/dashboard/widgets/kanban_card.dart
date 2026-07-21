import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/dashboard_layout_breakpoints.dart';
import 'kanban_column.dart';

bool kanbanUseImmediateDrag() {
  return kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}

/// Shell genérico de card Kanban: toque, arraste e feedback visual.
class KanbanCard<T> extends StatefulWidget {
  const KanbanCard({
    super.key,
    required this.item,
    required this.buildContent,
    required this.dragData,
    this.feedbackWidth,
    this.onTap,
    this.onDragStarted,
    this.onDragEnded,
    this.enableDrag = true,
    this.isMobileLayout = false,
  });

  final T item;
  final Widget Function({bool isDragging, bool isPlaceholder}) buildContent;
  final KanbanDragData<T> dragData;
  final double? feedbackWidth;
  final VoidCallback? onTap;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;
  final bool enableDrag;
  final bool isMobileLayout;

  @override
  State<KanbanCard<T>> createState() => _KanbanCardState<T>();
}

class _KanbanCardState<T> extends State<KanbanCard<T>> {
  bool _isDragging = false;
  bool _suppressTap = false;

  void _handleTap() {
    if (_isDragging || _suppressTap || widget.onTap == null) return;
    widget.onTap!();
  }

  void _handleDragStarted() {
    setState(() => _isDragging = true);
    widget.onDragStarted?.call();
  }

  void _handleDragEnd(DraggableDetails details) {
    if (details.wasAccepted) {
      _suppressTap = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _suppressTap = false);
      });
    }
    setState(() => _isDragging = false);
    widget.onDragEnded?.call();
  }

  void _handleDragCanceled() {
    setState(() => _isDragging = false);
    widget.onDragEnded?.call();
  }

  double _resolveFeedbackWidth(BuildContext context) {
    if (widget.feedbackWidth != null) return widget.feedbackWidth!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    const columns = 5.0;
    return (screenWidth / columns).clamp(120.0, 360.0);
  }

  Widget _buildFeedback(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: _resolveFeedbackWidth(context),
        child: widget.buildContent(isDragging: true, isPlaceholder: false),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.3,
        child: widget.buildContent(isDragging: false, isPlaceholder: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tappable = GestureDetector(
      onTap: widget.onTap == null ? null : _handleTap,
      behavior: HitTestBehavior.opaque,
      child: widget.buildContent(isDragging: _isDragging, isPlaceholder: false),
    );

    if (!widget.enableDrag) return tappable;

    final useLongPress = widget.isMobileLayout ||
        MediaQuery.sizeOf(context).width < DashboardLayoutBreakpoints.mobileCarousel ||
        !kanbanUseImmediateDrag();

    if (useLongPress) {
      return LongPressDraggable<KanbanDragData<T>>(
        data: widget.dragData,
        rootOverlay: true,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: _buildFeedback(context),
        childWhenDragging: _buildPlaceholder(),
        maxSimultaneousDrags: 1,
        delay: const Duration(milliseconds: 120),
        hapticFeedbackOnStart: false,
        onDragStarted: _handleDragStarted,
        onDragEnd: _handleDragEnd,
        onDraggableCanceled: (_, _) => _handleDragCanceled(),
        child: tappable,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<KanbanDragData<T>>(
        data: widget.dragData,
        rootOverlay: true,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: _buildFeedback(context),
        childWhenDragging: _buildPlaceholder(),
        maxSimultaneousDrags: 1,
        onDragStarted: _handleDragStarted,
        onDragEnd: _handleDragEnd,
        onDraggableCanceled: (_, _) => _handleDragCanceled(),
        child: tappable,
      ),
    );
  }
}
