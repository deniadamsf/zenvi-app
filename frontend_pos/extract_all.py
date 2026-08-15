import os
import re
import json

def generate_key(text):
    clean = re.sub(r'[^a-zA-Z0-9\s]', '', text.lower())
    words = clean.split()[:4]
    base = '_'.join(words)
    return base

def extract_strings(directory):
    extracted = {}
    
    # We want to match 'Something' but not strings that are already .tr()
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
                    if len(match) < 3:
                        continue
                    
                    if not match[0].isupper() and not match[0].isnumeric():
                        continue # Most UI strings start with uppercase
                    
                    if not re.search(r'[a-zA-Z]', match):
                        continue
                        
                    if match.startswith('/'):
                        continue
                        
                    if 'SELECT ' in match or 'INSERT ' in match or 'UPDATE ' in match:
                        continue # SQL
                        
                    if 'application/json' in match or 'Bearer ' in match:
                        continue # Network headers
                        
                    if '_' in match and ' ' not in match:
                        continue # snake_case keys
                        
                    # Accept it
                    key = generate_key(match)
                    key = f"{key}_{len(match)}"
                    if key not in extracted:
                        extracted[key] = match
                                
    return extracted

if __name__ == "__main__":
    directory = r'd:\zenvi\frontend_pos\lib'
    strings = extract_strings(directory)
    
    with open('deep_missing.json', 'w', encoding='utf-8') as f:
        json.dump(strings, f, indent=4, ensure_ascii=False)
        
    print(f"Extracted {len(strings)} strings to deep_missing.json")
