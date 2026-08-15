---
name: flutter-zenvi-rules
description: Pedoman arsitektur dan pengembangan Flutter khusus untuk proyek Zenvi. Gunakan skill ini secara otomatis ketika pengguna meminta penambahan fitur, perbaikan bug, atau refactoring kode Flutter di dalam repositori ini.
---

# 🚀 Pedoman Pengembangan Flutter (Proyek Zenvi)

Skill ini menetapkan standar pengkodean dan arsitektur aplikasi Flutter khusus untuk proyek Zenvi agar *codebase* tetap bersih, terukur (scalable), dan bebas dari bug.

## 1. Arsitektur & State Management (Provider)
- **Gunakan arsitektur berbasis fitur (Feature-first) atau MVVM ringan:** Pisahkan logika UI (`screens/` atau `widgets/`) dengan State Management (`providers/`) dan manipulasi data (`services/` atau `database/`).
- **State Management:** Selalu gunakan **Provider** (`context.watch`, `context.read`, `Consumer`).
- Jangan letakkan *business logic* kompleks (seperti kalkulasi pajak, diskon, atau sinkronisasi API) di dalam file UI. Pindahkan ke dalam file `Provider` yang relevan.

## 2. Lokalisasi (Easy Localization)
- Jangan pernah *hardcode* teks bahasa ke dalam UI!
- Gunakan `easy_localization` dengan format `.tr()`. Contoh: `Text('dashboard_title'.tr())`.
- Jika menambahkan fitur baru, pastikan untuk menambahkan *key* terjemahannya di `assets/translations/id.json` dan `en.json`.

## 3. Penanganan Data Lokal (Offline-First)
- Zenvi adalah aplikasi **Offline-First**. Semua data produk, kategori, shift, dan keranjang belanja harus disimpan atau dimanipulasi melalui **SQLite** (`DatabaseHelper`) lokal.
- Sinkronisasi dengan server Laravel hanya terjadi di latar belakang (*background*) lewat `SyncService`. Jangan pernah melakukan pemanggilan API secara langsung yang dapat memblokir interaksi pengguna di layar.

## 4. Standar Kode & Kerapian (Linting)
- Selalu patuhi standar linter Dart terbaru.
- **Wajib:** Tambahkan tipe pengembalian (`return type`) eksplisit pada setiap fungsi/metode.
- **Wajib:** Hindari variabel tipe `dynamic`. Selalu gunakan *strong typing* (`String`, `int`, model kustom seperti `ProductModel`).
- Jangan abaikan peringatan *Deprecation*. Selalu gunakan versi terbaru (misal: gunakan `.withValues(alpha: x)` bukan `.withOpacity(x)`).

## 5. Keamanan & Penanganan Error
- Gunakan blok `try-catch` di dalam setiap fungsi asinkron (`async`) yang berkomunikasi dengan *Database* atau *API*.
- Tangani `null` secara elegan menggunakan fitur *Null Safety* Dart (`?`, `??`, `??=`, atau `if (x != null)`).
- Jangan memunculkan *error stacktrace* mentah ke pengguna. Gunakan `ScaffoldMessenger.of(context).showSnackBar` untuk memberitahu error dengan ramah.
