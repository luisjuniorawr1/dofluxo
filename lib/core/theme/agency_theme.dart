import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AgencyTheme {
  final Color primaryColor;
  final String agencyName;

  AgencyTheme({required this.primaryColor, required this.agencyName});

  factory AgencyTheme.pequiDefault() {
    return AgencyTheme(
      primaryColor: const Color(0xFFF5C800),
      agencyName: 'Pequi Agência',
    );
  }

  ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF0F0F0),
      textTheme: GoogleFonts.montserratTextTheme(),
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
    );
  }

  // Constantes de cores do layout
  static const Color surfaceGray = Color(0xFFD8D8D8);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color statusGreen = Color(0xFF4CD97B);
  static const Color statusOrange = Color(0xFFFB923C);
  static const Color statusRed = Color(0xFFE74C4C);
  static const Color statusPurple = Color(0xFFC084FC); // Adicionada
  static const Color statusBlue = Color(0xFF60A5FA);   // Adicionada
}