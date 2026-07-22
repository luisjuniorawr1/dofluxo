import 'package:flutter/material.dart';

/// Entrega/projeto do Kanban exibido no calendário.
class CalendarDeliveryEntry {
  const CalendarDeliveryEntry({
    required this.projectId,
    required this.title,
    required this.deliveryDate,
    this.clientName,
    this.statusLabel,
    this.primaryTitle,
    this.zoneHeaderColor,
    this.accentColor,
  });

  final String projectId;
  final String title;
  final DateTime deliveryDate;
  final String? clientName;
  final String? statusLabel;

  /// Título como no card do Kanban (`cardPrimaryTitle`).
  final String? primaryTitle;

  /// Cor da barra do card (= coluna do Kanban).
  final Color? zoneHeaderColor;
  final Color? accentColor;

  String get cardTitle {
    final primary = primaryTitle?.trim();
    if (primary != null && primary.isNotEmpty) return primary;
    return displayTitle;
  }

  String get displayTitle {
    if (clientName != null && clientName!.isNotEmpty) {
      return '$clientName - $title';
    }
    return title;
  }

  String? get cardSubtitle {
    final parts = <String>[];
    final client = clientName?.trim();
    final status = statusLabel?.trim();
    if (client != null && client.isNotEmpty) parts.add(client);
    if (status != null && status.isNotEmpty) parts.add(status);
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }
}
