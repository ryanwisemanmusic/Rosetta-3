import re
import sys

def translate(asm_path, zig_path):
    with open(asm_path, 'r') as f:
        lines = f.readlines()

    out = []
    out.append('const std = @import("std");')
    out.append('const reg_map = @import("register_mapping.zig");')
    out.append('const Register = reg_map.Register;')
    out.append('const Executor = @import("instruction_operations.zig").Executor;')
    out.append('const abi = @import("abi_handshake.zig");')
    out.append('')
    out.append('pub export fn rosetta3_run_snax86() void {')
    out.append('    const allocator = std.heap.page_allocator;')
    out.append('    var ex = Executor.init(allocator, 1024 * 1024);')
    out.append('    defer ex.deinit();')
    out.append('    ex.regs.esp = 0x100000; // 1MB stack top')
    out.append('    abi.register_snake_thunks(&ex);')
    out.append('')
    
    # Simple data section handling
    data_addr = 0x2000
    equs = {}
    
    current_section = None
    
    for line in lines:
        line = line.strip()
        if not line or line.startswith(';'): continue
        
        # Handle section
        m = re.match(r'section\s+\.(data|text)', line)
        if m:
            current_section = m.group(1)
            continue
            
        # Handle EQU
        m = re.match(r'(\w+)\s+equ\s+(.*)', line)
        if m:
            name, val = m.group(1), m.group(2)
            # Try to evaluate simple math
            try:
                val = eval(val.replace('H', '0x').replace('h', '0x').replace('$', '0')) # crude
            except:
                pass
            equs[name] = val
            continue

        if current_section == 'data':
            # Handle db/dw/dd
            m = re.match(r'(\w+)\s+(db|dw|dd|times)\s+(.*)', line)
            if m:
                name, size, val = m.group(1), m.group(2), m.group(3)
                out.append(f'    // Data: {name} at 0x{data_addr:x}')
                out.append(f'    ex.labels.put("{name}", 0x{data_addr:x}) catch unreachable;')
                if size == 'db':
                    if val.startswith('"'):
                        s = val.strip('"')
                        for char in s:
                            out.append(f'    ex.mem.write8(0x{data_addr:x}, {ord(char)});')
                            data_addr += 1
                    else:
                        out.append(f'    ex.mem.write8(0x{data_addr:x}, {val});')
                        data_addr += 1
                elif size == 'dw':
                    out.append(f'    ex.mem.write16(0x{data_addr:x}, {val});')
                    data_addr += 2
                elif size == 'dd':
                    out.append(f'    ex.mem.write32(0x{data_addr:x}, {val});')
                    data_addr += 4
                continue

    out.append('')
    out.append('    // Entry point')
    out.append('    _main(&ex);')
    out.append('}')
    out.append('')

    # Translate functions
    current_func = None
    for line in lines:
        line = line.split(';')[0].strip()
        if not line: continue
        
        # Labels
        m = re.match(r'^(\w+):', line)
        if m:
            name = m.group(1)
            if current_func:
                out.append('}')
            current_func = name
            out.append(f'fn {name}(ex: *Executor) void {{')
            continue
        
        if not current_func: continue
        
        # Instructions (very crude mapping)
        parts = re.split(r'[\s,]+', line)
        inst = parts[0].lower()
        args = parts[1:]
        
        if inst == 'call':
            target = args[0]
            if target.startswith('_'):
                out.append(f'    ex.call_external("{target}");')
            else:
                out.append(f'    {target}(ex);')
        elif inst == 'mov':
            dst, src = args[0], args[1]
            if dst in ['eax', 'ebx', 'ecx', 'edx', 'esi', 'edi', 'ebp', 'esp']:
                if src.isdigit() or src.startswith('0x'):
                    out.append(f'    ex.mov_reg_imm(.{dst}, {src});')
                elif src in ['eax', 'ebx', 'ecx', 'edx', 'esi', 'edi', 'ebp', 'esp']:
                    out.append(f'    ex.mov_reg_reg(.{dst}, .{src});')
        elif inst == 'ret':
            out.append('    return;')

    if current_func:
        out.append('}')

    with open(zig_path, 'w') as f:
        f.write('\n'.join(out))

if __name__ == '__main__':
    translate(sys.argv[1], sys.argv[2])
