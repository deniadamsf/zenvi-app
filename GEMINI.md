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
2. **Jalankan Migrasi & Clear Cache (SSH):**
   ```bash
   ssh -p 65002 -i ~/.ssh/id_rsa u731410318@153.92.8.198 "cd /home/u731410318/domains/cellanoma.my.id/public_html/zenvi/api && php artisan migrate --force && php artisan optimize:clear"
   ```
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
