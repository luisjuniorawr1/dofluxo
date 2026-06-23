import '../../../core/agency/models/agency_role.dart';
import '../../../core/agency/models/membership.dart';

/// Ordenação da lista de equipe: Dono → Admin → Membro, depois por data de entrada.
class TeamMemberSorter {
  TeamMemberSorter._();

  static int compare(Membership a, Membership b) {
    final byRole = _roleRank(a.role).compareTo(_roleRank(b.role));
    if (byRole != 0) return byRole;

    final aJoined = a.joinedAt ?? a.createdAt;
    final bJoined = b.joinedAt ?? b.createdAt;
    if (aJoined == null && bJoined == null) return 0;
    if (aJoined == null) return 1;
    if (bJoined == null) return -1;
    return bJoined.compareTo(aJoined);
  }

  static List<Membership> sort(List<Membership> memberships) {
    final sorted = List<Membership>.from(memberships);
    sorted.sort(compare);
    return sorted;
  }

  static int _roleRank(AgencyRole role) {
    return switch (role) {
      AgencyRole.owner => 0,
      AgencyRole.admin => 1,
      AgencyRole.member => 2,
    };
  }
}
