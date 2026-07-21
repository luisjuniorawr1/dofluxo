import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'models/agency.dart';
import 'models/agency_invite_code.dart';
import 'models/membership.dart';
import 'models/user_profile.dart';
import 'services/agency_bootstrap_service.dart';
import 'services/agency_service.dart';
import 'services/invite_code_service.dart';
import 'services/membership_service.dart';
import 'services/user_service.dart';

/// Estado global da agência ativa e memberships do usuário logado.
class AgencyContext extends ChangeNotifier {
  AgencyContext({
    UserService? userService,
    AgencyService? agencyService,
    MembershipService? membershipService,
    AgencyBootstrapService? bootstrapService,
    InviteCodeService? inviteCodeService,
    Uuid? uuid,
  }) : _userService = userService ?? UserService(),
       _agencyService = agencyService ?? AgencyService(),
       _membershipService = membershipService ?? MembershipService(),
       _bootstrapService = bootstrapService ?? AgencyBootstrapService(),
       _inviteCodeServiceOverride = inviteCodeService,
       _uuid = uuid ?? const Uuid();

  final UserService _userService;
  final AgencyService _agencyService;
  final MembershipService _membershipService;
  final AgencyBootstrapService _bootstrapService;
  final InviteCodeService? _inviteCodeServiceOverride;
  InviteCodeService? _inviteCodeService;
  final Uuid _uuid;

  bool _isReady = false;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? _profile;
  Agency? _activeAgency;
  Membership? _activeMembership;
  List<Membership> _memberships = [];

  bool _needsOnboarding = false;
  bool _needsAgencySelection = false;
  String? _bootstrapForUid;

  bool get isReady => _isReady;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UserProfile? get profile => _profile;
  Agency? get activeAgency => _activeAgency;
  Membership? get activeMembership => _activeMembership;
  List<Membership> get memberships => List.unmodifiable(_memberships);

  String? get activeAgencyId => _activeAgency?.id;
  String get activeAgencyName => _activeAgency?.displayName ?? 'Pequi';
  Color get activePrimaryColor =>
      _activeAgency?.primaryColor ?? Agency.defaultPrimaryColor;

  /// UID da sessão em bootstrap — null após reset/logout.
  String? get sessionUserId => _bootstrapForUid;

  bool get needsOnboarding => _needsOnboarding;
  bool get needsAgencySelection => _needsAgencySelection;
  bool get hasActiveAgency =>
      _activeAgency != null && _activeMembership?.isActive == true;

  bool get canManageSettings =>
      _activeMembership?.role.canManageSettings ?? false;

  bool get canManageTeam => _activeMembership?.role.canManageTeam ?? false;

  bool get hasMultipleAgencies => _memberships.length > 1;

  /// Bootstrap pós-login: perfil, memberships e seleção de agência.
  Future<void> initialize(User user) async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null || authUser.uid != user.uid) return;

    _bootstrapForUid = user.uid;
    _isLoading = true;
    _isReady = false;
    _errorMessage = null;
    _needsOnboarding = false;
    _needsAgencySelection = false;
    _profile = null;
    _memberships = [];
    _inviteCodeService = null;
    _clearActiveAgencyState();
    notifyListeners();

    try {
      final result = await _bootstrapService.run(user);
      if (!_isSessionFor(user.uid)) return;

      _profile = result.profile.id == user.uid ? result.profile : null;
      _memberships = result.memberships
          .where((membership) => membership.userId == user.uid)
          .toList();

      if (result.outcome == AgencyBootstrapOutcome.needsOnboarding) {
        _clearActiveAgencyState();
        _needsOnboarding = true;
        _isReady = true;
        return;
      }

      await _resolveActiveAgency(user.uid, result.profile.activeAgencyId);
      if (!_isSessionFor(user.uid)) return;
      _isReady = true;
    } catch (e, stack) {
      if (!_isSessionFor(user.uid)) return;
      debugPrint('AgencyContext.initialize error: $e\n$stack');
      if (_isPermissionDenied(e)) {
        _errorMessage =
            'Permissão negada no Firestore durante o bootstrap.\n\n'
            'Republicar firestore.rules no Console (users, agencies, memberships).\n\n'
            'Detalhe: $e';
      } else if (_isFirestoreIndexError(e)) {
        _errorMessage =
            'Índice Firestore pendente.\n\n'
            'Abra o link do erro no Console ou crie o índice memberships '
            '(userId + status, escopo Coleta) e aguarde status Ativado.\n\n'
            'Detalhe: $e';
      } else {
        _errorMessage = 'Erro ao carregar agências: $e';
      }
      _isReady = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Wizard pós-login: cria primeira agência e define como ativa.
  Future<void> createFirstAgency({
    required String name,
    Color? primaryColor,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final agencyId = _uuid.v4();
      final trimmedName = name.trim();
      if (trimmedName.isEmpty) {
        throw ArgumentError('Nome da agência é obrigatório.');
      }

      final color = primaryColor ?? Agency.defaultPrimaryColor;
      final agency = Agency(
        id: agencyId,
        name: trimmedName,
        ownerId: user.uid,
        primaryColor: color,
        createdBy: user.uid,
        activeMemberIds: [user.uid],
      );

      await _agencyService.create(agency);
      final membership = await _membershipService.createOwnerMembership(
        agencyId: agencyId,
        userId: user.uid,
        agencyName: trimmedName,
        userEmail: user.email ?? '',
        userDisplayName: user.displayName,
      );

      _memberships = [membership];
      await _activateAgency(agency, membership, user.uid);
      _needsOnboarding = false;
      _needsAgencySelection = false;
      _isReady = true;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cria agência adicional (owner) e ativa automaticamente.
  Future<void> createAgency({required String name, Color? primaryColor}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }

    final agencyId = _uuid.v4();
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Nome da agência é obrigatório.');
    }

    final color = primaryColor ?? Agency.defaultPrimaryColor;
    final agency = Agency(
      id: agencyId,
      name: trimmedName,
      ownerId: user.uid,
      primaryColor: color,
      createdBy: user.uid,
      activeMemberIds: [user.uid],
    );

    await _agencyService.create(agency);
    final membership = await _membershipService.createOwnerMembership(
      agencyId: agencyId,
      userId: user.uid,
      agencyName: trimmedName,
      userEmail: user.email ?? '',
      userDisplayName: user.displayName,
    );

    _memberships = [..._memberships, membership];
    await _activateAgency(agency, membership, user.uid);
  }

  /// Resgata código de convite e ativa a agência correspondente.
  Future<AgencyInviteCode> redeemInviteCode(String rawCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await inviteCodeService.redeem(
        rawCode: rawCode,
        user: user,
      );
      final agency = await _agencyService.getById(result.invite.agencyId);
      if (agency == null) {
        throw StateError('Agência "${result.invite.agencyId}" não encontrada.');
      }

      _memberships = await _membershipService.listActiveForUser(user.uid);
      await _activateAgency(agency, result.membership, user.uid);
      _needsOnboarding = false;
      _needsAgencySelection = false;
      _isReady = true;
      return result.invite;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  InviteCodeService get inviteCodeService =>
      _inviteCodeServiceOverride ??
      (_inviteCodeService ??= InviteCodeService());

  /// Seleciona agência ativa (persiste em users/{uid}).
  Future<void> selectAgency(String agencyId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final membership = _memberships.firstWhere(
        (item) => item.agencyId == agencyId && item.isActive,
        orElse: () =>
            throw StateError('Membership não encontrada para a agência.'),
      );

      final agency = await _agencyService.getById(agencyId);
      if (agency == null) {
        throw StateError('Agência não encontrada.');
      }

      await _activateAgency(agency, membership, user.uid);
      _needsAgencySelection = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Atualiza branding da agência ativa (owner/admin).
  Future<void> updateActiveAgencyBranding({
    required String name,
    required Color primaryColor,
    String? logoUrl,
  }) async {
    final agencyId = activeAgencyId;
    if (agencyId == null || !canManageSettings) {
      throw StateError('Sem permissão para editar configurações da agência.');
    }

    await _agencyService.updateBranding(
      agencyId: agencyId,
      name: name,
      primaryColor: primaryColor,
      logoUrl: logoUrl,
    );
    await _membershipService.updateAgencyNameDenorm(
      agencyId: agencyId,
      agencyName: name,
      userId: FirebaseAuth.instance.currentUser!.uid,
    );

    _activeAgency = _activeAgency!.copyWith(
      name: name,
      primaryColor: primaryColor,
      logoUrl: logoUrl,
    );

    _memberships = _memberships.map((membership) {
      if (membership.agencyId != agencyId) return membership;
      return Membership(
        id: membership.id,
        agencyId: membership.agencyId,
        userId: membership.userId,
        role: membership.role,
        status: membership.status,
        agencyName: name.trim(),
        userEmail: membership.userEmail,
        userDisplayName: membership.userDisplayName,
        joinedAt: membership.joinedAt,
        createdAt: membership.createdAt,
        updatedAt: membership.updatedAt,
      );
    }).toList();

    notifyListeners();
  }

  void reset() {
    _bootstrapForUid = null;
    _isReady = false;
    _isLoading = false;
    _errorMessage = null;
    _profile = null;
    _memberships = [];
    _needsOnboarding = false;
    _needsAgencySelection = false;
    _inviteCodeService = null;
    _clearActiveAgencyState();
    notifyListeners();
  }

  bool _isSessionFor(String userId) {
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    return _bootstrapForUid == userId && authUid == userId;
  }

  static bool _isPermissionDenied(Object error) {
    if (error is FirebaseException) {
      return error.code == 'permission-denied';
    }
    return error.toString().contains('permission-denied');
  }

  static bool _isFirestoreIndexError(Object error) {
    if (_isFirestoreTerminated(error)) return false;
    if (error is FirebaseException) {
      return error.code == 'failed-precondition';
    }
    final message = error.toString();
    return message.contains('failed-precondition') && message.contains('index');
  }

  static bool _isFirestoreTerminated(Object error) {
    final message = error is FirebaseException
        ? '${error.code} ${error.message ?? ''}'
        : error.toString();
    return message.contains('already been terminated');
  }

  Future<void> _resolveActiveAgency(
    String userId,
    String? savedAgencyId,
  ) async {
    if (_memberships.isEmpty) {
      _clearActiveAgencyState();
      _needsOnboarding = true;
      return;
    }

    if (_memberships.length == 1) {
      final membership = _memberships.first;
      final agency = await _agencyService.getById(
        membership.agencyId,
        preferServer: true,
      );
      if (agency == null) {
        throw StateError('Agência "${membership.agencyId}" não encontrada.');
      }
      await _activateAgency(agency, membership, userId);
      _needsAgencySelection = false;
      return;
    }

    final savedIsValid =
        savedAgencyId != null &&
        _memberships.any((m) => m.agencyId == savedAgencyId && m.isActive);

    if (savedIsValid) {
      final membership = _memberships.firstWhere(
        (m) => m.agencyId == savedAgencyId,
      );
      final agency = await _agencyService.getById(
        savedAgencyId,
        preferServer: true,
      );
      if (agency != null) {
        await _activateAgency(agency, membership, userId);
        _needsAgencySelection = false;
        return;
      }
    }

    _clearActiveAgencyState();
    _needsAgencySelection = true;
  }

  Future<void> _activateAgency(
    Agency agency,
    Membership membership,
    String userId,
  ) async {
    final resolvedMembership = await _ensureOwnerMembershipDoc(
      agency: agency,
      userId: userId,
      membership: membership,
    );

    _activeAgency = agency;
    _activeMembership = resolvedMembership;
    await _userService.setActiveAgencyId(userId, agency.id);
    _profile = _profile?.copyWith(activeAgencyId: agency.id);
  }

  /// Garante doc memberships/{agencyId}_{userId} quando o owner acessa a agência.
  Future<Membership> _ensureOwnerMembershipDoc({
    required Agency agency,
    required String userId,
    required Membership membership,
  }) async {
    if (agency.ownerId != userId) return membership;

    final expectedId = Membership.composeId(
      agencyId: agency.id,
      userId: userId,
    );
    final existing = await _membershipService.getForUserInAgency(
      agencyId: agency.id,
      userId: userId,
    );
    if (existing != null && existing.isActive) {
      if (membership.id != expectedId) {
        _memberships = _memberships
            .map((item) => item.id == membership.id ? existing : item)
            .toList();
      }
      return existing;
    }

    final user = FirebaseAuth.instance.currentUser;
    final created = await _membershipService.createOwnerMembership(
      agencyId: agency.id,
      userId: userId,
      agencyName: agency.displayName,
      userEmail: user?.email ?? membership.userEmail,
      userDisplayName: user?.displayName ?? membership.userDisplayName,
    );

    _memberships = [
      for (final item in _memberships)
        if (item.id != membership.id) item,
      created,
    ];
    return created;
  }

  void _clearActiveAgencyState() {
    _activeAgency = null;
    _activeMembership = null;
  }
}
