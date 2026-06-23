import '../../../core/agency/models/agency_role.dart';
import '../../../core/agency/models/membership.dart';
import '../../../core/agency/models/membership_status.dart';
import '../../../core/agency/models/user_profile.dart';
import '../../../core/agency/services/membership_service.dart';
import '../../../core/agency/services/user_service.dart';

class TeamMemberNotFoundException implements Exception {
  const TeamMemberNotFoundException();

  @override
  String toString() => 'Nenhuma conta encontrada para este e-mail.';
}

class TeamMemberAlreadyExistsException implements Exception {
  const TeamMemberAlreadyExistsException();

  @override
  String toString() => 'Esta pessoa já faz parte da equipe.';
}

class TeamService {
  TeamService({
    required this.agencyId,
    MembershipService? membershipService,
    UserService? userService,
  })  : _membershipService = membershipService ?? MembershipService(),
        _userService = userService ?? UserService();

  final String agencyId;
  final MembershipService _membershipService;
  final UserService _userService;

  Stream<List<Membership>> watchActiveMembers() {
    return _membershipService.watchActiveForAgency(agencyId);
  }

  Future<UserProfile?> findUserByEmail(String email) {
    return _userService.findByEmail(email);
  }

  Future<void> addMemberByEmail({
    required String email,
    required AgencyRole role,
    required String agencyName,
  }) async {
    if (role == AgencyRole.owner) {
      throw ArgumentError('Não é possível adicionar outro dono por e-mail.');
    }

    final user = await _userService.findByEmail(email);
    if (user == null) throw const TeamMemberNotFoundException();

    final existing = await _membershipService.getForUserInAgency(
      agencyId: agencyId,
      userId: user.id,
    );
    if (existing != null && existing.isActive) {
      throw const TeamMemberAlreadyExistsException();
    }

    final membership = Membership(
      id: Membership.composeId(agencyId: agencyId, userId: user.id),
      agencyId: agencyId,
      userId: user.id,
      role: role,
      status: MembershipStatus.active,
      agencyName: agencyName,
      userEmail: user.email,
      userDisplayName: user.displayName.isNotEmpty ? user.displayName : null,
    );

    await _membershipService.create(membership);
  }

  Future<void> updateMemberRole({
    required String userId,
    required AgencyRole role,
  }) {
    if (role == AgencyRole.owner) {
      throw ArgumentError('Transferência de ownership não está disponível.');
    }
    return _membershipService.updateMemberRole(
      agencyId: agencyId,
      userId: userId,
      role: role,
    );
  }

  Future<void> removeMember(String userId) {
    return _membershipService.deactivateMember(
      agencyId: agencyId,
      userId: userId,
    );
  }
}
