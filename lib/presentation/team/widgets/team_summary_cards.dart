import 'package:flutter/material.dart';

import '../../../core/agency/models/agency_role.dart';
import '../../../core/agency/models/membership.dart';

class TeamSummaryCards extends StatelessWidget {
  const TeamSummaryCards({super.key, required this.members});

  final List<Membership> members;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = members.length;
    final admins = members.where((m) => m.role == AgencyRole.admin).length;
    final regularMembers = members
        .where((m) => m.role == AgencyRole.member)
        .length;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _SummaryCard(
          label: 'Membros',
          value: '$total',
          icon: Icons.people_alt_outlined,
          color: theme.colorScheme.primary,
        ),
        _SummaryCard(
          label: 'Admins',
          value: '$admins',
          icon: Icons.shield_outlined,
          color: theme.colorScheme.secondary,
        ),
        _SummaryCard(
          label: 'Colaboradores',
          value: '$regularMembers',
          icon: Icons.person_outline,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 132,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
