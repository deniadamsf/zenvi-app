# Zenvi

Aplikasi kasir (Point of Sale) dan sistem manajemen operasional bisnis multi-tenant yang dirancang untuk pelaku UMKM di bidang F&B, ritel, dan jasa. Repositori ini memuat aplikasi kasir mobile/tablet berbasis Flutter dan backend RESTful API berbasis Laravel yang dilengkapi panel admin Filament.

## Struktur Repositori

Proyek ini terdiri dari beberapa komponen utama:

- `frontend_pos/` — Aplikasi kasir mobile dan tablet berbasis Flutter (Android & iOS).
- `backend/` — Layanan RESTful API dan panel administrasi berbasis Laravel 10 dan Filament 3.2.
- `playstore_assets/` — Aset visual, metadata toko, dan catatan rilis untuk Google Play Store.

## Fitur Utama

- **Multi-Tenant dan Multi-Cabang**: Pengelolaan data terisolasi per perusahaan (`company`) dan per cabang outlet (`branch`).
- **Point of Sale (POS)**: Pemrosesan transaksi penjualan cepat, varian produk, diskon, berbagai metode pembayaran (Tunai, QRIS, Transfer Bank), dan pencetakan struk thermal via Bluetooth/USB ESC/POS.
- **Mode Offline-First**: Transaksi tetap dapat berjalan saat internet terputus menggunakan database lokal SQLite, kemudian tersinkronisasi otomatis saat online kembali.
- **Manajemen Bahan Baku & Resep (BOM)**: Pengurangan stok bahan baku secara otomatis per porsi pesanan, pencatatan bahan rusak atau terbuang (wastage), dan stok opname.
- **Presensi dan Manajemen Shift**: Pembukaan kasir dengan modal awal laci, pencatatan kas kecil (petty cash), presensi selfie dengan deteksi wajah dan verifikasi koordinat GPS, serta penutupan shift blind closing.
- **Program Loyalitas Pelanggan**: Pencatatan data member, akumulasi poin belanja, dan promo diskon khusus member.
- **Reservasi Meja & Menu Digital**: Halaman katalog menu digital berbasis scan QR code publik dan modul reservasi meja yang terhubung langsung ke kasir.
- **Kitchen Display System (KDS)**: Tampilan antrean status pesanan secara real-time untuk bagian dapur.
- **Komunikasi dan Izin Karyawan**: Modul pengajuan cuti atau izin sakit dengan lampiran foto bukti serta fitur obrolan internal antar-staf.
- **Notifikasi Real-Time**: Pengiriman notifikasi ke perangkat melalui Firebase Cloud Messaging (FCM).
- **Skema Langganan**: Pembagian tingkat paket (Gratis, Premium, Bisnis) dengan verifikasi pembelian Google Play In-App Purchase.

## Teknologi yang Digunakan

### Frontend
- Flutter 3.x (Dart SDK)
- Provider (state management)
- SQLite (`sqflite`) & `shared_preferences` (penyimpanan lokal dan offline cache)
- `blue_thermal_printer` & `esc_pos_utils_plus` (pencetakan struk thermal)
- Google ML Kit Face Detection (validasi selfie presensi)
- OpenStreetMap & Geolocator (geofencing radius outlet)
- Firebase Cloud Messaging & Flutter Local Notifications (notifikasi push dan lokal)
- In-App Purchase (Google Play Billing)
- Easy Localization (multi-bahasa ID dan EN)

### Backend
- PHP 8.1 / 8.2+
- Laravel 10
- Filament 3.2 (Admin Panel)
- Laravel Sanctum & Laravel Socialite
- MySQL / MariaDB
- Firebase HTTP v1 Client (OAuth2 Service Account)

## Panduan Memulai

### Prasyarat
- PHP >= 8.1 dengan ekstensi `pdo_mysql`, `curl`, `gd`, `mbstring`, `openssl`
- Composer
- MySQL 8.0+ atau MariaDB 10.4+
- Flutter SDK (versi 3.x) dan Android SDK / Xcode

### Setup Backend (Laravel)

1. Masuk ke direktori backend:
   ```bash
   cd backend
   ```
2. Pasang dependensi PHP:
   ```bash
   composer install
   ```
3. Salin berkas konfigurasi lingkungan dan hasilkan encryption key:
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```
4. Sesuaikan konfigurasi database pada `.env`, lalu jalankan migrasi database:
   ```bash
   php artisan migrate
   ```
5. Buat tautan simbolik ke direktori penyimpanan berkas publik:
   ```bash
   php artisan storage:link
   ```
6. Jalankan server lokal:
   ```bash
   php artisan serve
   ```
   Panel admin Filament dapat diakses melalui browser pada alamat `http://localhost:8000/admin`.

### Setup Frontend (Flutter)

1. Masuk ke direktori frontend:
   ```bash
   cd frontend_pos
   ```
2. Unduh paket dependensi Flutter:
   ```bash
   flutter pub get
   ```
3. Jalankan pengujian analisis kode:
   ```bash
   flutter analyze
   ```
4. Jalankan aplikasi pada perangkat atau emulator target:
   ```bash
   flutter run
   ```
