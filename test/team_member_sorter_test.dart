import 'package:dofluxo/core/agency/models/agency_role.dart';
import 'package:dofluxo/core/agency/models/membership.dart';
import 'package:dofluxo/core/agency/models/membership_status.dart';
import 'package:dofluxo/presentation/team/utils/team_member_sorter.dart';
import 'package:flutter_test/flutter_test.dart';

Membership _member({
  required String id,
  required AgencyRole role,
  DateTime? joinedAt,
}) {
  return Membership(
    id: 'agency_$id',
    agencyId: 'agency',
    userId: id,
    role: role,
    status: MembershipStatus.active,
    agencyName: 'Agência',
    userEmail: '$id@test.com',
    joinedAt: joinedAt,
  );
}

void main() {
  group('TeamMemberSorter', () {
    test('orders owner before admin before member', () {
      final sorted = TeamMemberSorter.sort([
        _member(id: 'm1', role: AgencyRole.member),
        _member(id: 'o1', role: AgencyRole.owner),
        _member(id: 'a1', role: AgencyRole.admin),
      ]);

      expect(sorted.map((m) => m.role).toList(), [
        AgencyRole.owner,
        AgencyRole.admin,
        AgencyRole.member,
      ]);
    });

    test('orders by joinedAt desc within same role', () {
      final sorted = TeamMemberSorter.sort([
        _member(id: 'm1', role: AgencyRole.member, joinedAt: DateTime(2025, 1, 1)),
        _member(id: 'm2', role: AgencyRole.member, joinedAt: DateTime(2025, 6, 1)),
      ]);

      expect(sorted.first.userId, 'm2');
    });
  });
}
