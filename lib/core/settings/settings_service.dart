import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AgencySettings {
  const AgencySettings({
    this.agencyName = '',
    this.primaryColor = const Color(0xFFFFD700),
  });

  final String agencyName;
  final Color primaryColor;

  String get displayName => agencyName.trim().isNotEmpty ? agencyName.trim() : 'Pequi';
}

class SettingsService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<AgencySettings> load(String uid) async {
    final doc = await _db.collection('settings').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return const AgencySettings();
    }

    final data = doc.data()!;
    final colorValue = int.tryParse(data['primaryColor']?.toString() ?? '');
    return AgencySettings(
      agencyName: data['agencyName'] as String? ?? '',
      primaryColor: colorValue != null ? Color(colorValue) : const Color(0xFFFFD700),
    );
  }

  Future<void> save(String uid, AgencySettings settings) async {
    await _db.collection('settings').doc(uid).set({
      'agencyName': settings.agencyName.trim(),
      'primaryColor': settings.primaryColor.toARGB32().toString(),
    });
  }
}
