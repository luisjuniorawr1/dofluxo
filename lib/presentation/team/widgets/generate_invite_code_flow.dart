import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/agency/agency_context.dart';
import '../../../core/agency/models/agency_invite_code.dart';
import '../../../core/agency/models/agency_role.dart';
import 'generate_invite_code_dialog.dart';
import '../../agency/pages/join_agency_page.dart';

Future<void> showGenerateInviteCodeFlow(BuildContext context) async {
  final agencyContext = context.read<AgencyContext>();
  final agencyId = agencyContext.activeAgencyId;
  final user = FirebaseAuth.instance.currentUser;
  if (agencyId == null || user == null) return;

  final role = await showDialog<AgencyRole>(
    context: context,
    builder: (context) => const GenerateInviteCodeDialog(),
  );
  if (role == null || !context.mounted) return;

  try {
    final invite = await agencyContext.inviteCodeService.generate(
      agencyId: agencyId,
      agencyName: agencyContext.activeAgencyName,
      role: role,
      createdBy: user.uid,
    );
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Código gerado'),
        content: _GeneratedInviteContent(invite: invite),
        actions: [
          TextButton(
            onPressed: () => copyInviteCode(context, invite.code),
            child: const Text('Copiar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Concluir'),
          ),
        ],
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro ao gerar código: $e'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _GeneratedInviteContent extends StatelessWidget {
  const _GeneratedInviteContent({required this.invite});

  final AgencyInviteCode invite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText(
            invite.code,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Função: ${invite.role.label}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Válido por 7 dias · uso único',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
