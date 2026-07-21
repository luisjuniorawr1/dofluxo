import 'package:flutter/material.dart';

import '../utils/theme_utils.dart';
import 'agency_theme_colors.dart';

class AppTheme {
  static const Color success = Color(0xFF2EAF6A);
  static const Color successBright = Color(0xFF4CD97B);

  static ThemeData build({
    required Color primaryColor,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final baseScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
    );

    final onSurface = isDark
        ? const Color(0xFFEAEAEA)
        : const Color(0xFF1A1A1A);
    final onSurfaceVariant = isDark
        ? const Color(0xFFB8B8B8)
        : const Color(0xFF5A5A5A);
    final surface = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final surfaceContainerHighest = isDark
        ? const Color(0xFF383838)
        : const Color(0xFFD8D8D8);

    final onBrand = ThemeUtils.getContrastColor(primaryColor);
    final contentAccent = ThemeUtils.readableAccent(
      accent: primaryColor,
      background: surface,
      fallback: onSurface,
    );
    final contentAccentOnFilled = ThemeUtils.readableAccent(
      accent: primaryColor,
      background: surfaceContainerHighest,
      fallback: onSurfaceVariant,
    );

    final colorScheme = baseScheme.copyWith(
      primary: primaryColor,
      onPrimary: onBrand,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      surfaceContainerLowest: isDark
          ? const Color(0xFF0D0D0D)
          : const Color(0xFFFFFFFF),
      surfaceContainerLow: isDark
          ? const Color(0xFF1C1C1C)
          : const Color(0xFFF3F3F3),
      surfaceContainer: isDark
          ? const Color(0xFF242424)
          : const Color(0xFFEBEBEB),
      surfaceContainerHigh: isDark
          ? const Color(0xFF2C2C2C)
          : const Color(0xFFE4E4E4),
      surfaceContainerHighest: surfaceContainerHighest,
      outline: isDark ? const Color(0xFF8E8E8E) : const Color(0xFF6E6E6E),
      outlineVariant: isDark
          ? const Color(0xFF4A4A4A)
          : const Color(0xFFBDBDBD),
    );

    final agencyColors = AgencyThemeColors(
      brand: primaryColor,
      onBrand: onBrand,
      contentAccent: contentAccent,
      contentAccentOnFilled: contentAccentOnFilled,
    );

    final baseTextTheme = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final textTheme = baseTextTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    final borderRadius = BorderRadius.circular(12);
    final outlineBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: colorScheme.outline),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryColor,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      extensions: [agencyColors],
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsPadding: const EdgeInsets.only(right: 48),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.5 : 0.4,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(
          color: contentAccentOnFilled,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
        border: outlineBorder,
        enabledBorder: outlineBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: contentAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedColor: primaryColor.withValues(alpha: 0.22),
        labelStyle: TextStyle(color: colorScheme.onSurface),
        secondaryLabelStyle: TextStyle(color: colorScheme.onSurface),
        deleteIconColor: colorScheme.onSurfaceVariant,
        side: BorderSide(color: colorScheme.outlineVariant),
        checkmarkColor: onBrand,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? colorScheme.surfaceContainerHighest
            : const Color(0xFF323232),
        contentTextStyle: TextStyle(
          color: isDark ? colorScheme.onSurface : Colors.white,
        ),
        actionTextColor: isDark ? contentAccent : Colors.white,
        behavior: SnackBarBehavior.floating,
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStateProperty.all(onBrand),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return null;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return contentAccent;
          return colorScheme.onSurfaceVariant;
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: onBrand,
          backgroundColor: primaryColor,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: onBrand,
          backgroundColor: primaryColor,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: contentAccent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: successBright,
        linearTrackColor: colorScheme.onSurface.withValues(alpha: 0.12),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
      ),
    );
  }
}
