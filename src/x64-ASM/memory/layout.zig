const bridge = @import("bridge_memory");

pub const Permissions = struct {
    pub const read: u8 = 1 << 0;
    pub const write: u8 = 1 << 1;
    pub const execute: u8 = 1 << 2;
};

pub fn isCanonical(addr: u64) bool {
    const sign = (addr >> 47) & 1;
    const upper = addr >> 48;
    return if (sign == 0) upper == 0 else upper == 0xFFFF;
}

pub fn classify(addr: u64, width: u8, stack_pointer: u64) struct {
    permissions: u8,
    region: bridge.MemoryRegionKind,
    null_page: bool,
    guard_page: bool,
    stack_access: bool,
    aligned: bool,
    canonical: bool,
    stack_grows_down: bool,
} {
    const null_page = addr < 0x1000;
    const canonical = isCanonical(addr);
    const guard_page = stack_pointer >= 0x1000 and addr >= stack_pointer - 0x1000 and addr < stack_pointer;
    const stack_access = addr >= stack_pointer - 0x8000 and addr < stack_pointer + 0x1000;
    const aligned = switch (width) {
        2 => (addr & 0x1) == 0,
        4 => (addr & 0x3) == 0,
        8 => (addr & 0x7) == 0,
        16 => (addr & 0xF) == 0,
        else => true,
    };
    var region: bridge.MemoryRegionKind = .data;
    if (null_page) region = .null_page else if (guard_page) region = .guard else if (stack_access) region = .stack else if (addr >= 0x1400_0000 and addr < 0x1800_0000) region = .pe_section;
    var perms: u8 = Permissions.read | Permissions.write;
    if (region == .pe_section) perms |= Permissions.execute;
    if (null_page or !canonical) perms = 0;
    return .{
        .permissions = perms,
        .region = region,
        .null_page = null_page,
        .guard_page = guard_page,
        .stack_access = stack_access,
        .aligned = aligned,
        .canonical = canonical,
        .stack_grows_down = true,
    };
}
