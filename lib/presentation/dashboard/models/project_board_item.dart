import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/date_format_utils.dart';
import '../../projects/models/planning_status.dart';
import '../../projects/models/project_category.dart';
import '../../projects/models/project_production_task.dart';
import '../config/dashboard_stages.dart';
import '../utils/dashboard_board_mapper.dart';

/// Item exibido no quadro Kanban do dashboard.
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
    this.isPlanejamento = false,
    this.format,
    this.planningStatusLabel,
    this.accentColor,
    this.order,
    this.hasCanonicalOrder = false,
    this.createdAtMillis,
  });

  final String id;
  final String title;
  final String? clientName;
  final String? expectedDeliveryDate;
  final String? description;
  final String? statusLabel;
  final double? progress;
  final bool isCompleted;
  final bool isPlanejamento;
  final String? format;
  final String? planningStatusLabel;
  final Color? accentColor;

  /// Posição persistida na coluna. `ordem` é canônico; `boardOrder` é lido
  /// apenas durante a migração de documentos antigos.
  final double? order;
  final bool hasCanonicalOrder;
  final int? createdAtMillis;

  bool get hasProgress => progress != null;

  /// Título principal exibido no card — nome do projeto.
  String get cardPrimaryTitle {
    final t = title.trim();
    if (t.isNotEmpty) return t;

    // Legado: projetos antigos sem título explícito.
    final client = clientName?.trim();
    final formatLabel = format?.trim();
    if (client != null &&
        client.isNotEmpty &&
        formatLabel != null &&
        formatLabel.isNotEmpty) {
      return '$client · $formatLabel';
    }
    if (client != null && client.isNotEmpty) return client;
    return 'Sem nome';
  }

  /// Segunda linha: data de entrega · cliente.
  String? get cardSubtitle {
    final parts = <String>[];
    final date = expectedDeliveryDate?.trim();
    final client = clientName?.trim();

    if (date != null && date.isNotEmpty) parts.add(date);
    if (client != null && client.isNotEmpty) parts.add(client);

    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

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
    bool? isPlanejamento,
    String? format,
    String? planningStatusLabel,
    Color? accentColor,
    double? order,
    bool? hasCanonicalOrder,
    int? createdAtMillis,
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
      isPlanejamento: isPlanejamento ?? this.isPlanejamento,
      format: format ?? this.format,
      planningStatusLabel: planningStatusLabel ?? this.planningStatusLabel,
      accentColor: accentColor ?? this.accentColor,
      order: order ?? this.order,
      hasCanonicalOrder: hasCanonicalOrder ?? this.hasCanonicalOrder,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    );
  }

  factory ProjectBoardItem.fromMap(String id, Map<String, dynamic> data) {
    return ProjectBoardItem.fromFirestore(id, data);
  }

  factory ProjectBoardItem.fromFirestore(String id, Map<String, dynamic> data) {
    final isPlanning = isPlanejamentoProject(data);
    final tasks = ProjectProductionTask.listFromFirestore(
      data['productionTasks'],
    );
    final tasksProgress = ProjectProductionTask.progressFromTasks(tasks);

    final progressRaw = data['progress'];
    double? progress = tasksProgress;
    if (progress == null && progressRaw is num) {
      progress = progressRaw.toDouble();
      if (progress > 1) progress = progress / 100;
    }

    final firestoreStatus = data['status'] as String?;
    final stageId = DashboardBoardMapper.stageIdForStatus(
      firestoreStatus,
      data: data,
    );
    final isCompleted =
        data['isCompleted'] == true ||
        DashboardBoardMapper.isCompletedStatus(firestoreStatus) ||
        stageId == DashboardStageId.concluido;

    final planningStatus = PlanningStatus.fromFirestore(
      data['planningStatus'] as String?,
    );

    final orderRaw = data['ordem'];
    final legacyOrderRaw = data['boardOrder'];
    final order = orderRaw is num
        ? orderRaw.toDouble()
        : legacyOrderRaw is num
        ? legacyOrderRaw.toDouble()
        : null;
    final createdAt = data['createdAt'];
    final createdAtMillis = createdAt is Timestamp
        ? createdAt.millisecondsSinceEpoch
        : null;

    final statusLabel =
        (data['statusLabel'] as String?)?.trim() ??
        DashboardBoardMapper.cardStatusLabel(
          firestoreStatus: firestoreStatus,
          stage: stageId,
          isCompleted: isCompleted,
          isPlanejamento: isPlanning,
          planningStatusLabel: planningStatus.label,
        );

    return ProjectBoardItem(
      id: id,
      title: (data['title'] as String?)?.trim() ?? '',
      clientName: (data['clientName'] as String?)?.trim(),
      expectedDeliveryDate: _readExpectedDeliveryDate(data),
      description: (data['description'] as String?)?.trim(),
      statusLabel: statusLabel,
      progress: progress,
      isCompleted: isCompleted,
      isPlanejamento: isPlanning,
      format: (data['format'] as String?)?.trim(),
      planningStatusLabel: isPlanning ? planningStatus.label : null,
      accentColor: isPlanning ? planningStatus.color : null,
      order: order,
      hasCanonicalOrder: orderRaw is num,
      createdAtMillis: createdAtMillis,
    );
  }

  static String? _readExpectedDeliveryDate(Map<String, dynamic> data) {
    final parsed =
        DateFormatUtils.fromFirestore(data['expectedDeliveryDate']) ??
        DateFormatUtils.fromFirestore(data['scheduledDate']);
    if (parsed != null) return DateFormatUtils.formatDayMonthYear(parsed);
    return null;
  }
}
