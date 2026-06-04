const bridge = @import("bridge_memory");

pub const Permissions = struct {
    pub const read: u8 = 1 << 0;
    pub const write: u8 = 1 << 1;
    pub const execute: u8 = 1 << 2;
};

pub fn classify(physical: u32, width: u8, stack_physical: u32, wrapped: bool) struct {
    permissions: u8,
    region: bridge.MemoryRegionKind,
    null_page: bool,
    guard_page: bool,
    stack_access: bool,
    aligned: bool,
    wraparound: bool,
    stack_grows_down: bool,
} {
    const null_page = physical == 0;
    const vga = physical >= 0xB8000 and physical < 0xBC000;
    const bda = physical >= 0x400 and physical < 0x500;
    const ivt = physical < 0x400;
    const mmio = vga or bda or ivt;
    const stack_access = physical >= stack_physical -| 0x2000 and physical < stack_physical + 0x100;
    const aligned = switch (width) {
        2 => (physical & 0x1) == 0,
        else => true,
    };
    var region: bridge.MemoryRegionKind = .data;
    if (null_page) region = .null_page else if (vga) region = .vga else if (mmio) region = .mmio else if (stack_access) region = .stack else if (physical < 0x10000) region = .code;
    var perms: u8 = Permissions.read | Permissions.write;
    if (region == .code) perms |= Permissions.execute;
    if (vga) perms = Permissions.read | Permissions.write;
    return .{
        .permissions = perms,
        .region = region,
        .null_page = null_page,
        .guard_page = false,
        .stack_access = stack_access,
        .aligned = aligned,
        .wraparound = wrapped,
        .stack_grows_down = true,
    };
}
