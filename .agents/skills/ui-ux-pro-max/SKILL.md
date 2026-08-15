---
name: ui-ux-pro-max
description: >-
  Panduan desain UI/UX tingkat lanjut (Pro Max) untuk aplikasi Flutter Zenvi.
  Mengatur geometri header presisi, pembatasan text scaling, kalibrasi tipografi Outfit,
  efek frosted glass modern, ergonomi tombol, dan konsistensi visual di seluruh layar.
---

# UI/UX Pro Max Design Guidelines & Best Practices

Panduan standar tinggi untuk menghasilkan antarmuka aplikasi Flutter yang presisi, responsif, elegan, dan terasa premium di semua perangkat mobile (Android, iOS) serta tablet/desktop.

---

## 1. Perlindungan Skala Font (Text Scaling Guard)
- **Masalah**: Pengaturan skala font bawaan sistem operasi HP (Large/Accessibility) sering membuat teks Flutter membesar tanpa batas hingga merusak layout.
- **Standar**:
  Wajib membungkus `MaterialApp` builder dengan pembatasan `textScaler`:
  ```dart
  builder: (context, child) {
    final mediaQuery = MediaQuery.of(context);
    final clampedTextScaler = mediaQuery.textScaler.clamp(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.15,
    );
    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: clampedTextScaler),
      child: child!,
    );
  }
  ```

---

## 2. Geometri Header Presisi (Precision Header Geometry)
- **Tinggi Header Standar**:
  - Tanpa Subtitle: `kToolbarHeight + topPadding` (sekitar `56.0 + topPadding`).
  - Dengan Subtitle / Dua Baris: `64.0 + topPadding`.
  - Jangan pernah menggunakan tinggi statis berlebih seperti `120 + topPadding` untuk header biasa!
- **Padding & Alignment**:
  - `top`: `topPadding + 6` s/d `topPadding + 8` (memberi celah yang pas dan bersih di bawah area kamera *punch-hole* / *notch*).
  - `bottom`: `8.0` s/d `10.0`.
  - `horizontal`: `16.0` s/d `20.0`.
  - Konten judul dan tombol kembali wajib disejajarkan secara vertikal (`Alignment.center` atau `CrossAxisAlignment.center`).
- **Efek Frosted Glass (Glassmorphism)**:
  - Gunakan `ClipRRect` + `BackdropFilter(filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16))`.
  - Latar belakang: `theme.colorScheme.surface.withValues(alpha: 0.85)`.
  - Garis pemisah bawah super halus: `Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08), width: 1))`.

---

## 3. Tipografi & Hierarki Teks (Outfit Typography Scale)
- **Font Utama**: **Outfit** via `google_fonts`.
- **Skala Ukuran Teks**:
  - `Display / Hero Title`: `24sp - 26sp`, `FontWeight.w800`, `letterSpacing: -0.5`.
  - `Header Bar Title`: `18sp - 20sp`, `FontWeight.w800`, `letterSpacing: -0.4`.
  - `Card Header Title`: `16sp - 17sp`, `FontWeight.w700`, `letterSpacing: -0.2`.
  - `Subtitle / Helper Text`: `12sp - 13sp`, `FontWeight.w500`, warna `theme.colorScheme.onSurfaceVariant`.
  - `Body Text`: `13sp - 14sp`, `FontWeight.w400`.
  - `Badge / Label Kecil`: `10sp - 11sp`, `FontWeight.w700`, `letterSpacing: 0.3`.

---

## 4. Ergonomi Tombol & Aksi (Button & Touch Ergonomics)
- **Tombol Kembali (Back Button)**:
  - Ukuran kontainer: `38x38` atau `40x40`.
  - Bentuk: `BoxShape.circle` atau `RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))`.
  - Latar: `theme.colorScheme.surface` dengan border halus `Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1))`.
  - Ikon: `Icons.arrow_back_ios_new_rounded`, ukuran `18sp`.
- **Tombol Aksi Kanan (Action Button)**:
  - Bentuk melingkar/persegi tumpul dengan latar `primary.withValues(alpha: 0.1)`.
  - Ikon dengan warna `primary`.
- **Touch Target**: Minimal `44x44` px untuk kenyamanan sentuhan jari.

---

## 5. Kartu & Elevasi (Card & Surface Elevation)
- **Border Radius**: `16` s/d `20` px.
- **Shadow**: Super halus, tidak tebal.
  `BoxShadow(color: theme.shadowColor.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))`.
- **Border**: `Border.all(color: theme.dividerColor.withValues(alpha: 0.08))` untuk memberi ketegasan tanpa terkesan kasar.

---

## 6. Navigasi Melayang (Floating Navigation & Scroll Through)
- Saat menggunakan navigasi bawah melayang (`Floating Pill`), pastikan `Scaffold(extendBody: true)`.
- Berikan padding bawah pada konten `CustomScrollView` / `ListView` sebesar `bottom: 120` agar konten terbawah tidak tertutup navigasi dan bisa discroll dengan leluasa.
