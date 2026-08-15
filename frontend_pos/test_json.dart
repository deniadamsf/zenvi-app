import 'dart:convert';
import 'dart:io';

void main() {
  try {
    final idStr = File('d:/zenvi/frontend_pos/assets/translations/id.json').readAsStringSync();
    final idJson = json.decode(idStr);
    print('id.json is valid, keys: ${idJson.length}');
  } catch(e) {
    print('id.json error: $e');
  }

  try {
    final enStr = File('d:/zenvi/frontend_pos/assets/translations/en.json').readAsStringSync();
    final enJson = json.decode(enStr);
    print('en.json is valid, keys: ${enJson.length}');
  } catch(e) {
    print('en.json error: $e');
  }
}
