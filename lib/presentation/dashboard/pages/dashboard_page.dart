import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/agency/agency_context.dart';
import '../../agency/agency_service_scope.dart';
import '../../profile/pages/profile_page.dart';
import '../../projects/manager/project_service.dart';
import '../../projects/pages/project_detail_page.dart';
import '../../projects/widgets/new_project_dialog.dart';
import '../config/dashboard_layout_breakpoints.dart';
import '../config/dashboard_zones.dart';
import '../utils/dashboard_board_mapper.dart';
import '../widgets/dashboard_welcome_header.dart';
import '../widgets/dashboard_board_layout.dart';
import '../widgets/dashboard_display_filter.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _uuid = const Uuid();
  bool _isCreatingProject = false;
  bool _showJobs = true;
  bool _showPlanning = true;
  Stream<QuerySnapshot>? _projectsStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _projectsStream ??= context.read<ProjectService>().getProjectsStream();
  }

  Future<void> _moveProject(
    String projectId,
    DashboardZoneId targetZone,
    int insertIndex,
    double boardOrder,
  ) async {
    if (!targetZone.acceptsDragDrop) return;

    try {
      final status = DashboardBoardMapper.firestoreStatusForZone(targetZone);
      final planningStatus = DashboardBoardMapper.planningStatusForZone(targetZone);

      await context.read<ProjectService>().updateProject(projectId, {
        'status': status,
        'boardOrder': boardOrder,
        if (planningStatus != null) 'planningStatus': planningStatus,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao mover projeto: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String get _userFirstName {
    try {
      final displayName = FirebaseAuth.instance.currentUser?.displayName?.trim();
      if (displayName == null || displayName.isEmpty) return '';
      return displayName.split(' ').first;
    } catch (_) {
      return '';
    }
  }

  Future<void> _openProfileSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
  }

  Future<void> _openProject(String projectId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => AgencyServiceScope.wrapRoute(
          context,
          ProjectDetailPage(projectId: projectId),
        ),
      ),
    );
  }

  Future<void> _showNewProjectDialog() async {
    try {
      final result = await showDialog<NewProjectResult>(
        context: context,
        builder: (dialogContext) => AgencyServiceScope.wrapRoute(
          context,
          const NewProjectDialog(),
        ),
      );

      if (result == null || !mounted) return;

      setState(() => _isCreatingProject = true);

      final projectId = _uuid.v4();
      final docId =
          await context.read<ProjectService>().addProject(result.toFirestorePayload(projectId));

      if (!mounted) return;

      if (docId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Faça login para criar projetos.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Projeto "${result.title}" criado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar projeto: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingProject = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < DashboardLayoutBreakpoints.mobileCarousel;
    final pagePadding = isMobile ? 16.0 : 28.0;

    return Padding(
      padding: isMobile
          ? EdgeInsets.all(pagePadding)
          : const EdgeInsets.fromLTRB(30, 26, 30, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardWelcomeHeader(
            userName: _userFirstName,
            actions: _buildActions(isMobile),
          ),
          SizedBox(height: isMobile ? 18 : 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _projectsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar projetos: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!_showJobs && !_showPlanning) {
                  return _buildNothingSelectedState(context);
                }

                final visibleBoard = snapshot.hasData
                    ? DashboardBoardMapper.groupSnapshot(
                        snapshot.data!,
                        includeJobs: _showJobs,
                        includePlanning: _showPlanning,
                      )
                    : DashboardBoardMapper.emptyBoard();

                final fullBoard = snapshot.hasData
                    ? DashboardBoardMapper.groupSnapshot(
                        snapshot.data!,
                        includeJobs: true,
                        includePlanning: true,
                      )
                    : DashboardBoardMapper.emptyBoard();

                return DashboardBoardLayout(
                  itemsByZone: visibleBoard,
                  fullItemsByZone: fullBoard,
                  onProjectMove: _moveProject,
                  onProjectTap: _openProject,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNothingSelectedState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_alt_off_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Nada selecionado para exibir',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Marque Job e/ou Planejamento digital nos filtros acima.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(bool isMobile) {
    final canManageSettings = context.watch<AgencyContext>().canManageSettings;
    final filter = DashboardDisplayFilter(
      showJobs: _showJobs,
      showPlanning: _showPlanning,
      onJobsChanged: (value) => setState(() => _showJobs = value),
      onPlanningChanged: (value) => setState(() => _showPlanning = value),
    );

    final settingsButton = OutlinedButton.icon(
      onPressed: _openProfileSettings,
      icon: const Icon(Icons.settings_outlined),
      label: isMobile ? const Text('Config.') : const Text('Configurações'),
    );

    final newProjectButton = FilledButton.icon(
      onPressed: _isCreatingProject ? null : _showNewProjectDialog,
      icon: _isCreatingProject
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add),
      label: const Text('Novo Projeto'),
    );

    return Padding(
      padding: EdgeInsets.only(right: isMobile ? 0 : 56),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          filter,
          if (canManageSettings) settingsButton,
          newProjectButton,
        ],
      ),
    );
  }
}
