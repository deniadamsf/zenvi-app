import 'dart:convert';
import 'dart:io';

void main() {
  final keys = {
    'financial_summary': {'id': 'Ringkasan Finansial', 'en': 'Financial Summary'},
    'all_branches': {'id': 'Semua Cabang', 'en': 'All Branches'},
    'today': {'id': 'Hari Ini', 'en': 'Today'},
    'net_profit': {'id': 'Keuntungan Bersih', 'en': 'Net Profit'},
    'margin': {'id': 'Margin {}%', 'en': 'Margin {}%'},
    'gross_revenue': {'id': 'Total Omzet (Kotor)', 'en': 'Gross Revenue'},
    'orders_count': {'id': '{} Pesanan', 'en': '{} Orders'},
    'total_expense': {'id': 'Total Pengeluaran', 'en': 'Total Expenses'},
    'average_order_value': {'id': 'Rata-rata Order (AOV)', 'en': 'Average Order Value (AOV)'},
    'per_transaction': {'id': 'Per Transaksi', 'en': 'Per Transaction'}
  };

  for (final lang in ['id', 'en']) {
    final file = File('d:/zenvi/frontend_pos/assets/translations/$lang.json');
    final jsonStr = file.readAsStringSync();
    final Map<String, dynamic> data = json.decode(jsonStr);
    
    for (final entry in keys.entries) {
      data[entry.key] = entry.value[lang];
    }
    
    file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
    print('Updated $lang.json');
  }
}
