import 'dart:io';

void main() {
  final dir = Directory('d:/zenvi/frontend_pos/lib');
  int filesImported = 0;
  
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = entity.readAsStringSync();
      
      if (content.contains('.tr(context: context)') && !content.contains("import 'package:easy_localization/easy_localization.dart';")) {
        // Insert after the first import or at the top
        final importLine = "import 'package:easy_localization/easy_localization.dart';\n";
        if (content.startsWith('import ')) {
          content = importLine + content;
        } else {
          content = importLine + content;
        }
        entity.writeAsStringSync(content);
        filesImported++;
      }
    }
  }
  print('Added easy_localization import to $filesImported files.');
}
