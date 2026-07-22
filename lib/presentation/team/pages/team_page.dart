import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/agency/agency_context.dart';
import '../../../core/agency/models/agency_role.dart';
import '../../../core/agency/models/membership.dart';
import '../manager/team_service.dart';
import '../utils/team_member_sorter.dart';
import '../widgets/add_member_dialog.dart';
import '../widgets/edit_role_dialog.dart';
import '../widgets/generate_invite_code_flow.dart';
import '../widgets/invite_codes_panel.dart';
import '../widgets/remove_member_dialog.dart';
import '../widgets/team_member_tile.dart';
import '../widgets/team_summary_cards.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  TeamService? _teamService;
  String? _agencyId;

  TeamService get teamService {
    final agencyId = context.read<AgencyContext>().activeAgencyId;
    if (agencyId == null) {
      throw StateError('Agência ativa não definida.');
    }
    if (_teamService == null || _agencyId != agencyId) {
      _agencyId = agencyId;
      _teamService = TeamService(agencyId: agencyId);
    }
    return _teamService!;
  }

  Future<void> _showAddMemberDialog(AgencyContext agencyContext) async {
    final result = await showDialog<(String, AgencyRole)>(
      context: context,
      builder: (context) => const AddMemberDialog(),
    );
    if (result == null || !mounted) return;

    try {
      await teamService.addMemberByEmail(
        email: result.$1,
        role: result.$2,
        agencyName: agencyContext.activeAgencyName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Membro adicionado: ${result.$1}')),
      );
    } on TeamMemberNotFoundException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Nenhuma conta encontrada para este e-mail. Convites por e-mail em breve.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } on TeamMemberAlreadyExistsException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Esta pessoa já faz parte da equipe.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao adicionar membro: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _showEditRoleDialog(Membership membership) async {
    final newRole = await showDialog<AgencyRole>(
      context: context,
      builder: (context) => EditRoleDialog(membership: membership),
    );
    if (newRole == null || newRole == membership.role || !mounted) return;

    if (membership.role == AgencyRole.admin && newRole == AgencyRole.member) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rebaixar admin'),
          content: Text(
            '${membership.userDisplayName ?? membership.userEmail} perderá acesso '
            'às configurações da agência. Continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    try {
      await teamService.updateMemberRole(userId: membership.userId, role: newRole);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cargo atualizado com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar cargo: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _confirmRemoveMember({
    required Membership membership,
    required AgencyContext agencyContext,
    required bool isCurrentUser,
  }) async {
    final confirmed = await showRemoveMemberDialog(
      context,
      membership: membership,
      agencyName: agencyContext.activeAgencyName,
      isCurrentUser: isCurrentUser,
    );
    if (confirmed != true || !mounted) return;

    try {
      await teamService.removeMember(membership.userId);
      if (!mounted) return;

      if (isCurrentUser) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await agencyContext.initialize(user);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCurrentUser ? 'Você saiu da agência.' : 'Membro removido da equipe.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao remover membro: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final agencyContext = context.watch<AgencyContext>();
    final theme = Theme.of(context);
    final canManage = agencyContext.canManageTeam;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final agencyId = agencyContext.activeAgencyId;
    final isCompact = MediaQuery.sizeOf(context).width < 768;
    final padding = isCompact ? 16.0 : 28.0;

    if (agencyId == null) {
      return const Center(child: Text('Nenhuma agência ativa.'));
    }

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Equipe',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      agencyContext.activeAgencyName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (canManage)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => showGenerateInviteCodeFlow(context),
                      icon: const Icon(Icons.vpn_key_outlined),
                      label: Text(isCompact ? 'Convite' : 'Gerar convite'),
                    ),
                    FilledButton.icon(
                      onPressed: () => _showAddMemberDialog(agencyContext),
                      icon: const Icon(Icons.person_add_outlined),
                      label: Text(isCompact ? 'Adicionar' : 'Adicionar membro'),
                    ),
                  ],
                ),
            ],
          ),
          if (!canManage) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Modo visualização — apenas donos e admins podem gerenciar a equipe.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          if (canManage) ...[
            const SizedBox(height: 20),
            InviteCodesPanel(
              agencyId: agencyId,
              inviteCodeService: agencyContext.inviteCodeService,
            ),
          ],
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<Membership>>(
              stream: teamService.watchActiveMembers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  final error = snapshot.error.toString();
                  final isPermissionDenied = error.contains('permission-denied');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        isPermissionDenied
                            ? 'Sem permissão para carregar a equipe.\n\n'
                                'Republicar as regras do Firestore (firebase deploy --only firestore) '
                                'e faça hot restart (R).'
                            : 'Erro ao carregar equipe: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final members = TeamMemberSorter.sort(snapshot.data ?? []);

                if (members.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhum membro encontrado',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (canManage) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => _showAddMemberDialog(agencyContext),
                            icon: const Icon(Icons.person_add_outlined),
                            label: const Text('Adicionar membro'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView(
                  children: [
                    TeamSummaryCards(members: members),
                    const SizedBox(height: 16),
                    Text(
                      '${members.length} ${members.length == 1 ? 'pessoa' : 'pessoas'} na agência',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final membership in members) ...[
                      TeamMemberTile(
                        membership: membership,
                        isCurrentUser: membership.userId == currentUserId,
                        canManage: canManage,
                        onEditRole: canManage && membership.role != AgencyRole.owner
                            ? () => _showEditRoleDialog(membership)
                            : null,
                        onRemove: () => _confirmRemoveMember(
                          membership: membership,
                          agencyContext: agencyContext,
                          isCurrentUser: membership.userId == currentUserId,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
