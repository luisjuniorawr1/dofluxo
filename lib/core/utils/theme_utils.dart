import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/agency_theme_colors.dart';

class ThemeUtils {
  /// Retorna preto ou branco conforme a luminância do fundo (W3C).
  static Color getContrastColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  /// Razão de contraste WCAG entre duas cores (mín. 4.5 texto, 3.0 UI).
  static double contrastRatio(Color foreground, Color background) {
    final l1 = foreground.computeLuminance();
    final l2 = background.computeLuminance();
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Usa a cor de destaque somente se houver contraste legível sobre o fundo.
  static Color readableAccent({
    required Color accent,
    required Color background,
    required Color fallback,
    double minRatio = 3.0,
  }) {
    if (contrastRatio(accent, background) >= minRatio) return accent;
    return fallback;
  }

  /// Cor de texto legível sobre um fundo arbitrário.
  static Color readableOn(Color background) {
    return getContrastColor(background);
  }

  /// Ajusta cores de marca (ex.: preto do TikTok) para ficarem visíveis no tema atual.
  static Color brandColor(BuildContext context, Color brand) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final luminance = brand.computeLuminance();

    if (isDark && luminance < 0.2) return scheme.onSurface;
    if (!isDark && luminance > 0.85) return scheme.onSurface;
    return brand;
  }

  static Color successColor(BuildContext context) {
    return AppTheme.successBright;
  }

  static TextStyle sectionTitle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.titleSmall!.copyWith(
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.onSurface,
    );
  }

  static TextStyle bodyMuted(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );
  }

  /// Fundo + texto de badge tingido pela cor de destaque, com contraste ≥ 4.5.
  static ({Color background, Color foreground}) tintedBadgeColors({
    required Color accent,
    required Color surface,
    required Brightness brightness,
    double minRatio = 4.5,
  }) {
    final background = Color.alphaBlend(
      accent.withValues(alpha: brightness == Brightness.dark ? 0.34 : 0.22),
      surface,
    );
    final foreground = readableAccent(
      accent: accent,
      background: background,
      fallback: getContrastColor(background),
      minRatio: minRatio,
    );
    return (background: background, foreground: foreground);
  }

  /// Destaque de marca seguro para uso em superfícies de conteúdo.
  static Color contentAccent(BuildContext context, {Color? background}) {
    final agency = AgencyThemeColors.of(context);
    if (background == null) return agency.contentAccent;
    return readableAccent(
      accent: agency.brand,
      background: background,
      fallback: Theme.of(context).colorScheme.onSurface,
      minRatio: 4.5,
    );
  }
}
