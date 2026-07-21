import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Entidade organizacional — branding e metadados da agência.
class Agency {
  const Agency({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.primaryColor,
    this.logoUrl,
    this.createdBy,
    this.activeMemberIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String ownerId;
  final Color primaryColor;
  final String? logoUrl;
  final String? createdBy;
  final List<String> activeMemberIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static const defaultPrimaryColor = Color(0xFFFFD700);

  String get displayName => name.trim().isNotEmpty ? name.trim() : 'Pequi';

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'name': name.trim(),
      'ownerId': ownerId,
      'primaryColor': primaryColor.withValues(alpha: 1).toARGB32().toString(),
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (createdBy != null) 'createdBy': createdBy,
      if (isCreate && activeMemberIds.isNotEmpty)
        'activeMemberIds': activeMemberIds,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Agency.fromFirestore(String id, Map<String, dynamic> data) {
    final colorValue = int.tryParse(data['primaryColor']?.toString() ?? '');
    return Agency(
      id: id,
      name: data['name'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      primaryColor: colorValue != null
          ? Color(colorValue).withValues(alpha: 1)
          : defaultPrimaryColor,
      logoUrl: data['logoUrl'] as String?,
      createdBy: data['createdBy'] as String?,
      activeMemberIds: _readStringList(data['activeMemberIds']),
      createdAt: _readTimestamp(data['createdAt']),
      updatedAt: _readTimestamp(data['updatedAt']),
    );
  }

  Agency copyWith({String? name, Color? primaryColor, String? logoUrl}) {
    return Agency(
      id: id,
      name: name ?? this.name,
      ownerId: ownerId,
      primaryColor: primaryColor ?? this.primaryColor,
      logoUrl: logoUrl ?? this.logoUrl,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
