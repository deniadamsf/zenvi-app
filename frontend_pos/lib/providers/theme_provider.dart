import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // --- PREMIUM COLOR PALETTE ---
  // Light Mode Colors
  static const Color lightBg = Color(0xFFF8FAFC); // Sangat cerah, kebiruan/abu lembut
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF0D9488); // Teal Mewah
  static const Color lightSecondary = Color(0xFF14B8A6); // Teal Cerah
  static const Color lightAccent = Color(0xFF0F766E); // Teal Gelap
  static const Color lightText = Color(0xFF0F172A); // Slate gelap

  // Dark Mode Colors
  static const Color darkBg = Color(0xFF020617); // Slate Sangat Gelap (Hampir Hitam)
  static const Color darkSurface = Color(0xFF0F172A); // Slate Biasa
  static const Color darkPrimary = Color(0xFF14B8A6); // Teal Terang agar kontras
  static const Color darkSecondary = Color(0xFF2DD4BF); // Teal Lebih Terang
  static const Color darkAccent = Color(0xFF0D9488); // Teal Medium
  static const Color darkText = Color(0xFFF8FAFC); // Putih Abu

  ThemeData get lightTheme => _buildLightTheme();
  ThemeData get darkTheme => _buildDarkTheme();

  ThemeData _buildLightTheme() {
    final baseTextTheme = GoogleFonts.outfitTextTheme();
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.outfit().fontFamily,
      brightness: Brightness.light,
      primaryColor: lightPrimary,
      scaffoldBackgroundColor: lightBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: lightPrimary,
        brightness: Brightness.light,
        primary: lightPrimary,
        secondary: lightSecondary,
        tertiary: lightAccent,
        surface: lightSurface,
        onSurface: lightText,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: lightText, fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.5),
        displayMedium: baseTextTheme.displayMedium?.copyWith(color: lightText, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.4),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: lightText, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.4),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: lightText, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.3),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: lightText, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.2),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: lightText, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.3),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: lightText, fontWeight: FontWeight.w600, fontSize: 15),
        titleSmall: baseTextTheme.titleSmall?.copyWith(color: lightText, fontWeight: FontWeight.w600, fontSize: 14),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: lightText, fontSize: 14),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: lightText, fontSize: 13),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: const Color(0xFF64748B), fontSize: 12),
        labelLarge: baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
        labelMedium: baseTextTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 11),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: lightText,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: lightText,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightText,
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightPrimary, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFF1F5F9), thickness: 1),
    );
  }

  ThemeData _buildDarkTheme() {
    final baseTextTheme = GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.outfit().fontFamily,
      brightness: Brightness.dark,
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkPrimary,
        brightness: Brightness.dark,
        primary: darkPrimary,
        secondary: darkSecondary,
        tertiary: darkAccent,
        surface: darkSurface,
        onSurface: darkText,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: darkText, fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.5),
        displayMedium: baseTextTheme.displayMedium?.copyWith(color: darkText, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.4),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: darkText, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.4),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: darkText, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.3),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: darkText, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.2),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: darkText, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.3),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: darkText, fontWeight: FontWeight.w600, fontSize: 15),
        titleSmall: baseTextTheme.titleSmall?.copyWith(color: darkText, fontWeight: FontWeight.w600, fontSize: 14),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: darkText, fontSize: 14),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: darkText, fontSize: 13),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: const Color(0xFF94A3B8), fontSize: 12),
        labelLarge: baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
        labelMedium: baseTextTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 11),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: darkText,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: darkBg, // Teks gelap untuk tombol terang
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkText,
          side: const BorderSide(color: Color(0xFF334155), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E293B)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E293B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF0F172A), thickness: 1),
    );
  }
}
