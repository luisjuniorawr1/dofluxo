import '../../../core/utils/date_format_utils.dart';
import '../../projects/models/project_production_task.dart';
import '../utils/dashboard_board_mapper.dart';
/// Item exibido no quadro do dashboard.
///
/// Campos opcionais são renderizados somente quando preenchidos,
/// permitindo que cada agência alimente os cards conforme seu uso.
class ProjectBoardItem {
  const ProjectBoardItem({
    required this.id,
    required this.title,
    this.clientName,
    this.expectedDeliveryDate,
    this.description,
    this.statusLabel,
    this.progress,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String? clientName;
  final String? expectedDeliveryDate;
  final String? description;
  final String? statusLabel;
  final double? progress;
  final bool isCompleted;

  bool get hasProgress => progress != null;

  String get displayTitle {
    if (clientName != null && clientName!.isNotEmpty) {
      return '$clientName - $title';
    }
    return title;
  }

  ProjectBoardItem copyWith({
    String? title,
    String? clientName,
    String? expectedDeliveryDate,
    String? description,
    String? statusLabel,
    double? progress,
    bool? isCompleted,
  }) {
    return ProjectBoardItem(
      id: id,
      title: title ?? this.title,
      clientName: clientName ?? this.clientName,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      description: description ?? this.description,
      statusLabel: statusLabel ?? this.statusLabel,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
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

    return ProjectBoardItem(
      id: id,
      title: (data['title'] as String?)?.trim() ?? '',
      clientName: (data['clientName'] as String?)?.trim(),
      expectedDeliveryDate: _readExpectedDeliveryDate(data),
      description: (data['description'] as String?)?.trim(),      statusLabel: statusLabel,
      progress: progress,
      isCompleted: isCompleted,
    );
  }

  static String? _readExpectedDeliveryDate(Map<String, dynamic> data) {
    final parsed = DateFormatUtils.fromFirestore(data['expectedDeliveryDate']);
    if (parsed != null) return DateFormatUtils.formatDayMonthYear(parsed);
    return null;
  }
}