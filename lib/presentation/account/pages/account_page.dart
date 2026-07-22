import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/agency/agency_context.dart';
import '../../../core/agency/models/membership.dart';
import '../../../core/utils/theme_utils.dart';
import '../../agency/pages/agency_onboarding_page.dart';
import '../../agency/pages/join_agency_page.dart';
import '../../profile/pages/profile_page.dart';
import '../../team/widgets/role_badge.dart';

/// Tela de conta: dados do usuário e agências vinculadas.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  String _resolveDisplayName(AgencyContext agencyContext) {
    final profileName = agencyContext.profile?.displayName.trim();
    if (profileName != null && profileName.isNotEmpty) return profileName;

    final authName = FirebaseAuth.instance.currentUser?.displayName?.trim();
    if (authName != null && authName.isNotEmpty) return authName;

    return 'Usuário';
  }

  String _resolveEmail(AgencyContext agencyContext) {
    final profileEmail = agencyContext.profile?.email.trim();
    if (profileEmail != null && profileEmail.isNotEmpty) return profileEmail;

    return FirebaseAuth.instance.currentUser?.email ?? '—';
  }

  String? _resolvePhotoUrl(AgencyContext agencyContext) {
    final profilePhoto = agencyContext.profile?.photoUrl?.trim();
    if (profilePhoto != null && profilePhoto.isNotEmpty) return profilePhoto;

    return FirebaseAuth.instance.currentUser?.photoURL;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  List<Membership> _sortedMemberships(AgencyContext agencyContext) {
    final activeId = agencyContext.activeAgencyId;
    final memberships = agencyContext.memberships.where((m) => m.isActive).toList();

    memberships.sort((a, b) {
      final aActive = a.agencyId == activeId;
      final bActive = b.agencyId == activeId;
      if (aActive != bActive) return aActive ? -1 : 1;

      final roleOrder = a.role.index.compareTo(b.role.index);
      if (roleOrder != 0) return roleOrder;

      return a.displayAgencyName.toLowerCase().compareTo(b.displayAgencyName.toLowerCase());
    });

    return memberships;
  }

  Future<void> _selectAgency(BuildContext context, Membership membership) async {
    final agencyContext = context.read<AgencyContext>();
    if (agencyContext.activeAgencyId == membership.agencyId || agencyContext.isLoading) {
      return;
    }

    try {
      await agencyContext.selectAgency(membership.agencyId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Agência ativa: ${membership.displayAgencyName}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao trocar agência: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final agencyContext = context.watch<AgencyContext>();
    final displayName = _resolveDisplayName(agencyContext);
    final email = _resolveEmail(agencyContext);
    final photoUrl = _resolvePhotoUrl(agencyContext);
    final memberships = _sortedMemberships(agencyContext);
    final activeId = agencyContext.activeAgencyId;
    final isDesktop = MediaQuery.sizeOf(context).width > 900;
    final pagePadding = isDesktop ? 28.0 : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(pagePadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Minha conta',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Seus dados de acesso e agências vinculadas.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? Text(
                                _initials(displayName),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nome',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'E-mail',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'ID da conta',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            SelectableText(
                              FirebaseAuth.instance.currentUser?.uid ?? '—',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Agências',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Workspaces em que você participa como membro, admin ou dono.',
                style: ThemeUtils.bodyMuted(context),
              ),
              const SizedBox(height: 16),
              if (memberships.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          size: 40,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Você ainda não está em nenhuma agência.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...memberships.map((membership) {
                  final isActive = membership.agencyId == activeId;
                  final initial = membership.displayAgencyName.isNotEmpty
                      ? membership.displayAgencyName[0].toUpperCase()
                      : '?';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: CircleAvatar(child: Text(initial)),
                        title: Text(membership.displayAgencyName),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              RoleBadge(role: membership.role),
                              if (isActive) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '· Ativa agora',
                                  // contentAccent: legível no dark mesmo com marca escura.
                                  // Nunca primary cru (pode sumir no card escuro).
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: ThemeUtils.contentAccent(context),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        trailing: isActive
                            ? Icon(
                                Icons.check_circle,
                                color: ThemeUtils.contentAccent(context),
                              )
                            : Icon(
                                Icons.chevron_right,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                        onTap: isActive
                            ? null
                            : () => _selectAgency(context, membership),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const JoinAgencyPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.vpn_key_outlined),
                    label: const Text('Entrar com código'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const AgencyOnboardingPage(isAdditional: true),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_business_outlined),
                    label: const Text('Criar agência'),
                  ),
                  if (agencyContext.canManageSettings)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const ProfilePage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings_outlined),
                      label: const Text('Config. da agência'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
