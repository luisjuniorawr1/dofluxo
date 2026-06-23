import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dofluxo/core/agency/models/agency.dart';
import 'package:dofluxo/core/agency/models/agency_role.dart';
import 'package:dofluxo/core/agency/models/membership.dart';
import 'package:dofluxo/core/agency/models/membership_status.dart';

void main() {
  group('Agency', () {
    test('serializes branding to Firestore', () {
      final agency = Agency(
        id: 'agency-1',
        name: ' Pequi ',
        ownerId: 'user-1',
        primaryColor: const Color(0xFFFFD700),
      );

      final map = agency.toFirestore(isCreate: true);
      expect(map['name'], 'Pequi');
      expect(map['ownerId'], 'user-1');
      expect(map['primaryColor'], const Color(0xFFFFD700).toARGB32().toString());
    });

    test('restores from Firestore document', () {
      final restored = Agency.fromFirestore('agency-1', {
        'name': 'Pequi',
        'ownerId': 'user-1',
        'primaryColor': const Color(0xFFFFD700).toARGB32().toString(),
      });

      expect(restored.displayName, 'Pequi');
      expect(restored.primaryColor, const Color(0xFFFFD700));
    });
  });

  group('Membership', () {
    test('composeId uses agencyId_userId', () {
      expect(
        Membership.composeId(agencyId: 'a1', userId: 'u1'),
        'a1_u1',
      );
    });

    test('serializes role and status', () {
      final membership = Membership(
        id: 'a1_u1',
        agencyId: 'a1',
        userId: 'u1',
        role: AgencyRole.owner,
        status: MembershipStatus.active,
        agencyName: 'Pequi',
      );

      final map = membership.toFirestore(isCreate: true);
      expect(map['role'], 'owner');
      expect(map['status'], 'active');
      expect(map['agencyName'], 'Pequi');
    });
  });

  group('AgencyRole', () {
    test('permissions for Fase 1 roles', () {
      expect(AgencyRole.owner.canManageSettings, isTrue);
      expect(AgencyRole.admin.canManageSettings, isTrue);
      expect(AgencyRole.member.canManageSettings, isFalse);
      expect(AgencyRole.owner.canDeleteAgency, isTrue);
      expect(AgencyRole.admin.canDeleteAgency, isFalse);
      expect(AgencyRole.fromFirestore('admin'), AgencyRole.admin);
    });
  });
}
