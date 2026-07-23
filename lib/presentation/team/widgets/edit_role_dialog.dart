import 'package:flutter/material.dart';

import '../../../core/agency/models/agency_role.dart';
import '../../../core/agency/models/membership.dart';
import '../../shared/widgets/app_modal.dart';

class EditRoleDialog extends StatefulWidget {
  const EditRoleDialog({super.key, required this.membership});

  final Membership membership;

  @override
  State<EditRoleDialog> createState() => _EditRoleDialogState();
}

class _EditRoleDialogState extends State<EditRoleDialog> {
  late AgencyRole _role = widget.membership.role == AgencyRole.admin
      ? AgencyRole.admin
      : AgencyRole.member;

  String get _displayName {
    final name = widget.membership.userDisplayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return widget.membership.userEmail;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppModalShell(
      size: AppModalSize.compact,
      shrinkWrap: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppModalHeader(title: 'Editar cargo'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                if (widget.membership.userEmail.isNotEmpty)
                  Text(
                    widget.membership.userEmail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Novo cargo',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                RadioListTile<AgencyRole>(
                  value: AgencyRole.member,
                  groupValue: _role,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _role = value);
                  },
                  title: const Text('Membro'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<AgencyRole>(
                  value: AgencyRole.admin,
                  groupValue: _role,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _role = value);
                  },
                  title: const Text('Admin'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          AppModalFooter(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, _role),
                child: const Text('Salvar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
