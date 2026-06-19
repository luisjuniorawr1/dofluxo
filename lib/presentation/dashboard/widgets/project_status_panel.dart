import 'package:flutter/material.dart';
import '../models/project_board_item.dart';
import '../../../core/utils/theme_utils.dart';

/// Coluna lateral de progresso macro dos projetos (referência visual).
class ProjectStatusPanel extends StatelessWidget {
  const ProjectStatusPanel({
    super.key,
    required this.projects,
  });

  final List<ProjectBoardItem> projects;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.colorScheme.surfaceContainerHigh;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status do Projeto',
            style: ThemeUtils.sectionTitle(context),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: projects.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum projeto em andamento',
                      textAlign: TextAlign.center,
                      style: ThemeUtils.bodyMuted(context),
                    ),
                  )
                : ListView.separated(
                    itemCount: projects.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _ProjectProgressTile(item: projects[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProjectProgressTile extends StatelessWidget {
  const _ProjectProgressTile({required this.item});

  final ProjectBoardItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (item.progress ?? 0).clamp(0.0, 1.0);
    final success = ThemeUtils.successColor(context);
    final percentLabel = item.hasProgress
        ? '${(progress * 100).round()}% concluído'
        : 'Sem atividades de produção';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.displayTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          percentLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: item.hasProgress ? success : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (item.hasProgress) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.15),
              color: success,
            ),
          ),
        ],
      ],
    );
  }
}
