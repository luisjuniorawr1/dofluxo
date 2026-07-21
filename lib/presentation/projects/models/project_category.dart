import 'package:flutter/material.dart';

enum ProjectCategory { job, planejamento }

extension ProjectCategoryX on ProjectCategory {
  String get firestoreValue => name;

  String get label => switch (this) {
    ProjectCategory.job => 'Job',
    ProjectCategory.planejamento => 'Planejamento digital',
  };

  /// Faixa lateral do card no Kanban: roxo = Job, vermelho = Planejamento.
  Color get boardStripeColor => switch (this) {
    ProjectCategory.job => const Color(0xFF9C27B0),
    ProjectCategory.planejamento => const Color(0xFFE74C4C),
  };
}

ProjectCategory projectCategoryFromFirestore(String? value) {
  if (value == ProjectCategory.planejamento.firestoreValue) {
    return ProjectCategory.planejamento;
  }
  return ProjectCategory.job;
}

bool isPlanejamentoProject(Map<String, dynamic> data) {
  return projectCategoryFromFirestore(data['category'] as String?) ==
      ProjectCategory.planejamento;
}
