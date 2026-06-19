/// Entrega de projeto exibida no calendário lateral.
class CalendarDeliveryEntry {
  const CalendarDeliveryEntry({
    required this.projectId,
    required this.title,
    required this.deliveryDate,
    this.clientName,
    this.statusLabel,
  });

  final String projectId;
  final String title;
  final DateTime deliveryDate;
  final String? clientName;
  final String? statusLabel;

  String get displayTitle {
    if (clientName != null && clientName!.isNotEmpty) {
      return '$clientName - $title';
    }
    return title;
  }
}
