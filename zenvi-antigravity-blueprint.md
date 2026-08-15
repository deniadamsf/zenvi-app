# 🚀 ZENVI: The Antigravity SaaS Blueprint
**Dokumen Arsitektur & Panduan Spesifikasi Sistem Kasir, ERP & Pemantauan Multi-Tenant**

**Zenvi** (*Zen + Visibilitas*) dirancang dengan filosofi *antigravity*: sistem terasa sangat ringan, responsif, dan intuitif bagi pengguna di lapangan (Flutter Mobile/Tablet), serta memiliki pondasi logika yang kokoh, modular, dan aman di sisi server (Laravel).

---

## 📜 Aturan Utama Pengembangan (Development Rules)
1. **Analisis Kode (Zero Warnings):** Selalu jalankan `dart analyze` / `flutter analyze` untuk memastikan kode frontend bebas dari pesan error dan warning (*unused imports*, *deprecated members*, dll).
2. **Mandatory Sinkronisasi Hostinger Live:** Setiap ada perubahan Backend (Laravel), migrasi database, model, controller, route, atau view, **wajib langsung diunggah via SCP** ke server Hostinger dan menjalankan perintah:
   ```bash
   ssh -p 65002 -i ~/.ssh/id_rsa u731410318@153.92.8.198 "cd /home/u731410318/domains/cellanoma.my.id/public_html/zenvi/api && php artisan migrate --force && php artisan optimize:clear"
   ```
   * **Host / IP:** `153.92.8.198` | **Port:** `65002` | **User:** `u731410318`
   * **Remote Path:** `/home/u731410318/domains/cellanoma.my.id/public_html/zenvi/api`
3. **Mandatory Lokalisasi (Bilingual — ID & EN):** Setiap ada penambahan atau perubahan **teks UI apapun** di kode Flutter (label, hint, helper, snackbar, dialog, judul, dll), **WAJIB** menambahkan atau memperbarui key terjemahannya di **kedua** file berikut:
   * `frontend_pos/assets/translations/id.json` — versi Bahasa Indonesia
   * `frontend_pos/assets/translations/en.json` — versi Bahasa Inggris

   **Format penamaan key:** gunakan format deskriptif dengan underscore, kelompokkan per fitur/layar. Contoh:
   ```json
   // id.json
   "membership_earning_label": "Kelipatan Belanja per 1 Poin",
   "membership_redeem_title": "② Cara MEMAKAI Poin (Tukar/Redeem)"
   
   // en.json
   "membership_earning_label": "Spending per 1 Point",
   "membership_redeem_title": "② How Members USE Points (Redeem)"
   ```

   **Di kode Dart**, selalu gunakan `.tr(context: context)` — **DILARANG** hardcode string UI langsung di widget:
   ```dart
   // ✅ BENAR
   Text('membership_earning_label'.tr(context: context))
   
   // ❌ SALAH
   Text('Kelipatan Belanja per 1 Poin')
   ```

   Untuk string dengan parameter dinamis, gunakan `args`:
   ```dart
   'membership_earning_example'.tr(context: context, args: [examplePoints.toString()])
   // id.json: "membership_earning_example": "Contoh: Belanja Rp 100.000 = {} Poin"
   // en.json: "membership_earning_example": "Example: Rp 100,000 purchase = {} Points"
   ```

---

## 1. 🏗️ Tech Stack & Arsitektur Sistem

* **Backend:** Laravel 10/11 (PHP 8.2+) RESTful API Provider, Firebase HTTP v1 Client, Multi-Tenant Engine.
* **Frontend Mobile / POS:** Flutter 3.x (Dart), Multi-Provider State Management, Offline SQLite / Local Cache, Flutter Local Notifications & FCM.
* **Database:** MySQL / MariaDB (Hostinger Live Cloud Database).
* **Cloud & Services:** Firebase Cloud Messaging (FCM Spark Plan), OpenStreetMap GPS Geolocation, Google Service Account OAuth2.
* **Pendekatan Arsitektur:**
  * *Single-Database Multi-Tenancy:* Seluruh data tenant dipisahkan secara tegas menggunakan `company_id` dan `branch_id`.
  * *Offline-First POS:* Kasir tetap dapat memproses pesanan lokal saat offline, lalu sinkronisasi otomatis saat internet kembali tersedia.
  * *Granular Permission & Multi-Role:* Kontrol akses dinamis per karyawan.

---

## 2. 🔐 Modul & Fitur Unggulan Zenvi

### 🏢 A. Multi-Tenant & Multi-Cabang (Multi-Branch)
- **Tenant Isolation:** Setiap pemilik bisnis memiliki entitas unik (`companies`) dengan kode registrasi bisnis (misal: `ZNV-XXXX`).
- **Multi-Outlet / Cabang:** Satu perusahaan dapat memiliki banyak cabang outlet (`branches`). Karyawan dan transaksi dapat diisolasi per cabang atau dikelola secara terpusat oleh Owner.
- **Custom Branding & Logo:** Upload logo bisnis untuk dicetak pada struk thermal dan ditampilkan pada QR Menu.

### 👥 B. Presensi Cerdas & Izin Karyawan (Smart Attendance & Leave)
- **Presensi Selfie & GPS Geofencing:** Buka/tutup shift kasir dapat mewajibkan foto selfie dan verifikasi radius lokasi GPS outlet.
- **Jadwal Kerja Perusahaan:** Pengaturan jam buka-tutup dan batas toleransi keterlambatan.
- **Modul Pengajuan Izin / Cuti:** Karyawan dapat mengajukan izin/cuti dengan lampiran bukti foto dari aplikasi. Owner menerima notifikasi instan dan dapat menyetujui (*Approve*) atau menolak (*Reject*).

### 🛒 C. Point of Sale (POS) & Bill of Materials (BOM)
- **Kategori & Varian Produk:** Pengelompokan produk dengan dukungan varian (misal: Dingin/Panas, Ukuran) dengan resep BOM masing-masing.
- **Pengurangan Stok Otomatis (Antigravity BOM):** Setiap transaksi kasir otomatis memotong stok bahan baku (`ingredients`) sesuai resep porsi.
- **Toleransi Susut & Wastage:** Pencatatan bahan terbuang/rusak (*wastage*) dan toleransi selisih saat Stock Opname.
- **Metode Pembayaran Fleksibel:** Tunai, QRIS, Transfer Bank, Kartu Debit/Kredit, dan Custom Payment.
- **Pencetakan Struk Thermal:** Cetak struk via Bluetooth/USB printer dengan format rapi dan logo outlet.

### 💰 D. Manajemen Kas & Shift (Cash Control)
- **Wajib Saldo Laci Awal:** Validasi modal awal kasir sebelum memulai transaksi.
- **Petty Cash (Kas Kecil):** Pencatatan pengeluaran operasional darurat di toko.
- **Blind Shift Closing:** Kasir menginput uang fisik riil tanpa melihat perhitungan omzet sistem untuk mencegah kecurangan (*discrepancy detection*).

### 👑 E. Sistem Membership & Loyalty Program
- **Database Pelanggan:** Pencatatan member (Nama, No. Telepon, Email, Level Member: Silver/Gold/Platinum).
- **Loyalty Point & Promo:** Diskon otomatis member, potongan harga nominal, dan akumulasi poin belanja.
- **Fast Lookup Member:** Pencarian cepat member saat transaksi POS via nomor telepon atau scan barcode.

### 🍽️ F. Reservasi Meja & Jasa (Reservation Management)
- **Multi-Channel Booking:** Menerima reservasi dari kasir POS maupun dari halaman web publik QR Menu.
- **Status Alur Reservasi:** `pending` ➔ `confirmed` ➔ `seated` ➔ `completed` / `cancelled`.
- **Pengaturan Reservasi:** Jumlah tamu, deposit/DP, nomor meja, dan catatan khusus.

### 📱 G. QR Menu & Landing Page Digital
- Pelanggan dapat melihat katalog menu digital restoran/toko secara live melalui scan QR code tanpa perlu login.
- Tombol pemesanan online dan reservasi meja langsung terhubung ke dashboard POS toko.

### 🔔 H. Notifikasi Real-Time & FCM Push Notification
- **Firebase Cloud Messaging (FCM HTTP v1):** Pengiriman notifikasi ke perangkat HP Owner dan Karyawan saat aplikasi tertutup (Background) maupun terbuka (Foreground).
- **In-App Notification Center:** Halaman pusat notifikasi dengan filter kategori (Shift, Stok Rendah, Izin, Chat, Reservasi), swipe to dismiss, dan navigasi langsung ke modul terkait.
- **Skenario Trigger Otomatis:**
  1. *Karyawan Buka / Tutup Shift* ➔ Notifikasi ke Owner.
  2. *Stok Bahan / Produk Menipis* ➔ Notifikasi ke Owner & Karyawan.
  3. *Pengajuan Cuti Karyawan* ➔ Notifikasi ke Owner.
  4. *Persetujuan / Penolakan Cuti* ➔ Notifikasi ke Karyawan bersangkutan.
  5. *Pesan Chat Masuk* ➔ Notifikasi ke Lawan Bicara.
  6. *Reservasi Baru Masuk* ➔ Notifikasi ke Owner & Karyawan.

### 💬 I. Chat Internal Terintegrasi
- Komunikasi real-time antar karyawan dan Owner langsung di dalam aplikasi untuk koordinasi operasional tanpa aplikasi pihak ketiga.

---

## 3. 💾 Struktur Entitas & Relasi Database Inti

```
+------------------+         +-------------------+         +-------------------+
|    companies     | <---+---|     branches      | <---+---|       users       |
+------------------+     |   +-------------------+     |   +-------------------+
| id               |     |   | id                |     |   | id                |
| name, code, logo |     |   | company_id        |     |   | company_id        |
| settings (json)  |     |   | name, address     |     |   | branch_id, role   |
+------------------+     |   | lat, lng, radius  |     |   | permissions (json)|
                         |   +-------------------+     |   +-------------------+
                         |                             |
                         |   +-------------------+     |   +-------------------+
                         +---|    ingredients    |     +---|      shifts       |
                         |   +-------------------+     |   +-------------------+
                         |   | id, company_id    |     |   | id, user_id       |
                         |   | name, unit, stock |     |   | opening_balance   |
                         |   | min_stock         |     |   | closing_balance   |
                         |   +-------------------+     |   | selfie_path, lat  |
                         |                             |   +-------------------+
                         |   +-------------------+     |
                         +---|     products      |     |   +-------------------+
                         |   +-------------------+     +---|      orders       |
                         |   | id, company_id    |         +-------------------+
                         |   | name, price, disc |         | id, shift_id      |
                         |   +-------------------+         | member_id         |
                         |                                 | total, payment_mth|
                         |   +-------------------+         +-------------------+
                         +---|   reservations    |
                         |   +-------------------+         +-------------------+
                         |   | id, customer_name |         |   user_devices    |
                         |   | table_no, status  |         +-------------------+
                         |   +-------------------+         | user_id, token    |
                         |                                 | platform          |
                         |   +-------------------+         +-------------------+
                         +---|      members      |
                             +-------------------+         +-------------------+
                             | id, name, phone   |         |in_app_notification|
                             | points, tier      |         +-------------------+
                             +-------------------+         | user_id, title    |
                                                           | type, is_read     |
                                                           +-------------------+
```

---

## 4. 🎯 Roadmap Menuju Finishing & UI Polish

- [x] Backend & Database Migrations (Hostinger Live)
- [x] Offline POS Engine & Multi-Branch Architecture
- [x] Smart Attendance & Employee Permission Approval
- [x] Bill of Materials (BOM) Auto-Deduction & Wastage
- [x] Membership & Loyalty Promo Calculation
- [x] Table & Service Reservation System
- [x] Firebase Cloud Messaging (FCM) & In-App Notification Center
- [ ] **Finishing & UI/UX Enhancement:**
  - Standardisasi tema (*Glassmorphism*, palet warna dinamis, animasi halus).
  - Optimasi responsivitas tata letak (Smartphone & Tablet POS).
  - Quick-action shortcuts & micro-interactions.
