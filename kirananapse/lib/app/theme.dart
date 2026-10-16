import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kirana-Napse UI/UX Design System
/// A ledger-inspired palette with paper, ink, turmeric, and stock status colors.
class KiranaNapseTheme {
  // ─── Base Surfaces & Backgrounds ───
  static const Color rice = Color(0xFFF5F3E9);
  static const Color riceCard = Color(0xFFFFFEF8);

  // ─── Primary Accents: Turmeric Gold (CTAs & Numbers) ───
  static const Color turmeric = Color(0xFFE6A63D);
  static const Color turmericDark = Color(0xFF8A570E);
  static const Color turmericTint = Color(0xFFFFF0D4);

  // Brand ink; the terracotta names remain as compatibility aliases.
  static const Color ledger = Color(0xFF234D43);
  static const Color ledgerDark = Color(0xFF173A32);
  static const Color ledgerTint = Color(0xFFE4EEE8);
  static const Color terracotta = ledger;
  static const Color terracottaDark = ledgerDark;
  static const Color terracottaTint = ledgerTint;

  // ─── Functional Alert Colors ───
  static const Color chili = Color(0xFFB64236);
  static const Color chiliTint = Color(0xFFF9E6E1);

  static const Color marigold = Color(0xFF9D641C);
  static const Color marigoldTint = Color(0xFFF9ECD5);

  static const Color betel = Color(0xFF54754D);
  static const Color betelTint = Color(0xFFE6EFE1);

  // ─── Typography & Ink: Jute Brown ───
  static const Color jute = Color(0xFF24342E);
  static const Color juteSoft = Color(0xFF55645D);
  static const Color juteMuted = Color(0xFF68766F);

  // ─── Borders & Dividers: Sandstone ───
  static const Color sandstone = Color(0xFFD4DACD);
  static const Color sandstoneSoft = Color(0xFFECF0E7);

  // ─── Backward-compatibility Aliases ───
  static const Color primary = turmeric;
  static const Color primaryDark = turmericDark;
  static const Color accent = terracotta;
  static const Color accentGreen = betel;
  static const Color accentOrange = marigold;
  static const Color accentRed = chili;

  static const Color bisqueBg = rice;
  static const Color bisqueCard = riceCard;
  static const Color bisqueBorder = sandstone;
  static const Color bisqueCardAlt = sandstoneSoft;
  static const Color darkBg = rice;
  static const Color darkCard = riceCard;
  static const Color darkBorder = sandstone;
  static const Color textPrimary = jute;
  static const Color textSecondary = juteSoft;
  static const Color textMuted = juteMuted;
  static const Color goldPrimary = turmeric;
  static const Color goldDark = turmericDark;
  static const Color goldSurface = turmericTint;
  static const Color goldBorder = sandstone;
  static const Color royalBlue = terracotta;
  static const Color royalBlueSurface = terracottaTint;

  // ─── Gradients ───
  static const LinearGradient turmericGradient = LinearGradient(
    colors: [Color(0xFFF3B759), Color(0xFFE8A33D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient terracottaGradient = LinearGradient(
    colors: [Color(0xFF2D5A4E), Color(0xFF173A32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bottomCtaFade = LinearGradient(
    colors: [Colors.transparent, Color(0xDDF5F3E9), Color(0xFFF5F3E9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient primaryGradient = turmericGradient;
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF6C9063), Color(0xFF54754D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Main Theme ───
  static ThemeData get lightTheme {
    final textTheme = TextTheme(
      // Baloo 2 for headings & displays
      displayLarge: GoogleFonts.baloo2(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: jute,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.baloo2(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: jute,
      ),
      headlineLarge: GoogleFonts.baloo2(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: jute,
      ),
      headlineMedium: GoogleFonts.baloo2(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: jute,
      ),
      headlineSmall: GoogleFonts.baloo2(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: jute,
      ),
      titleLarge: GoogleFonts.baloo2(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: jute,
      ),
      titleMedium: GoogleFonts.baloo2(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: jute,
      ),

      // Hind for body & labels
      bodyLarge: GoogleFonts.hind(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: jute,
      ),
      bodyMedium: GoogleFonts.hind(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: juteSoft,
      ),
      bodySmall: GoogleFonts.hind(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: juteMuted,
      ),
      labelLarge: GoogleFonts.hind(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: jute,
      ),
      labelMedium: GoogleFonts.hind(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: juteSoft,
      ),
      labelSmall: GoogleFonts.hind(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: juteMuted,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: rice,
      colorScheme: const ColorScheme.light(
        primary: turmeric,
        onPrimary: Color(0xFF4A2E0A),
        secondary: terracotta,
        onSecondary: Colors.white,
        surface: riceCard,
        onSurface: jute,
        error: chili,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: riceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: sandstone, width: 1.0),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: terracotta,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.baloo2(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFBE9DE)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: turmeric,
          foregroundColor: jute,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.hind(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: jute,
          side: const BorderSide(color: sandstone, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.hind(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: riceCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: sandstone),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: sandstone),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: terracotta, width: 2),
        ),
        hintStyle: GoogleFonts.hind(color: juteMuted, fontSize: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: riceCard,
        selectedItemColor: terracotta,
        unselectedItemColor: juteSoft,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: riceCard,
        indicatorColor: ledgerTint,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.hind(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? ledgerDark
                : juteSoft,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: sandstoneSoft,
        labelStyle: GoogleFonts.hind(
          fontSize: 12,
          color: juteSoft,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide.none,
        ),
      ),
      dividerTheme: const DividerThemeData(color: sandstone, thickness: 1.0),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: jute,
        contentTextStyle: GoogleFonts.hind(
          color: rice,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
