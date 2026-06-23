import 'package:flutter/material.dart';

import '../../../core/agency/models/agency_invite_code.dart';
import '../../../core/agency/services/invite_code_service.dart';
import '../../../core/utils/date_format_utils.dart';
import '../../agency/pages/join_agency_page.dart';

class InviteCodesPanel extends StatelessWidget {
  const InviteCodesPanel({
    super.key,
    required this.agencyId,
    required this.inviteCodeService,
  });

  final String agencyId;
  final InviteCodeService inviteCodeService;

  Future<void> _revokeCode(BuildContext context, String code) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revogar código'),
        content: Text('O código $code não poderá mais ser usado. Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revogar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await inviteCodeService.revoke(code);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código revogado.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao revogar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<AgencyInviteCode>>(
      stream: inviteCodeService.watchActiveForAgency(agencyId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Erro ao carregar convites: ${snapshot.error}',
            style: TextStyle(color: theme.colorScheme.error),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          );
        }

        final invites = snapshot.data ?? [];
        if (invites.isEmpty) {
          return Text(
            'Nenhum código ativo. Gere um convite para freelancers ou novos membros.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Códigos ativos',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final invite in invites) ...[
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  title: Text(
                    invite.code,
                    style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.8),
                  ),
                  subtitle: Text(
                    '${invite.role.label} · expira ${DateFormatUtils.formatDayMonthYear(invite.expiresAt ?? DateTime.now())}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Copiar',
                        onPressed: () => copyInviteCode(context, invite.code),
                        icon: const Icon(Icons.copy_outlined),
                      ),
                      IconButton(
                        tooltip: 'Revogar',
                        onPressed: () => _revokeCode(context, invite.code),
                        icon: Icon(Icons.block, color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}
