pub const Arch = enum {
    dos,
    x86,
    x64,
    arm64,
};

pub const Phase = enum {
    before_instruction,
    after_instruction,
    before_call,
    after_call,
    before_interrupt,
    after_interrupt,
    checkpoint,
};

pub const Scalar = struct {
    valid: bool = false,
    value: u64 = 0,
};

pub const SemanticRegisters = struct {
    result: Scalar = .{},
    arg0: Scalar = .{},
    arg1: Scalar = .{},
    arg2: Scalar = .{},
    arg3: Scalar = .{},
    stack: Scalar = .{},
    frame: Scalar = .{},
    counter: Scalar = .{},
    base: Scalar = .{},
    data: Scalar = .{},
    source: Scalar = .{},
    dest: Scalar = .{},
    instruction: Scalar = .{},
    flags: Scalar = .{},
    segment_cs: Scalar = .{},
    segment_ds: Scalar = .{},
    segment_es: Scalar = .{},
    segment_ss: Scalar = .{},
    fs_base: Scalar = .{},
    gs_base: Scalar = .{},
};

pub const Snapshot = struct {
    arch: Arch,
    phase: Phase,
    sequence: u64,
    scope: [64]u8 = [_]u8{0} ** 64,
    scope_len: u8 = 0,
    regs: SemanticRegisters = .{},
};

pub const Operation = struct {
    arch: Arch,
    sequence: u64,
    scope: [64]u8 = [_]u8{0} ** 64,
    scope_len: u8 = 0,
    opname: [48]u8 = [_]u8{0} ** 48,
    opname_len: u8 = 0,
    lhs: u64 = 0,
    rhs: u64 = 0,
    result: u64 = 0,
    width_bits: u16 = 0,
    flags_before: u64 = 0,
    flags_after: u64 = 0,
};

pub const MemoryAccess = enum {
    read,
    write,
};

pub const MemoryEvent = struct {
    arch: Arch,
    sequence: u64,
    scope: [64]u8 = [_]u8{0} ** 64,
    scope_len: u8 = 0,
    access: MemoryAccess = .read,
    address: u64 = 0,
    width_bytes: u8 = 0,
    value: u64 = 0,
};

pub const StackEvent = struct {
    arch: Arch,
    phase: Phase,
    sequence: u64,
    scope: [64]u8 = [_]u8{0} ** 64,
    scope_len: u8 = 0,
    sp: u64 = 0,
    fp: u64 = 0,
    alignment: u8 = 0,
    top0: Scalar = .{},
    top1: Scalar = .{},
    arg0: Scalar = .{},
    arg1: Scalar = .{},
    arg2: Scalar = .{},
    arg3: Scalar = .{},
};
