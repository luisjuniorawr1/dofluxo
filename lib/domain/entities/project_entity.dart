enum ProjectStatus {
  creation,
  capture,
  editing,
  approval,
  approved,
  fire, // Para os incêndios 🔥
}

class ProjectEntity {
  final String id;
  final String clientId;
  final String title;
  final String date;
  final String description;
  final ProjectStatus status;

  ProjectEntity({
    required this.id,
    required this.clientId,
    required this.title,
    required this.date,
    required this.description,
    required this.status,
  });
}