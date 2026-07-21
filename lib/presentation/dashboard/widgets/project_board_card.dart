import 'package:flutter/material.dart';

import '../../projects/models/project_category.dart';

import '../models/project_board_item.dart';

/// Card minimalista do Kanban: nome do projeto + data · cliente.

class ProjectBoardCard extends StatelessWidget {
  const ProjectBoardCard({super.key, required this.item, this.compact = false});

  final ProjectBoardItem item;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final surface = isDark
        ? theme.colorScheme.surfaceContainerLow
        : theme.colorScheme.surface;

    final category = item.isPlanejamento
        ? ProjectCategory.planejamento
        : ProjectCategory.job;

    final accent = category.boardStripeColor;

    final radius = compact ? 4.0 : 6.0;

    final padding = compact
        ? const EdgeInsets.fromLTRB(7, 6, 7, 6)
        : const EdgeInsets.fromLTRB(9, 8, 9, 8);

    final subtitle = item.cardSubtitle;

    return Container(
      decoration: BoxDecoration(
        color: surface,

        borderRadius: BorderRadius.circular(radius),

        border: Border.all(color: Colors.transparent, width: 0),

        boxShadow: null,
      ),

      clipBehavior: Clip.antiAlias,

      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            Container(width: 2, color: accent),

            Expanded(
              child: Padding(
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

                        color: theme.colorScheme.onSurface,
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

                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
