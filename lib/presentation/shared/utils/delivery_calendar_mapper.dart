import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/date_format_utils.dart';
import '../../dashboard/utils/dashboard_board_mapper.dart';
import '../models/calendar_delivery_entry.dart';

/// Agrupa projetos por data de entrega prevista para o calendário lateral.
class DeliveryCalendarMapper {
  DeliveryCalendarMapper._();

  static Map<DateTime, List<CalendarDeliveryEntry>> fromSnapshot(QuerySnapshot snapshot) {
    final grouped = <DateTime, List<CalendarDeliveryEntry>>{};

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final deliveryDate = DateFormatUtils.fromFirestore(data['expectedDeliveryDate']);
      final title = (data['title'] as String?)?.trim() ?? '';
      if (deliveryDate == null || title.isEmpty) continue;

      final key = DateFormatUtils.dateOnly(deliveryDate);
      final status = data['status'] as String?;
      final stageId = DashboardBoardMapper.stageIdForStatus(status);
      final statusLabel = DashboardBoardMapper.cardStatusLabel(
        firestoreStatus: status,
        stage: stageId,
        isCompleted: DashboardBoardMapper.isCompletedStatus(status),
      );

      grouped.putIfAbsent(key, () => []).add(
            CalendarDeliveryEntry(
              projectId: doc.id,
              title: title,
              deliveryDate: key,
              clientName: (data['clientName'] as String?)?.trim(),
              statusLabel: statusLabel,
            ),
          );
    }

    for (final entries in grouped.values) {
      entries.sort((a, b) => a.title.compareTo(b.title));
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
