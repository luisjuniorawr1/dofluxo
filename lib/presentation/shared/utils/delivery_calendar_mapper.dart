import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/date_format_utils.dart';
import '../../dashboard/config/kanban_constants.dart';
import '../../dashboard/models/project_board_item.dart';
import '../../dashboard/utils/dashboard_board_mapper.dart';
import '../models/calendar_delivery_entry.dart';

/// Agrupa os mesmos cards do Kanban por data de entrega (`projectDeliveryDate`).
class DeliveryCalendarMapper {
  DeliveryCalendarMapper._();

  static Map<DateTime, List<CalendarDeliveryEntry>> fromSnapshot(QuerySnapshot snapshot) {
    final grouped = <DateTime, List<CalendarDeliveryEntry>>{};

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final item = ProjectBoardItem.fromFirestore(doc.id, data);
      if (item.cardPrimaryTitle == 'Sem nome' && item.title.isEmpty) continue;

      // Mesma data que o card do Kanban exibe (com fallback do label formatado).
      final deliveryDate = DateFormatUtils.projectDeliveryDate(data) ??
          (item.expectedDeliveryDate != null
              ? DateFormatUtils.tryParseDayMonthYear(item.expectedDeliveryDate!)
              : null);
      if (deliveryDate == null) continue;

      final zone = DashboardBoardMapper.workflowZoneForItem(data, item);
      final zoneColor = KanbanConstants.cardHeaderColorForZone(zone.name);

      grouped.putIfAbsent(deliveryDate, () => []).add(
            CalendarDeliveryEntry(
              projectId: doc.id,
              title: item.title,
              deliveryDate: deliveryDate,
              clientName: item.clientName,
              statusLabel: item.statusLabel ?? item.planningStatusLabel,
              primaryTitle: item.cardPrimaryTitle,
              zoneHeaderColor: zoneColor,
              accentColor: item.accentColor,
            ),
          );
    }

    for (final entries in grouped.values) {
      entries.sort((a, b) => a.cardTitle.compareTo(b.cardTitle));
    }

    return grouped;
  }

  static List<CalendarDeliveryEntry> entriesForDay(
    Map<DateTime, List<CalendarDeliveryEntry>> grouped,
    DateTime day,
  ) {
    return grouped[DateFormatUtils.dateOnly(day)] ?? const [];
  }

  static int countInMonth(Map<DateTime, List<CalendarDeliveryEntry>> grouped, DateTime month) {
    var count = 0;
    for (final entry in grouped.entries) {
      if (DateFormatUtils.isSameMonth(entry.key, month)) {
        count += entry.value.length;
      }
    }
    return count;
  }
}
