pub const HostCallingConvention = enum(u8) {
    darwin_aapcs64 = 1,
    lowered_guest = 2,
    windows_arm64ec = 3,
};

pub const HostSignalKind = enum(u8) {
    none = 0,
    sigill = 4,
    sigtrap = 5,
    sigabort = 6,
    sigfpe = 8,
    sigbus = 10,
    sigsegv = 11,
};

pub const HostState = struct {
    x: [31]u64 = [_]u64{0} ** 31,
    sp: u64 = 0,
    pc: u64 = 0,
    nzcv: u32 = 0,
    fpcr: u32 = 0,
    fpsr: u32 = 0,
    fp: [32]u128 = [_]u128{0} ** 32,
    page_size: u32 = 16384,
    memory_permissions: u8 = 0x7,
    cache_coherent: bool = true,
    generated_code_dirty: bool = false,
    call_boundary: bool = false,
    calling_convention: HostCallingConvention = .darwin_aapcs64,
    signal_kind: HostSignalKind = .none,
    signal_mapped_exception: u32 = 0,
};
