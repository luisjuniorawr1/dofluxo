import 'package:flutter/material.dart';

/// Status do fluxo de planejamento digital (posts dos clientes).
enum PlanningStatusId { pendente, emProducao, pronto, agendado, publicado }

class PlanningStatus {
  const PlanningStatus({
    required this.id,
    required this.label,
    required this.color,
    required this.order,
  });

  final PlanningStatusId id;
  final String label;
  final Color color;
  final int order;

  String get firestoreValue => id.name;

  static const List<PlanningStatus> all = [
    PlanningStatus(
      id: PlanningStatusId.pendente,
      label: 'Pendente',
      color: Color(0xFF9E9E9E),
      order: 0,
    ),
    PlanningStatus(
      id: PlanningStatusId.emProducao,
      label: 'Em produção',
      color: Color(0xFFFF9800),
      order: 1,
    ),
    PlanningStatus(
      id: PlanningStatusId.pronto,
      label: 'Pronto',
      color: Color(0xFF2196F3),
      order: 2,
    ),
    PlanningStatus(
      id: PlanningStatusId.agendado,
      label: 'Agendado',
      color: Color(0xFF9C27B0),
      order: 3,
    ),
    PlanningStatus(
      id: PlanningStatusId.publicado,
      label: 'Publicado',
      color: Color(0xFF4CAF50),
      order: 4,
    ),
  ];

  static PlanningStatus fromFirestore(String? value) {
    if (value == null || value.isEmpty) return all.first;
    for (final status in all) {
      if (status.firestoreValue == value) return status;
    }
    final normalized = value.toLowerCase().trim();
    return all.firstWhere(
      (s) => s.label.toLowerCase() == normalized,
      orElse: () => all.first,
    );
  }
}

class PlanningFormat {
  PlanningFormat._();

  static const List<String> options = [
    'Feed',
    'Reels',
    'Stories',
    'Carrossel',
    'Vídeo',
    'Outro',
  ];
}
