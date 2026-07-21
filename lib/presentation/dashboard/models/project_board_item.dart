import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/date_format_utils.dart';
import '../../projects/models/project_production_task.dart';
import '../config/dashboard_stages.dart';
import '../utils/board_order_utils.dart';
import '../utils/dashboard_board_mapper.dart';

/// Item exibido no quadro do dashboard.
class ProjectBoardItem {
  const ProjectBoardItem({
    required this.id,
    required this.title,
    required this.stageId,
    this.clientName,
    this.expectedDeliveryDate,
    this.description,
    this.statusLabel,
    this.progress,
    this.isCompleted = false,
    this.order,
    this.createdAtMillis,
  });

  final String id;
  final String title;
  final DashboardStageId stageId;
  final String? clientName;
  final String? expectedDeliveryDate;
  final String? description;
  final String? statusLabel;
  final double? progress;
  final bool isCompleted;
  final double? order;
  final int? createdAtMillis;

  bool get hasProgress => progress != null;
  bool get hasCanonicalOrder => order != null;

  String get displayTitle {
    if (clientName != null && clientName!.isNotEmpty) {
      return '$clientName - $title';
    }
    return title;
  }

  ProjectBoardItem copyWith({
    String? title,
    DashboardStageId? stageId,
    String? clientName,
    String? expectedDeliveryDate,
    String? description,
    String? statusLabel,
    double? progress,
    bool? isCompleted,
    double? order,
    int? createdAtMillis,
  }) {
    return ProjectBoardItem(
      id: id,
      title: title ?? this.title,
      stageId: stageId ?? this.stageId,
      clientName: clientName ?? this.clientName,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      description: description ?? this.description,
      statusLabel: statusLabel ?? this.statusLabel,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    );
  }

  factory ProjectBoardItem.fromMap(String id, Map<String, dynamic> data) {
    return ProjectBoardItem.fromFirestore(id, data);
  }

  factory ProjectBoardItem.fromFirestore(String id, Map<String, dynamic> data) {
    final tasks = ProjectProductionTask.listFromFirestore(data['productionTasks']);
    final tasksProgress = ProjectProductionTask.progressFromTasks(tasks);

    final progressRaw = data['progress'];
    double? progress = tasksProgress;
    if (progress == null && progressRaw is num) {
      progress = progressRaw.toDouble();
      if (progress > 1) progress = progress / 100;
    }

    final firestoreStatus = data['status'] as String?;
    final stageId = DashboardBoardMapper.stageIdForStatus(firestoreStatus);
    final isCompleted = data['isCompleted'] == true ||
        DashboardBoardMapper.isCompletedStatus(firestoreStatus);

    final statusLabel = (data['statusLabel'] as String?)?.trim() ??
        DashboardBoardMapper.cardStatusLabel(
          firestoreStatus: firestoreStatus,
          stage: stageId,
          isCompleted: isCompleted,
        );

    final orderRaw = data['ordem'] ?? data['boardOrder'];
    final createdAt = data['createdAt'];
    int? createdAtMillis;
    if (createdAt is Timestamp) {
      createdAtMillis = createdAt.millisecondsSinceEpoch;
    }

    return ProjectBoardItem(
      id: id,
      title: (data['title'] as String?)?.trim() ?? '',
      stageId: stageId,
      clientName: (data['clientName'] as String?)?.trim(),
      expectedDeliveryDate: _readExpectedDeliveryDate(data),
      description: (data['description'] as String?)?.trim(),
      statusLabel: statusLabel,
      progress: progress,
      isCompleted: isCompleted,
      order: orderRaw is num ? orderRaw.toDouble() : null,
      createdAtMillis: createdAtMillis,
    );
  }

  static String? _readExpectedDeliveryDate(Map<String, dynamic> data) {
    final parsed = DateFormatUtils.fromFirestore(data['expectedDeliveryDate']);
    if (parsed != null) return DateFormatUtils.formatDayMonthYear(parsed);
    return null;
  }
}

/// Ordena cada coluna do board por `ordem`.
void sortBoardColumns(Map<String, List<ProjectBoardItem>> board) {
  for (final items in board.values) {
    items.sort(BoardOrderUtils.compareItems);
  }
}
