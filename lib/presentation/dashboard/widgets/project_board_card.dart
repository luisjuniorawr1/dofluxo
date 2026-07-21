import 'package:flutter/material.dart';

import '../config/kanban_constants.dart';
import '../models/project_board_item.dart';

/// Card do Kanban com hover, elevação e estados de drag/placeholder.
class ProjectBoardCard extends StatefulWidget {
  const ProjectBoardCard({
    super.key,
    required this.item,
    required this.zoneCardColor,
    this.compact = false,
    this.isDragging = false,
    this.isPlaceholder = false,
    this.interactive = true,
  });

  final ProjectBoardItem item;
  final Color zoneCardColor;
  final bool compact;
  final bool isDragging;
  final bool isPlaceholder;
  final bool interactive;

  @override
  State<ProjectBoardCard> createState() => _ProjectBoardCardState();
}

class _ProjectBoardCardState extends State<ProjectBoardCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const bodyColor = Color(0xFF1A1A1A);
    const radius = 12.0;
    final barHeight = widget.compact ? 4.0 : 5.0;
    final padding = widget.compact
        ? const EdgeInsets.fromLTRB(8, 6, 8, 7)
        : const EdgeInsets.fromLTRB(10, 8, 10, 9);
    final subtitle = widget.item.cardSubtitle;

    final canHover =
        widget.interactive && !widget.isDragging && !widget.isPlaceholder;
    final showHover = canHover && _isHovered;

    final elevation = widget.isDragging ? 8.0 : (showHover ? 5.0 : 1.0);
    final scale = showHover ? 1.02 : 1.0;

    Widget card = AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        elevation: elevation,
        shadowColor: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: showHover
                ? Border.all(
                    color: bodyColor.withValues(alpha: 0.35),
                    width: 1.5,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: barHeight, color: widget.zoneCardColor),
              Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.item.cardPrimaryTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: widget.compact ? 12 : 14,
                        height: 1.3,
                        color: bodyColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: widget.compact ? 2 : 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: widget.compact ? 10 : 11,
                          height: 1.25,
                          color: bodyColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (canHover) {
      card = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: card,
      );
    }

    return card;
  }
}
