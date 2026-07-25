import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system CodePath — diambil dari desain Adobe XD asli
/// (dark teal + gold/mustard + maroon, card rounded besar).
class AppColors {
  AppColors._();

  static const Color primaryTeal = Color(0xFF0D3B36);
  static const Color gold = Color(0xFFC9A227);
  static const Color maroon = Color(0xFFA02020);
  static const Color background = Color(0xFFF5F3EF);
  static const Color cardBackground = Color(0xFFF0F0EE);
  static const Color inputBackground = Color(0xFFE0E0E0);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMuted = Color(0xFF6B6B6B);
  static const Color success = Color(0xFF1E7A46);
}

class AppRadius {
  AppRadius._();
  static const double card = 24;
  static const double pill = 999;
}

ThemeData buildAppTheme() {
  final base = ThemeData.light();
  final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
    headlineMedium: GoogleFonts.poppins(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    titleLarge: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.textDark,
    ),
    titleMedium: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textDark,
    ),
    bodyMedium: GoogleFonts.nunito(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textDark,
    ),
    bodySmall: GoogleFonts.nunito(
      fontSize: 12,
      color: AppColors.textMuted,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primaryTeal,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primaryTeal,
      secondary: AppColors.gold,
      error: AppColors.maroon,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryTeal,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
