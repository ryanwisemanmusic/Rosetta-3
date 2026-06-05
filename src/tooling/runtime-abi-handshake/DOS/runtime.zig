const common = @import("../common.zig");

pub const AccessKind = enum { read, write };

pub fn init() void {
    common.acquire();
}

pub fn deinit() void {
    common.release();
}

pub fn validateSession(phase: []const u8, memory_len: usize, cs: u16, ip: u16, ss: u16, sp: u16, flags_raw: u16) void {
    common.noteValidation();
    const cs_ip = (((@as(u32, cs) << 4) + @as(u32, ip)) & 0xFFFFF);
    const ss_sp = (((@as(u32, ss) << 4) + @as(u32, sp)) & 0xFFFFF);
    if (cs_ip >= memory_len)
        common.violation("dos", "cs_ip_range", "{s}: CS:IP 0x{x}:0x{x} -> 0x{x} outside {d}", .{ phase, cs, ip, cs_ip, memory_len });
    if (ss_sp >= memory_len)
        common.violation("dos", "ss_sp_range", "{s}: SS:SP 0x{x}:0x{x} -> 0x{x} outside {d}", .{ phase, ss, sp, ss_sp, memory_len });
    if ((flags_raw & 0x0002) == 0)
        common.violation("dos", "flags_reserved1", "{s}: FLAGS bit1 cleared (raw=0x{x})", .{ phase, flags_raw });
}

pub fn validateMemoryAccess(kind: AccessKind, memory_len: usize, segment: u16, offset: u16, width: usize) void {
    common.noteValidation();
    const physical = (((@as(u32, segment) << 4) + @as(u32, offset)) & 0xFFFFF);
    if (physical + width > memory_len)
        common.violation("dos", "memory_range", "{s} at {x:0>4}:{x:0>4} -> 0x{x} width {d} exceeds memory {d}", .{ @tagName(kind), segment, offset, physical, width, memory_len });
}

pub fn validateMemorySemantics(kind: AccessKind, physical: u32, width: usize, permissions: u8, aligned: bool, null_page: bool, stack_access: bool, wraparound: bool, region_kind: []const u8) void {
    common.noteValidation();
    if (null_page and kind != .read)
        common.violation("dos", "null_page", "{s} at 0x{x} touched DOS null page", .{ @tagName(kind), physical });
    if (!aligned)
        common.violation("dos", "unaligned_access", "{s} at 0x{x} width {d} unaligned", .{ @tagName(kind), physical, width });
    const need_bit: u8 = switch (kind) {
        .read => 1 << 0,
        .write => 1 << 1,
    };
    if ((permissions & need_bit) == 0)
        common.violation("dos", "page_permissions", "{s} at 0x{x} width {d} denied by perms 0x{x} in {s}", .{ @tagName(kind), physical, width, permissions, region_kind });
    _ = stack_access;
    _ = wraparound;
}

pub fn validateLoad(kind: []const u8, memory_len: usize, psp_segment: u16, load_segment: u16, entry_cs: u16, entry_ip: u16, stack_ss: u16, stack_sp: u16) void {
    common.noteValidation();
    const psp_base = (((@as(u32, psp_segment) << 4)) & 0xFFFFF);
    const entry = (((@as(u32, entry_cs) << 4) + @as(u32, entry_ip)) & 0xFFFFF);
    const stack = (((@as(u32, stack_ss) << 4) + @as(u32, stack_sp)) & 0xFFFFF);
    if (psp_base + 256 > memory_len)
        common.violation("dos", "psp_range", "{s}: PSP segment 0x{x} exceeds memory {d}", .{ kind, psp_segment, memory_len });
    if (load_segment < psp_segment)
        common.violation("dos", "load_segment", "{s}: load segment 0x{x} precedes PSP segment 0x{x}", .{ kind, load_segment, psp_segment });
    if (entry >= memory_len)
        common.violation("dos", "entry_range", "{s}: entry CS:IP 0x{x}:0x{x} -> 0x{x} outside memory {d}", .{ kind, entry_cs, entry_ip, entry, memory_len });
    if (stack >= memory_len)
        common.violation("dos", "stack_range", "{s}: stack SS:SP 0x{x}:0x{x} -> 0x{x} outside memory {d}", .{ kind, stack_ss, stack_sp, stack, memory_len });
}

pub fn validateInterrupt(vector: u8, ah: u8, al: u8) void {
    common.noteValidation();
    switch (vector) {
        0x10, 0x15, 0x16, 0x1A, 0x20, 0x21, 0x33 => {},
        else => common.violation("dos", "interrupt_vector", "unexpected interrupt vector 0x{x} (AH=0x{x}, AL=0x{x})", .{ vector, ah, al }),
    }
}

pub fn validateDosMemoryMap(memory_len: usize, ivt_base: usize, bda_base: usize, vga_text_base: usize) void {
    common.noteValidation();
    if (ivt_base != 0)
        common.violation("dos", "ivt_base", "IVT must start at physical 0x00000, saw 0x{x}", .{ivt_base});
    if (bda_base != 0x400)
        common.violation("dos", "bda_base", "BDA must start at physical 0x00400, saw 0x{x}", .{bda_base});
    if (vga_text_base != 0xB8000)
        common.violation("dos", "vga_text_base", "VGA text memory must start at 0xB8000, saw 0x{x}", .{vga_text_base});
    if (memory_len <= vga_text_base + 0x1000)
        common.violation("dos", "memory_map", "memory size {d} too small for VGA text region", .{memory_len});
}

pub fn validatePsp(memory_len: usize, psp_segment: u16, env_segment: u16, command_tail_len: u8, dta_segment: u16, dta_offset: u16, int20_lo: u8, int20_hi: u8) void {
    common.noteValidation();
    const psp_base = (((@as(u32, psp_segment) << 4)) & 0xFFFFF);
    const env_base = (((@as(u32, env_segment) << 4)) & 0xFFFFF);
    const dta_base = (((@as(u32, dta_segment) << 4) + @as(u32, dta_offset)) & 0xFFFFF);
    if (psp_base + 256 > memory_len)
        common.violation("dos", "psp_bounds", "PSP segment 0x{x} exceeds memory {d}", .{ psp_segment, memory_len });
    if (int20_lo != 0xCD or int20_hi != 0x20)
        common.violation("dos", "psp_int20", "PSP entry opcode expected CD 20, saw {x:0>2} {x:0>2}", .{ int20_lo, int20_hi });
    if (command_tail_len > 126)
        common.violation("dos", "psp_cmdtail", "command tail length {d} exceeds DOS PSP max 126", .{command_tail_len});
    if (env_segment != 0 and env_base >= memory_len)
        common.violation("dos", "psp_env", "environment segment 0x{x} -> 0x{x} outside memory {d}", .{ env_segment, env_base, memory_len });
    if (dta_base >= memory_len)
        common.violation("dos", "psp_dta", "DTA {x:0>4}:{x:0>4} -> 0x{x} outside memory {d}", .{ dta_segment, dta_offset, dta_base, memory_len });
}

pub fn validateMzLoad(memory_len: usize, load_segment: u16, image_size: usize, relocation_count: u16, relocation_table_offset: u16, entry_cs: u16, entry_ip: u16, stack_ss: u16, stack_sp: u16) void {
    common.noteValidation();
    const load_base = (((@as(u32, load_segment) << 4)) & 0xFFFFF);
    const entry = (((@as(u32, entry_cs) << 4) + @as(u32, entry_ip)) & 0xFFFFF);
    const stack = (((@as(u32, stack_ss) << 4) + @as(u32, stack_sp)) & 0xFFFFF);
    if (load_base + image_size > memory_len)
        common.violation("dos", "mz_image_range", "MZ image at segment 0x{x} size {d} exceeds memory {d}", .{ load_segment, image_size, memory_len });
    if (relocation_count != 0 and relocation_table_offset < 0x1C)
        common.violation("dos", "mz_reloc_table", "MZ relocation table offset 0x{x} invalid for relocation count {d}", .{ relocation_table_offset, relocation_count });
    if (entry >= memory_len)
        common.violation("dos", "mz_entry_range", "MZ entry CS:IP 0x{x}:0x{x} -> 0x{x} outside memory {d}", .{ entry_cs, entry_ip, entry, memory_len });
    if (stack >= memory_len)
        common.violation("dos", "mz_stack_range", "MZ stack SS:SP 0x{x}:0x{x} -> 0x{x} outside memory {d}", .{ stack_ss, stack_sp, stack, memory_len });
}

pub fn validateVideoService(ah: u8, al: u8, row: u8, col: u8, page: u8) void {
    common.noteValidation();
    switch (ah) {
        0x00, 0x01, 0x02, 0x03, 0x06, 0x09, 0x0E, 0x0F => {},
        else => common.violation("dos", "video_service", "unsupported INT 10h AH=0x{x} AL=0x{x}", .{ ah, al }),
    }
    if (row >= 50)
        common.violation("dos", "video_row", "cursor row {d} outside expected text range", .{row});
    if (col >= 160)
        common.violation("dos", "video_col", "cursor col {d} outside expected text range", .{col});
    _ = page;
}

pub fn validateKeyboardService(ah: u8, ascii: u8, scan: u8, zf: bool) void {
    common.noteValidation();
    switch (ah) {
        0x00, 0x01 => {},
        else => common.violation("dos", "keyboard_service", "unsupported INT 16h AH=0x{x}", .{ah}),
    }
    if (ah == 0x01 and zf and (ascii != 0 or scan != 0))
        common.violation("dos", "keyboard_peek", "INT 16h AH=01 signaled empty buffer but returned ascii=0x{x} scan=0x{x}", .{ ascii, scan });
}

pub fn validateTimerService(ah: u8, cx: u16, dx: u16) void {
    common.noteValidation();
    switch (ah) {
        0x00, 0x01 => {},
        else => common.violation("dos", "timer_service", "unsupported INT 1Ah AH=0x{x}", .{ah}),
    }
    _ = cx;
    _ = dx;
}

pub fn validateMouseService(ax: u16, bx: u16, cx: u16, dx: u16) void {
    common.noteValidation();
    switch (ax) {
        0x0000, 0x0003 => {},
        else => common.violation("dos", "mouse_service", "unsupported INT 33h AX=0x{x}", .{ax}),
    }
    _ = bx;
    _ = cx;
    _ = dx;
}

pub fn validateDosFunction(ah: u8, al: u8, ds: u16, dx: u16) void {
    common.noteValidation();
    switch (ah) {
        0x09, 0x0A, 0x1A, 0x2C, 0x4C => {},
        else => common.violation("dos", "dos_function", "unsupported INT 21h AH=0x{x} AL=0x{x}", .{ ah, al }),
    }
    _ = ds;
    _ = dx;
}
