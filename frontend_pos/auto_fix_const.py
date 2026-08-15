import os
import re
from collections import defaultdict

def fix_const_errors(output_file):
    if not os.path.exists(output_file):
        print(f"File {output_file} not found.")
        return

    with open(output_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # Group errors by file
    errors_by_file = defaultdict(list)
    for line in lines:
        line = line.strip()
        if 'CONST_EVAL_METHOD_INVOCATION' in line or 'CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE' in line or 'NON_CONSTANT_LIST_ELEMENT' in line or 'CONST_CONSTRUCTOR_PARAM' in line or 'CONST_WITH_NON_CONSTANT_ARGUMENT' in line:
            parts = line.split('|')
            if len(parts) > 6:
                filepath = parts[3]
                line_num = int(parts[4])
                errors_by_file[filepath].append(line_num)
                
        # Handle arguments of const constructor not being const
        if 'CONST_WITH_NON_CONSTANT_ARGUMENT' in line:
            parts = line.split('|')
            if len(parts) > 6:
                filepath = parts[3]
                line_num = int(parts[4])
                errors_by_file[filepath].append(line_num)

    fixed_files = 0
    for filepath, line_nums in errors_by_file.items():
        if not os.path.exists(filepath):
            continue
            
        with open(filepath, 'r', encoding='utf-8') as f:
            content_lines = f.readlines()
            
        modified = False
        
        # Sort line numbers descending so we don't mess up indices if we add/remove lines (we won't add/remove, just replace)
        for line_num in sorted(set(line_nums), reverse=True):
            idx = line_num - 1
            if idx >= len(content_lines):
                continue
                
            # Scan backwards from the error line to find the nearest 'const '
            # and remove it.
            found_const = False
            for i in range(idx, max(-1, idx - 15), -1):
                if 'const ' in content_lines[i]:
                    # Remove the LAST 'const ' in that line (closest to the error)
                    # Use rsplit to replace only the last occurrence
                    parts = content_lines[i].rsplit('const ', 1)
                    content_lines[i] = ''.join(parts)
                    modified = True
                    found_const = True
                    break
                    
            if not found_const:
                # try again up to 30 lines
                for i in range(max(-1, idx - 15), max(-1, idx - 30), -1):
                    if 'const ' in content_lines[i]:
                        parts = content_lines[i].rsplit('const ', 1)
                        content_lines[i] = ''.join(parts)
                        modified = True
                        found_const = True
                        break

        if modified:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.writelines(content_lines)
            fixed_files += 1

    print(f"Fixed const errors in {fixed_files} files.")

if __name__ == "__main__":
    fix_const_errors('analyze_output.txt')
