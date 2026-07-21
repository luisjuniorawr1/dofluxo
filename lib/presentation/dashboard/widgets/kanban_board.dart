import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/agency_theme_colors.dart';
import '../../../core/utils/theme_utils.dart';
import '../config/dashboard_layout_breakpoints.dart';
import '../config/kanban_constants.dart';
import 'kanban_column.dart';

/// Quadro Kanban genérico: colunas expandidas no desktop e carrossel no mobile.
class KanbanBoard<T> extends StatefulWidget {
  const KanbanBoard({
    super.key,
    required this.columns,
    required this.itemsByColumn,
    required this.itemId,
    required this.cardBuilder,
    this.onMove,
    this.onTap,
  });

  final List<KanbanColumnConfig> columns;
  final Map<String, List<T>> itemsByColumn;
  final KanbanItemIdCallback<T> itemId;
  final KanbanCardBuilder<T> cardBuilder;
  final KanbanMoveCallback<T>? onMove;
  final KanbanItemTapCallback<T>? onTap;

  @override
  State<KanbanBoard<T>> createState() => _KanbanBoardState<T>();
}

class _KanbanBoardState<T> extends State<KanbanBoard<T>> {
  late final PageController _pageController;
  final ValueNotifier<String?> _draggingItemId = ValueNotifier(null);
  final ValueNotifier<bool> _isDragging = ValueNotifier(false);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: DashboardLayoutBreakpoints.mobileColumnViewportFraction,
    );
  }

  void _onDragStarted(String itemId) {
    _draggingItemId.value = itemId;
    _isDragging.value = true;
  }

  void _onDragEnded() {
    _draggingItemId.value = null;
    _isDragging.value = false;
  }

  void _goToPage(int index) {
    if (index < 0 || index >= widget.columns.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  KanbanColumn<T> _buildColumn(KanbanColumnConfig column, {bool isMobileCarousel = false}) {
    return KanbanColumn<T>(
      column: column,
      items: widget.itemsByColumn[column.id] ?? const [],
      itemId: widget.itemId,
      cardBuilder: widget.cardBuilder,
      draggingItemId: _draggingItemId,
      onMove: widget.onMove,
      onTap: widget.onTap,
      onDragStarted: _onDragStarted,
      onDragEnded: _onDragEnded,
      isMobileCarousel: isMobileCarousel,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _draggingItemId.dispose();
    _isDragging.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < DashboardLayoutBreakpoints.mobileCarousel;

          if (isMobile) {
            return _MobileCarousel<T>(
              pageController: _pageController,
              currentPage: _currentPage,
              isDragging: _isDragging,
              columns: widget.columns,
              buildColumn: (column) => _buildColumn(column, isMobileCarousel: true),
              onPageChanged: (index) => setState(() => _currentPage = index),
              onGoToPage: _goToPage,
              onPreviousPage: () => _goToPage(_currentPage - 1),
              onNextPage: () => _goToPage(_currentPage + 1),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < widget.columns.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i == widget.columns.length - 1 ? 0 : KanbanConstants.columnSpacing,
                    ),
                    child: _buildColumn(widget.columns[i]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MobileCarousel<T> extends StatelessWidget {
  const _MobileCarousel({
    required this.pageController,
    required this.currentPage,
    required this.isDragging,
    required this.columns,
    required this.buildColumn,
    required this.onPageChanged,
    required this.onGoToPage,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  final PageController pageController;
  final int currentPage;
  final ValueNotifier<bool> isDragging;
  final List<KanbanColumnConfig> columns;
  final Widget Function(KanbanColumnConfig column) buildColumn;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onGoToPage;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canGoBack = currentPage > 0;
    final canGoForward = currentPage < columns.length - 1;
    final currentTitle = columns[currentPage].title;

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
            itemCount: columns.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final selected = index == currentPage;
              final shortLabel = columns[index].title.replaceAll(RegExp(r'[^\w\sÀ-ÿ]'), '').trim();
              return ChoiceChip(
                label: Text(shortLabel),
                selected: selected,
                onSelected: (_) => onGoToPage(index),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(columns.length, (index) {
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
                itemCount: columns.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : DashboardLayoutBreakpoints.mobileColumnSpacing / 2,
                      right: DashboardLayoutBreakpoints.mobileColumnSpacing,
                    ),
                    child: buildColumn(columns[index]),
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
