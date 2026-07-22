import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_format_utils.dart';
import '../../projects/manager/project_service.dart';
import '../models/calendar_delivery_entry.dart';
import '../utils/delivery_calendar_mapper.dart';

typedef DeliveryProjectTap = void Function(String projectId);

/// Calendário compacto na sidebar com entregas previstas dos projetos.
class SidebarDeliveryCalendar extends StatefulWidget {
  const SidebarDeliveryCalendar({
    super.key,
    required this.onPrimary,
    this.onProjectTap,
  });

  final Color onPrimary;
  final DeliveryProjectTap? onProjectTap;

  @override
  State<SidebarDeliveryCalendar> createState() => _SidebarDeliveryCalendarState();
}

class _SidebarDeliveryCalendarState extends State<SidebarDeliveryCalendar> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;
  Stream<QuerySnapshot>? _projectsStream;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = DateFormatUtils.dateOnly(now);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _projectsStream ??= context.read<ProjectService>().getProjectsStream();
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      _syncSelectionWithFocusedMonth();
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      _syncSelectionWithFocusedMonth();
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month);
      _selectedDay = DateFormatUtils.dateOnly(now);
    });
  }

  void _syncSelectionWithFocusedMonth() {
    if (_selectedDay != null && !DateFormatUtils.isSameMonth(_selectedDay!, _focusedMonth)) {
      final now = DateTime.now();
      _selectedDay = DateFormatUtils.isSameMonth(now, _focusedMonth)
          ? DateFormatUtils.dateOnly(now)
          : null;
    }
  }

  void _selectDay(DateTime day) {
    setState(() => _selectedDay = DateFormatUtils.dateOnly(day));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _projectsStream,
      builder: (context, snapshot) {
        final grouped = snapshot.hasData
            ? DeliveryCalendarMapper.fromSnapshot(snapshot.data!)
            : <DateTime, List<CalendarDeliveryEntry>>{};

        final monthCount = DeliveryCalendarMapper.countInMonth(grouped, _focusedMonth);
        final selectedEntries = _selectedDay == null
            ? const <CalendarDeliveryEntry>[]
            : DeliveryCalendarMapper.entriesForDay(grouped, _selectedDay!);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(monthCount),
            const SizedBox(height: 8),
            _buildWeekdayLabels(),
            const SizedBox(height: 4),
            _buildMonthGrid(grouped),
            if (_selectedDay != null) ...[
              const SizedBox(height: 12),
              _buildSelectedDayPanel(selectedEntries),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHeader(int monthCount) {
    final muted = widget.onPrimary.withValues(alpha: 0.75);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _iconButton(Icons.chevron_left_rounded, _goToPreviousMonth),
            Expanded(
              child: GestureDetector(
                onTap: _goToToday,
                child: Text(
                  DateFormatUtils.formatMonthYear(_focusedMonth),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: widget.onPrimary,
                  ),
                ),
              ),
            ),
            _iconButton(Icons.chevron_right_rounded, _goToNextMonth),
          ],
        ),
        if (monthCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$monthCount entrega${monthCount == 1 ? '' : 's'} no mês',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: muted),
            ),
          ),
      ],
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: widget.onPrimary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon, size: 18, color: widget.onPrimary),
        ),
      ),
    );
  }

  Widget _buildWeekdayLabels() {
    return Row(
      children: DateFormatUtils.weekdayLabelsShort
          .map(
            (label) => Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: widget.onPrimary.withValues(alpha: 0.65),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMonthGrid(Map<DateTime, List<CalendarDeliveryEntry>> grouped) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final leading = firstDay.weekday % 7;
    final today = DateFormatUtils.dateOnly(DateTime.now());
    final totalCells = ((leading + daysInMonth + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayNumber = index - leading + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final day = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
        final hasDeliveries = grouped.containsKey(DateFormatUtils.dateOnly(day));
        final isSelected = DateFormatUtils.isSameDay(day, _selectedDay);
        final isToday = DateFormatUtils.isSameDay(day, today);

        return _DayCell(
          day: dayNumber,
          onPrimary: widget.onPrimary,
          isSelected: isSelected,
          isToday: isToday,
          hasDeliveries: hasDeliveries,
          onTap: () => _selectDay(day),
        );
      },
    );
  }

  Widget _buildSelectedDayPanel(List<CalendarDeliveryEntry> entries) {
    final dayLabel = DateFormatUtils.formatDayMonth(_selectedDay!);
    final muted = widget.onPrimary.withValues(alpha: 0.8);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.onPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.onPrimary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: widget.onPrimary,
            ),
          ),
          const SizedBox(height: 6),
          if (entries.isEmpty)
            Text(
              'Nenhuma entrega nesta data',
              style: TextStyle(fontSize: 10, color: muted),
            )
          else
            ...entries.map((entry) => _DeliveryTile(
                  entry: entry,
                  onPrimary: widget.onPrimary,
                  onTap: widget.onProjectTap == null
                      ? null
                      : () => widget.onProjectTap!(entry.projectId),
                )),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.onPrimary,
    required this.isSelected,
    required this.isToday,
    required this.hasDeliveries,
    required this.onTap,
  });

  final int day;
  final Color onPrimary;
  final bool isSelected;
  final bool isToday;
  final bool hasDeliveries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = isSelected
        ? onPrimary.withValues(alpha: 0.28)
        : isToday
            ? onPrimary.withValues(alpha: 0.14)
            : Colors.transparent;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                color: onPrimary.withValues(alpha: isSelected ? 1 : 0.9),
              ),
            ),
            if (hasDeliveries)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: onPrimary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryTile extends StatelessWidget {
  const _DeliveryTile({
    required this.entry,
    required this.onPrimary,
    this.onTap,
  });

  final CalendarDeliveryEntry entry;
  final Color onPrimary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: onPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: onPrimary,
                    height: 1.25,
                  ),
                ),
                if (entry.statusLabel != null && entry.statusLabel!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.statusLabel!,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: onPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
