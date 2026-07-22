import 'package:flutter/material.dart';

import '../../../core/agency/models/agency_role.dart';
import '../../shared/widgets/app_tag_badge.dart';

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final AgencyRole role;

  /// Accent sólido por papel — nunca `primaryContainer` com alpha (some no dark).
  static Color accentFor(AgencyRole role, ColorScheme scheme, Brightness brightness) {
    return switch (role) {
      AgencyRole.owner => scheme.primary,
      AgencyRole.admin => scheme.secondary,
      // Cinza opaco com contraste claro vs card nos dois temas.
      AgencyRole.member => brightness == Brightness.dark
          ? const Color(0xFFC2C2C2)
          : const Color(0xFF5C5C5C),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppTagBadge.filled(
      label: role.label,
      accent: accentFor(role, scheme, theme.brightness),
      brightness: theme.brightness,
    );
  }
}
