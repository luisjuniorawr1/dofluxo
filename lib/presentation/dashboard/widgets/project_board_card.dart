import 'package:flutter/material.dart';

import '../models/project_board_item.dart';

/// Card do Kanban branco com barra superior na cor da zona.
class ProjectBoardCard extends StatelessWidget {
  const ProjectBoardCard({
    super.key,
    required this.item,
    required this.zoneCardColor,
    this.compact = false,
  });

  final ProjectBoardItem item;
  final Color zoneCardColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const bodyColor = Color(0xFF1A1A1A);
    final radius = compact ? 8.0 : 10.0;
    final barHeight = compact ? 4.0 : 5.0;
    final padding = compact
        ? const EdgeInsets.fromLTRB(8, 6, 8, 7)
        : const EdgeInsets.fromLTRB(10, 8, 10, 9);
    final subtitle = item.cardSubtitle;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: compact ? 4 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: barHeight, color: zoneCardColor),
          Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.cardPrimaryTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 12 : 14,
                    height: 1.3,
                    color: bodyColor,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: compact ? 2 : 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: compact ? 10 : 11,
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
    );
  }
}
