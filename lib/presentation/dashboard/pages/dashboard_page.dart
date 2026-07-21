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
import '../models/project_board_item.dart';
import '../utils/board_order_utils.dart';
import '../utils/dashboard_board_mapper.dart';
import '../widgets/dashboard_welcome_header.dart';
import '../widgets/dashboard_board_layout.dart';
import '../widgets/dashboard_display_filter.dart';
import '../widgets/dashboard_workflow_board.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _uuid = const Uuid();
  bool _isCreatingProject = false;
  final Set<String> _movingProjectIds = {};
  final Map<String, _PendingBoardMove> _pendingMoves = {};
  final Map<String, DateTime> _dragStartedAt = {};
  String? _scheduledOrderMigration;
  bool _showJobs = true;
  bool _showPlanning = true;

  Stream<QuerySnapshot>? _projectsStream;
  final ValueNotifier<bool> _isBoardDragging = ValueNotifier(false);
  final ValueNotifier<int> _pendingMovesTick = ValueNotifier(0);
  Map<String, List<ProjectBoardItem>> _lastVisibleBoard =
      DashboardBoardMapper.emptyBoard();
  Map<String, List<ProjectBoardItem>> _lastOptimisticBoard =
      DashboardBoardMapper.emptyBoard();

  @override
  void dispose() {
    _isBoardDragging.dispose();
    _pendingMovesTick.dispose();
    super.dispose();
  }

  void _notifyBoardDataChanged() {
    _pendingMovesTick.value++;
  }

  Future<void> _moveProject(
    ProjectMoveIntent intent,
    Map<String, List<ProjectBoardItem>> fullBoard,
  ) async {
    if (_movingProjectIds.contains(intent.projectId)) return;

    final targetColumn =
        fullBoard[intent.targetStage.name] ?? const <ProjectBoardItem>[];
    final columnWithoutDragged = targetColumn
        .where((item) => item.id != intent.projectId)
        .toList()
      ..sort(BoardOrderUtils.compareItems);

    final insertIndex =
        intent.targetInsertIndex.clamp(0, columnWithoutDragged.length);
    final dropPosition = FullDropPosition(
      insertIndex: insertIndex,
      beforeProjectId:
          insertIndex > 0 ? columnWithoutDragged[insertIndex - 1].id : null,
      afterProjectId: insertIndex < columnWithoutDragged.length
          ? columnWithoutDragged[insertIndex].id
          : null,
    );
    final draggedItem = fullBoard.values
        .expand((items) => items)
        .where((item) => item.id == intent.projectId)
        .firstOrNull;
    if (draggedItem == null) return;

    // No-op: mesmos vizinhos = mesma posição (não misturar índices com/sem o card).
    final currentColumnKey = fullBoard.entries
        .where((entry) => entry.value.any((item) => item.id == intent.projectId))
        .map((entry) => entry.key)
        .firstOrNull;
    if (currentColumnKey == intent.targetStage.name) {
      final sortedColumn = List<ProjectBoardItem>.of(targetColumn)
        ..sort(BoardOrderUtils.compareItems);
      final currentIndex = sortedColumn.indexWhere(
        (item) => item.id == intent.projectId,
      );
      if (currentIndex >= 0) {
        final currentBefore =
            currentIndex > 0 ? sortedColumn[currentIndex - 1].id : null;
        final currentAfter = currentIndex < sortedColumn.length - 1
            ? sortedColumn[currentIndex + 1].id
            : null;
        if (currentBefore == dropPosition.beforeProjectId &&
            currentAfter == dropPosition.afterProjectId) {
          return;
        }
      }
    }

    _movingProjectIds.add(intent.projectId);
    _pendingMoves[intent.projectId] = _PendingBoardMove(
      projectId: intent.projectId,
      targetStageKey: intent.targetStage.name,
      beforeProjectId: dropPosition.beforeProjectId,
      afterProjectId: dropPosition.afterProjectId,
    );
    _notifyBoardDataChanged();

    try {
      await context.read<ProjectService>().moveProject(
        projectId: intent.projectId,
        targetStatus: DashboardBoardMapper.firestoreStatusForStage(
          intent.targetStage,
        ),
        targetColumnProjectIds: targetColumn
            .map((item) => item.id)
            .toList(growable: false),
        beforeProjectId: dropPosition.beforeProjectId,
        afterProjectId: dropPosition.afterProjectId,
        planningStatus: DashboardBoardMapper.planningStatusForStage(
          intent.targetStage,
        ),
        updatePlanningStatus: draggedItem.isPlanejamento,
      );
    } catch (e) {
      _pendingMoves.remove(intent.projectId);
      _notifyBoardDataChanged();
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

  /// Confirma move otimista só quando a posição relativa já bate com o stream.
  void _reconcilePendingMoves(Map<String, List<ProjectBoardItem>> streamBoard) {
    if (_pendingMoves.isEmpty) return;

    final confirmedIds = <String>[];
    for (final move in _pendingMoves.values) {
      final target = streamBoard[move.targetStageKey] ?? const [];
      final index = target.indexWhere((item) => item.id == move.projectId);
      if (index < 0) continue;

      final beforeId = index > 0 ? target[index - 1].id : null;
      final afterId = index < target.length - 1 ? target[index + 1].id : null;
      if (beforeId == move.beforeProjectId && afterId == move.afterProjectId) {
        confirmedIds.add(move.projectId);
      }
    }

    if (confirmedIds.isEmpty) return;
    for (final id in confirmedIds) {
      _pendingMoves.remove(id);
    }
    _notifyBoardDataChanged();
  }

  Map<String, List<ProjectBoardItem>> _applyPendingMoves(
    Map<String, List<ProjectBoardItem>> streamBoard,
  ) {
    if (_pendingMoves.isEmpty) return streamBoard;

    final board = {
      for (final entry in streamBoard.entries)
        entry.key: List<ProjectBoardItem>.of(entry.value),
    };

    for (final move in _pendingMoves.values) {
      ProjectBoardItem? movingItem;
      for (final items in board.values) {
        final index = items.indexWhere((item) => item.id == move.projectId);
        if (index >= 0) {
          movingItem = items.removeAt(index);
          break;
        }
      }
      if (movingItem == null) continue;

      final target = board[move.targetStageKey];
      if (target == null) continue;

      var insertIndex = target.length;
      if (move.afterProjectId != null) {
        final index = target.indexWhere(
          (item) => item.id == move.afterProjectId,
        );
        if (index >= 0) insertIndex = index;
      } else if (move.beforeProjectId != null) {
        final index = target.indexWhere(
          (item) => item.id == move.beforeProjectId,
        );
        if (index >= 0) insertIndex = index + 1;
      }

      target.insert(insertIndex.clamp(0, target.length), movingItem);
    }

    return board;
  }

  void _scheduleOrderMigration(Map<String, List<ProjectBoardItem>> fullBoard) {
    if (_isBoardDragging.value || _pendingMoves.isNotEmpty) return;

    final missingIds =
        fullBoard.values
            .expand((items) => items)
            .where((item) => !item.hasCanonicalOrder)
            .map((item) => item.id)
            .toList()
          ..sort();
    if (missingIds.isEmpty) {
      _scheduledOrderMigration = null;
      return;
    }

    final signature = missingIds.join('|');
    if (_scheduledOrderMigration == signature) return;
    _scheduledOrderMigration = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await context.read<ProjectService>().migrateMissingOrders(fullBoard);
      } catch (e) {
        _scheduledOrderMigration = null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao migrar ordem dos projetos: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    });
  }

  void _markProjectDragStarted(String projectId) {
    _dragStartedAt[projectId] = DateTime.now();
    _isBoardDragging.value = true;
  }

  void _markProjectDragEnded(String projectId) {
    _dragStartedAt[projectId] = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _isBoardDragging.value = false;
    });
  }

  String get _userFirstName {
    try {
      final displayName = FirebaseAuth.instance.currentUser?.displayName
          ?.trim();
      if (displayName == null || displayName.isEmpty) return '';
      return displayName.split(' ').first;
    } catch (_) {
      return '';
    }
  }

  Future<void> _openProfileSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ProfilePage()));
  }

  Future<void> _openProject(String projectId) async {
    final draggedAt = _dragStartedAt[projectId];
    if (draggedAt != null &&
        DateTime.now().difference(draggedAt) <
            const Duration(milliseconds: 600)) {
      return;
    }
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
        builder: (dialogContext) =>
            AgencyServiceScope.wrapRoute(context, const NewProjectDialog()),
      );

      if (result == null || !mounted) return;

      setState(() => _isCreatingProject = true);

      final projectId = _uuid.v4();
      final docId = await context.read<ProjectService>().addProject(
        result.toFirestorePayload(projectId),
      );

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
          SnackBar(
            content: Text('Projeto "${result.title}" criado com sucesso!'),
          ),
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
    final isMobile =
        MediaQuery.sizeOf(context).width <
        DashboardLayoutBreakpoints.mobileCarousel;
    final pagePadding = isMobile ? 16.0 : 28.0;
    _projectsStream ??= context.read<ProjectService>().getProjectsStream();

    return Padding(
      padding: EdgeInsets.all(pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardWelcomeHeader(
            userName: _userFirstName,
            actions: _buildActions(isMobile),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _projectsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar projetos: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData &&
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!_showJobs && !_showPlanning) {
                  return _buildNothingSelectedState(context);
                }

                final fullBoard = snapshot.hasData
                    ? DashboardBoardMapper.groupSnapshot(snapshot.data!)
                    : DashboardBoardMapper.emptyBoard();

                return ValueListenableBuilder<bool>(
                  valueListenable: _isBoardDragging,
                  builder: (context, isDragging, _) {
                    return ValueListenableBuilder<int>(
                      valueListenable: _pendingMovesTick,
                      builder: (context, _, __) {
                        if (!isDragging) {
                          _reconcilePendingMoves(fullBoard);
                          _scheduleOrderMigration(fullBoard);
                        }

                        final optimisticBoard = _applyPendingMoves(fullBoard);
                        final visibleBoard = DashboardBoardMapper.filterBoard(
                          optimisticBoard,
                          includeJobs: _showJobs,
                          includePlanning: _showPlanning,
                        );

                        // Congela o board só durante o arraste (antes do drop).
                        // Depois do drop (com pending) mostra a posição otimista na hora.
                        final freezeBoard =
                            isDragging && _pendingMoves.isEmpty;
                        if (!freezeBoard) {
                          _lastVisibleBoard = visibleBoard;
                          _lastOptimisticBoard = optimisticBoard;
                        }

                        final boardToShow =
                            freezeBoard ? _lastVisibleBoard : visibleBoard;
                        final boardForMove = freezeBoard
                            ? _lastOptimisticBoard
                            : optimisticBoard;

                        return DashboardBoardLayout(
                          itemsByStage: boardToShow,
                          onProjectMove: (intent) =>
                              _moveProject(intent, boardForMove),
                          onProjectTap: _openProject,
                          onProjectDragStarted: _markProjectDragStarted,
                          onProjectDragEnded: _markProjectDragEnded,
                        );
                      },
                    );
                  },
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
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Nada selecionado para exibir',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
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

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        filter,
        if (canManageSettings) settingsButton,
        newProjectButton,
      ],
    );
  }
}

class _PendingBoardMove {
  const _PendingBoardMove({
    required this.projectId,
    required this.targetStageKey,
    this.beforeProjectId,
    this.afterProjectId,
  });

  final String projectId;
  final String targetStageKey;
  final String? beforeProjectId;
  final String? afterProjectId;
}
