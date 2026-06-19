import 'package:flutter/material.dart';

/// Etapas do fluxo operacional exibidas no dashboard (referência visual Pequi).
enum DashboardStageId {
  postagensDoDia,
  criacao,
  incendios,
  captacao,
  edicao,
  aprovacao,
}

class DashboardStage {
  const DashboardStage({
    required this.id,
    required this.title,
    required this.columnBackground,
    required this.cardBackground,
    required this.completedCardBackground,
    this.columnWidth = 200,
    this.compactGrid = false,
  });

  final DashboardStageId id;
  final String title;
  final Color columnBackground;
  final Color cardBackground;
  final Color completedCardBackground;
  final double columnWidth;
  final bool compactGrid;

  String get storageKey => id.name;

  static const List<DashboardStage> workflow = [
    DashboardStage(
      id: DashboardStageId.postagensDoDia,
      title: 'Postagens do dia',
      columnBackground: Color(0xFFF0D4D4),
      cardBackground: Color(0xFFE74C4C),
      completedCardBackground: Color(0xFF4CD97B),
      columnWidth: 210,
    ),
    DashboardStage(
      id: DashboardStageId.criacao,
      title: 'Criação',
      columnBackground: Color(0xFFE4E4E4),
      cardBackground: Color(0xFFD8D8D8),
      completedCardBackground: Color(0xFF4CD97B),
      columnWidth: 190,
    ),
    DashboardStage(
      id: DashboardStageId.incendios,
      title: 'INCÊNDIOS',
      columnBackground: Color(0xFFE4E4E4),
      cardBackground: Color(0xFFE74C4C),
      completedCardBackground: Color(0xFFE74C4C),
      columnWidth: 190,
      compactGrid: true,
    ),
    DashboardStage(
      id: DashboardStageId.captacao,
      title: 'Captação',
      columnBackground: Color(0xFFE4E4E4),
      cardBackground: Color(0xFFD8D8D8),
      completedCardBackground: Color(0xFF4CD97B),
      columnWidth: 190,
    ),
    DashboardStage(
      id: DashboardStageId.edicao,
      title: 'Edição',
      columnBackground: Color(0xFFE4E4E4),
      cardBackground: Color(0xFFFB923C),
      completedCardBackground: Color(0xFF4CD97B),
      columnWidth: 190,
    ),
    DashboardStage(
      id: DashboardStageId.aprovacao,
      title: 'Aprovação',
      columnBackground: Color(0xFFE4E4E4),
      cardBackground: Color(0xFFC084FC),
      completedCardBackground: Color(0xFF4CD97B),
      columnWidth: 190,
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
