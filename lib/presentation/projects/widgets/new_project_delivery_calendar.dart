import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_format_utils.dart';
import '../../../core/utils/theme_utils.dart';
import '../../projects/manager/project_service.dart';
import '../../shared/models/calendar_delivery_entry.dart';
import '../../shared/utils/delivery_calendar_mapper.dart';

typedef NewProjectCalendarProjectTap = void Function(String projectId);

/// Calendário mensal amplo: nomes clicáveis nas datas de entrega (como a sidebar).
class NewProjectDeliveryCalendar extends StatefulWidget {
  const NewProjectDeliveryCalendar({
    super.key,
    this.selectedDay,
    this.onDaySelected,
    this.onProjectTap,
    this.previewEntries = const [],
  });

  final DateTime? selectedDay;
  final ValueChanged<DateTime>? onDaySelected;
  final NewProjectCalendarProjectTap? onProjectTap;

  /// Cards do rascunho (Planejamento) — aparecem na hora sem fechar a janela.
  final List<CalendarDeliveryEntry> previewEntries;

  @override
  State<NewProjectDeliveryCalendar> createState() =>
      _NewProjectDeliveryCalendarState();
}

class _NewProjectDeliveryCalendarState extends State<NewProjectDeliveryCalendar> {
  static const _weekdayLabels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  late DateTime _focusedMonth;
  Stream<QuerySnapshot>? _projectsStream;
  QuerySnapshot? _initialProjects;

  @override
  void initState() {
    super.initState();
    final seed = widget.selectedDay ?? DateTime.now();
    _focusedMonth = DateTime(seed.year, seed.month);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mesma fonte da sidebar: projetos do usuário via ProjectService.
    if (_projectsStream == null) {
      final service = context.read<ProjectService>();
      _initialProjects = service.lastProjectsSnapshot;
      _projectsStream = service.getProjectsStream();
    }
  }

  @override
  void didUpdateWidget(covariant NewProjectDeliveryCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selected = widget.selectedDay;
    if (selected != null &&
        !DateFormatUtils.isSameMonth(selected, _focusedMonth)) {
      _focusedMonth = DateTime(selected.year, selected.month);
    }
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() => _focusedMonth = DateTime(now.year, now.month));
    widget.onDaySelected?.call(DateFormatUtils.dateOnly(now));
  }

  void _mergePreviewEntries(
    Map<DateTime, List<CalendarDeliveryEntry>> grouped,
    List<CalendarDeliveryEntry> preview,
  ) {
    for (final entry in preview) {
      final key = DateFormatUtils.dateOnly(entry.deliveryDate);
      final list = grouped.putIfAbsent(key, () => <CalendarDeliveryEntry>[]);
      // Rascunho fica no topo do dia para o preview ser óbvio.
      list.removeWhere((e) => e.projectId == entry.projectId);
      list.insert(0, entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StreamBuilder<QuerySnapshot>(
      initialData: _initialProjects,
      stream: _projectsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outline),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Não foi possível carregar as entregas do calendário.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outline),
              ),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
        }

        final grouped = snapshot.hasData
            ? DeliveryCalendarMapper.fromSnapshot(snapshot.data!)
            : <DateTime, List<CalendarDeliveryEntry>>{};
        _mergePreviewEntries(grouped, widget.previewEntries);
        final monthCount =
            DeliveryCalendarMapper.countInMonth(grouped, _focusedMonth);
        final selected = widget.selectedDay == null
            ? null
            : DateFormatUtils.dateOnly(widget.selectedDay!);
        final selectedEntries = selected == null
            ? const <CalendarDeliveryEntry>[]
            : DeliveryCalendarMapper.entriesForDay(grouped, selected);

        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(theme, scheme, monthCount),
                const SizedBox(height: 10),
                _buildWeekdayLabels(scheme),
                const SizedBox(height: 6),
                Expanded(child: _buildMonthGrid(theme, scheme, grouped, selected)),
                if (selected != null) ...[
                  const SizedBox(height: 10),
                  _buildSelectedDayPanel(theme, scheme, selected, selectedEntries),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme scheme, int monthCount) {
    return Row(
      children: [
        _navButton(scheme, Icons.chevron_left_rounded, _goToPreviousMonth),
        Expanded(
          child: InkWell(
            onTap: _goToToday,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  Text(
                    DateFormatUtils.formatMonthYear(_focusedMonth),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    monthCount == 0
                        ? 'Nenhuma entrega no mês'
                        : '$monthCount entrega${monthCount == 1 ? '' : 's'} no mês',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _navButton(scheme, Icons.chevron_right_rounded, _goToNextMonth),
      ],
    );
  }

  Widget _navButton(ColorScheme scheme, IconData icon, VoidCallback onPressed) {
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: scheme.onSurface),
        ),
      ),
    );
  }

  Widget _buildWeekdayLabels(ColorScheme scheme) {
    return Row(
      children: _weekdayLabels
          .map(
            (label) => Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMonthGrid(
    ThemeData theme,
    ColorScheme scheme,
    Map<DateTime, List<CalendarDeliveryEntry>> grouped,
    DateTime? selected,
  ) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final leading = firstDay.weekday % 7;
    final today = DateFormatUtils.dateOnly(DateTime.now());
    final totalCells = ((leading + daysInMonth + 6) ~/ 7) * 7;
    final rows = (totalCells / 7).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 4.0;
        final rawHeight = (constraints.maxHeight - gap * (rows - 1)) / rows;
        final cellHeight = rawHeight.clamp(88.0, 140.0);

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            mainAxisExtent: cellHeight,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            final dayNumber = index - leading + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }

            final day =
                DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
            final dayKey = DateFormatUtils.dateOnly(day);
            final entries = grouped[dayKey] ?? const <CalendarDeliveryEntry>[];
            final isSelected = DateFormatUtils.isSameDay(day, selected);
            final isToday = DateFormatUtils.isSameDay(day, today);

            return _MonthDayCell(
              dayNumber: dayNumber,
              entries: entries,
              isSelected: isSelected,
              isToday: isToday,
              onDayTap: () => widget.onDaySelected?.call(dayKey),
              onProjectTap: widget.onProjectTap,
            );
          },
        );
      },
    );
  }

  Widget _buildSelectedDayPanel(
    ThemeData theme,
    ColorScheme scheme,
    DateTime selected,
    List<CalendarDeliveryEntry> entries,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormatUtils.formatDayMonthYear(selected),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Text(
                'Nenhuma entrega nesta data',
                style: ThemeUtils.bodyMuted(context),
              )
            else
              ...entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _ClickableProjectName(
                    entry: entry,
                    dense: false,
                    onTap: widget.onProjectTap == null ||
                            entry.projectId.startsWith('draft:')
                        ? null
                        : () => widget.onProjectTap!(entry.projectId),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.dayNumber,
    required this.entries,
    required this.isSelected,
    required this.isToday,
    required this.onDayTap,
    this.onProjectTap,
  });

  final int dayNumber;
  final List<CalendarDeliveryEntry> entries;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onDayTap;
  final NewProjectCalendarProjectTap? onProjectTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = ThemeUtils.contentAccent(context);

    final background = isSelected ? scheme.primaryContainer : scheme.surface;
    final borderColor = isSelected
        ? scheme.primary
        : isToday
            ? accent
            : scheme.outline;

    return Material(
      color: background,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onDayTap,
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: isToday || isSelected ? 1.8 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      '$dayNumber',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                    if (entries.isNotEmpty) ...[
                      const Spacer(),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: entries.isEmpty
                      ? const SizedBox.shrink()
                      : ListView(
                          padding: EdgeInsets.zero,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            for (final entry in entries.take(3))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: _ClickableProjectName(
                                  entry: entry,
                                  dense: true,
                                  onTap: onProjectTap == null ||
                                          entry.projectId.startsWith('draft:')
                                      ? null
                                      : () => onProjectTap!(entry.projectId),
                                ),
                              ),
                            if (entries.length > 3)
                              Text(
                                '+${entries.length - 3}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Só o nome do projeto, clicável — abre o card completo (igual à sidebar).
class _ClickableProjectName extends StatelessWidget {
  const _ClickableProjectName({
    required this.entry,
    required this.dense,
    this.onTap,
  });

  final CalendarDeliveryEntry entry;
  final bool dense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = ThemeUtils.contentAccent(context);
    final title = entry.cardTitle;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 2 : 4,
          vertical: dense ? 2 : 4,
        ),
        child: Text(
          title,
          maxLines: dense ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: onTap == null ? scheme.onSurface : accent,
            fontWeight: FontWeight.w800,
            fontSize: dense ? 11 : 13,
            height: 1.2,
            decoration: onTap == null ? null : TextDecoration.underline,
            decorationColor: accent.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}
