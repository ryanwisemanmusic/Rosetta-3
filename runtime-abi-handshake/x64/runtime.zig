const common = @import("../common.zig");

pub fn init() void {
    common.acquire();
}

pub fn deinit() void {
    common.release();
}

pub fn validateState(phase: []const u8, rip: u64, rsp: u64, rflags: u64, fs_base: u64, gs_base: u64) void {
    common.noteValidation();
    if ((rflags & 0x2) == 0)
        common.violation("x64", "rflags_reserved1", "{s}: RFLAGS bit1 cleared (raw=0x{x})", .{ phase, rflags });
    if ((rsp & 0xF) != 0)
        common.violation("x64", "stack_alignment", "{s}: RSP 0x{x} is not 16-byte aligned", .{ phase, rsp });
    if (rip == 0)
        common.violation("x64", "rip_zero", "{s}: RIP is zero", .{phase});
    if (fs_base == 0 and gs_base == 0)
        common.violation("x64", "segment_bases", "{s}: FS/GS bases are both zero", .{phase});
}

pub fn validateAddressing(ip_after_decode: u64, computed: u64) void {
    common.noteValidation();
    if (computed == 0)
        common.violation("x64", "address_zero", "computed x64 address is zero (RIP after decode 0x{x})", .{ip_after_decode});
}
