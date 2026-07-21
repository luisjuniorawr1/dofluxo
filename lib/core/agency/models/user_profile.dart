import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.activeAgencyId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? activeAgencyId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'displayName': displayName.trim(),
      'email': email.trim(),
      if (photoUrl != null && photoUrl!.isNotEmpty) 'photoUrl': photoUrl,
      if (activeAgencyId != null) 'activeAgencyId': activeAgencyId,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserProfile.fromFirestore(String id, Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      activeAgencyId: data['activeAgencyId'] as String?,
      createdAt: _readTimestamp(data['createdAt']),
      updatedAt: _readTimestamp(data['updatedAt']),
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    String? activeAgencyId,
    bool clearActiveAgencyId = false,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      activeAgencyId: clearActiveAgencyId
          ? null
          : (activeAgencyId ?? this.activeAgencyId),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
