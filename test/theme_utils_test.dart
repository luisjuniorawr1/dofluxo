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
  });
}
