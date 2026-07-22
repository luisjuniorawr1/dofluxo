import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/agency/agency_context.dart';
import '../../core/theme/theme_provider.dart';
import '../auth/manager/auth_service.dart';
import '../clients/pages/clients_page.dart';
import '../dashboard/pages/dashboard_page.dart';
import '../agency/widgets/agency_switcher.dart';
import '../agency/agency_service_scope.dart';
import '../team/pages/team_page.dart';
import '../account/pages/account_page.dart';
import '../projects/pages/project_detail_page.dart';
import 'theme_toggle_button.dart';
import 'widgets/sidebar_delivery_calendar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const ClientsPage(),
    const TeamPage(),
    const AccountPage(),
  ];

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Deseja encerrar sua sessão?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sair')),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    context.read<AgencyContext>().reset();
    context.read<ThemeProvider>().resetToDefaults();
    await _authService.signOut();
  }

  Future<void> _openProjectFromCalendar(String projectId, {required bool isMobile}) async {
    if (isMobile) Navigator.pop(context);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => AgencyServiceScope.wrapRoute(
          context,
          ProjectDetailPage(projectId: projectId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final agencyName = context.select<ThemeProvider, String>((p) => p.agencyName);

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(agencyName),
              actions: const [
                ThemeToggleButton(),
                SizedBox(width: 4),
              ],
            ),
      drawer: isDesktop ? null : _buildSidebar(isMobile: true),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              if (isDesktop) _buildSidebar(),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _pages,
                ),
              ),
            ],
          ),
          if (isDesktop)
            Positioned(
              top: 8,
              right: 8,
              child: ThemeToggleButton(
                iconColor: Theme.of(context).colorScheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebar({bool isMobile = false}) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    final agencyName = context.select<ThemeProvider, String>((p) => p.agencyName);

    return Container(
      width: 250,
      color: theme.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            agencyName,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: -2,
              color: onPrimary,
            ),
          ),
          Text(
            'AGÊNCIA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              color: onPrimary.withValues(alpha: 0.8),
            ),
          ),
          AgencySwitcher(onPrimary: onPrimary),
          const SizedBox(height: 8),
          _navItem(0, 'Dashboard', Icons.dashboard_rounded, isMobile),
          _navItem(1, 'Clientes', Icons.business_rounded, isMobile),
          _navItem(2, 'Equipe', Icons.people_alt_rounded, isMobile),
          _navItem(3, 'Conta', Icons.person_outline_rounded, isMobile),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: SidebarDeliveryCalendar(
                onPrimary: onPrimary,
                onProjectTap: (projectId) => _openProjectFromCalendar(projectId, isMobile: isMobile),
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _handleLogout,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, size: 18, color: onPrimary.withValues(alpha: 0.8)),
                  const SizedBox(width: 10),
                  Text(
                    'Sair',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, String label, IconData icon, bool isMobile) {
    final selected = _currentIndex == index;
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    return InkWell(
      onTap: () {
        setState(() => _currentIndex = index);
        if (isMobile) Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? onPrimary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? onPrimary : onPrimary.withValues(alpha: 0.9)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? onPrimary : onPrimary.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
