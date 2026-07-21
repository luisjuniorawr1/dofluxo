import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/theme_provider.dart';
import 'agency_context.dart';

/// Sincroniza [ThemeProvider] com branding de `agencies/{activeAgencyId}`.
class AgencyBrandingSync extends StatefulWidget {
  const AgencyBrandingSync({super.key, required this.child});

  final Widget child;

  @override
  State<AgencyBrandingSync> createState() => _AgencyBrandingSyncState();
}

class _AgencyBrandingSyncState extends State<AgencyBrandingSync> {
  @override
  void initState() {
    super.initState();
    context.read<AgencyContext>().addListener(_syncBranding);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncBranding());
  }

  @override
  void dispose() {
    context.read<AgencyContext>().removeListener(_syncBranding);
    super.dispose();
  }

  void _syncBranding() {
    if (!mounted) return;
    final agencyContext = context.read<AgencyContext>();
    context.read<ThemeProvider>().applyAgencyBranding(
      name: agencyContext.activeAgencyName,
      color: agencyContext.activePrimaryColor,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
