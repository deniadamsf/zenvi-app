import 'dart:convert';
import 'dart:io';

void main() {
  final keys = {
    'last_7_days': {'id': '7 Hari Terakhir', 'en': 'Last 7 Days'},
    'last_30_days': {'id': '30 Hari Terakhir', 'en': 'Last 30 Days'},
    'this_month': {'id': 'Bulan Ini', 'en': 'This Month'},
    'this_year': {'id': 'Tahun Ini', 'en': 'This Year'},
    'select_time': {'id': 'Pilih Waktu', 'en': 'Select Time'},
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

  // Update owner_dashboard_screen.dart
  final file = File('d:/zenvi/frontend_pos/lib/screens/dashboard/owner_dashboard_screen.dart');
  String content = file.readAsStringSync();

  final replacements = {
    "'7 Hari Terakhir'": "'last_7_days'.tr(context: context)",
    "'30 Hari Terakhir'": "'last_30_days'.tr(context: context)",
    "'Bulan Ini'": "'this_month'.tr(context: context)",
    "'Tahun Ini'": "'this_year'.tr(context: context)",
    "'Pilih Waktu'": "'select_time'.tr(context: context)",
  };

  for (final entry in replacements.entries) {
    content = content.replaceAll(entry.key, entry.value);
  }

  file.writeAsStringSync(content);
  print('Replaced more strings in owner_dashboard_screen.dart');
}
