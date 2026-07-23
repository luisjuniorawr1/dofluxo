import 'package:flutter/material.dart';

import '../../../core/agency/models/agency_role.dart';
import '../../shared/widgets/app_modal.dart';

class GenerateInviteCodeDialog extends StatefulWidget {
  const GenerateInviteCodeDialog({super.key});

  @override
  State<GenerateInviteCodeDialog> createState() => _GenerateInviteCodeDialogState();
}

class _GenerateInviteCodeDialogState extends State<GenerateInviteCodeDialog> {
  AgencyRole _role = AgencyRole.member;

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
          const AppModalHeader(title: 'Gerar código de convite'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A pessoa usará este código em "Entrar em uma agência". '
                  'Válido por 7 dias e uso único.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Função na agência',
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
                  subtitle: const Text('Clientes e projetos'),
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
                  subtitle: const Text('Configurações e equipe'),
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
                child: const Text('Gerar código'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
