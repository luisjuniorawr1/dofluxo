import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Exibir:',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
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
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 36,
              width: 36,
              child: Checkbox(
                value: value,
                onChanged: (checked) => onChanged(checked ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
