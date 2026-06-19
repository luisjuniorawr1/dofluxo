class ProjectProductionTask {
  const ProjectProductionTask({
    required this.label,
    this.completed = false,
  });

  final String label;
  final bool completed;

  Map<String, dynamic> toMap() => {
        'label': label.trim(),
        'completed': completed,
      };

  factory ProjectProductionTask.fromMap(Map<String, dynamic> data) {
    return ProjectProductionTask(
      label: data['label'] as String? ?? '',
      completed: data['completed'] == true,
    );
  }

  ProjectProductionTask copyWith({String? label, bool? completed}) {
    return ProjectProductionTask(
      label: label ?? this.label,
      completed: completed ?? this.completed,
    );
  }

  static List<ProjectProductionTask> listFromFirestore(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => ProjectProductionTask.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static double? progressFromTasks(List<ProjectProductionTask> tasks) {
    final active = tasks.where((task) => task.label.trim().isNotEmpty).toList();
    if (active.isEmpty) return null;
    final done = active.where((task) => task.completed).length;
    return done / active.length;
  }

  static List<Map<String, dynamic>> serializeList(List<ProjectProductionTask> tasks) {
    return tasks.map((task) => task.toMap()).toList();
  }
}
