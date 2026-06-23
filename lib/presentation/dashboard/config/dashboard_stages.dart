import 'package:flutter/material.dart';

/// Etapas do fluxo Kanban unificado (Job + Planejamento digital).
enum DashboardStageId {
  incendios,
  planejamento,
  producao,
  aprovacao,
  concluido,
}

class DashboardStage {
  const DashboardStage({
    required this.id,
    required this.title,
    required this.columnBackground,
    required this.cardBackground,
    required this.completedCardBackground,
    this.columnWidth = 200,
    this.isPriority = false,
  });

  final DashboardStageId id;
  final String title;
  final Color columnBackground;
  final Color cardBackground;
  final Color completedCardBackground;
  final double columnWidth;
  final bool isPriority;

  String get storageKey => id.name;

  static const List<DashboardStage> workflow = [
    DashboardStage(
      id: DashboardStageId.incendios,
      title: '🔥 Incêndios',
      columnBackground: Color(0xFFFCE8E8),
      cardBackground: Color(0xFFE74C4C),
      completedCardBackground: Color(0xFFE74C4C),
      columnWidth: 210,
      isPriority: true,
    ),
    DashboardStage(
      id: DashboardStageId.planejamento,
      title: '📋 Planejamento',
      columnBackground: Color(0xFFE8EEF5),
      cardBackground: Color(0xFF94A3B8),
      completedCardBackground: Color(0xFF64748B),
      columnWidth: 200,
    ),
    DashboardStage(
      id: DashboardStageId.producao,
      title: '🏃 Produção',
      columnBackground: Color(0xFFE4E4E4),
      cardBackground: Color(0xFFFB923C),
      completedCardBackground: Color(0xFF4CD97B),
      columnWidth: 200,
    ),
    DashboardStage(
      id: DashboardStageId.aprovacao,
      title: '💬 Aprovação',
      columnBackground: Color(0xFFF3E8FF),
      cardBackground: Color(0xFFC084FC),
      completedCardBackground: Color(0xFF4CD97B),
      columnWidth: 200,
    ),
    DashboardStage(
      id: DashboardStageId.concluido,
      title: '✅ Concluído',
      columnBackground: Color(0xFFE8F5EC),
      cardBackground: Color(0xFF4CD97B),
      completedCardBackground: Color(0xFF2EAF6A),
      columnWidth: 200,
    ),
  ];

  static DashboardStage? find(DashboardStageId id) {
    for (final stage in workflow) {
      if (stage.id == id) return stage;
    }
    return null;
  }

  static DashboardStage? findByKey(String key) {
    for (final stage in workflow) {
      if (stage.storageKey == key) return stage;
    }
    return null;
  }
}
