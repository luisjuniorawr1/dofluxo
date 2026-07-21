import 'package:flutter/material.dart';

import '../../../core/agency/models/agency_role.dart';
import '../../../core/utils/theme_utils.dart';

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final AgencyRole role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (background, foreground) = switch (role) {
      AgencyRole.owner => () {
          final tinted = ThemeUtils.tintedBadgeColors(
            accent: scheme.primary,
            surface: scheme.surfaceContainerLow,
            brightness: theme.brightness,
          );
          return (tinted.background, tinted.foreground);
        }(),
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
        border: Border.all(
          color: Color.alphaBlend(
            foreground.withValues(alpha: 0.22),
            background,
          ),
        ),
      ),
      child: Text(
        role.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
