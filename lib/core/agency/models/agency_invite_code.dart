import 'package:cloud_firestore/cloud_firestore.dart';

import 'agency_role.dart';
import 'invite_code_status.dart';

class AgencyInviteCode {
  const AgencyInviteCode({
    required this.code,
    required this.agencyId,
    required this.agencyName,
    required this.role,
    required this.status,
    required this.createdBy,
    this.createdAt,
    this.expiresAt,
    this.usedBy,
    this.usedAt,
  });

  final String code;
  final String agencyId;
  final String agencyName;
  final AgencyRole role;
  final InviteCodeStatus status;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final String? usedBy;
  final DateTime? usedAt;

  bool get isActive => status == InviteCodeStatus.active;

  bool isExpiredAt(DateTime now) {
    final expires = expiresAt;
    if (expires == null) return false;
    return !now.isBefore(expires);
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'code': code,
      'agencyId': agencyId,
      'agencyName': agencyName.trim(),
      'role': role.firestoreValue,
      'status': status.firestoreValue,
      'createdBy': createdBy,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      if (usedBy != null) 'usedBy': usedBy,
      if (usedAt != null) 'usedAt': Timestamp.fromDate(usedAt!),
    };
  }

  factory AgencyInviteCode.fromFirestore(String id, Map<String, dynamic> data) {
    return AgencyInviteCode(
      code: id,
      agencyId: data['agencyId'] as String? ?? '',
      agencyName: data['agencyName'] as String? ?? '',
      role: AgencyRole.fromFirestore(data['role'] as String?),
      status: InviteCodeStatus.fromFirestore(data['status'] as String?),
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: _readTimestamp(data['createdAt']),
      expiresAt: _readTimestamp(data['expiresAt']),
      usedBy: data['usedBy'] as String?,
      usedAt: _readTimestamp(data['usedAt']),
    );
  }

  static DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
