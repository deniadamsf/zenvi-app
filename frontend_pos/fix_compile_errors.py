import os

def fix_chat_provider():
    p = r'd:\zenvi\frontend_pos\lib\providers\chat_provider.dart'
    with open(p, 'r', encoding='utf-8') as f:
        c = f.read()
    c = c.replace("this.lastMessage = 'mulai_percakapan_16'.tr(),", "this.lastMessage = 'Mulai Percakapan',")
    c = c.replace("lastMessage: json['last_message'] ?? 'mulai_percakapan_16'.tr(),", "lastMessage: json['last_message'] ?? 'Mulai Percakapan',")
    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)

def fix_login_screen():
    p = r'd:\zenvi\frontend_pos\lib\screens\auth\login_screen.dart'
    with open(p, 'r', encoding='utf-8') as f:
        c = f.read()
    c = c.replace("const RoleSelectionScreen()", "RoleSelectionScreen()")
    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)

def fix_pending_approval():
    p = r'd:\zenvi\frontend_pos\lib\screens\auth\pending_approval_screen.dart'
    with open(p, 'r', encoding='utf-8') as f:
        c = f.read()
    c = c.replace("const RoleSelectionScreen()", "RoleSelectionScreen()")
    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)

def fix_settings_screen():
    p = r'd:\zenvi\frontend_pos\lib\screens\settings\settings_screen.dart'
    with open(p, 'r', encoding='utf-8') as f:
        c = f.read()
    c = c.replace("const EmployeeSettingsScreen()", "EmployeeSettingsScreen()")
    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)

def fix_employee_verification():
    p = r'd:\zenvi\frontend_pos\lib\screens\dashboard\employee_verification_screen.dart'
    with open(p, 'r', encoding='utf-8') as f:
        c = f.read()
    
    # We need to replace the switch with if-else
    # Let's just find the switch and replace it
    import re
    # The code looks like:
    # switch (selectedRole) {
    #   case 'kasir_5'.tr(context: context): ...
    #   case 'staf_layanan_12'.tr(context: context): ...
    #   case 'dapur_barista_15'.tr(context: context): ...
    #   case 'gudang_6'.tr(context: context): ...
    #   case 'kustom_6'.tr(context: context): ...
    # }
    
    # It's easier to just use standard strings for the logic, wait, selectedRole is generated from the dropdown which uses tr().
    # So we change the switch to if-else.
    
    # Let's do a simple regex replacement for the cases.
    switch_block = re.search(r'switch\s*\([^\)]+\)\s*\{[^\}]+\}', c)
    if switch_block:
        block = switch_block.group(0)
        new_block = block.replace("switch (selectedRole) {", "")
        new_block = new_block.replace("}", "")
        
        lines = new_block.split("\n")
        out_lines = []
        is_first = True
        for line in lines:
            if "case" in line and ".tr(context: context):" in line:
                cond = line.split("case")[1].split(":")[0].strip()
                if is_first:
                    out_lines.append(f"if (selectedRole == {cond}) {{")
                    is_first = False
                else:
                    out_lines.append(f"}} else if (selectedRole == {cond}) {{")
            elif "break;" in line:
                pass # skip breaks
            else:
                out_lines.append(line)
        out_lines.append("}")
        
        c = c.replace(block, "\n".join(out_lines))
        
        with open(p, 'w', encoding='utf-8') as f:
            f.write(c)
    
fix_chat_provider()
fix_login_screen()
fix_pending_approval()
fix_settings_screen()
fix_employee_verification()
