import 'package:flutter/material.dart';

import '../../../core/theme/agency_theme_colors.dart';
import '../../../core/utils/theme_utils.dart';
import '../config/dashboard_layout_breakpoints.dart';
import '../config/dashboard_stages.dart';
import '../models/project_board_item.dart';
import 'dashboard_workflow_board.dart';
import 'project_status_panel.dart';

/// Layout responsivo do quadro: colunas flexíveis no desktop e carrossel no mobile.
class DashboardBoardLayout extends StatefulWidget {
  const DashboardBoardLayout({
    super.key,
    required this.itemsByStage,
    required this.statusProjects,
    this.onProjectMove,
    this.onProjectTap,
  });

  final Map<String, List<ProjectBoardItem>> itemsByStage;
  final List<ProjectBoardItem> statusProjects;
  final ProjectMoveCallback? onProjectMove;
  final ProjectTapCallback? onProjectTap;

  @override
  State<DashboardBoardLayout> createState() => _DashboardBoardLayoutState();
}

class _DashboardBoardLayoutState extends State<DashboardBoardLayout> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _isDragging = false;

  static const _mobilePageCount = 7;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: DashboardLayoutBreakpoints.mobileColumnViewportFraction,
    );
  }

  void _onDragStarted() => setState(() => _isDragging = true);

  void _onDragEnded() {
    if (!mounted) return;
    setState(() => _isDragging = false);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < DashboardLayoutBreakpoints.mobileCarousel;

        if (isMobile) {
          return _MobileCarousel(
            pageController: _pageController,
            currentPage: _currentPage,
            isDragging: _isDragging,
            onPageChanged: (index) => setState(() => _currentPage = index),
            onGoToPage: _goToPage,
            onPreviousPage: _goToPreviousPage,
            onNextPage: _goToNextPage,
            itemsByStage: widget.itemsByStage,
            statusProjects: widget.statusProjects,
            onProjectMove: widget.onProjectMove,
            onProjectTap: widget.onProjectTap,
            onDragStarted: _onDragStarted,
            onDragEnded: _onDragEnded,
          );
        }

        return _DesktopBoard(
          itemsByStage: widget.itemsByStage,
          statusProjects: widget.statusProjects,
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
    required this.statusProjects,
    this.onProjectMove,
    this.onProjectTap,
    this.onDragStarted,
    this.onDragEnded,
  });

  final Map<String, List<ProjectBoardItem>> itemsByStage;
  final List<ProjectBoardItem> statusProjects;
  final ProjectMoveCallback? onProjectMove;
  final ProjectTapCallback? onProjectTap;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;

  @override
  Widget build(BuildContext context) {
    final criacao = DashboardStage.find(DashboardStageId.criacao)!;
    final incendios = DashboardStage.find(DashboardStageId.incendios)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final stage in DashboardStage.workflow)
          if (stage.id == DashboardStageId.incendios)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: WorkflowCriacaoIncendiosColumn(
                  criacaoStage: criacao,
                  incendiosStage: incendios,
                  criacaoItems: itemsByStage[criacao.storageKey] ?? const [],
                  incendiosItems: itemsByStage[incendios.storageKey] ?? const [],
                  onProjectMove: onProjectMove,
                  onProjectTap: onProjectTap,
                  onDragStarted: onDragStarted,
                  onDragEnded: onDragEnded,
                ),
              ),
            )
          else if (stage.id != DashboardStageId.criacao)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: WorkflowColumn(
                  stage: stage,
                  items: itemsByStage[stage.storageKey] ?? const [],
                  onProjectMove: onProjectMove,
                  onProjectTap: onProjectTap,
                  onDragStarted: onDragStarted,
                  onDragEnded: onDragEnded,
                ),
              ),
            ),
        Expanded(
          child: ProjectStatusPanel(projects: statusProjects),
        ),
      ],
    );
  }
}

class _MobileCarousel extends StatelessWidget {
  const _MobileCarousel({
    required this.pageController,
    required this.currentPage,
    required this.isDragging,
    required this.onPageChanged,
    required this.onGoToPage,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.itemsByStage,
    required this.statusProjects,
    this.onProjectMove,
    this.onProjectTap,
    this.onDragStarted,
    this.onDragEnded,
  });

  final PageController pageController;
  final int currentPage;
  final bool isDragging;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onGoToPage;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final Map<String, List<ProjectBoardItem>> itemsByStage;
  final List<ProjectBoardItem> statusProjects;
  final ProjectMoveCallback? onProjectMove;
  final ProjectTapCallback? onProjectTap;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;

  static const _pageTitles = [
    'Postagens do dia',
    'Criação',
    'Incêndios',
    'Captação',
    'Edição',
    'Aprovação',
    'Status do Projeto',
  ];

  static const _chipLabels = [
    'Postagens',
    'Criação',
    'Incêndios',
    'Captação',
    'Edição',
    'Aprovação',
    'Status',
  ];

  @override
  Widget build(BuildContext context) {
    final criacao = DashboardStage.find(DashboardStageId.criacao)!;
    final incendios = DashboardStage.find(DashboardStageId.incendios)!;
    final postagens = DashboardStage.find(DashboardStageId.postagensDoDia)!;
    final captacao = DashboardStage.find(DashboardStageId.captacao)!;
    final edicao = DashboardStage.find(DashboardStageId.edicao)!;
    final aprovacao = DashboardStage.find(DashboardStageId.aprovacao)!;

    final pages = <Widget>[
      WorkflowColumn(
        stage: postagens,
        items: itemsByStage[postagens.storageKey] ?? const [],
        onProjectMove: onProjectMove,
        onProjectTap: onProjectTap,
        onDragStarted: onDragStarted,
        onDragEnded: onDragEnded,
        isMobileCarousel: true,
      ),
      WorkflowColumn(
        stage: criacao,
        items: itemsByStage[criacao.storageKey] ?? const [],
        onProjectMove: onProjectMove,
        onProjectTap: onProjectTap,
        onDragStarted: onDragStarted,
        onDragEnded: onDragEnded,
        isMobileCarousel: true,
      ),
      WorkflowColumn(
        stage: incendios,
        items: itemsByStage[incendios.storageKey] ?? const [],
        onProjectMove: onProjectMove,
        onProjectTap: onProjectTap,
        onDragStarted: onDragStarted,
        onDragEnded: onDragEnded,
        isMobileCarousel: true,
      ),
      WorkflowColumn(
        stage: captacao,
        items: itemsByStage[captacao.storageKey] ?? const [],
        onProjectMove: onProjectMove,
        onProjectTap: onProjectTap,
        onDragStarted: onDragStarted,
        onDragEnded: onDragEnded,
        isMobileCarousel: true,
      ),
      WorkflowColumn(
        stage: edicao,
        items: itemsByStage[edicao.storageKey] ?? const [],
        onProjectMove: onProjectMove,
        onProjectTap: onProjectTap,
        onDragStarted: onDragStarted,
        onDragEnded: onDragEnded,
        isMobileCarousel: true,
      ),
      WorkflowColumn(
        stage: aprovacao,
        items: itemsByStage[aprovacao.storageKey] ?? const [],
        onProjectMove: onProjectMove,
        onProjectTap: onProjectTap,
        onDragStarted: onDragStarted,
        onDragEnded: onDragEnded,
        isMobileCarousel: true,
      ),
      ProjectStatusPanel(projects: statusProjects),
    ];

    final theme = Theme.of(context);
    final canGoBack = currentPage > 0;
    final canGoForward = currentPage < pages.length - 1;

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
                _pageTitles[currentPage],
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
          child: PageView.builder(
            controller: pageController,
            padEnds: false,
            physics: isDragging
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            onPageChanged: onPageChanged,
            itemCount: pages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : DashboardLayoutBreakpoints.mobileColumnSpacing / 2,
                  right: DashboardLayoutBreakpoints.mobileColumnSpacing,
                ),
                child: pages[index],
              );
            },
          ),
        ),
      ],
    );
  }
}
