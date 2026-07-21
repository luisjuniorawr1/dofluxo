import 'package:flutter/material.dart';

import '../../../core/utils/theme_utils.dart';
import '../models/planning_status.dart';

class PlanningStatusChip extends StatelessWidget {
  const PlanningStatusChip({
    super.key,
    required this.status,
    this.compact = false,
    this.onTap,
    this.selected = false,
  });

  final PlanningStatus status;
  final bool compact;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectedText = ThemeUtils.readableOn(status.color);
    final tinted = ThemeUtils.tintedBadgeColors(
      accent: status.color,
      surface: scheme.surface,
      brightness: theme.brightness,
    );
    final background = selected ? status.color : tinted.background;
    final foreground = selected ? selectedText : tinted.foreground;

    final chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? status.color
              : Color.alphaBlend(
                  status.color.withValues(alpha: 0.45),
                  scheme.outlineVariant,
                ),
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 8,
            height: compact ? 6 : 8,
            decoration: BoxDecoration(
              color: selected ? selectedText : status.color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            status.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: chip,
      ),
    );
  }
}
