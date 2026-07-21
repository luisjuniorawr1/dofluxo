import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../profile/pages/profile_page.dart';
import '../../projects/manager/project_service.dart';
import '../../projects/pages/project_detail_page.dart';
import '../../projects/widgets/new_project_dialog.dart';
import '../config/dashboard_layout_breakpoints.dart';
import '../config/dashboard_stages.dart';
import '../models/project_board_item.dart';
import '../utils/board_order_utils.dart';
import '../utils/dashboard_board_mapper.dart';
import '../widgets/dashboard_welcome_header.dart';
import '../widgets/dashboard_board_layout.dart';
import '../widgets/dashboard_workflow_board.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ProjectService _projectService = ProjectService();
  final _uuid = const Uuid();
  bool _isCreatingProject = false;
  final Set<String> _movingProjectIds = {};

  Future<void> _moveProject(
    ProjectMoveIntent intent,
    Map<String, List<ProjectBoardItem>> fullBoard,
  ) async {
    if (_movingProjectIds.contains(intent.projectId)) return;

    final stageKey = intent.targetStage.name;
    final fullColumn = fullBoard[stageKey] ?? const <ProjectBoardItem>[];
    final visibleColumn = fullColumn;

    final targetIndex = BoardOrderUtils.resolveKanbanTargetIndex(
      visibleColumn: visibleColumn,
      fullColumn: fullColumn,
      draggedProjectId: intent.projectId,
      visibleDropIndex: intent.visibleDropIndex,
      visibleDragIndex: intent.visibleDragIndex,
    );

    final dropPosition = BoardOrderUtils.resolveDropPosition(
      fullColumn: fullColumn,
      draggedProjectId: intent.projectId,
      targetIndex: targetIndex,
    );

    final currentStageKey = fullBoard.entries
        .where((entry) => entry.value.any((item) => item.id == intent.projectId))
        .map((entry) => entry.key)
        .firstOrNull;

    if (currentStageKey == stageKey) {
      final existingIndex = fullColumn.indexWhere((item) => item.id == intent.projectId);
      if (existingIndex >= 0) {
        final currentBefore = existingIndex > 0 ? fullColumn[existingIndex - 1].id : null;
        final currentAfter =
            existingIndex < fullColumn.length - 1 ? fullColumn[existingIndex + 1].id : null;
        if (currentBefore == dropPosition.beforeProjectId &&
            currentAfter == dropPosition.afterProjectId) {
          return;
        }
      }
    }

    _movingProjectIds.add(intent.projectId);

    try {
      await _projectService.moveProject(
        projectId: intent.projectId,
        targetStatus: DashboardBoardMapper.firestoreStatusForStage(intent.targetStage),
        targetColumnProjectIds:
            fullColumn.map((item) => item.id).toList(growable: false),
        beforeProjectId: dropPosition.beforeProjectId,
        afterProjectId: dropPosition.afterProjectId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao mover projeto: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      _movingProjectIds.remove(intent.projectId);
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
      MaterialPageRoute(builder: (context) => ProjectDetailPage(projectId: projectId)),
    );
  }

  Future<void> _showNewProjectDialog() async {
    try {
      final result = await showDialog<NewProjectResult>(
        context: context,
        builder: (context) => const NewProjectDialog(),
      );

      if (result == null || !mounted) return;

      setState(() => _isCreatingProject = true);

      final projectId = _uuid.v4();
      final docId = await _projectService.addProject(result.toFirestorePayload(projectId));

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
      padding: EdgeInsets.all(pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardWelcomeHeader(
            userName: _userFirstName,
            actions: _buildActions(),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _projectService.getProjectsStream(),
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

                final fullBoard = snapshot.hasData
                    ? DashboardBoardMapper.groupSnapshot(snapshot.data!)
                    : DashboardBoardMapper.emptyBoard();
                final visibleBoard = fullBoard;
                final statusProjects = DashboardBoardMapper.statusPanelProjects(fullBoard);

                return DashboardBoardLayout(
                  itemsByStage: visibleBoard,
                  statusProjects: statusProjects,
                  onProjectMove: (intent) => _moveProject(intent, fullBoard),
                  onProjectTap: _openProject,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final settingsButton = OutlinedButton.icon(
      onPressed: _openProfileSettings,
      icon: const Icon(Icons.settings_outlined),
      label: const Text('Configurações'),
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        settingsButton,
        const SizedBox(width: 12),
        newProjectButton,
      ],
    );
  }
}
