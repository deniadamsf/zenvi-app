import os
import re
from collections import defaultdict

def scan_directory(directory):
    hardcoded_strings = []
    
    # Regex to find single quoted strings: 'something'
    # We ignore strings that are keys (e.g. before a colon) or already have .tr()
    # This is a naive regex for estimation.
    string_pattern = re.compile(r"'([^'\$]+)'")
    
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                    
                # Remove strings that already have .tr(
                clean_content = re.sub(r"'[^']+'\.tr\b", "", content)
                
                # Find all remaining strings
                matches = string_pattern.findall(clean_content)
                
                for match in matches:
                    # Filter out obvious non-display strings (like IDs, short paths, empty strings, pure numbers, snake_case)
                    if len(match) > 2 and re.search(r'[a-zA-Z]', match) and ' ' in match and not '_' in match:
                        hardcoded_strings.append((file, match))
                        
    return hardcoded_strings

directory = r'd:\zenvi\frontend_pos\lib\screens'
strings = scan_directory(directory)

print(f"Found {len(strings)} potential hardcoded UI strings across {len(set(f for f, s in strings))} files.")
print("Sample:")
for f, s in strings[:20]:
    print(f" - {f}: '{s}'")
