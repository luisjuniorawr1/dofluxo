import 'package:cloud_firestore/cloud_firestore.dart';

import 'agency_role.dart';
import 'membership_status.dart';

class Membership {
  const Membership({
    required this.id,
    required this.agencyId,
    required this.userId,
    required this.role,
    required this.status,
    required this.agencyName,
    this.userEmail = '',
    this.userDisplayName,
    this.joinedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String agencyId;
  final String userId;
  final AgencyRole role;
  final MembershipStatus status;
  final String agencyName;
  final String userEmail;
  final String? userDisplayName;
  final DateTime? joinedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static String composeId({required String agencyId, required String userId}) {
    return '${agencyId}_$userId';
  }

  String get displayAgencyName =>
      agencyName.trim().isNotEmpty ? agencyName.trim() : 'Agência';

  bool get isActive => status == MembershipStatus.active;

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'agencyId': agencyId,
      'userId': userId,
      'role': role.firestoreValue,
      'status': status.firestoreValue,
      'agencyName': agencyName.trim(),
      'userEmail': userEmail,
      if (userDisplayName != null && userDisplayName!.isNotEmpty)
        'userDisplayName': userDisplayName,
      if (isCreate) ...{
        'joinedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Membership.fromFirestore(String id, Map<String, dynamic> data) {
    return Membership(
      id: id,
      agencyId: data['agencyId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      role: AgencyRole.fromFirestore(data['role'] as String?),
      status: MembershipStatus.fromFirestore(data['status'] as String?),
      agencyName: data['agencyName'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      userDisplayName: data['userDisplayName'] as String?,
      joinedAt: _readTimestamp(data['joinedAt']),
      createdAt: _readTimestamp(data['createdAt']),
      updatedAt: _readTimestamp(data['updatedAt']),
    );
  }

  static DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
