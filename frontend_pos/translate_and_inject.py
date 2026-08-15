import json
import os
import re
from deep_translator import GoogleTranslator

# 1. Load missing translations
with open(r'C:\Users\Hype\.gemini\antigravity\brain\719db2d4-5755-4e37-9644-a56d39464aa5\scratch\missing_translations.json', 'r', encoding='utf-8') as f:
    missing = json.load(f)

# 2. Translate to English
print(f'Translating {len(missing)} strings...')
translator = GoogleTranslator(source='id', target='en')
translated_en = {}
count = 0
for k, v in missing.items():
    try:
        translated_en[k] = translator.translate(v)
    except Exception as e:
        print(f"Error translating {v}: {e}")
        translated_en[k] = v
    count += 1
    if count % 50 == 0:
        print(f'Translated {count}/{len(missing)}')

# 3. Load existing en.json and id.json
id_path = r'd:\zenvi\frontend_pos\assets\translations\id.json'
en_path = r'd:\zenvi\frontend_pos\assets\translations\en.json'

with open(id_path, 'r', encoding='utf-8') as f:
    id_json = json.load(f)
with open(en_path, 'r', encoding='utf-8') as f:
    en_json = json.load(f)

# 4. Merge new keys
for k, v in missing.items():
    if k not in id_json:
        id_json[k] = v
    if k not in en_json:
        en_json[k] = translated_en[k]

with open(id_path, 'w', encoding='utf-8') as f:
    json.dump(id_json, f, indent=2, ensure_ascii=False)
with open(en_path, 'w', encoding='utf-8') as f:
    json.dump(en_json, f, indent=2, ensure_ascii=False)

print('Updated id.json and en.json')

# 5. Generate inject_tr.dart
dart_script = """import 'dart:io';
import 'dart:convert';

void main() {
  final dir = Directory('d:/zenvi/frontend_pos/lib');
  
  // Mapping original string -> key
  final Map<String, String> stringToKey = {
"""

for k, v in missing.items():
    escaped_v = v.replace('\\', '\\\\').replace("'", "\\'")
    dart_script += f"    '{escaped_v}': '{k}',\n"

dart_script += """  };

  int filesChanged = 0;
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = entity.readAsStringSync();
      bool changed = false;
      
      for (final entry in stringToKey.entries) {
        final val = entry.key;
        final key = entry.value;
        
        final r1 = "Text('${val}'";
        final r2 = 'Text("${val}"';
        final target1 = "Text('${key}'.tr(context: context)";
        final target2 = "Text('${key}'.tr(context: context)";
        
        if (content.contains(r1)) { content = content.replaceAll(r1, target1); changed = true; }
        if (content.contains(r2)) { content = content.replaceAll(r2, target2); changed = true; }
        
        final r3 = "Text('${val}',";
        final r4 = 'Text("${val}",';
        final target3 = "Text('${key}'.tr(context: context),";
        final target4 = "Text('${key}'.tr(context: context),";
        
        if (content.contains(r3)) { content = content.replaceAll(r3, target3); changed = true; }
        if (content.contains(r4)) { content = content.replaceAll(r4, target4); changed = true; }
        
        final r5 = "Text('${val}'))";
        final r6 = 'Text("${val}"))';
        final target5 = "Text('${key}'.tr(context: context)))";
        final target6 = "Text('${key}'.tr(context: context)))";
        
        if (content.contains(r5)) { content = content.replaceAll(r5, target5); changed = true; }
        if (content.contains(r6)) { content = content.replaceAll(r6, target6); changed = true; }
      }
      
      if (changed) {
        entity.writeAsStringSync(content);
        filesChanged++;
      }
    }
  }
  print('Injected .tr(context: context) into $filesChanged files.');
}
"""

with open(r'd:\zenvi\frontend_pos\inject_tr.dart', 'w', encoding='utf-8') as f:
    f.write(dart_script)

print('Generated inject_tr.dart')
