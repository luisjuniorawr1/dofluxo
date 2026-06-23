import 'package:flutter/material.dart';

import '../../../core/agency/models/agency_role.dart';
import '../../../core/agency/models/membership.dart';
import '../../../core/utils/date_format_utils.dart';
import 'role_badge.dart';

class TeamMemberTile extends StatelessWidget {
  const TeamMemberTile({
    super.key,
    required this.membership,
    required this.isCurrentUser,
    required this.canManage,
    this.onEditRole,
    this.onRemove,
  });

  final Membership membership;
  final bool isCurrentUser;
  final bool canManage;
  final VoidCallback? onEditRole;
  final VoidCallback? onRemove;

  String get _displayName {
    final name = membership.userDisplayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = membership.userEmail.trim();
    if (email.contains('@')) return email.split('@').first;
    return email.isNotEmpty ? email : 'Membro';
  }

  String get _initial => _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?';

  String? get _joinedLabel {
    final joined = membership.joinedAt ?? membership.createdAt;
    if (joined == null) return null;
    return DateFormatUtils.formatDayMonthYear(joined);
  }

  bool get _canShowMenu {
    if (!canManage && !isCurrentUser) return false;
    if (membership.role == AgencyRole.owner && !isCurrentUser) return false;
    return onEditRole != null || onRemove != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final joinedLabel = _joinedLabel;

    return Material(
      color: isCurrentUser
          ? theme.colorScheme.surfaceContainerLow
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              child: Text(_initial),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isCurrentUser)
                        Text(
                          'Você',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      RoleBadge(role: membership.role),
                    ],
                  ),
                  if (membership.userEmail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      membership.userEmail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (joinedLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Desde $joinedLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_canShowMenu)
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEditRole?.call();
                    case 'remove':
                      onRemove?.call();
                  }
                },
                itemBuilder: (context) {
                  final items = <PopupMenuEntry<String>>[];

                  if (canManage &&
                      membership.role != AgencyRole.owner &&
                      onEditRole != null) {
                    items.add(
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Editar cargo'),
                      ),
                    );
                  }

                  if (onRemove != null &&
                      (canManage && membership.role != AgencyRole.owner || isCurrentUser)) {
                    items.add(
                      PopupMenuItem(
                        value: 'remove',
                        child: Text(
                          isCurrentUser ? 'Sair da agência' : 'Remover da equipe',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    );
                  }

                  return items;
                },
              ),
          ],
        ),
      ),
    );
  }
}
