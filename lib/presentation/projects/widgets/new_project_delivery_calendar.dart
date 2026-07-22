import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_format_utils.dart';
import '../../../core/utils/theme_utils.dart';
import '../../projects/manager/project_service.dart';
import '../../shared/models/calendar_delivery_entry.dart';
import '../../shared/utils/delivery_calendar_mapper.dart';

/// Calendário mensal amplo para o painel “Novo Projeto” (entregas do DOFLUXO).
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

  @override
  void initState() {
    super.initState();
    final seed = widget.selectedDay ?? DateTime.now();
    _focusedMonth = DateTime(seed.year, seed.month);
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
      stream: context.read<ProjectService>().getProjectsStream(),
      builder: (context, snapshot) {
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(theme, scheme, monthCount),
                const SizedBox(height: 12),
                _buildWeekdayLabels(scheme),
                const SizedBox(height: 6),
                Expanded(child: _buildMonthGrid(theme, scheme, grouped, selected)),
                if (selected != null) ...[
                  const SizedBox(height: 12),
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
                  if (monthCount > 0)
                    Text(
                      '$monthCount entrega${monthCount == 1 ? '' : 's'} no mês',
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
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
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

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.78,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayNumber = index - leading + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final day = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
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
              ...entries.take(4).map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: ThemeUtils.contentAccent(context),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            if (entries.length > 4)
              Text(
                '+${entries.length - 4} mais',
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

    final background = isSelected
        ? scheme.primaryContainer
        : scheme.surface;
    final borderColor = isSelected
        ? scheme.primary
        : isToday
            ? accent
            : scheme.outline;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: isToday || isSelected ? 1.5 : 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dayNumber',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isSelected ? scheme.onPrimaryContainer : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                ...entries.take(2).map((entry) {
                  final label = (entry.clientName?.isNotEmpty ?? false)
                      ? entry.clientName!
                      : entry.title;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (entries.length > 2)
                  Text(
                    '+${entries.length - 2}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
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
