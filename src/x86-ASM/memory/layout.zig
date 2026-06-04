const bridge = @import("bridge_memory");

pub const Permissions = struct {
    pub const read: u8 = 1 << 0;
    pub const write: u8 = 1 << 1;
    pub const execute: u8 = 1 << 2;
};

pub fn classify(addr: u32, width: u8, stack_pointer: u32) struct {
    permissions: u8,
    region: bridge.MemoryRegionKind,
    null_page: bool,
    guard_page: bool,
    stack_access: bool,
    aligned: bool,
    stack_grows_down: bool,
} {
    const guard_page = addr >= 0xFFF0_0000;
    const stack_low = stack_pointer -| 0x4000;
    const stack_high = stack_pointer + 0x1000;
    const stack_access = addr >= stack_low and addr < stack_high;
    const aligned = switch (width) {
        2 => (addr & 0x1) == 0,
        4 => (addr & 0x3) == 0,
        else => true,
    };
    var region: bridge.MemoryRegionKind = .data;
    if (guard_page) region = .guard else if (stack_access) region = .stack else if (addr < 0x10000) region = .code;
    var perms: u8 = Permissions.read | Permissions.write | Permissions.execute;
    if (region == .stack) perms = Permissions.read | Permissions.write;
    return .{
        .permissions = perms,
        .region = region,
        .null_page = false,
        .guard_page = guard_page,
        .stack_access = stack_access,
        .aligned = aligned,
        .stack_grows_down = true,
    };
}
