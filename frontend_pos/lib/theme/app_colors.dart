import 'package:flutter/material.dart';

/// Sumber kebenaran tunggal untuk warna Zenvi.
///
/// Sebelum file ini ada, warna tersebar sebagai 141 literal heksadesimal dan
/// ~800 pemakaian `Colors.*` di 89 berkas, sehingga aplikasi memakai tiga hijau,
/// lima merah, dan empat oranye yang berbeda sekaligus. Semua warna baru wajib
/// lewat sini.
///
/// Aturan pasangan Fill/Text
/// -------------------------
/// Warna semantik disediakan berpasangan karena satu nilai tidak bisa melayani
/// dua peran: nilai setingkat -500 cukup pekat sebagai LATAR tapi hanya
/// mencapai 2,5-3,7:1 saat dipakai sebagai TEKS di atas putih - di bawah ambang
/// WCAG AA (4,5:1). Varian `*Text` adalah setingkat -700 yang sudah diverifikasi
/// >= 4,5:1 di atas [lightSurface].
///
///   * `xxxFill` -> latar, isi ikon besar, batang grafik, titik indikator
///   * `xxxText` -> teks, ikon kecil, label angka
abstract final class AppColors {
  // --- Merek ---------------------------------------------------------------
  // [brand] dan [brandBright] hanya untuk permukaan besar dan gradien, tempat
  // teks di atasnya berukuran besar. Untuk isian tombol dan teks berwarna merek
  // di atas putih pakai [brandDeep] (5,48:1) - [brand] hanya 3,75:1 dan
  // membuat label tombol utama gagal AA.
  static const Color brand = Color(0xFF0D9488); // teal-600
  static const Color brandDeep = Color(0xFF0F766E); // teal-700
  static const Color brandBright = Color(0xFF14B8A6); // teal-500
  static const Color brandGlow = Color(0xFF2DD4BF); // teal-400, khusus mode gelap
  static const Color brandDarkest = Color(0xFF134E4A); // teal-900, ujung gradien

  // --- Permukaan terang ----------------------------------------------------
  // [lightBg] sengaja lebih pekat daripada slate-50 yang dipakai sebelumnya:
  // #F8FAFC hanya berbeda 1,05:1 dari kartu putih, jadi kartunya tidak terbaca
  // sebagai kartu dan seluruh layar terasa satu bidang putih. Nilai sekarang
  // memberi 1,17:1 - cukup untuk memisahkan bidang, masih cukup terang untuk
  // tetap terasa lapang.
  static const Color lightBg = Color(0xFFE9EEF4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF1F5F9); // petak di dalam kartu
  static const Color lightSurfaceSunken = Color(0xFFE2E8F0); // petak di dalam petak
  static const Color lightBorder = Color(0xFFDCE3EC);
  static const Color lightDivider = Color(0xFFE2E8F0);

  // --- Permukaan gelap -----------------------------------------------------
  static const Color darkBg = Color(0xFF020617);
  static const Color darkSurface = Color(0xFF0F172A);
  static const Color darkSurfaceAlt = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF1E293B);
  // Batas yang perlu lebih tegas dari kartu, mis. tombol bergaris.
  static const Color darkBorderStrong = Color(0xFF334155);
  // Sebelumnya divider mode gelap bernilai sama persis dengan warna kartu
  // (#0F172A), jadi setiap garis pemisah di dalam kartu tidak pernah terlihat.
  static const Color darkDivider = Color(0xFF243044);

  // --- Teks ----------------------------------------------------------------
  static const Color textStrong = Color(0xFF0F172A);
  // 5,42:1 di atas putih dan 4,95:1 di atas [lightSurfaceAlt]. Slate-500
  // (#64748B) yang dipakai sebelumnya jatuh ke 4,34:1 di petak abu.
  static const Color textMuted = Color(0xFF5B6B82);
  static const Color darkTextStrong = Color(0xFFF8FAFC);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // --- Semantik ------------------------------------------------------------
  // Sukses sengaja digeser ke emerald yang lebih dalam dan lebih kuning supaya
  // tidak tertukar dengan teal merek. Di grafik keuangan, "untung" dan "ini
  // Zenvi" tidak boleh terbaca sebagai warna yang sama.
  static const Color successFill = Color(0xFF10B981);
  static const Color successText = Color(0xFF047857);
  static const Color successSoft = Color(0xFFECFDF5);

  static const Color dangerFill = Color(0xFFF43F5E);
  static const Color dangerText = Color(0xFFBE123C);
  static const Color dangerSoft = Color(0xFFFFF1F2);

  static const Color warningFill = Color(0xFFF59E0B);
  static const Color warningText = Color(0xFFB45309);
  static const Color warningSoft = Color(0xFFFFFBEB);

  static const Color infoFill = Color(0xFF3B82F6);
  static const Color infoText = Color(0xFF1D4ED8);
  static const Color infoSoft = Color(0xFFEFF6FF);
  // Varian terang untuk teks/ikon info di atas permukaan gelap.
  static const Color infoBright = Color(0xFF60A5FA);

  static const Color neutralFill = Color(0xFF94A3B8);
  static const Color neutralText = Color(0xFF475569);

  // --- Paket berbayar ------------------------------------------------------
  // Emas adalah satu-satunya warna di luar keluarga teal/slate yang boleh
  // dipakai untuk kroma besar, dan HANYA untuk penanda paket berbayar. Karena
  // tidak muncul di tempat lain, lencana emas langsung terbaca sebagai "ini
  // terkunci" tanpa perlu dijelaskan.
  static const Color premiumText = Color(0xFF8A6614); // 5,26:1 di atas putih
  static const Color premium = Color(0xFFB4881F);
  static const Color premiumBright = Color(0xFFE2B857);
  static const Color premiumGlow = Color(0xFFF5DFA0);
  static const Color premiumSoft = Color(0xFFFDF6E3);

  /// Gradien latar untuk kepala tawaran upgrade dan kartu paket.
  static const List<Color> premiumGradient = <Color>[
    Color(0xFF134E4A),
    Color(0xFF0F766E),
    Color(0xFF115E59),
  ];

  /// Deret grafik laba rugi. Warnanya membawa MAKNA, bukan sekadar kategori:
  /// hijau untuk laba dan merah untuk beban adalah konvensi yang dibaca orang
  /// jauh lebih cepat daripada label mana pun.
  ///
  /// Omzet sengaja indigo, BUKAN teal merek. Kalau omzet memakai teal dan laba
  /// memakai hijau, satu grafik berisi dua warna yang nyaris sama - dan pada
  /// layar ponsel di bawah lampu toko keduanya tidak terbedakan.
  static const Color chartRevenue = Color(0xFF6366F1);
  static const Color chartProfit = successFill;
  static const Color chartExpense = dangerFill;

  /// Warna deret grafik, sudah dijauhkan rona satu sama lain supaya masih
  /// terbedakan pada layar kecil dan pada penglihatan warna yang terbatas.
  static const List<Color> chartSeries = <Color>[
    Color(0xFF0F766E), // teal - deret utama
    Color(0xFFF59E0B), // amber
    Color(0xFFF43F5E), // rose
    Color(0xFF6366F1), // indigo
    Color(0xFF047857), // emerald tua
    Color(0xFF94A3B8), // slate
  ];
}
