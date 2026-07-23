import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/agency/agency_context.dart';
import '../../../core/agency/models/agency_invite_code.dart';
import '../../../core/agency/models/agency_role.dart';
import '../../shared/widgets/app_modal.dart';
import 'generate_invite_code_dialog.dart';
import '../../agency/pages/join_agency_page.dart';

Future<void> showGenerateInviteCodeFlow(BuildContext context) async {
  final agencyContext = context.read<AgencyContext>();
  final agencyId = agencyContext.activeAgencyId;
  final user = FirebaseAuth.instance.currentUser;
  if (agencyId == null || user == null) return;

  final role = await showAppModal<AgencyRole>(
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

    await showAppModal<void>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        return AppModalShell(
          size: AppModalSize.compact,
          shrinkWrap: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppModalHeader(title: 'Código gerado'),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: _GeneratedInviteContent(invite: invite),
              ),
              AppModalFooter(
                children: [
                  TextButton(
                    onPressed: () => copyInviteCode(dialogContext, invite.code),
                    child: const Text('Copiar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                    ),
                    child: const Text('Concluir'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SelectableText(
          invite.code,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Função: ${invite.role.label}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Válido por 7 dias · uso único',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
