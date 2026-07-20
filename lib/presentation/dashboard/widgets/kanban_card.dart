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
    required this.child,
    required this.dragData,
    this.onTap,
    this.onDragStarted,
    this.onDragEnded,
    this.enableDrag = true,
    this.isMobileLayout = false,
  });

  final T item;
  final Widget child;
  final KanbanDragData<T> dragData;
  final VoidCallback? onTap;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;
  final bool enableDrag;
  final bool isMobileLayout;

  @override
  State<KanbanCard<T>> createState() => _KanbanCardState<T>();
}

class _KanbanCardState<T> extends State<KanbanCard<T>> {
  final GlobalKey _sizeKey = GlobalKey();
  Size? _dragSize;

  Size? _readChildSize() {
    final renderObject = _sizeKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      return renderObject.size;
    }
    return null;
  }

  void _handleDragStarted() {
    _dragSize = _readChildSize();
    widget.onDragStarted?.call();
  }

  void _handleDragEnded([DraggableDetails? _]) {
    _dragSize = null;
    widget.onDragEnded?.call();
  }

  Widget _sizedChild(Widget child) {
    final size = _dragSize ?? _readChildSize();
    if (size == null) return child;
    return SizedBox(
      width: size.width,
      height: size.height,
      child: child,
    );
  }

  Widget _buildFeedback() {
    return Material(
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent,
      child: _sizedChild(widget.child),
    );
  }

  Widget _buildDragPlaceholder() => _sizedChild(const SizedBox.shrink());

  @override
  Widget build(BuildContext context) {
    final cardContent = KeyedSubtree(
      key: _sizeKey,
      child: MouseRegion(
        cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: widget.child,
      ),
    );

    final tappable = GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: cardContent,
    );

    if (!widget.enableDrag) return tappable;

    final useLongPress = widget.isMobileLayout ||
        MediaQuery.sizeOf(context).width < DashboardLayoutBreakpoints.mobileCarousel ||
        !kanbanUseImmediateDrag();

    if (useLongPress) {
      return LongPressDraggable<KanbanDragData<T>>(
        data: widget.dragData,
        rootOverlay: true,
        dragAnchorStrategy: childDragAnchorStrategy,
        feedback: _buildFeedback(),
        childWhenDragging: _buildDragPlaceholder(),
        delay: const Duration(milliseconds: 120),
        hapticFeedbackOnStart: false,
        onDragStarted: _handleDragStarted,
        onDragCompleted: _handleDragEnded,
        onDragEnd: _handleDragEnded,
        onDraggableCanceled: (_, _) => _handleDragEnded(),
        child: tappable,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<KanbanDragData<T>>(
        data: widget.dragData,
        rootOverlay: true,
        dragAnchorStrategy: childDragAnchorStrategy,
        feedback: _buildFeedback(),
        childWhenDragging: _buildDragPlaceholder(),
        maxSimultaneousDrags: 1,
        onDragStarted: _handleDragStarted,
        onDragCompleted: _handleDragEnded,
        onDragEnd: _handleDragEnded,
        onDraggableCanceled: (_, _) => _handleDragEnded(),
        child: tappable,
      ),
    );
  }
}
