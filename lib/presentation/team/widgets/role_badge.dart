import 'package:flutter/material.dart';

import '../../../core/agency/models/agency_role.dart';

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final AgencyRole role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (background, foreground) = switch (role) {
      AgencyRole.owner => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
        ),
      AgencyRole.admin => (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer,
        ),
      AgencyRole.member => (
          scheme.surfaceContainerHighest,
          scheme.onSurface,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
