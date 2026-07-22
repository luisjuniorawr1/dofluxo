import 'package:flutter/material.dart';

import '../../../core/agency/models/agency_role.dart';
import '../../shared/widgets/app_tag_badge.dart';

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final AgencyRole role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return switch (role) {
      AgencyRole.owner => AppTagBadge.filled(
          label: role.label,
          accent: scheme.primary,
          brightness: theme.brightness,
        ),
      AgencyRole.admin => AppTagBadge(
          label: role.label,
          background: scheme.secondaryContainer,
          foreground: scheme.onSecondaryContainer,
        ),
      AgencyRole.member => AppTagBadge(
          label: role.label,
          background: scheme.surfaceContainerHighest,
          foreground: scheme.onSurface,
        ),
    };
  }
}
