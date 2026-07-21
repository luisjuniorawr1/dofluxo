import 'package:flutter/material.dart';

import '../../../core/utils/theme_utils.dart';

/// Tag/pill legível em claro e escuro — fundo opaco, nunca “some” no card.
class AppTagBadge extends StatelessWidget {
  const AppTagBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  /// Tag com cor de marca sólida (ex.: Você / Dono).
  factory AppTagBadge.filled({
    Key? key,
    required String label,
    required Color accent,
  }) {
    final filled = ThemeUtils.filledBadgeColors(accent);
    return AppTagBadge(
      key: key,
      label: label,
      background: filled.background,
      foreground: filled.foreground,
    );
  }

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: foreground.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
        ),
      ),
    );
  }
}
