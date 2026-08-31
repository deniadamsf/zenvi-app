# Rencana Implementasi Fitur Langganan Zenvi

> Status: **desain final, belum ada kode.** Dokumen ini dibaca oleh Claude/Codex/Gemini
> yang bergantian mengerjakan repo ini. Kalau ada keputusan yang berubah, perbarui di sini.

---

## 0. Dua keputusan yang harus dikunci sebelum baris kode pertama

**0.1 Tanggal cutoff grandfathering.** Semua toko yang terdaftar sebelum tanggal ini
dapat paket berbayar gratis selamanya. Tanpa tanggal yang ditetapkan dan diumumkan,
batasnya kabur dan pemberian gratis tidak pernah berhenti.

**0.2 Jalur pembayaran di Android.** Ada `playstore_assets/` di repo — aplikasi ini
terdistribusi lewat Play Store. Google mewajibkan Play Billing untuk pembelian digital
di dalam aplikasi; menjual langganan lewat Midtrans di dalam APK berisiko reject atau
takedown. Dua pilihan:

- **Checkout di browser eksternal** (halaman billing Laravel, dibuka dengan
  `url_launcher` ke browser — bukan WebView in-app). Paling aman, paling cepat.
- **Play Billing** untuk jalur Android. Lebih patuh, jauh lebih banyak kerjaan.

Keputusan ini menentukan apakah halaman checkout dibuat di Flutter atau di Blade,
jadi harus diambil sebelum Tahap 4.

---

## 1. Paket (sudah diputuskan)

| | **GRATIS** | **PREMIUM** | **BISNIS** |
|---|---|---|---|
| Karyawan | 10 | tak terbatas | tak terbatas |
| Cabang | 1 | 1 | 5 |
| Produk | 50 | tak terbatas | tak terbatas |
| Riwayat transaksi | 30 hari | penuh | penuh |
| **Harga/bulan** | **Rp 0** | **Rp 59.000** | **Rp 149.000** |
| Harga/tahun | — | Rp 590.000 | Rp 1.490.000 |
| Cabang tambahan | — | — | Rp 39.000/cabang/bulan |

**GRATIS** — POS + varian + diskon, tunai/QRIS/transfer, struk thermal + label,
mode offline + sync, shift + laci kas, **stok & bahan baku + resep/HPP + opname +
wastage + riwayat stok**, **absensi GPS tanpa foto**, jadwal & izin karyawan,
**chat internal**, **laporan performa karyawan**, pengeluaran + laporan harian.

**PREMIUM** menambah — semua batas dilepas kecuali cabang, foto produk,
**selfie absensi**, member + poin + promo, QR menu & halaman toko publik,
reservasi, KDS, laporan laba rugi penuh, export Excel/PDF + dashboard analitik.

**BISNIS** menambah — multi-cabang + stok per cabang, laporan konsolidasi lintas
cabang, perbandingan performa antar cabang, transfer stok antar cabang.

**Trial Premium 14 hari otomatis** untuk setiap toko baru.
Lebih dari ~10 cabang → "Hubungi kami". Jangan bikin tingkat keempat.

> **Catatan harga.** Rp 59rb dipilih untuk menekan hambatan masuk di pasar UMKM.
> Konsekuensinya: (a) menurunkan harga adalah pintu satu arah — menaikkannya nanti
> jauh lebih sulit, apalagi karena sudah ada komitmen grandfather permanen;
> (b) biaya transaksi gateway yang berbentuk flat (VA ~Rp 4.400) memakan ~7,5% dari
> Rp 59rb, jauh lebih terasa daripada di harga tinggi — jadi **dorong paket tahunan**
> dan utamakan QRIS yang biayanya persentase kecil, bukan VA.
> Alternatif yang menjaga pintu tetap terbuka tanpa mengubah kode sama sekali:
> pasang Rp 99rb sebagai harga normal dan Rp 59rb sebagai **harga perkenalan yang
> dikunci selamanya untuk pelanggan awal**.

### Alasan pembagiannya

- Alur jualan tidak pernah dikunci. Kalau kasir tidak bisa berjualan karena langganan
  habis, mereka pindah aplikasi hari itu juga — bukan bayar.
- Yang dikunci adalah yang **tumbuh bersama ukuran usaha** (cabang) dan yang
  **mahal di server** (foto, QR menu publik, KDS polling, riwayat panjang).
- Fitur karyawan sengaja gratis karena justru **menciptakan permintaan** kuota:
  owner melihat laporan performa → ingin data per kasir → butuh akun ke-11 → upgrade.
- Sumbu pembeda Premium vs Bisnis adalah **cabang**, bukan jumlah karyawan.
  Pelanggan 50-karyawan terlalu langka untuk menopang satu tingkat.
  Di halaman harga, jual Bisnis dengan "kelola banyak cabang", bukan "50 karyawan".

---

## 2. Arsitektur

- **Unit langganan = `companies`**, bukan user. Semua data sudah digantung ke sana,
  tidak perlu refactor.
- **Definisi paket di `config/plans.php`**, bukan tabel. Paket jarang berubah tapi
  dibaca tiap request; di config ia ikut ter-cache `config:cache` → nol query.
- **Status langganan sebagai kolom di `companies`.** `AuthController@me` mengembalikan
  `$user->load('company')`, jadi status paket otomatis terbawa ke aplikasi tanpa
  endpoint baru.
- **Gating WAJIB di server.** Hari ini `routes/api.php` nol middleware fitur dan
  controller hanya cek `role !== 'Owner'`. Toggle di Flutter murni UX.
- **Nilai efektif fitur = `toggle_owner && paket_mengizinkan`.**

---

## 3. Tahapan

### Tahap 1 — Pondasi entitlement (backend)

| File | Aksi |
|---|---|
| `config/plans.php` | **baru** — definisi 3 paket: `features[]`, `limits[]`, harga |
| `database/migrations/*_add_subscription_to_companies_table.php` | **baru** |
| `app/Support/Entitlements.php` | **baru** — `hasFeature()`, `limit()`, `isPremium()`, `onGrace()` |
| `app/Http/Middleware/EnsureFeatureEnabled.php` | **baru** — alias `feature` |
| `app/Http/Middleware/EnsurePlanLimit.php` | **baru** — alias `plan.limit` |
| `app/Http/Kernel.php` | daftarkan alias di `$middlewareAliases` (baris ~55) |
| `routes/api.php` | pasang middleware per grup route |
| `app/Models/Company.php` | `$fillable`, `$casts`, `$appends` info paket |

Kolom baru di `companies`:

```
plan_code          string  default 'free'
plan_status        string  default 'active'   -- trialing|active|grace|expired
plan_expires_at    datetime nullable          -- NULL = tanpa kedaluwarsa
trial_ends_at      datetime nullable
extra_branches     integer default 0
is_founding_member boolean default false
```

Migration yang sama **mem-backfill toko lama**: semua company yang dibuat sebelum
tanggal cutoff → `plan_code = 'business'`, `plan_expires_at = NULL`,
`is_founding_member = true`.

Pemasangan middleware di `routes/api.php`:

```php
Route::apiResource('members', MemberController::class)->middleware('feature:membership');
Route::apiResource('member-promos', MemberPromoController::class)->middleware('feature:membership');
Route::apiResource('reservations', ReservationController::class)->middleware('feature:reservation');
Route::get('/orders/kds', ...)->middleware('feature:kds');
Route::apiResource('branches', BranchController::class)->middleware('feature:multi_branch');
```

**Kontrak respons saat terkunci** — aplikasi harus bisa membedakannya dari
unauthorized biasa:

```json
HTTP 403
{ "error": "feature_locked", "feature": "kds", "required_plan": "business" }
```
```json
HTTP 403
{ "error": "plan_limit_reached", "limit": "products", "current": 50, "max": 50, "required_plan": "premium" }
```

Pakai **403 dengan body bertipe**, bukan 402. Secara semantik 402 Payment Required
memang lebih tepat, tapi sebagian proxy dan klien HTTP menanganinya dengan aneh;
403 + field `error` yang eksplisit tidak pernah ambigu.

### Tahap 2 — Penegakan batas

| Batas | Titik penegakan | Catatan |
|---|---|---|
| Produk (50) | `ProductController@store` | |
| Karyawan (10) | `CompanyController@approveEmployee` | **bukan** saat karyawan mendaftar |
| Cabang (1 / 5) | `BranchController@store` | |
| Riwayat 30 hari | `OrderController@index`, `ExpenseController@financialReport`, `ShiftController@index` | batasi rentang, jangan hapus data |
| Toggle fitur premium | `CompanyController@updateSettings` (baris ~215) | tolak menyalakan fitur di luar paket |

Kuota karyawan ditegakkan saat **owner menyetujui**, bukan saat karyawan mendaftar.
Karyawan tetap boleh masuk antrean; owner yang melihat "kuota penuh, upgrade untuk
menyetujui" — tepat saat sedang menatap nama orang yang mau dia terima kerja.
Momen konversi terbaik yang tersedia. Hitung hanya `is_approved = true`;
owner tidak dihitung.

### Tahap 3 — Gating di Flutter

| File | Aksi |
|---|---|
| `lib/services/api_client.dart` | **baru** — pembungkus HTTP terpusat |
| `lib/providers/auth_provider.dart` | `planCode`, `isPremium`, `hasFeature()`; bungkus getter fitur yang sudah ada |
| `lib/widgets/premium_gate.dart` | **baru** — gembok + bottom sheet upsell |
| `lib/screens/subscription/plan_screen.dart` | **baru** — halaman paket |
| `lib/screens/subscription/billing_history_screen.dart` | **baru** |
| `lib/screens/settings/settings_screen.dart` | entry point ke halaman paket |
| `assets/translations/id.json` + `en.json` | key baru, wajib sinkron (CLAUDE.md §3) |

`api_client.dart` bukan opsional: saat ini 15 provider memanggil `package:http`
langsung, tanpa klien bersama. Tanpa pembungkus terpusat, penanganan
`403 feature_locked` harus ditambal satu per satu di semua provider.

Getter fitur yang sudah ada di `auth_provider.dart:26-37` dibungkus jadi
`isKdsEnabled => toggleOwner && hasFeature('kds')`. Karena seluruh layar sudah
membaca dari titik ini, gating UI-nya hampir gratis.

**Jangan sembunyikan menu premium** — tampilkan dengan gembok. Menu yang
tersembunyi tidak menjual apa pun.

### Tahap 4 — Penagihan

| Komponen | Catatan |
|---|---|
| Tabel `subscriptions` | riwayat siklus: company_id, plan_code, period_start/end, amount, source |
| Tabel `subscription_payments` | `order_id` **unique** ← ini yang membuat webhook idempoten |
| Transfer manual | upload bukti → admin approve. **Kerjakan duluan** |
| Halaman admin (Blade) | lihat company + paket, approve pembayaran, perpanjang manual |
| `POST /api/billing/checkout` | buat transaksi, kembalikan snap token / invoice URL |
| `GET /api/billing/status`, `/history` | |
| `POST /api/webhooks/{gateway}` | route publik, verifikasi signature, idempoten |
| `app/Console/Commands/CheckSubscriptionExpiry.php` | reminder H-7/H-3/H-1 + flip status |

**Hanya webhook yang boleh mengubah `plan_status`.** Jangan pernah mengaktifkan
paket dari sisi klien.

**Transfer manual dikerjakan lebih dulu.** Registrasi merchant gateway bisa makan
waktu berminggu-minggu; jalur manual membuat fiturnya bisa dijual duluan.

Command expiry dijadwalkan di `app/Console/Kernel.php`. **Cron di Hostinger sudah
aktif dan terverifikasi** (lihat `storage/framework/scheduler_last_run`), jadi task
terjadwal aman diandalkan. Reminder memakai `InAppNotification` + FCM yang
infrastrukturnya sudah ada.

### Tahap 5 — Fitur premium yang benar-benar baru

Karena hari ini semua fitur gratis, peluncuran akan terbaca "sekarang berbayar"
kecuali paket berbayar membawa sesuatu yang belum pernah ada.

1. **Export laporan Excel/PDF** — paling sering diminta pemilik toko, belum ada
2. **Dashboard analitik** — produk terlaris, jam ramai, tren mingguan; datanya sudah
   lengkap di `orders` + `order_items`, tinggal query + grafik
3. **Transfer stok antar cabang** (Bisnis) — dibangun di atas `branch_ingredients`
   yang sudah ada. Mustahil dipakai kalau cuma punya 1 cabang, jadi pembeda paling
   bersih untuk tingkat Bisnis

Satu saja dari nomor 1–2 sudah cukup mengubah cerita peluncuran dari
"fitur lama dikunci" jadi "ada paket baru dengan fitur baru".

---

## 4. Aturan yang tidak boleh dilanggar

- **Paket expired TIDAK menghapus data.** Turun ke entitlement gratis, modul premium
  jadi read-only. Kalau data pelanggan hilang saat telat bayar, user kabur.
- **Turun paket TIDAK menghapus akun karyawan.** Beri owner 7 hari memilih siapa yang
  tetap aktif; lewat itu sistem menonaktifkan otomatis dan menyisakan yang paling lama
  disetujui. Nonaktif = tidak bisa login, data utuh, hidup lagi saat upgrade.
  Menghapus akun karyawan sama saja menghapus riwayat shift dan penjualannya.
- **Jangan batasi jumlah transaksi per hari.** Itu menghentikan orang berjualan, dan
  hasilnya pindah aplikasi — bukan bayar.
- **Batas paket gratis adalah tuas pendapatan utama.** Setelah stok, absensi, chat,
  dan laporan performa digratiskan, seluruh monetisasi bertumpu pada batas angka +
  fitur premium. Jangan dilonggarkan saat ada yang protes.
- **Gating wajib server-side.** Toggle Flutter hanya UX.
- **`env()` jangan dipanggil di luar `config/`** — selalu null setelah `config:cache`.
- **Route closure tidak bisa di-`route:cache`** — pakai `Route::view()` atau controller.

---

## 5. Urutan rilis

```
Tahap 1 + 2 + 3 + transfer manual  →  SUDAH BISA DIJUAL
                                       (gateway otomatis menyusul paralel)
```

Setelah tiga tahap pertama plus jalur transfer manual, fiturnya sudah menghasilkan
uang. Integrasi gateway, admin panel yang rapi, dan fitur premium baru bisa
dikerjakan sambil jalan.

---

## 6. Risiko yang sudah diketahui

| Risiko | Mitigasi |
|---|---|
| Play Billing menolak pembayaran pihak ketiga | Checkout di browser eksternal, bukan WebView |
| Peluncuran terbaca "fitur dirampas" | Grandfather permanen + lencana "Pengguna Awal" + minimal 1 fitur premium yang benar-benar baru |
| Paket gratis terlalu murah hati | Jaga batas 1 cabang. Itu yang tersisa sebagai pembeda utama |
| Webhook dobel → paket diperpanjang 2× | `subscription_payments.order_id` unique |
| Cron mati diam-diam → tagihan tidak jalan | Penanda `storage/framework/scheduler_last_run`; pemantauan otomatis dibangun di Tahap 4 |
