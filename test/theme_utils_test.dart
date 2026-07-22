import 'package:dofluxo/core/utils/theme_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeUtils contrast', () {
    test('yellow on white falls back to neutral', () {
      const yellow = Color(0xFFFFD700);
      const white = Color(0xFFFFFFFF);
      const black = Color(0xFF1A1A1A);

      final result = ThemeUtils.readableAccent(
        accent: yellow,
        background: white,
        fallback: black,
      );

      expect(result, black);
      expect(ThemeUtils.contrastRatio(yellow, white), lessThan(3.0));
    });

    test('yellow on dark background keeps accent', () {
      const yellow = Color(0xFFFFD700);
      const dark = Color(0xFF121212);

      final result = ThemeUtils.readableAccent(
        accent: yellow,
        background: dark,
        fallback: Colors.white,
      );

      expect(result, yellow);
    });

    test('blue on white keeps accent', () {
      const blue = Color(0xFF1565C0);
      const white = Color(0xFFFFFFFF);

      final result = ThemeUtils.readableAccent(
        accent: blue,
        background: white,
        fallback: Colors.black,
      );

      expect(result, blue);
    });

    test('tintedBadgeColors keeps readable contrast on dark surface', () {
      const gold = Color(0xFFC9A227);
      const darkSurface = Color(0xFF1C1C1C);

      final badge = ThemeUtils.tintedBadgeColors(
        accent: gold,
        surface: darkSurface,
        brightness: Brightness.dark,
      );

      expect(
        ThemeUtils.contrastRatio(badge.foreground, badge.background),
        greaterThanOrEqualTo(4.5),
      );
      // Fundo do chip deve se afastar da superfície do card.
      expect(
        ThemeUtils.contrastRatio(badge.background, darkSurface),
        greaterThanOrEqualTo(1.45),
      );
    });

    test('tintedBadgeColors keeps readable contrast on light surface', () {
      const gold = Color(0xFFC9A227);
      const lightSurface = Color(0xFFF3F3F3);

      final badge = ThemeUtils.tintedBadgeColors(
        accent: gold,
        surface: lightSurface,
        brightness: Brightness.light,
      );

      expect(
        ThemeUtils.contrastRatio(badge.foreground, badge.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('filledBadgeColors uses solid accent with contrast text', () {
      const gold = Color(0xFFF5C800);
      final badge = ThemeUtils.filledBadgeColors(gold);

      expect(badge.background, gold);
      expect(
        ThemeUtils.contrastRatio(badge.foreground, badge.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('filledBadgeColors stays visible on dark card (gold + black brand)', () {
      const gold = Color(0xFFFFD700);
      const darkCard = Color(0xFF1C1C1C);
      const blackBrand = Color(0xFF111111);

      final goldBadge = ThemeUtils.filledBadgeColors(
        gold,
        brightness: Brightness.dark,
      );
      expect(
        ThemeUtils.contrastRatio(goldBadge.background, darkCard),
        greaterThan(3.0),
      );
      expect(
        ThemeUtils.contrastRatio(goldBadge.foreground, goldBadge.background),
        greaterThanOrEqualTo(4.5),
      );

      final darkBrandBadge = ThemeUtils.filledBadgeColors(
        blackBrand,
        brightness: Brightness.dark,
      );
      expect(
        ThemeUtils.contrastRatio(darkBrandBadge.background, darkCard),
        greaterThan(1.45),
      );
    });

    test('member/admin solid accents stay visible on dark card', () {
      const darkCard = Color(0xFF1C1C1C);
      const memberAccent = Color(0xFFC2C2C2);
      const adminAccent = Color(0xFFB8C7D6);

      for (final accent in [memberAccent, adminAccent]) {
        final badge = ThemeUtils.filledBadgeColors(
          accent,
          brightness: Brightness.dark,
        );
        expect(
          ThemeUtils.contrastRatio(badge.background, darkCard),
          greaterThan(2.5),
          reason: 'accent $accent must pop from dark card',
        );
        expect(
          ThemeUtils.contrastRatio(badge.foreground, badge.background),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('tintedBadgeColors lifts grey accent off dark card', () {
      const grey = Color(0xFF9E9E9E);
      const darkSurface = Color(0xFF1C1C1C);

      final badge = ThemeUtils.tintedBadgeColors(
        accent: grey,
        surface: darkSurface,
        brightness: Brightness.dark,
      );

      expect(
        ThemeUtils.contrastRatio(badge.background, darkSurface),
        greaterThanOrEqualTo(1.45),
      );
    });
  });
}
