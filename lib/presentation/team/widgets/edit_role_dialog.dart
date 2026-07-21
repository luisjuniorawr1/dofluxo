import 'package:flutter/material.dart';

import '../../../core/agency/models/agency_role.dart';
import '../../../core/agency/models/membership.dart';

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
    return AlertDialog(
      title: const Text('Editar cargo'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _displayName,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (widget.membership.userEmail.isNotEmpty)
              Text(
                widget.membership.userEmail,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Novo cargo',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _role),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
