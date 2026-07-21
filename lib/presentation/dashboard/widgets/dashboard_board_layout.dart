import 'package:flutter/material.dart';

import '../../../core/theme/agency_theme_colors.dart';
import '../../../core/utils/theme_utils.dart';
import '../config/dashboard_layout_breakpoints.dart';
import '../config/dashboard_stages.dart';
import '../models/project_board_item.dart';
import 'dashboard_workflow_board.dart';

/// Layout responsivo do Kanban: 5 colunas no desktop e carrossel no mobile.
class DashboardBoardLayout extends StatefulWidget {
  const DashboardBoardLayout({
    super.key,
    required this.itemsByStage,
    this.onProjectMove,
    this.onProjectTap,
    this.onProjectDragStarted,
    this.onProjectDragEnded,
  });

  final Map<String, List<ProjectBoardItem>> itemsByStage;
  final ProjectMoveCallback? onProjectMove;
  final ProjectTapCallback? onProjectTap;
  final ProjectDragStartedCallback? onProjectDragStarted;
  final ProjectDragStartedCallback? onProjectDragEnded;

  @override
  State<DashboardBoardLayout> createState() => _DashboardBoardLayoutState();
}

class _DashboardBoardLayoutState extends State<DashboardBoardLayout> {
  late final PageController _pageController;
  final ValueNotifier<String?> _draggingProjectId = ValueNotifier(null);
  final ValueNotifier<bool> _isDragging = ValueNotifier(false);
  int _currentPage = 0;

  static const _mobilePageCount = 5;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: DashboardLayoutBreakpoints.mobileColumnViewportFraction,
    );
  }

  void _onDragStarted(String projectId) {
    _draggingProjectId.value = projectId;
    _isDragging.value = true;
    widget.onProjectDragStarted?.call(projectId);
  }

  void _onDragEnded() {
    final projectId = _draggingProjectId.value;
    if (projectId != null) {
      widget.onProjectDragEnded?.call(projectId);
    }
    // Libera o board no próximo frame (aceita o drop antes, sem travar).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _draggingProjectId.value = null;
      _isDragging.value = false;
    });
  }

  void _goToPage(int index) {
    if (index < 0 || index >= _mobilePageCount) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToPreviousPage() => _goToPage(_currentPage - 1);

  void _goToNextPage() => _goToPage(_currentPage + 1);

  @override
  void dispose() {
    _pageController.dispose();
    _draggingProjectId.dispose();
    _isDragging.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile =
            constraints.maxWidth < DashboardLayoutBreakpoints.mobileCarousel;

        if (isMobile) {
          return _MobileCarousel(
            pageController: _pageController,
            currentPage: _currentPage,
            isDragging: _isDragging,
            draggingProjectId: _draggingProjectId,
            onPageChanged: (index) => setState(() => _currentPage = index),
            onGoToPage: _goToPage,
            onPreviousPage: _goToPreviousPage,
            onNextPage: _goToNextPage,
            itemsByStage: widget.itemsByStage,
            onProjectMove: widget.onProjectMove,
            onProjectTap: widget.onProjectTap,
            onDragStarted: _onDragStarted,
            onDragEnded: _onDragEnded,
          );
        }

        return _DesktopBoard(
          itemsByStage: widget.itemsByStage,
          draggingProjectId: _draggingProjectId,
          onProjectMove: widget.onProjectMove,
          onProjectTap: widget.onProjectTap,
          onDragStarted: _onDragStarted,
          onDragEnded: _onDragEnded,
        );
      },
    );
  }
}

class _DesktopBoard extends StatelessWidget {
  const _DesktopBoard({
    required this.itemsByStage,
    required this.draggingProjectId,
    this.onProjectMove,
    this.onProjectTap,
    this.onDragStarted,
    this.onDragEnded,
  });

  final Map<String, List<ProjectBoardItem>> itemsByStage;
  final ValueNotifier<String?> draggingProjectId;
  final ProjectMoveCallback? onProjectMove;
  final ProjectTapCallback? onProjectTap;
  final ProjectDragStartedCallback? onDragStarted;
  final ProjectDragEndedCallback? onDragEnded;

  @override
  Widget build(BuildContext context) {
    final stages = DashboardStage.workflow;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < stages.length; i++) ...[
          if (i > 0)
            const SizedBox(width: DashboardLayoutBreakpoints.desktopColumnSpacing),
          Expanded(
            child: WorkflowColumn(
              stage: stages[i],
              items: itemsByStage[stages[i].storageKey] ?? const [],
              draggingProjectId: draggingProjectId,
              onProjectMove: onProjectMove,
              onProjectTap: onProjectTap,
              onDragStarted: onDragStarted,
              onDragEnded: onDragEnded,
            ),
          ),
        ],
      ],
    );
  }
}

class _MobileCarousel extends StatelessWidget {
  const _MobileCarousel({
    required this.pageController,
    required this.currentPage,
    required this.isDragging,
    required this.draggingProjectId,
    required this.onPageChanged,
    required this.onGoToPage,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.itemsByStage,
    this.onProjectMove,
    this.onProjectTap,
    this.onDragStarted,
    this.onDragEnded,
  });

  final PageController pageController;
  final int currentPage;
  final ValueNotifier<bool> isDragging;
  final ValueNotifier<String?> draggingProjectId;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onGoToPage;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final Map<String, List<ProjectBoardItem>> itemsByStage;
  final ProjectMoveCallback? onProjectMove;
  final ProjectTapCallback? onProjectTap;
  final ProjectDragStartedCallback? onDragStarted;
  final ProjectDragEndedCallback? onDragEnded;

  static const _chipLabels = [
    'Incêndios',
    'Planejamento',
    'Produção',
    'Aprovação',
    'Concluído',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = DashboardStage.workflow
        .map(
          (stage) => WorkflowColumn(
            stage: stage,
            items: itemsByStage[stage.storageKey] ?? const [],
            draggingProjectId: draggingProjectId,
            onProjectMove: onProjectMove,
            onProjectTap: onProjectTap,
            onDragStarted: onDragStarted,
            onDragEnded: onDragEnded,
            isMobileCarousel: true,
          ),
        )
        .toList();

    final theme = Theme.of(context);
    final canGoBack = currentPage > 0;
    final canGoForward = currentPage < pages.length - 1;
    final currentTitle = DashboardStage.workflow[currentPage].title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: canGoBack ? onPreviousPage : null,
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: 'Coluna anterior',
            ),
            Expanded(
              child: Text(
                currentTitle,
                textAlign: TextAlign.center,
                style: ThemeUtils.sectionTitle(context),
              ),
            ),
            IconButton(
              onPressed: canGoForward ? onNextPage : null,
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'Próxima coluna',
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _chipLabels.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final selected = index == currentPage;
              return ChoiceChip(
                label: Text(_chipLabels[index]),
                selected: selected,
                onSelected: (_) => onGoToPage(index),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pages.length, (index) {
            final active = index == currentPage;
            return GestureDetector(
              onTap: () => onGoToPage(index),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: active ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active
                        ? AgencyThemeColors.of(context).contentAccent
                        : theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: isDragging,
            builder: (context, dragging, _) {
              return PageView.builder(
                controller: pageController,
                padEnds: false,
                physics: dragging
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                onPageChanged: onPageChanged,
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0
                          ? 0
                          : DashboardLayoutBreakpoints.mobileColumnSpacing / 2,
                      right: DashboardLayoutBreakpoints.mobileColumnSpacing,
                    ),
                    child: pages[index],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
