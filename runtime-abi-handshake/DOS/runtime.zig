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
        0x10, 0x15, 0x16, 0x20, 0x21 => {},
        else => common.violation("dos", "interrupt_vector", "unexpected interrupt vector 0x{x} (AH=0x{x}, AL=0x{x})", .{ vector, ah, al }),
    }
}
