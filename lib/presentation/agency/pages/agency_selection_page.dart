import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/agency/agency_context.dart';
import '../../../core/agency/models/membership.dart';

/// Seletor de agência quando o usuário pertence a mais de uma.
class AgencySelectionPage extends StatelessWidget {
  const AgencySelectionPage({super.key});

  Future<void> _selectAgency(BuildContext context, Membership membership) async {
    final agencyContext = context.read<AgencyContext>();
    if (agencyContext.activeAgencyId == membership.agencyId) return;

    try {
      await agencyContext.selectAgency(membership.agencyId);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar agência: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final agencyContext = context.watch<AgencyContext>();
    final memberships = agencyContext.memberships;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.apartment_outlined, size: 56, color: theme.colorScheme.primary),
                  const SizedBox(height: 24),
                  Text(
                    'Escolha uma agência',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Você tem acesso a ${memberships.length} agências. Selecione qual deseja usar agora.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (agencyContext.isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: memberships.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final membership = memberships[index];
                          final initial = membership.displayAgencyName.isNotEmpty
                              ? membership.displayAgencyName[0].toUpperCase()
                              : '?';
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              leading: CircleAvatar(child: Text(initial)),
                              title: Text(membership.displayAgencyName),
                              subtitle: Text(membership.role.label),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _selectAgency(context, membership),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
