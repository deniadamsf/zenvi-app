import os
import glob
import re

directories = [
    r'd:\zenvi\frontend_pos\lib\models',
    r'd:\zenvi\frontend_pos\lib\providers',
    r'd:\zenvi\frontend_pos\lib\services'
]

for d in directories:
    for filepath in glob.glob(d + r'\**\*.dart', recursive=True):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        if '.tr(context: context)' in content:
            content = content.replace('.tr(context: context)', '.tr()')
            if 'package:easy_localization/easy_localization.dart' not in content:
                content = "import 'package:easy_localization/easy_localization.dart';\n" + content
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
                
# Also fix main.dart CONST_WITH_NON_CONST
main_file = r'd:\zenvi\frontend_pos\lib\main.dart'
with open(main_file, 'r', encoding='utf-8') as f:
    main_content = f.read()
# if we stripped const from a widget in main.dart but the constructor requires const (or vice versa),
# Actually CONST_WITH_NON_CONST means `const SomeWidget(...)` but one of its children is no longer const.
# We can just remove the `const ` modifier from the parent widget in main.dart.
main_content = main_content.replace('const RoleSelectionScreen()', 'RoleSelectionScreen()')
main_content = main_content.replace('const PendingApprovalScreen()', 'PendingApprovalScreen()')
with open(main_file, 'w', encoding='utf-8') as f:
    f.write(main_content)
