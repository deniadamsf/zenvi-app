import os
import re

files_to_fix = [
    r'd:\zenvi\frontend_pos\lib\screens\auth\company_setup_screen.dart',
    r'd:\zenvi\frontend_pos\lib\screens\auth\employee_register_screen.dart',
]

for file_path in files_to_fix:
    if os.path.exists(file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Fix const SnackBar
        content = re.sub(r'const\s+SnackBar\s*\((.*?\.tr\(.*?\).*?)\)', r'SnackBar(\1)', content, flags=re.DOTALL)
        
        # Fix const Center
        content = re.sub(r'const\s+Center\s*\((.*?\.tr\(.*?\).*?)\)', r'Center(\1)', content, flags=re.DOTALL)

        # Fix const Text that has .tr inside
        content = re.sub(r'const\s+Text\s*\((.*?\.tr\(.*?\).*?)\)', r'Text(\1)', content, flags=re.DOTALL)
        
        # Fix const AlertDialog
        content = re.sub(r'const\s+AlertDialog\s*\((.*?\.tr\(.*?\).*?)\)', r'AlertDialog(\1)', content, flags=re.DOTALL)

        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {file_path}")
    else:
        print(f"File not found: {file_path}")
