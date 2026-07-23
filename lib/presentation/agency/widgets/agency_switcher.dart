import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/agency/agency_context.dart';
import '../../shared/widgets/app_modal.dart';

/// Troca de agência ativa na sidebar (2+ memberships).
class AgencySwitcher extends StatelessWidget {
  const AgencySwitcher({
    super.key,
    required this.onPrimary,
  });

  final Color onPrimary;

  Future<void> _switchAgency(BuildContext context, String agencyId) async {
    final agencyContext = context.read<AgencyContext>();
    if (agencyContext.activeAgencyId == agencyId || agencyContext.isLoading) return;

    try {
      await agencyContext.selectAgency(agencyId);
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
    final agencyContext = context.watch<AgencyContext>();

    if (!agencyContext.hasMultipleAgencies) {
      return const SizedBox.shrink();
    }

    final activeId = agencyContext.activeAgencyId;
    final muted = onPrimary.withValues(alpha: 0.9);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: agencyContext.isLoading
              ? null
              : () => _showAgencyMenu(context, agencyContext, activeId),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.swap_horiz_rounded, size: 16, color: muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Trocar agência',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                  ),
                ),
                if (agencyContext.isLoading)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: muted),
                  )
                else
                  Icon(Icons.expand_more, size: 18, color: muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAgencyMenu(
    BuildContext context,
    AgencyContext agencyContext,
    String? activeId,
  ) {
    return showAppModal<void>(
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
              const AppModalHeader(title: 'Suas agências'),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  children: agencyContext.memberships.map((membership) {
                    final isActive = membership.agencyId == activeId;
                    final initial = membership.displayAgencyName.isNotEmpty
                        ? membership.displayAgencyName[0].toUpperCase()
                        : '?';
                    return ListTile(
                      leading: CircleAvatar(child: Text(initial)),
                      title: Text(
                        membership.displayAgencyName,
                        style: TextStyle(color: scheme.onSurface),
                      ),
                      subtitle: Text(
                        membership.role.label,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      trailing: isActive
                          ? Icon(Icons.check_circle, color: scheme.primary)
                          : null,
                      selected: isActive,
                      onTap: isActive
                          ? null
                          : () {
                              Navigator.pop(dialogContext);
                              _switchAgency(context, membership.agencyId);
                            },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
