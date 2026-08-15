---
name: ui-ux-pro
description: Pedoman eksklusif untuk UI/UX Premium (Pro). Gunakan skill ini secara otomatis ketika pengguna meminta desain UI, perbaikan layout, pembuatan komponen visual, atau merombak tampilan aplikasi menjadi lebih modern dan profesional kelas atas (Apple-like, Square POS, Moka POS).
---

# 🎨 Pedoman UI/UX Pro (Zenvi Premium Design)

Skill ini wajib dipatuhi setiap kali agen melakukan tugas terkait desain UI (User Interface) dan UX (User Experience) di proyek Zenvi atau aplikasi Flutter lainnya agar hasil selalu berstandar "Pro".

## 1. Filosofi Desain (The "WOW" Factor)
- **Hindari desain default kaku:** Jangan pernah gunakan desain bawaan `Material` yang kaku (misal: kotak bersudut tajam, garis tepi yang tebal, tombol default yang membosankan).
- **Glassmorphism & Soft UI:** Gunakan efek bayangan lembut (`blurRadius` tinggi dengan `opacity` sangat rendah, misalnya `alpha: 0.05` hingga `alpha: 0.1`).
- **Rounded & Pill-shaped:** Gunakan sudut melengkung ekstrem (`BorderRadius.circular(24)` hingga `40` untuk kartu besar, atau sudut kapsul untuk tombol).

## 2. Palet Warna (Color Tokens)
Gunakan palet warna yang kohesif dan kontras:
- **Light Mode:** 
  - Background: `Soft Pearl Gray` (`0xFFF3F4F6` atau `0xFFF5F6FA`) - Jangan gunakan putih murni untuk *background*.
  - Surface (Cards): `0xFFFFFFFF` (Putih Murni).
  - Primary: Warna elektrik/neon seperti Indigo (`0xFF4F46E5`) atau Violet.
- **Dark Mode:**
  - Background: `Deep Slate / Charcoal` (`0xFF0F172A`).
  - Surface (Cards): `0xFF1E293B` (Sedikit lebih terang dari background).
  - Primary: `0xFF6366F1` (Neon Indigo yang terang di latar gelap).

## 3. Micro-Animations (Kehidupan UI)
- Setiap interaksi pengguna (tekan, geser, tab) harus direspon dengan mikro-animasi.
- Gunakan `AnimatedContainer`, `AnimatedSwitcher`, atau `ScaleTransition`.
- Kurva animasi wajib menggunakan kurva yang natural, seperti `Curves.easeOutCubic` atau `Curves.easeOutBack`.

## 4. Tipografi (Typography)
- Gunakan hierarki kontras yang tajam. Judul (`Headline`) harus tebal (`FontWeight.w900`) dengan *letter-spacing* minus (misal: `-0.5`).
- Subtitle atau label harus menggunakan warna yang redup (`onSurfaceVariant`) agar mata pengguna fokus pada konten utama.

## 5. Layouting Kasir (POS)
- Menu kasir wajib menggunakan konsep *Bento Box* Grid, dengan spasi (padding/margin) yang lega (*breathing room*).
- Sidebar navigasi sebaiknya melayang (*floating*) dengan *padding* luar, bukan menempel kaku di pinggir layar.

## 6. Aturan Kode Flutter
- Saat mengatur opasitas warna, **WAJIB** menggunakan `.withValues(alpha: X)` untuk Flutter 3.27+ (Jangan gunakan `.withOpacity()` karena *deprecated*).
- Hapus semua *app bar* bawaan yang memiliki *elevation* dan *shadow* pekat. Ganti dengan `AppBar` transparan (`backgroundColor: Colors.transparent, elevation: 0`).
