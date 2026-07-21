import 'package:firebase_auth/firebase_auth.dart';

import '../models/membership.dart';

import '../models/user_profile.dart';

import 'membership_service.dart';

import 'user_service.dart';

/// Resultado do bootstrap pós-login.

enum AgencyBootstrapOutcome { ready, needsOnboarding }

class AgencyBootstrapResult {
  const AgencyBootstrapResult({
    required this.outcome,

    required this.profile,

    required this.memberships,
  });

  final AgencyBootstrapOutcome outcome;

  final UserProfile profile;

  final List<Membership> memberships;
}

/// Inicialização de usuário e detecção de onboarding.

class AgencyBootstrapService {
  AgencyBootstrapService({
    UserService? userService,

    MembershipService? membershipService,
  }) : _userService = userService ?? UserService(),

       _membershipService = membershipService ?? MembershipService();

  final UserService _userService;

  final MembershipService _membershipService;

  Future<AgencyBootstrapResult> run(User user) async {
    final profile = await _runStep(
      'users/${user.uid}',

      () => _userService.upsertFromAuth(user, preferServer: true),
    );

    final memberships = await _runStep(
      'memberships (listActiveForUser)',
      () => _membershipService.listActiveForUser(user.uid, preferServer: true),
    );

    if (memberships.isEmpty) {
      return AgencyBootstrapResult(
        outcome: AgencyBootstrapOutcome.needsOnboarding,

        profile: profile,

        memberships: const [],
      );
    }

    return AgencyBootstrapResult(
      outcome: AgencyBootstrapOutcome.ready,

      profile: profile,

      memberships: memberships,
    );
  }

  Future<T> _runStep<T>(String step, Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw StateError('Bootstrap falhou em "$step": $e');
    }
  }
}
