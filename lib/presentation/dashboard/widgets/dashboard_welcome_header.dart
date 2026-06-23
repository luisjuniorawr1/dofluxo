import 'package:flutter/material.dart';

class DashboardWelcomeHeader extends StatelessWidget {
  const DashboardWelcomeHeader({
    super.key,
    required this.userName,
    this.title,
    this.subtitle,
    this.actions,
  });

  final String userName;
  final String? title;
  final String? subtitle;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = userName.trim().isEmpty
        ? 'Olá, Seja bem vindo!'
        : 'Olá $userName, Seja bem vindo!';

    final heading = title != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title!,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                greeting,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          )
        : Text(
            greeting,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        heading,
        if (actions != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: actions!,
          ),
        ],
      ],
    );
  }
}
