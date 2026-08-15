import os
import re
import json

dart_files = [
    r'd:\zenvi\frontend_pos\lib\screens\dashboard\owner_dashboard_screen.dart',
    r'd:\zenvi\frontend_pos\lib\screens\dashboard\employee_dashboard_screen.dart'
]

replacements = {
    "'Kelola Bisnis'": "'kelola_bisnis_501'.tr(context: context)",
    "'Eksplorasi Semua Fitur'": "'eksplorasi_semua_fitur_502'.tr(context: context)",
    "'Pusat Notifikasi'": "'pusat_notifikasi_503'.tr(context: context)",
    "'Kelola Cabang'": "'kelola_cabang_504'.tr(context: context)",
    "'Persetujuan Izin'": "'persetujuan_izin_505'.tr(context: context)",
    "'Reservasi'": "'reservasi_506'.tr(context: context)",
    "'Membership'": "'membership_507'.tr(context: context)",
    "'Performa'": "'performa_508'.tr(context: context)",
    "'Karyawan'": "'karyawan_509'.tr(context: context)",
    "'Produk'": "'produk_510'.tr(context: context)",
    "'Stok'": "'stok_511'.tr(context: context)",
    "'Log Transaksi'": "'log_transaksi_512'.tr(context: context)",
    "'Pengeluaran'": "'pengeluaran_513'.tr(context: context)",
    "'Shift Log'": "'shift_log_514'.tr(context: context)",
    "'KDS (Dapur)'": "'kds_dapur_515'.tr(context: context)",
}

for filepath in dart_files:
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        for k, v in replacements.items():
            content = content.replace(k, v)
            
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

# Update JSON
id_json_path = r'd:\zenvi\frontend_pos\assets\translations\id.json'
en_json_path = r'd:\zenvi\frontend_pos\assets\translations\en.json'

new_id = {
    "kelola_bisnis_501": "Kelola Bisnis",
    "eksplorasi_semua_fitur_502": "Eksplorasi Semua Fitur",
    "pusat_notifikasi_503": "Pusat Notifikasi",
    "kelola_cabang_504": "Kelola Cabang",
    "persetujuan_izin_505": "Persetujuan Izin",
    "reservasi_506": "Reservasi",
    "membership_507": "Membership",
    "performa_508": "Performa",
    "karyawan_509": "Karyawan",
    "produk_510": "Produk",
    "stok_511": "Stok",
    "log_transaksi_512": "Log Transaksi",
    "pengeluaran_513": "Pengeluaran",
    "shift_log_514": "Shift Log",
    "kds_dapur_515": "KDS (Dapur)"
}

new_en = {
    "kelola_bisnis_501": "Manage Business",
    "eksplorasi_semua_fitur_502": "Explore All Features",
    "pusat_notifikasi_503": "Notification Center",
    "kelola_cabang_504": "Manage Branches",
    "persetujuan_izin_505": "Permission Approvals",
    "reservasi_506": "Reservations",
    "membership_507": "Membership",
    "performa_508": "Performance",
    "karyawan_509": "Employees",
    "produk_510": "Products",
    "stok_511": "Stock",
    "log_transaksi_512": "Transaction Log",
    "pengeluaran_513": "Expenses",
    "shift_log_514": "Shift Log",
    "kds_dapur_515": "KDS (Kitchen)"
}

for json_path, new_data in [(id_json_path, new_id), (en_json_path, new_en)]:
    if os.path.exists(json_path):
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        data.update(new_data)
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=4)
