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

    // Texto principal e secundário com contraste forte nos dois temas.
    final onSurface = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF121212);
    // Secundário: legível em cards (não “cinza fantasma”).
    final onSurfaceVariant = isDark ? const Color(0xFFE2E2E2) : const Color(0xFF3A3A3A);
    final surface = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final surfaceContainerHighest =
        isDark ? const Color(0xFF454545) : const Color(0xFFD0D0D0);

    final onBrand = ThemeUtils.getContrastColor(primaryColor);
    final contentAccent = ThemeUtils.readableAccent(
      accent: primaryColor,
      background: surface,
      fallback: onSurface,
      minRatio: 4.5,
    );
    final contentAccentOnFilled = ThemeUtils.readableAccent(
      accent: primaryColor,
      background: surfaceContainerHighest,
      fallback: onSurfaceVariant,
      minRatio: 4.5,
    );

    // Containers de marca bem visíveis em qualquer página (chips, avatares, tags).
    final primaryContainerBase = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final primaryContainer = Color.lerp(
      primaryContainerBase,
      primaryColor,
      isDark ? 0.72 : 0.75,
    )!;
    final onPrimaryContainer = ThemeUtils.getContrastColor(primaryContainer);

    final secondary = isDark ? const Color(0xFFB8C7D6) : const Color(0xFF2A3A4A);
    final secondaryContainer =
        isDark ? const Color(0xFF455A6E) : const Color(0xFFC9D7E6);
    final onSecondaryContainer =
        isDark ? const Color(0xFFF0F6FC) : const Color(0xFF102033);

    final tertiaryContainer =
        isDark ? const Color(0xFF3A342C) : const Color(0xFFEDE4D6);
    final onTertiaryContainer =
        isDark ? const Color(0xFFF3EADF) : const Color(0xFF2A2216);

    final colorScheme = baseScheme.copyWith(
      primary: primaryColor,
      onPrimary: onBrand,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: ThemeUtils.getContrastColor(secondary),
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      surfaceContainerLowest: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFFFFFF),
      surfaceContainerLow: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF3F3F3),
      surfaceContainer: isDark ? const Color(0xFF242424) : const Color(0xFFEBEBEB),
      surfaceContainerHigh: isDark ? const Color(0xFF303030) : const Color(0xFFE0E0E0),
      surfaceContainerHighest: surfaceContainerHighest,
      outline: isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5F5F5F),
      outlineVariant: isDark ? const Color(0xFF555555) : const Color(0xFFB0B0B0),
      // SnackBar / banner de update usam inverse* — seed pode gerar preto-no-preto.
      inverseSurface: isDark ? const Color(0xFFE8E8E8) : const Color(0xFF2C2C2C),
      onInverseSurface: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
    );

    final agencyColors = AgencyThemeColors(
      brand: primaryColor,
      onBrand: onBrand,
      contentAccent: contentAccent,
      contentAccentOnFilled: contentAccentOnFilled,
    );

    final baseTextTheme = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final textTheme = baseTextTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ).copyWith(
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
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
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      primaryIconTheme: IconThemeData(color: colorScheme.onSurface),
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
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Opaco: alpha no fill lava labels/hints nos dois temas.
        fillColor: colorScheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: contentAccentOnFilled,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
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
        // Fundo opaco + borda: chips Material legíveis em qualquer página.
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: primaryColor,
        // ChoiceChip usa secondary* no estado selecionado.
        secondarySelectedColor: primaryColor,
        disabledColor: colorScheme.surfaceContainer,
        labelStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: TextStyle(
          color: onBrand,
          fontWeight: FontWeight.w700,
        ),
        deleteIconColor: colorScheme.onSurfaceVariant,
        side: BorderSide(color: colorScheme.outline),
        checkmarkColor: onBrand,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return onBrand;
            return colorScheme.onSurface;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return primaryColor;
            return colorScheme.surfaceContainerHigh;
          }),
          side: WidgetStateProperty.all(BorderSide(color: colorScheme.outline)),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
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
        // Fundo sempre escuro o bastante + texto branco (vale em error SnackBars também).
        backgroundColor: const Color(0xFF2C2C2C),
        contentTextStyle: const TextStyle(
          color: Color(0xFFF5F5F5),
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: contentAccent,
        behavior: SnackBarBehavior.floating,
      ),
      checkboxTheme: CheckboxThemeData(
        // Unselected: borda branca/preta explícita (não depende de outline fraco).
        // Selected: fill da marca + ✓ com contraste (onBrand).
        checkColor: WidgetStateProperty.all(onBrand),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          // Fill leve pra a caixa existir como bloco, não só linha.
          return isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFFFFF);
        }),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BorderSide(width: 2.5, color: primaryColor);
          }
          return BorderSide(
            width: 2.5,
            color: isDark ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          );
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return contentAccent;
          return isDark ? const Color(0xFFF5F5F5) : const Color(0xFF121212);
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return onBrand;
          return isDark ? const Color(0xFFF5F5F5) : const Color(0xFF121212);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return isDark ? const Color(0xFFF5F5F5) : const Color(0xFF121212);
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
        linearTrackColor: colorScheme.onSurface.withValues(alpha: 0.16),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerLow,
        textStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      ),
    );
  }
}
