import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/agency/agency_context.dart';
import '../../core/theme/agency_theme_colors.dart';
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
import 'widgets/app_modal.dart';
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
    final confirmed = await showAppConfirmModal(
      context: context,
      title: 'Sair da conta',
      message: 'Deseja encerrar sua sessão?',
      confirmLabel: 'Sair',
      isDestructive: true,
    );

    if (confirmed != true) return;

    if (!mounted) return;
    context.read<AgencyContext>().reset();
    context.read<ThemeProvider>().resetToDefaults();
    await _authService.signOut();
  }

  Future<void> _openProjectFromCalendar(String projectId, {required bool isMobile}) async {
    if (isMobile) Navigator.pop(context);
    await showAppModalPage(
      context: context,
      size: AppModalSize.large,
      child: AgencyServiceScope.wrapRoute(
        context,
        ProjectDetailPage(projectId: projectId),
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
              top: 18,
              right: 22,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: ThemeToggleButton(
                  iconColor: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebar({bool isMobile = false}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final sidebarForeground = colors.onSurface;
    final accent = theme.extension<AgencyThemeColors>()?.contentAccent ?? colors.primary;
    final agencyName = context.select<ThemeProvider, String>((p) => p.agencyName);

    return Container(
      width: 268,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border(right: BorderSide(color: colors.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  'DF',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF111318),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agencyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: sidebarForeground,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'DOFLUXO · WORKSPACE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AgencySwitcher(onPrimary: sidebarForeground),
          Divider(color: colors.outlineVariant, height: 24),
          _navItem(0, 'Dashboard', Icons.dashboard_rounded, isMobile),
          _navItem(1, 'Clientes', Icons.business_rounded, isMobile),
          _navItem(2, 'Equipe', Icons.people_alt_rounded, isMobile),
          _navItem(3, 'Conta', Icons.person_outline_rounded, isMobile),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: SidebarDeliveryCalendar(
                  onPrimary: sidebarForeground,
                  onProjectTap: (projectId) =>
                      _openProjectFromCalendar(projectId, isMobile: isMobile),
                ),
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
                  Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Sair',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurfaceVariant,
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
    final colors = theme.colorScheme;
    final accent = theme.extension<AgencyThemeColors>()?.contentAccent ?? colors.primary;
    final foreground = selected ? accent : colors.onSurfaceVariant;

    return InkWell(
      onTap: () {
        setState(() => _currentIndex = index);
        if (isMobile) Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent.withValues(alpha: 0.24) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: foreground),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
