const bridge = @import("bridge_memory");

pub const Permissions = struct {
    pub const read: u8 = 1 << 0;
    pub const write: u8 = 1 << 1;
    pub const execute: u8 = 1 << 2;
};

pub fn classify(addr: u64, width: u8, sp: u64) struct {
    permissions: u8,
    region: bridge.MemoryRegionKind,
    null_page: bool,
    guard_page: bool,
    stack_access: bool,
    aligned: bool,
    stack_grows_down: bool,
} {
    const null_page = addr < 0x1000;
    const guard_page = sp >= 0x1000 and addr >= sp - 0x1000 and addr < sp;
    const stack_access = addr >= sp - 0x8000 and addr < sp + 0x1000;
    const aligned = switch (width) {
        2 => (addr & 0x1) == 0,
        4 => (addr & 0x3) == 0,
        8 => (addr & 0x7) == 0,
        16 => (addr & 0xF) == 0,
        else => true,
    };
    var region: bridge.MemoryRegionKind = .data;
    if (null_page) region = .null_page else if (guard_page) region = .guard else if (stack_access) region = .stack;
    var perms: u8 = Permissions.read | Permissions.write | Permissions.execute;
    if (null_page) perms = 0;
    if (stack_access) perms = Permissions.read | Permissions.write;
    return .{
        .permissions = perms,
        .region = region,
        .null_page = null_page,
        .guard_page = guard_page,
        .stack_access = stack_access,
        .aligned = aligned,
        .stack_grows_down = true,
    };
}
