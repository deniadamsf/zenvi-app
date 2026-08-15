import 'dart:io';

void main() {
  final file = File('d:/zenvi/frontend_pos/lib/screens/dashboard/owner_dashboard_screen.dart');
  String content = file.readAsStringSync();

  final replacements = {
    "'Ringkasan Finansial'": "'financial_summary'.tr(context: context)",
    "'Semua Cabang'": "'all_branches'.tr(context: context)",
    "'Hari Ini'": "'today'.tr(context: context)",
    "'Keuntungan Bersih'": "'net_profit'.tr(context: context)",
    "'Total Omzet (Kotor)'": "'gross_revenue'.tr(context: context)",
    "'Total Pengeluaran'": "'total_expense'.tr(context: context)",
    "'Rata-rata Order (AOV)'": "'average_order_value'.tr(context: context)",
    "'Per Transaksi'": "'per_transaction'.tr(context: context)",
  };

  for (final entry in replacements.entries) {
    content = content.replaceAll(entry.key, entry.value);
  }

  // Also replace some complex strings that might be string interpolation
  // "0 Pesanan" -> "${reports['total_orders']} Pesanan" -> We can replace "' Pesanan'" with "' orders'.tr(context: context)"
  // Wait, let's just see if we can do basic replace first.
  content = content.replaceAll("' Pesanan'", " ' \${'orders'.tr(context: context)}'");

  file.writeAsStringSync(content);
  print('Replaced strings in owner_dashboard_screen.dart');
}
