import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/agency/agency_context.dart';

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

  void _showAgencyMenu(
    BuildContext context,
    AgencyContext agencyContext,
    String? activeId,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  'Suas agências',
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              ...agencyContext.memberships.map((membership) {
                final isActive = membership.agencyId == activeId;
                final initial = membership.displayAgencyName.isNotEmpty
                    ? membership.displayAgencyName[0].toUpperCase()
                    : '?';
                return ListTile(
                  leading: CircleAvatar(child: Text(initial)),
                  title: Text(membership.displayAgencyName),
                  subtitle: Text(membership.role.label),
                  trailing: isActive ? const Icon(Icons.check_circle) : null,
                  selected: isActive,
                  onTap: isActive
                      ? null
                      : () {
                          Navigator.pop(sheetContext);
                          _switchAgency(context, membership.agencyId);
                        },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
