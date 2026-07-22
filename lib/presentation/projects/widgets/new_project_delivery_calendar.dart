import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_format_utils.dart';
import '../../../core/utils/theme_utils.dart';
import '../../projects/manager/project_service.dart';
import '../../shared/models/calendar_delivery_entry.dart';
import '../../shared/utils/delivery_calendar_mapper.dart';

/// Calendário mensal amplo: cards do Kanban nas datas de entrega.
class NewProjectDeliveryCalendar extends StatefulWidget {
  const NewProjectDeliveryCalendar({
    super.key,
    this.selectedDay,
    this.onDaySelected,
  });

  final DateTime? selectedDay;
  final ValueChanged<DateTime>? onDaySelected;

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
    // initialData = snapshot que a sidebar/Kanban já têm (evita mês vazio).
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
          // Stream.empty() termina sem data — não ficar em loading infinito.
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
                        : '$monthCount card${monthCount == 1 ? '' : 's'} do Kanban',
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
        // Células altas o bastante para mini-cards do Kanban.
        final cellHeight = rawHeight.clamp(112.0, 180.0);

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
              onTap: () => widget.onDaySelected?.call(dayKey),
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
                'Nenhum card do Kanban nesta data',
                style: ThemeUtils.bodyMuted(context),
              )
            else
              ...entries.take(5).map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _KanbanMiniCard(entry: entry, dense: false),
                    ),
                  ),
            if (entries.length > 5)
              Text(
                '+${entries.length - 5} cards',
                style: ThemeUtils.bodyMuted(context),
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
    required this.onTap,
  });

  final int dayNumber;
  final List<CalendarDeliveryEntry> entries;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

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
        onTap: onTap,
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: entries.first.zoneHeaderColor ?? accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${entries.length}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
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
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            for (final entry in entries.take(2))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: _KanbanMiniCard(entry: entry, dense: true),
                              ),
                            if (entries.length > 2)
                              Text(
                                '+${entries.length - 2}',
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

/// Mini card no visual do Kanban (barra colorida da coluna + título).
class _KanbanMiniCard extends StatelessWidget {
  const _KanbanMiniCard({
    required this.entry,
    required this.dense,
  });

  final CalendarDeliveryEntry entry;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barColor = entry.zoneHeaderColor ??
        entry.accentColor ??
        ThemeUtils.contentAccent(context);
    final subtitle = entry.cardSubtitle;

    return Material(
      color: Colors.white,
      elevation: dense ? 0.5 : 1,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: dense ? 3.5 : 4.5, color: barColor),
          Padding(
            padding: EdgeInsets.fromLTRB(
              dense ? 5 : 8,
              dense ? 4 : 6,
              dense ? 5 : 8,
              dense ? 4 : 6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.cardTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w800,
                    fontSize: dense ? 11 : 12,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF1A1A1A).withValues(alpha: 0.65),
                      fontWeight: FontWeight.w600,
                      fontSize: dense ? 9 : 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
