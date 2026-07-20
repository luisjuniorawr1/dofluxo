/// Zonas do dashboard reorganizado (wireframe 5 colunas / 7 áreas).
enum DashboardZoneId {
  postagensDoDia,
  jobs,
  incendio,
  producao,
  aprovacao,
  concluidos,
  statusPlanejamento,
}

extension DashboardZoneIdX on DashboardZoneId {
  String get storageKey => name;

  /// Colunas espelho — cópias visuais; o card permanece na zona de workflow.
  bool get isMirrorZone => switch (this) {
        DashboardZoneId.postagensDoDia => true,
        DashboardZoneId.incendio => true,
        _ => false,
      };

  /// Colunas automáticas / somente leitura — preenchidas por regra de negócio.
  bool get isAutoPopulated => isMirrorZone || this == DashboardZoneId.statusPlanejamento;

  /// Fluxo manual: arrastar apenas entre Jobs, Produção, Aprovação e Concluídos.
  bool get acceptsDragDrop => switch (this) {
        DashboardZoneId.jobs ||
        DashboardZoneId.producao ||
        DashboardZoneId.aprovacao ||
        DashboardZoneId.concluidos =>
          true,
        _ => false,
      };
}
