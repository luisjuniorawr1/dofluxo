import '../../../core/utils/date_format_utils.dart';
import '../../shared/models/calendar_delivery_entry.dart';
import 'planning_status.dart';
import 'project_category.dart';

/// Card de planejamento montado na janela Novo Projeto (estado local / rascunho).
///
/// Persistência: cada card vira um doc em `projects` (D4 — sem `planning_posts`).
class PlanningDraftCard {
  const PlanningDraftCard({
    required this.localId,
    required this.clientId,
    required this.clientName,
    required this.scheduledDate,
    required this.format,
    required this.description,
    required this.planningStatus,
    this.reference,
  });

  final String localId;
  final String clientId;
  final String clientName;
  final DateTime scheduledDate;
  final String format;
  final String description;
  final String? reference;
  final PlanningStatus planningStatus;

  /// Título curto para calendário / Kanban.
  String get shortTitle {
    final desc = description.trim();
    if (desc.isNotEmpty) {
      final firstLine = desc.split(RegExp(r'[\r\n]+')).first.trim();
      if (firstLine.length <= 48) return firstLine;
      return '${firstLine.substring(0, 45).trimRight()}…';
    }
    final client = clientName.trim();
    if (client.isNotEmpty) return '$client · $format';
    return format;
  }

  CalendarDeliveryEntry toPreviewEntry() {
    final day = DateFormatUtils.dateOnly(scheduledDate);
    return CalendarDeliveryEntry(
      projectId: 'draft:$localId',
      title: shortTitle,
      deliveryDate: day,
      clientName: clientName.trim().isEmpty ? null : clientName.trim(),
      statusLabel: planningStatus.label,
      primaryTitle: shortTitle,
      accentColor: planningStatus.color,
    );
  }

  /// Payload Firestore de um post do grupo de planejamento.
  Map<String, dynamic> toFirestorePayload({
    required String projectUuid,
    required String groupTitle,
  }) {
    final deliveryTimestamp = DateFormatUtils.toFirestoreTimestamp(scheduledDate);
    final ref = reference?.trim();

    return {
      'id': projectUuid,
      'category': ProjectCategory.planejamento.firestoreValue,
      'title': shortTitle,
      'description': description.trim(),
      'clientId': clientId,
      'clientName': clientName,
      'format': format,
      if (ref != null && ref.isNotEmpty) 'reference': ref,
      'planningStatus': planningStatus.firestoreValue,
      'planningGroup': groupTitle.trim(),
      'status': 'Planejamento',
      if (deliveryTimestamp != null) 'scheduledDate': deliveryTimestamp,
      if (deliveryTimestamp != null) 'expectedDeliveryDate': deliveryTimestamp,
    };
  }

  PlanningDraftCard copyWith({
    String? clientId,
    String? clientName,
    DateTime? scheduledDate,
    String? format,
    String? description,
    String? reference,
    PlanningStatus? planningStatus,
  }) {
    return PlanningDraftCard(
      localId: localId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      format: format ?? this.format,
      description: description ?? this.description,
      reference: reference ?? this.reference,
      planningStatus: planningStatus ?? this.planningStatus,
    );
  }
}
