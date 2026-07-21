/// Papéis internos de uma agência (Fase 1 — sem partner).
enum AgencyRole {
  owner('owner'),
  admin('admin'),
  member('member');

  const AgencyRole(this.firestoreValue);

  final String firestoreValue;

  static AgencyRole fromFirestore(String? value) {
    return AgencyRole.values.firstWhere(
      (role) => role.firestoreValue == value,
      orElse: () => AgencyRole.member,
    );
  }

  bool get canManageSettings =>
      this == AgencyRole.owner || this == AgencyRole.admin;

  bool get canManageTeam => canManageSettings;

  bool get canDeleteAgency => this == AgencyRole.owner;

  String get label => switch (this) {
    AgencyRole.owner => 'Dono',
    AgencyRole.admin => 'Admin',
    AgencyRole.member => 'Membro',
  };
}
