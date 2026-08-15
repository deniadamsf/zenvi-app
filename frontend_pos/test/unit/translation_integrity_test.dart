import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Translation Integrity & Completeness Test', () {
    test('id.json and en.json should have matching keys and valid JSON', () async {
      final idFile = File('assets/translations/id.json');
      final enFile = File('assets/translations/en.json');

      expect(idFile.existsSync(), isTrue, reason: 'id.json must exist');
      expect(enFile.existsSync(), isTrue, reason: 'en.json must exist');

      final idContent = await idFile.readAsString();
      final enContent = await enFile.readAsString();

      Map<String, dynamic> idMap = {};
      Map<String, dynamic> enMap = {};

      expect(() => idMap = jsonDecode(idContent), returnsNormally, reason: 'id.json must be valid JSON');
      expect(() => enMap = jsonDecode(enContent), returnsNormally, reason: 'en.json must be valid JSON');

      final idKeys = idMap.keys.toSet();
      final enKeys = enMap.keys.toSet();

      final missingInEn = idKeys.difference(enKeys);
      final missingInId = enKeys.difference(idKeys);

      expect(missingInEn, isEmpty, reason: 'Keys in id.json but missing in en.json: $missingInEn');
      expect(missingInId, isEmpty, reason: 'Keys in en.json but missing in id.json: $missingInId');

      // Verify no empty values
      for (final entry in idMap.entries) {
        expect(entry.value.toString().trim().isNotEmpty, isTrue, reason: 'Empty translation in id.json for key "${entry.key}"');
      }
      for (final entry in enMap.entries) {
        expect(entry.value.toString().trim().isNotEmpty, isTrue, reason: 'Empty translation in en.json for key "${entry.key}"');
      }
    });
  });
}
