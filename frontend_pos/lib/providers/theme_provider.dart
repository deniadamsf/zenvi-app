import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _prefsKey = 'is_dark_mode';

  ThemeProvider() {
    _restore();
  }

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Pilihan tema disimpan supaya bertahan antar sesi. Sebelumnya nilainya
  /// selalu dimulai dari terang, jadi pengguna yang memilih mode gelap
  /// menemukannya kembali menyala setiap kali membuka aplikasi.
  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_prefsKey);
    if (saved != null && saved != _isDarkMode) {
      _isDarkMode = saved;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, _isDarkMode);
  }

  // Alias lama supaya kode yang sudah memakai nama ini tetap jalan. Warna
  // sesungguhnya tinggal di AppColors.
  static const Color lightBg = AppColors.lightBg;
  static const Color lightSurface = AppColors.lightSurface;
  static const Color lightPrimary = AppColors.brandDeep;
  static const Color lightSecondary = AppColors.brand;
  static const Color lightAccent = AppColors.brandDarkest;
  static const Color lightText = AppColors.textStrong;

  static const Color darkBg = AppColors.darkBg;
  static const Color darkSurface = AppColors.darkSurface;
  static const Color darkPrimary = AppColors.brandBright;
  static const Color darkSecondary = AppColors.brandGlow;
  static const Color darkAccent = AppColors.brand;
  static const Color darkText = AppColors.darkTextStrong;

  // Skema warna diangkat jadi konstanta supaya ThemeData dan tema sakelar
  // membaca nilai yang sama persis - kalau dibangun dua kali, keduanya bisa
  // berbeda diam-diam saat salah satu diubah.
  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: AppColors.brandDeep,
    brightness: Brightness.light,
    primary: AppColors.brandDeep,
    onPrimary: Colors.white,
    secondary: AppColors.brand,
    tertiary: AppColors.brandBright,
    error: AppColors.dangerText,
    onError: Colors.white,
    surface: AppColors.lightSurface,
    onSurface: AppColors.textStrong,
    onSurfaceVariant: AppColors.textMuted,
    surfaceContainerLowest: AppColors.lightSurface,
    surfaceContainerLow: AppColors.lightSurfaceAlt,
    surfaceContainer: AppColors.lightSurfaceAlt,
    surfaceContainerHigh: AppColors.lightSurfaceSunken,
    surfaceContainerHighest: AppColors.lightSurfaceSunken,
    outline: AppColors.lightBorder,
    outlineVariant: AppColors.lightDivider,
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: AppColors.brandBright,
    brightness: Brightness.dark,
    primary: AppColors.brandBright,
    onPrimary: AppColors.darkBg,
    secondary: AppColors.brandGlow,
    tertiary: AppColors.brand,
    error: AppColors.dangerFill,
    onError: AppColors.darkBg,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextStrong,
    onSurfaceVariant: AppColors.darkTextMuted,
    surfaceContainerLowest: AppColors.darkBg,
    surfaceContainerLow: AppColors.darkSurface,
    surfaceContainer: AppColors.darkSurfaceAlt,
    surfaceContainerHigh: AppColors.darkSurfaceAlt,
    surfaceContainerHighest: AppColors.darkSurfaceAlt,
    outline: AppColors.darkBorder,
    outlineVariant: AppColors.darkDivider,
  );

  /// Tema sakelar yang dipakai kedua mode.
  static SwitchThemeData _switchTheme(ColorScheme scheme) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        if (states.contains(WidgetState.selected)) return scheme.onPrimary;
        return scheme.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.selected)) return scheme.primary;
        return scheme.surfaceContainerHighest;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.transparent;
        return scheme.onSurfaceVariant.withValues(alpha: 0.55);
      }),
      trackOutlineWidth: const WidgetStatePropertyAll<double>(1.5),
    );
  }

  ThemeData get lightTheme => _buildLightTheme();
  ThemeData get darkTheme => _buildDarkTheme();

  ThemeData _buildLightTheme() {
    final baseTextTheme = GoogleFonts.outfitTextTheme();
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.outfit().fontFamily,
      brightness: Brightness.light,
      primaryColor: AppColors.brandDeep,
      scaffoldBackgroundColor: AppColors.lightBg,
      // Permukaan dan pembatas ditetapkan eksplisit, bukan diturunkan dari seed:
      // turunan otomatis menghasilkan abu bersemu teal yang bertabrakan dengan
      // keluarga slate yang dipakai teks di seluruh aplikasi.
      colorScheme: _lightScheme,
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: AppColors.textStrong, fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.5),
        displayMedium: baseTextTheme.displayMedium?.copyWith(color: AppColors.textStrong, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.4),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: AppColors.textStrong, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.4),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: AppColors.textStrong, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.3),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: AppColors.textStrong, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.2),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: AppColors.textStrong, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.3),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: AppColors.textStrong, fontWeight: FontWeight.w600, fontSize: 15),
        titleSmall: baseTextTheme.titleSmall?.copyWith(color: AppColors.textStrong, fontWeight: FontWeight.w600, fontSize: 14),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: AppColors.textStrong, fontSize: 14),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: AppColors.textStrong, fontSize: 13),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: AppColors.textMuted, fontSize: 12),
        labelLarge: baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
        labelMedium: baseTextTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 11),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textStrong,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textStrong,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandDeep,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textStrong,
          side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Isian medan sengaja lebih pekat daripada kartu putih supaya kotak
        // isian tetap terbaca sebagai kotak isian saat berada di dalam kartu.
        fillColor: AppColors.lightSurfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.brandDeep, width: 2),
        ),
      ),
      // Sakelar sebelumnya hanya menyetel `activeThumbColor` di tiap pemanggilan.
      // Itu membuat Flutter kembali ke perilaku lama: jalur menjadi versi pucat
      // dari warna bulatan, sehingga bulatan dan jalur nyaris senada dan
      // keadaan nyala tidak terbaca sekilas. Keadaan mati lebih parah - tanpa
      // garis tepi, bulatannya hampir tidak terlihat di atas jalurnya.
      //
      // Kontras sekarang ditaruh pada JALUR: nyala = jalur terisi penuh warna
      // merek dengan bulatan terang; mati = jalur abu bergaris tepi dengan
      // bulatan gelap.
      switchTheme: _switchTheme(_lightScheme),
      dividerTheme: const DividerThemeData(color: AppColors.lightDivider, thickness: 1),
    );
  }

  ThemeData _buildDarkTheme() {
    final baseTextTheme = GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.outfit().fontFamily,
      brightness: Brightness.dark,
      primaryColor: AppColors.brandBright,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: _darkScheme,
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: AppColors.darkTextStrong, fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.5),
        displayMedium: baseTextTheme.displayMedium?.copyWith(color: AppColors.darkTextStrong, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.4),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: AppColors.darkTextStrong, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.4),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: AppColors.darkTextStrong, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.3),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: AppColors.darkTextStrong, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.2),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: AppColors.darkTextStrong, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.3),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: AppColors.darkTextStrong, fontWeight: FontWeight.w600, fontSize: 15),
        titleSmall: baseTextTheme.titleSmall?.copyWith(color: AppColors.darkTextStrong, fontWeight: FontWeight.w600, fontSize: 14),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: AppColors.darkTextStrong, fontSize: 14),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: AppColors.darkTextStrong, fontSize: 13),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: AppColors.darkTextMuted, fontSize: 12),
        labelLarge: baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
        labelMedium: baseTextTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 11),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.darkTextStrong,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.darkTextStrong,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandBright,
          foregroundColor: AppColors.darkBg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTextStrong,
          side: const BorderSide(color: AppColors.darkBorderStrong, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.brandBright, width: 2),
        ),
      ),
      // Sebelumnya bernilai #0F172A - sama persis dengan warna kartu, sehingga
      // tidak ada satu pun divider yang terlihat di mode gelap.
      switchTheme: _switchTheme(_darkScheme),
      dividerTheme: const DividerThemeData(color: AppColors.darkDivider, thickness: 1),
    );
  }
}
