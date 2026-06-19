/// Breakpoints do layout do dashboard.
abstract final class DashboardLayoutBreakpoints {
  static const double mobileCarousel = 768;
  static const double compactHeader = 720;

  /// Fração da largura da tela ocupada por cada coluna no mobile (~22% da próxima visível).
  static const double mobileColumnViewportFraction = 0.78;

  /// Espaço entre colunas no carrossel mobile.
  static const double mobileColumnSpacing = 10;
}
