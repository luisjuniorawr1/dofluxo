import 'package:flutter/material.dart';

/// Cores da agência com variantes seguras para leitura em cada superfície.
@immutable
class AgencyThemeColors extends ThemeExtension<AgencyThemeColors> {
  const AgencyThemeColors({
    required this.brand,
    required this.onBrand,
    required this.contentAccent,
    required this.contentAccentOnFilled,
  });

  /// Cor principal da marca (sidebar, botões preenchidos).
  final Color brand;

  /// Texto/ícones sobre fundo da marca.
  final Color onBrand;

  /// Destaque em áreas de conteúdo (labels, links, bordas focadas).
  final Color contentAccent;

  /// Destaque sobre campos preenchidos e chips.
  final Color contentAccentOnFilled;

  static AgencyThemeColors of(BuildContext context) {
    return Theme.of(context).extension<AgencyThemeColors>() ??
        const AgencyThemeColors(
          brand: Color(0xFFFFD700),
          onBrand: Colors.black,
          contentAccent: Color(0xFF1A1A1A),
          contentAccentOnFilled: Color(0xFF1A1A1A),
        );
  }

  @override
  AgencyThemeColors copyWith({
    Color? brand,
    Color? onBrand,
    Color? contentAccent,
    Color? contentAccentOnFilled,
  }) {
    return AgencyThemeColors(
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      contentAccent: contentAccent ?? this.contentAccent,
      contentAccentOnFilled: contentAccentOnFilled ?? this.contentAccentOnFilled,
    );
  }

  @override
  AgencyThemeColors lerp(ThemeExtension<AgencyThemeColors>? other, double t) {
    if (other is! AgencyThemeColors) return this;
    return AgencyThemeColors(
      brand: Color.lerp(brand, other.brand, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      contentAccent: Color.lerp(contentAccent, other.contentAccent, t)!,
      contentAccentOnFilled: Color.lerp(contentAccentOnFilled, other.contentAccentOnFilled, t)!,
    );
  }
}
