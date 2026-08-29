# GEMINI.md - Development & Auto-Deployment Rules for Zenvi

## 1. Mandatory Hostinger Live Database & Backend Synchronization
Setiap kali ada perubahan pada backend (Laravel) baik berupa:
- Model (`app/Models/*.php`)
- Migration (`database/migrations/*.php`)
- Controller (`app/Http/Controllers/**/*.php`)
- View Blade (`resources/views/**/*.blade.php`)
- Route (`routes/api.php`, `routes/web.php`)
- Konfigurasi lainnya

**WAJIB HUKUMNYA** untuk langsung mengunggah file-file tersebut ke server Hostinger via SSH/SCP dan menjalankan migrasi database serta pembersihan cache secara otomatis!

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
   > Konsekuensi `route:cache`: route berbentuk closure tidak bisa di-cache. Pakai `Route::view()` untuk halaman statis, atau controller — jangan `Route::get('/x', function () { ... })`.
3. Pastikan permission folder upload selalu siap:
   ```bash
   ssh -p 65002 -i ~/.ssh/id_rsa u731410318@153.92.8.198 "mkdir -p /home/u731410318/domains/cellanoma.my.id/public_html/zenvi/api/public/uploads/logos && chmod -R 775 /home/u731410318/domains/cellanoma.my.id/public_html/zenvi/api/public/uploads"
   ```

## 2. Frontend Code Quality
- Jalankan `dart analyze` / `flutter analyze` untuk memastikan tidak ada compile errors.

## 3. Mandatory Multi-Language / Easy Localization (i18n)
- Setiap kali membuat atau mengedit tampilan UI di frontend Flutter, **DILARANG KERAS** menggunakan teks *hardcoded* (baik bahasa Indonesia maupun Inggris secara langsung).
- **WAJIB** menggunakan `easy_localization` dengan ekstensi `.tr(context: context)` atau `.tr()`.
- Semua key terjemahan baru wajib didaftarkan secara lengkap dan sinkron di kedua file:
  - `frontend_pos/assets/translations/id.json` (Bahasa Indonesia)
  - `frontend_pos/assets/translations/en.json` (Bahasa Inggris)
- Jika saat proses pengeditan/pengecekan menemukan string yang masih *hardcoded* atau belum multibahasa, maka **wajib langsung diubah ke Easy Localization**.

## 4. Mandatory Automated Git Version Control
- Setiap kali selesai melakukan perbaikan bug, penambahan fitur, atau modifikasi file di Zenvi, **WAJIB** membuat Git commit otomatis dengan format pesan deskriptif (Conventional Commits: `feat(...)`, `fix(...)`, `refactor(...)`, dll).
- Jika remote repository (`origin`) sudah terhubung, lakukan `git push origin <branch>` secara otomatis agar backup kode selalu up-to-date.

## 5. Aturan Pemilihan Model & Delegasi Sub-Agent OTOMATIS
Konteks: sesi utama selalu jalan dengan model tertinggi (**Opus 5**) sebagai orkestrator. Pemilihan model untuk sub-agent DAN keputusan mendelegasikan tugas ke sub-agent **wajib dilakukan otomatis oleh AI itu sendiri** berdasarkan kriteria di bawah — **JANGAN tanya/konfirmasi ke user dulu** ("mau pakai model apa?", "boleh saya delegasikan?"). AI langsung menilai kompleksitas & sifat tugas, lalu langsung pilih tingkatan model yang sesuai dan langsung spawn sub-agent kalau memang kriterianya terpenuhi — tanpa menunggu instruksi eksplisit dari user setiap kali.

**Tingkatan model:**
- **Opus 5 (orkestrator)** — tetap di sesi utama untuk reasoning inti, perencanaan, keputusan arsitektur/desain, dan sintesis akhir. Jangan didelegasikan ke sub-agent kecuali sub-task itu sendiri butuh reasoning berat yang tidak bisa diturunkan.
- **Sonnet 5 (default sub-agent)** — dipakai untuk delegasi multi-step: eksplorasi lintas banyak file, riset yang butuh sintesis, implementasi perubahan multi-file, code review. Kalau ragu tingkatan mana yang dipakai, pakai ini.
- **Haiku 4.5 (tugas ringan/mekanis)** — dipakai untuk pencarian lokasi file/simbol (grep/glob-style lookup), tugas bervolume tinggi tapi berpola jelas, ringkasan singkat, validasi format. Jangan pakai Opus/Sonnet untuk ini karena hanya menambah biaya & latensi tanpa manfaat.

**Kapan BOLEH spawn sub-agent:**
- Riset terbuka yang butuh lebih dari ±3 kali pencarian/pembacaan file dan hasilnya perlu dirangkum.
- Task yang independen dan bisa dikerjakan paralel dengan pekerjaan lain di sesi utama.

**Kapan TIDAK BOLEH spawn sub-agent (kerjakan langsung di sesi utama pakai Glob/Grep/Read):**
- Kalau lokasi file/simbol yang dicari bisa ditemukan dengan 1-3 kali panggilan Glob/Grep langsung — spawn agent di sini hanya menambah latensi start-up dan agent harus re-derive konteks yang sudah diketahui sesi utama.
- Kalau sub-agent sebelumnya gagal/terputus di tengah jalan: **jangan** retry dengan agent besar yang sama. Turun dulu ke pencarian langsung (Grep/Glob/Read) sebelum mempertimbangkan spawn ulang.

**Instruksi konkret untuk Claude Code** (tool `Agent`, parameter `model`) — semua ini dilakukan otomatis tanpa bertanya ke user:
- Default: `sonnet` untuk task delegasi multi-step biasa.
- Set eksplisit `haiku` untuk lookup/pencarian sederhana yang jelas polanya.
- Set eksplisit `opus` hanya kalau task benar-benar butuh reasoning setara orkestrator dan tidak bisa dikerjakan langsung di sesi utama.
- Sebelum spawn agent apa pun untuk "mencari file/kode", coba dulu Glob/Grep langsung — baru pertimbangkan delegasi kalau memang scope-nya luas.
- Kalau kriteria "BOLEH spawn sub-agent" di atas terpenuhi, langsung spawn dengan tingkatan model yang sesuai — tidak perlu minta izin user, karena ini murni keputusan teknis/eksekusi, bukan keputusan yang berdampak besar/berisiko.

> **Scope: bagian ini HANYA berlaku untuk Claude Code.** Nama model (Opus 5, Sonnet 5, Haiku 4.5) itu spesifik Anthropic/Claude — tidak ada padanannya di Gemini/Antigravity atau Codex, jadi seluruh Bagian 5 ini **tidak berlaku** saat mengerjakan project ini lewat Gemini/Antigravity atau Codex. Kalau tool tersebut punya mekanisme delegasi/sub-agent sendiri, ikuti konvensi native tool itu masing-masing, bukan tingkatan di atas.
