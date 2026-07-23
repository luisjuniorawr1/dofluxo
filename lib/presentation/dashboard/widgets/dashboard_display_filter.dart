import 'package:flutter/material.dart';

import '../../../core/theme/agency_theme_colors.dart';
import '../../projects/models/project_category.dart';

/// Filtro de exibição na dashboard: Job e/ou Planejamento digital.
class DashboardDisplayFilter extends StatelessWidget {
  const DashboardDisplayFilter({
    super.key,
    required this.showJobs,
    required this.showPlanning,
    required this.onJobsChanged,
    required this.onPlanningChanged,
  });

  final bool showJobs;
  final bool showPlanning;
  final ValueChanged<bool> onJobsChanged;
  final ValueChanged<bool> onPlanningChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 4),
            child: Text(
              'Exibir:',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          _FilterCheckbox(
            label: ProjectCategory.job.label,
            value: showJobs,
            onChanged: onJobsChanged,
          ),
          _FilterCheckbox(
            label: ProjectCategory.planejamento.label,
            value: showPlanning,
            onChanged: onPlanningChanged,
          ),
        ],
      ),
    );
  }
}

class _FilterCheckbox extends StatelessWidget {
  const _FilterCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = theme.extension<AgencyThemeColors>()?.contentAccent ?? colors.primary;

    return Semantics(
      checked: value,
      button: true,
      label: 'Exibir $label',
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(left: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: value ? accent.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: value
                  ? accent.withValues(alpha: 0.28)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                value ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 17,
                color: value ? accent : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: value ? FontWeight.w700 : FontWeight.w600,
                  color: value ? colors.onSurface : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
