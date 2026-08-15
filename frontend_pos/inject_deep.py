import json
import os

with open('deep_missing.json', 'r', encoding='utf-8') as f:
    raw_data = json.load(f)

# Filter out SQL and translate to English
id_dict = {}
en_dict = {}

# Simple fallback translation
def translate_to_en(text):
    translations = {
        "Cabang": "Branch",
        "Unknown": "Unknown",
        "Notifikasi": "Notification",
        "Mulai percakapan": "Start conversation",
        "Sesi telah berakhir. Silakan login kembali.": "Session has expired. Please login again.",
        "Logout": "Logout",
        "Satu Langkah Lagi!": "One More Step!",
        "Buat nama perusahaan/toko Anda untuk mulai menggunakan Zenvi POS dan menikmati fitur seperti Chat, Cabang, dan Shift.": "Create your company/store name to start using Zenvi POS and enjoy features like Chat, Branch, and Shift.",
        "Nama Perusahaan": "Company Name",
        "Nama perusahaan tidak boleh kosong": "Company name cannot be empty",
        "Harap masukkan kode toko.": "Please enter store code.",
        "Karyawan": "Employee",
        "Owner": "Owner",
        "Employee": "Employee",
        "System will automatically detect your store status & access permissions.": "System will automatically detect your store status & access permissions.",
        "Toko": "Store",
        "Utama": "Main",
        "Keluar Akun": "Logout",
        "Menunggu Verifikasi Owner": "Waiting for Owner Verification",
        "Permohonan Anda sedang ditinjau oleh Owner toko. Begitu disetujui, Anda langsung dapat mulai bekerja.": "Your application is being reviewed by the store Owner. Once approved, you can start working immediately.",
        "Nama Karyawan": "Employee Name",
        "Toko / Perusahaan": "Store / Company",
        "Cabang Penempatan": "Branch Placement",
        "Status Akun": "Account Status",
        "Menunggu Persetujuan": "Waiting for Approval",
        "Memeriksa...": "Checking...",
        "Cek Status Persetujuan": "Check Approval Status",
        "Batalkan Pendaftaran / Ganti Toko": "Cancel Registration / Change Store",
        "Keluar / Ganti Akun": "Logout / Change Account",
        "Batal": "Cancel",
        "Keluar": "Exit",
        "Pengguna": "User",
        "Pesan Internal": "Internal Message",
        "Grup Karyawan & Obrolan Pribadi": "Employee Group & Private Chat",
        "Belum ada pesan": "No messages yet",
        "Chat": "Chat",
        "Manajemen Stok": "Stock Management",
        "Catat Pengeluaran": "Record Expense",
        "Menu Operasional": "Operational Menu",
        "Rp ": "Rp ",
        "Performa Karyawan": "Employee Performance",
        "Segarkan Data": "Refresh Data",
        "Kasir": "Cashier",
        "Staf Layanan": "Service Staff",
        "Dapur / Barista": "Kitchen / Barista",
        "Gudang": "Warehouse",
        "Kustom": "Custom",
        "Kapster / Terapis": "Stylist / Therapist",
        "Staff Dapur / Barista": "Kitchen / Barista Staff",
        "Staff Gudang": "Warehouse Staff",
        "Setujui & Tentukan Hak Akses": "Approve & Set Access Rights",
        "Kelola Hak Akses Karyawan": "Manage Employee Access Rights",
        "Jenis Pengeluaran": "Expense Type",
        "Pilih Bahan Baku": "Select Ingredient",
        "Nama Bahan (misal: Gula)": "Ingredient Name (e.g., Sugar)",
        "Satuan (misal: gram, ml, pcs)": "Unit (e.g., gram, ml, pcs)",
        "Stok Awal": "Initial Stock",
        "Toleransi Susut (%)": "Shrinkage Tolerance (%)",
        "Simpan": "Save",
        "Manajemen Bahan": "Ingredient Management",
        "Peringatan Indikasi Fraud!": "Fraud Indication Warning!",
        "Catat Pengeluaran Baru": "Record New Expense",
        "Catat biaya operasional, gaji, atau order bahan": "Record operational costs, salary, or material orders",
        "Toko Saya": "My Store",
        "OWNER PORTAL": "OWNER PORTAL",
        "Log Kasir & Shift": "Cashier & Shift Log",
        "Lihat Semua": "See All",
        "Belum ada shift kasir yang tercatat pada rentang ini.": "No cashier shifts recorded in this range.",
        "Daftar Produk": "Product List",
        "Belum ada produk": "No products yet",
        "Tambahkan produk untuk mulai berjualan": "Add products to start selling",
        "Tanpa Kategori": "Uncategorized",
        "Log Shift Karyawan": "Employee Shift Log",
        "Refresh": "Refresh",
        "Belum Ada Data Shift": "No Shift Data",
        "Riwayat buka dan tutup shift kasir akan tercatat secara otomatis di sini.": "Cashier shift opening and closing history will be automatically recorded here.",
        "HH:mm": "HH:mm",
        "EEEE, dd MMM yyyy": "EEEE, dd MMM yyyy",
        "SEDANG AKTIF": "CURRENTLY ACTIVE",
        "OTOMATIS TUTUP": "AUTO CLOSED",
        "SELESAI": "COMPLETED",
        "Waktu Shift": "Shift Time",
        "Sekarang": "Now",
        "Pelanggan": "Customer",
        "Membership": "Membership",
        "Daftar Member": "Member List",
        "Promo Member": "Member Promo",
        "Nama Lengkap *": "Full Name *",
        "Misal: Budi Santoso": "e.g., John Doe",
        "No. WhatsApp / HP *": "WhatsApp / Phone No. *",
        "Misal: 08123456789": "e.g., 08123456789",
        "Email (opsional)": "Email (optional)",
        "Alamat (opsional)": "Address (optional)",
        "Diskon Khusus Member (%)": "Special Member Discount (%)",
        "Catatan (opsional)": "Notes (optional)",
        "Pusat Notifikasi": "Notification Center",
        "Baca Semua": "Read All",
        "Semua": "All",
        "Shift": "Shift",
        "Stok Rendah": "Low Stock",
        "Cuti / Izin": "Leave / Permission",
        "Reservasi": "Reservation",
        "Persetujuan Izin": "Permission Approval",
        "Misal: Rina Wijaya": "e.g., Jane Doe",
        "Gagal menambahkan member.": "Failed to add member.",
        "Mendaftarkan...": "Registering...",
        "Simpan & Pilih Member": "Save & Select Member",
        "Cari member...": "Search member...",
        "Device": "Device",
        "Terhubung": "Connected",
        "Terputus": "Disconnected",
        "Unknown Device": "Unknown Device",
        "Tunai (Cash)": "Cash",
        "QRIS": "QRIS",
        "Transfer": "Transfer",
        "Total Tagihan": "Total Bill",
        "Kelola Cabang": "Manage Branches",
        "Toko Belum Dinamai": "Unnamed Store",
        "ZNV-8829": "ZNV-8829",
        "Shift Pagi": "Morning Shift",
        "Nama Shift (misal: Shift Pagi)": "Shift Name (e.g., Morning Shift)",
        "Mulai (HH:mm)": "Start (HH:mm)",
        "Selesai (HH:mm)": "End (HH:mm)",
        "Pembayaran Kasir": "Cashier Payment",
        "Metode Pembayaran": "Payment Method",
        "Tunai (Cash) selalu aktif secara default. Aktifkan QRIS / Transfer sesuai kebutuhan toko.": "Cash is always active by default. Enable QRIS / Transfer as needed for the store.",
        "Indonesia": "Indonesia",
        "English": "English",
        "GPS tidak aktif. Harap nyalakan GPS/Lokasi.": "GPS is inactive. Please turn on GPS/Location.",
        "Izin lokasi ditolak": "Location permission denied",
        "Izin lokasi ditolak secara permanen. Buka pengaturan aplikasi.": "Location permission permanently denied. Open app settings.",
        "Debug Mode: Lokasi Bypass Aktif!": "Debug Mode: Location Bypass Active!",
        "Lokasi valid! Anda berada di area cabang.": "Valid location! You are in the branch area.",
        "Total Harga Beli Awal (Rp)": "Total Initial Purchase Price (Rp)"
    }
    return translations.get(text, text)

for key, text in raw_data.items():
    if 'ALTER TABLE' in text:
        continue
    
    id_dict[key] = text
    en_dict[key] = translate_to_en(text)

with open(r'd:\zenvi\frontend_pos\assets\translations\id.json', 'r', encoding='utf-8') as f:
    existing_id = json.load(f)
    
with open(r'd:\zenvi\frontend_pos\assets\translations\en.json', 'r', encoding='utf-8') as f:
    existing_en = json.load(f)

existing_id.update(id_dict)
existing_en.update(en_dict)

with open(r'd:\zenvi\frontend_pos\assets\translations\id.json', 'w', encoding='utf-8') as f:
    json.dump(existing_id, f, indent=4, ensure_ascii=False)

with open(r'd:\zenvi\frontend_pos\assets\translations\en.json', 'w', encoding='utf-8') as f:
    json.dump(existing_en, f, indent=4, ensure_ascii=False)

print("Translations updated successfully.")

# Now replace in Dart files
import glob

def replace_in_files():
    dart_files = glob.glob(r'd:\zenvi\frontend_pos\lib\**\*.dart', recursive=True)
    replacements = 0
    
    for filepath in dart_files:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        modified = False
        for key, text in id_dict.items():
            # Match the exact string with single quotes
            pattern = f"'{text}'"
            replacement = f"'{key}'.tr(context: context)"
            if pattern in content:
                # Basic context check:
                # If 'context' isn't imported or in scope, .tr() won't compile if it uses context: context
                # However, all our widgets usually have context.
                content = content.replace(pattern, replacement)
                modified = True
                replacements += 1
                
        if modified:
            # We must make sure easy_localization is imported!
            if 'package:easy_localization/easy_localization.dart' not in content:
                # insert after first import
                content = content.replace("import '", "import 'package:easy_localization/easy_localization.dart';\nimport '", 1)
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
                
    print(f"Replaced {replacements} strings in Dart files.")

replace_in_files()
