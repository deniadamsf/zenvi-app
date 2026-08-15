import 'dart:io';

void main() {
  final dir = Directory('d:/zenvi/frontend_pos/lib');
  final regex = RegExp(r"Text\(\s*'([^']+)'\s*(?:,|\))");
  int totalMatches = 0;

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      final matches = regex.allMatches(content);
      if (matches.isNotEmpty) {
        print('${entity.path.split('\\').last}:');
        for (final m in matches) {
          final text = m.group(1)!;
          if (!text.contains('.tr')) {
            print('  - $text');
            totalMatches++;
          }
        }
      }
    }
  }
  print('Total hardcoded Text strings: $totalMatches');
}
