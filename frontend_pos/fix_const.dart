import 'dart:io';

void main() {
  final dir = Directory('d:/zenvi/frontend_pos/lib');
  int filesChanged = 0;
  
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = entity.readAsStringSync();
      
      // We want to find `const Text('...'.tr(context: context)`
      // and replace with `Text('...'.tr(context: context)`
      // Same for const EdgeInsets if we messed it up? No, only Text.
      
      final regex = RegExp(r"const\s+Text\(([^)]+\.tr\(context:\s*context\)[^)]*)\)");
      if (regex.hasMatch(content)) {
        content = content.replaceAllMapped(regex, (match) {
          return "Text(${match.group(1)})";
        });
        entity.writeAsStringSync(content);
        filesChanged++;
      }
    }
  }
  print('Fixed const Text in $filesChanged files.');
}
