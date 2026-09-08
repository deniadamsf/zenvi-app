<!--
  AGENTS.md — aturan kerja proyek Zenvi untuk agent coding apa pun.
  File inilah SATU-SATUNYA salinan isi aturan. `CLAUDE.md` dan `GEMINI.md`
  hanya penunjuk pendek ke sini, supaya tidak ada dua/tiga salinan yang bisa
  melenceng diam-diam — kalau ada banyak salinan, salah satu pasti basi dan
  tidak ada yang memberi tahu.

  Dibaca oleh: Gemini Antigravity, Gemini CLI, Codex, Cursor (AGENTS.md),
  dan Claude Code (lewat @AGENTS.md di CLAUDE.md).
-->

# Zenvi — Aturan Pengembangan & Auto-Deployment (untuk semua agent coding)

> **Baca ini dulu sebelum menulis kode apa pun di repo ini.**
> Ini bukan panduan gaya yang boleh ditawar. Sebagian besar aturannya lahir
> dari masalah nyata yang sudah pernah terjadi di proyek ini, dan alasannya
> ditulis di tempatnya masing-masing. Kalau sebuah aturan terasa merepotkan,
> baca dulu alasan di sub-section-nya sebelum memutuskan melanggarnya.

## Cara memakai dokumen ini

- **Section 1** — deploy backend ke Hostinger. Wajib dijalankan tiap kali file
  backend berubah, bukan "nanti kalau sempat".
- **Section 2–3** — gerbang mutu frontend Flutter (analyze bersih + i18n).
- **Section 4** — git commit & push otomatis.
- **Section 5** — pembagian kerja & pemilihan model saat mendelegasikan tugas.

**Semua perubahan aturan ditulis di berkas ini**, bukan di `CLAUDE.md` atau
`GEMINI.md`. Kalau kamu (agent mana pun, termasuk Antigravity) perlu mengubah
aturan, edit `AGENTS.md` — dua berkas lain tidak perlu disentuh.

## Bagian yang penyebutannya khusus per-tool

Sebagian aturan menyebut nama peralatan Claude Code (subagent, nama model).
Kalau dikerjakan dengan agent lain, **isi aturannya tetap berlaku, cara
menjalankannya yang menyesuaikan**:

| Bagian | Isinya | Padanan di agent lain |
|---|---|---|
| §5 | Delegasi otomatis ke subagent + tingkatan model | Antigravity punya mekanisme agent/task sendiri; kalau tidak ada, kerjakan sendiri tapi **jangan lewati gate-nya** — deploy backend (§1), `flutter analyze` bersih (§2), dan verifikasi kunci i18n (§3) tetap wajib sebelum sesuatu dianggap selesai |

Yang **tidak boleh** dibuang saat berpindah agent adalah gate-nya, bukan
mekanismenya.

## Berkas pendamping

- `RENCANA_LANGGANAN.md` — desain paket langganan & gating.
- `zenvi-antigravity-blueprint.md` — blueprint arsitektur.
- `.agents/rules/flutter_ui_guidelines.md` — panduan UI Flutter.

---

## 1. Wajib Sinkron ke Database & Backend Live Hostinger

Setiap kali ada perubahan pada backend (Laravel) baik berupa:
- Model (`app/Models/*.php`)
- Migration (`database/migrations/*.php`)
- Controller (`app/Http/Controllers/**/*.php`)
- View Blade (`resources/views/**/*.blade.php`)
- Route (`routes/api.php`, `routes/web.php`)
- Konfigurasi lainnya

**WAJIB HUKUMNYA** untuk langsung mengunggah file-file tersebut ke server
Hostinger via SSH/SCP dan menjalankan migrasi database serta pembersihan cache
secara otomatis!

### Parameter Akses SSH Hostinger
- **Host / IP:** `153.92.8.198` (atau gunakan host `hostinger` jika terkonfigurasi di `~/.ssh/config`)
- **Port:** `65002`
- **Username:** `u731410318`
- **Identity File:** `C:\Users\Hype\.ssh\id_rsa`
- **Remote Directory:** `/home/u731410318/domains/cellanoma.my.id/public_html/zenvi/api`

### Alur Eksekusi Wajib
1. **Upload File Backend (SCP):**
   ```bash
   scp -P 65002 -i ~/.ssh/id_rsa backend/path/to/file u731410318@153.92.8.198:/home/u731410318/domains/cellanoma.my.id/public_html/zenvi/api/path/to/
   ```
2. **Jalankan Migrasi & Bangun Ulang Cache (SSH):**
   ```bash
   ssh -p 65002 -i ~/.ssh/id_rsa u731410318@153.92.8.198 "cd /home/u731410318/domains/cellanoma.my.id/public_html/zenvi/api && php artisan migrate --force && php artisan config:cache && php artisan route:cache"
   ```
   > **JANGAN pakai `php artisan optimize:clear` sendirian.** Perintah itu menghapus config & route cache dan tidak pernah membangunnya kembali, sehingga Laravel mem-parsing ulang seluruh config dan route di SETIAP request (~0,4 detik tambahan per request di shared hosting). Selalu akhiri deploy dengan `config:cache && route:cache`.
   >
   > Konsekuensi `config:cache`: `env()` di luar folder `config/` **selalu mengembalikan null**. Kalau butuh nilai dari `.env` di controller/service/model, daftarkan dulu di `config/*.php` lalu baca dengan `config('...')`. Jangan pernah panggil `env()` langsung di luar `config/`.
   >
   > Konsekuensi `route:cache`: route berbentuk closure tidak bisa di-cache. Pakai `Route::view()` untuk halaman statis, atau controller — jangan mendaftarkan route dengan closure sebagai handler.
3. Pastikan permission folder upload selalu siap:
   ```bash
   ssh -p 65002 -i ~/.ssh/id_rsa u731410318@153.92.8.198 "mkdir -p /home/u731410318/domains/cellanoma.my.id/public_html/zenvi/api/public/uploads/logos && chmod -R 775 /home/u731410318/domains/cellanoma.my.id/public_html/zenvi/api/public/uploads"
   ```

## 2. Kualitas Kode Frontend
- Jalankan `dart analyze` / `flutter analyze` untuk memastikan tidak ada compile errors.

## 3. Wajib Multi-Bahasa / Easy Localization (i18n)
- Setiap kali membuat atau mengedit tampilan UI di frontend Flutter, **DILARANG KERAS** menggunakan teks *hardcoded* (baik bahasa Indonesia maupun Inggris secara langsung).
- **WAJIB** menggunakan `easy_localization` dengan ekstensi `.tr(context: context)` atau `.tr()`.
- Semua key terjemahan baru wajib didaftarkan secara lengkap dan sinkron di kedua file:
  - `frontend_pos/assets/translations/id.json` (Bahasa Indonesia)
  - `frontend_pos/assets/translations/en.json` (Bahasa Inggris)
- Jika saat proses pengeditan/pengecekan menemukan string yang masih *hardcoded* atau belum multibahasa, maka **wajib langsung diubah ke Easy Localization**.
- **`flutter analyze` tidak menangkap kunci `.tr()` yang belum terdaftar di JSON** — kunci hilang baru ketahuan sebagai teks mentah di layar saat runtime. Jadi sebelum commit, cocokkan sendiri daftar kunci baru di kode dengan isi `id.json` **dan** `en.json`.

## 4. Wajib Git Version Control Otomatis
- Setiap kali selesai melakukan perbaikan bug, penambahan fitur, atau modifikasi file di Zenvi, **WAJIB** membuat Git commit otomatis dengan format pesan deskriptif (Conventional Commits: `feat(...)`, `fix(...)`, `refactor(...)`, dll).
- Jika remote repository (`origin`) sudah terhubung, lakukan `git push origin <branch>` secara otomatis agar backup kode selalu up-to-date.

## 5. Delegasi Agent & Pemilihan Model (Wajib, Otomatis)

Sesi utama selalu jalan dengan model tertinggi sebagai **orkestrator**.
Pemilihan model untuk sub-agent DAN keputusan mendelegasikan tugas **wajib
dilakukan otomatis oleh AI itu sendiri** berdasarkan kriteria di bawah —
**JANGAN tanya/konfirmasi ke user dulu** ("mau pakai model apa?", "boleh saya
delegasikan?"). Ini keputusan teknis/eksekusi, bukan keputusan berisiko yang
butuh izin; user sudah memberi izin berdiri untuk project ini.

### 5.1 Gate mutu yang tidak boleh hilang

Bagian ini **tetap wajib** walau mekanisme subagent tidak tersedia di tool yang
sedang dipakai. Yang menulis kode cenderung tidak melihat kesalahannya
sendiri, jadi implementasi dan pemeriksaan tetap **dua langkah terpisah** —
bukan satu langkah yang sama.

1. **Setelah menulis/mengubah kode backend Laravel**, periksa ulang: file yang
   berubah benar-benar sudah ter-upload ke Hostinger (§1), migrasi jalan,
   deploy diakhiri `config:cache && route:cache`, tidak ada `env()` di luar
   `config/`, dan tidak ada route berbentuk closure.
2. **Setelah mengubah UI Flutter**, scan: tidak ada string hardcoded (§3),
   semua kunci `.tr()` baru sudah ada di `id.json` **dan** `en.json`, dan
   `flutter analyze` bersih (§2).

### 5.2 Tingkatan model

| Jenis kerja | Di Claude Code | Di Gemini Antigravity |
|---|---|---|
| Reasoning inti, perencanaan, keputusan arsitektur/desain, review korektnes | Opus 5 (orkestrator) | Gemini 3.1 Pro (High), atau Claude Opus 4.6 |
| Implementasi rutin: modul Laravel / layar Flutter, eksplorasi multi-file, code review | Sonnet 5 (default sub-agent) | **Gemini 3.8 Flash (High)** |
| Kerja mekanis: cari lokasi file/simbol (grep/glob), scan drift UI & i18n, ringkasan singkat, validasi format | Haiku 4.5 | **Gemini 3.8 Flash (normal)** |

> Padanan model Antigravity di atas adalah keputusan pemilik proyek
> (8 September 2026), disamakan dengan project Rajaku Printing.

Mode penalarannya bagian dari keputusan, bukan detail bebas. Implementasi
memakai **High** karena aturan §1–§3 harus ditimbang sambil menulis kode; scan
drift memakai mode **normal** karena kerjanya mencocokkan pola teks —
menaikkan mode di situ hanya menambah biaya tanpa menambah temuan.

Untuk pekerjaan yang salahnya berakibat nyata — apa pun yang menyentuh auth,
uang/langganan, atau migration — pakai model tier atas untuk **review**-nya
walaupun implementasinya memakai tier menengah.

**Pembagian model = strategi biaya**, jangan diubah tanpa alasan. Jangan pakai
tier atas untuk kerja mekanis: itu hanya menambah biaya & latensi tanpa
manfaat.

### 5.3 Kapan BOLEH delegasi
- Riset terbuka yang butuh lebih dari ±3 kali pencarian/pembacaan file dan hasilnya perlu dirangkum.
- Implementasi multi-file yang aturannya sudah tertulis jelas di dokumen ini.
- Task independen yang bisa jalan paralel dengan pekerjaan lain di sesi utama (mis. perubahan backend + perubahan UI yang tidak saling bergantung — boleh dua panggilan sekaligus; gate review-nya menyusul setelah keduanya selesai).

### 5.4 Kapan TIDAK usah delegasi
Kerjakan langsung di sesi utama pakai Glob/Grep/Read kalau:
- Lokasi file/simbol bisa ditemukan dengan 1–3 kali panggilan Glob/Grep langsung — spawn agent di sini hanya menambah latensi start-up dan agent harus menurunkan ulang konteks yang sudah diketahui sesi utama.
- Edit satu baris, jawab pertanyaan soal kode yang sudah ada di context, baca 1 file, atau jalankan 1 perintah git/deploy.
- Sub-agent sebelumnya gagal/terputus di tengah jalan: **jangan** retry dengan agent besar yang sama. Turun dulu ke pencarian langsung (Grep/Glob/Read) sebelum mempertimbangkan spawn ulang.

### 5.5 Batas sub-agent
Sub-agent mulai dari context kosong — kirim brief yang berdiri sendiri (path
file, nama modul, endpoint/layar yang terlibat, hasil yang diharapkan). Jangan
asumsikan dia tahu isi percakapan sebelumnya. Sub-agent juga tidak bisa
memanggil sub-agent lain.

### 5.6 Instruksi konkret untuk Claude Code
Tool `Agent`, parameter `model` — semua dilakukan otomatis tanpa bertanya:
- Default `sonnet` untuk task delegasi multi-step biasa.
- Set eksplisit `haiku` untuk lookup/pencarian sederhana yang jelas polanya.
- Set eksplisit `opus` hanya kalau task benar-benar butuh reasoning setara orkestrator dan tidak bisa dikerjakan langsung di sesi utama.
- Sebelum spawn agent apa pun untuk "mencari file/kode", coba dulu Glob/Grep langsung.
- Aturan ini **override** default "jangan panggil Agent tool kecuali diminta".
