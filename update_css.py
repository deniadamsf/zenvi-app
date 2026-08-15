import re

file_path = r"d:\zenvi\backend\resources\views\menu\digital_menu.blade.php"

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Change font-family
content = re.sub(
    r"font-family: 'Plus Jakarta Sans', -apple-system", 
    "font-family: 'Outfit', -apple-system", 
    content
)

# Let's adjust root variables
content = re.sub(r"--radius-xl:\s*\d+px;", "--radius-xl: 24px;", content)
content = re.sub(r"--radius-lg:\s*\d+px;", "--radius-lg: 24px;", content)
content = re.sub(r"--radius-md:\s*\d+px;", "--radius-md: 20px;", content)
content = re.sub(r"--radius-sm:\s*\d+px;", "--radius-sm: 16px;", content)

# General border-radius replacements
content = re.sub(r"border-radius:\s*1[68]px;", "border-radius: 24px;", content)
content = re.sub(r"border-radius:\s*12px;", "border-radius: 20px;", content)
content = re.sub(r"border-radius:\s*8px;", "border-radius: 16px;", content)
content = re.sub(r"border-radius:\s*20px;", "border-radius: 24px;", content)

# Hero banner
content = re.sub(
    r"\.hero-banner\s*\{[^}]*\}",
    ".hero-banner {\n            position: relative;\n            background: linear-gradient(135deg, rgba(4, 120, 87, 0.8) 0%, rgba(5, 150, 105, 0.8) 40%, rgba(16, 185, 129, 0.8) 100%);\n            backdrop-filter: blur(12px);\n            -webkit-backdrop-filter: blur(12px);\n            color: #ffffff;\n            padding: 36px 16px 48px;\n            border-bottom-left-radius: 28px;\n            border-bottom-right-radius: 28px;\n            box-shadow: 0 20px 25px -5px rgba(5, 150, 105, 0.28);\n            overflow: hidden;\n            border-bottom: 1px solid rgba(255, 255, 255, 0.2);\n        }",
    content
)

# Product card
content = re.sub(
    r"\.product-card\s*\{[^}]*\}",
    ".product-card {\n            display: flex;\n            gap: 14px;\n            padding: 14px;\n            background: rgba(255, 255, 255, 0.65);\n            backdrop-filter: blur(16px);\n            -webkit-backdrop-filter: blur(16px);\n            border-radius: var(--radius-lg);\n            border: 1px solid rgba(255, 255, 255, 0.5);\n            box-shadow: var(--shadow-sm);\n            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);\n            position: relative;\n            overflow: hidden;\n        }",
    content
)

# Dark mode replacements for .product-card
content = re.sub(
    r"(\@media\s*\(prefers-color-scheme:\s*dark\)\s*\{[\s\S]*?\.product-card\s*\{)[\s\S]*?(\})",
    r"\1\n                background: rgba(19, 27, 46, 0.6);\n                backdrop-filter: blur(16px);\n                -webkit-backdrop-filter: blur(16px);\n                border: 1px solid rgba(255, 255, 255, 0.08);\n            \2",
    content
)

# Search bar
content = re.sub(
    r"\.search-input\s*\{[^}]*\}",
    ".search-input {\n            width: 100%;\n            padding: 14px 16px 14px 44px;\n            background: rgba(255, 255, 255, 0.7);\n            backdrop-filter: blur(12px);\n            -webkit-backdrop-filter: blur(12px);\n            border: 1px solid rgba(255, 255, 255, 0.5);\n            border-radius: var(--radius-xl);\n            font-family: inherit;\n            font-size: 15px;\n            color: var(--text-main);\n            outline: none;\n            box-shadow: var(--shadow-sm);\n            transition: all 0.3s ease;\n        }",
    content
)

# Bottom Nav bar
content = re.sub(
    r"\.bottom-nav\s*\{[^}]*\}",
    ".bottom-nav {\n            position: fixed;\n            bottom: 0;\n            left: 0;\n            right: 0;\n            background: rgba(255, 255, 255, 0.85);\n            backdrop-filter: blur(20px);\n            -webkit-backdrop-filter: blur(20px);\n            border-top: 1px solid rgba(255, 255, 255, 0.5);\n            display: flex;\n            justify-content: space-around;\n            padding: 12px 16px;\n            padding-bottom: calc(12px + env(safe-area-inset-bottom));\n            z-index: 50;\n            box-shadow: 0 -4px 20px rgba(0,0,0,0.04);\n        }",
    content
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done updating digital menu CSS via Python.')
