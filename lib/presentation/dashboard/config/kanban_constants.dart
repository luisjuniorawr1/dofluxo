import 'package:flutter/material.dart';

import 'dashboard_zones.dart';

/// Configuração visual de uma área do dashboard.
class KanbanColumnConfig {
  const KanbanColumnConfig({
    required this.id,
    required this.title,
    required this.cardColor,
    required this.cardHeaderColor,
    this.acceptsDragDrop = true,
    this.isMirror = false,
    this.stackFlex = 1,
  });

  final String id;
  final String title;
  final Color cardColor;
  final Color cardHeaderColor;
  final bool acceptsDragDrop;
  final bool isMirror;
  final int stackFlex;

  DashboardZoneId get zoneId {
    return DashboardZoneId.values.firstWhere((zone) => zone.name == id);
  }
}

class StackedZoneConfig {
  const StackedZoneConfig(this.column);

  final KanbanColumnConfig column;
}

class DashboardColumnGroup {
  const DashboardColumnGroup({
    required this.zones,
    this.flex = 1,
    this.gapAfter = 0,
  });

  final List<StackedZoneConfig> zones;
  final int flex;
  final double gapAfter;
}

/// Cores, labels e layout do dashboard.
abstract final class KanbanConstants {
  static const double columnBodyRadius = 18;
  static const double headerListGap = 10;
  static const double firstCardTopPadding = 6;
  static const double cardVerticalGap = 4;
  static const double columnSpacing = 14;
  static const double stackedZoneGap = 14;
  static const double sectionGap = 20;
  static const double dropSlotHeight = 4;

  static const int heroColumnFlex = 4;
  static const int narrowColumnFlex = 3;
  static const int stackedTopFlex = 12;
  static const int stackedBottomFlex = 5;

  static const KanbanColumnConfig postagensDoDia = KanbanColumnConfig(
    id: 'postagensDoDia',
    title: 'Postagens do dia',
    cardColor: Color(0xFFF5B942),
    cardHeaderColor: Color(0xFFD99A17),
    acceptsDragDrop: false,
    isMirror: true,
    stackFlex: stackedTopFlex,
  );

  static const KanbanColumnConfig incendio = KanbanColumnConfig(
    id: 'incendio',
    title: 'Incêndio',
    cardColor: Color(0xFFF45B69),
    cardHeaderColor: Color(0xFFD93A4A),
    acceptsDragDrop: false,
    isMirror: true,
    stackFlex: stackedBottomFlex,
  );

  static const KanbanColumnConfig jobs = KanbanColumnConfig(
    id: 'jobs',
    title: 'Jobs',
    cardColor: Color(0xFFE85D9E),
    cardHeaderColor: Color(0xFFC93D82),
  );

  static const KanbanColumnConfig producao = KanbanColumnConfig(
    id: 'producao',
    title: 'Produção',
    cardColor: Color(0xFF8B5CF6),
    cardHeaderColor: Color(0xFF7041D8),
  );

  static const KanbanColumnConfig aprovacao = KanbanColumnConfig(
    id: 'aprovacao',
    title: 'Aprovação',
    cardColor: Color(0xFFF59E0B),
    cardHeaderColor: Color(0xFFD47F00),
    stackFlex: stackedTopFlex,
  );

  static const KanbanColumnConfig concluidos = KanbanColumnConfig(
    id: 'concluidos',
    title: 'Concluídos',
    cardColor: Color(0xFF22C55E),
    cardHeaderColor: Color(0xFF159447),
    stackFlex: stackedBottomFlex,
  );

  static const KanbanColumnConfig statusPlanejamento = KanbanColumnConfig(
    id: 'statusPlanejamento',
    title: 'Status do Planejamento',
    cardColor: Color(0xFF38BDF8),
    cardHeaderColor: Color(0xFF1496D4),
    acceptsDragDrop: false,
  );

  static const List<DashboardColumnGroup> desktopLayout = [
    DashboardColumnGroup(
      flex: heroColumnFlex,
      gapAfter: sectionGap,
      zones: [
        StackedZoneConfig(postagensDoDia),
        StackedZoneConfig(incendio),
      ],
    ),
    DashboardColumnGroup(flex: narrowColumnFlex, zones: [StackedZoneConfig(jobs)]),
    DashboardColumnGroup(flex: narrowColumnFlex, zones: [StackedZoneConfig(producao)]),
    DashboardColumnGroup(
      flex: narrowColumnFlex,
      gapAfter: sectionGap,
      zones: [
        StackedZoneConfig(aprovacao),
        StackedZoneConfig(concluidos),
      ],
    ),
    DashboardColumnGroup(flex: narrowColumnFlex, zones: [StackedZoneConfig(statusPlanejamento)]),
  ];

  static const List<KanbanColumnConfig> mobileZones = [
    postagensDoDia,
    incendio,
    jobs,
    producao,
    aprovacao,
    concluidos,
    statusPlanejamento,
  ];

  static List<KanbanColumnConfig> get allZones => mobileZones;

  static KanbanColumnConfig? findById(String id) {
    for (final column in allZones) {
      if (column.id == id) return column;
    }
    return null;
  }

  static bool canAcceptDragFrom(String fromColumnId) {
    return findById(fromColumnId)?.acceptsDragDrop ?? false;
  }

  static Color columnBodyBackground(KanbanColumnConfig column) => column.cardColor;

  static Color cardColorForZone(String zoneId) {
    return findById(zoneId)?.cardColor ?? const Color(0xFF9E9E9E);
  }

  static Color cardHeaderColorForZone(String zoneId) {
    return findById(zoneId)?.cardHeaderColor ?? const Color(0xFF616161);
  }

  static Color onCardColor(Color background) {
    return background.computeLuminance() > 0.55 ? const Color(0xFF1A1A1A) : Colors.white;
  }

  static Color columnHeaderAccent(KanbanColumnConfig column) {
    return Color.lerp(column.cardHeaderColor, Colors.black, 0.15)!;
  }
}
