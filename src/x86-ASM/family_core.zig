const std = @import("std");

pub const ExecutionMode = enum {
    ia32,
    x64,
};

pub const OperandWidth = enum(u16) {
    byte = 8,
    word = 16,
    dword = 32,
    qword = 64,
    tbyte = 80,
    xmmword = 128,
    ymmword = 256,

    pub fn bytes(self: OperandWidth) usize {
        return @intFromEnum(self) / 8;
    }
};

pub const Signedness = enum {
    unsigned,
    signed,
};

pub const ExtensionKind = enum {
    none,
    zero,
    sign,
};

pub const InstructionFamily = enum {
    data_movement,
    arithmetic,
    logical,
    shift_rotate,
    multiply_divide,
    compare_test,
    control_flow,
    stack,
    string,
    floating_point,
    simd,
    system,
    runtime,
};

pub const OperandKind = enum {
    register,
    immediate,
    memory,
    relative,
    segment,
    instruction_pointer,
};

pub const AddressForm = enum {
    direct,
    register,
    indirect,
    indexed,
    base_index_scale_disp,
    rip_relative,
};

pub const PrefixKind = enum {
    lock,
    rep,
    repe,
    repne,
    operand_size_override,
    address_size_override,
    segment_override,
    rex,
};

pub const FlagMask = packed struct(u16) {
    cf: bool = false,
    pf: bool = false,
    af: bool = false,
    zf: bool = false,
    sf: bool = false,
    tf: bool = false,
    if_: bool = false,
    df: bool = false,
    of: bool = false,
    reserved: u7 = 0,
};

pub const ModeCapabilities = struct {
    mode: ExecutionMode,
    gpr_width: OperandWidth,
    stack_width: OperandWidth,
    ip_width: OperandWidth,
    has_rex: bool,
    has_rip_relative: bool,
    uses_flat_long_mode: bool,
};

pub fn capabilitiesFor(mode: ExecutionMode) ModeCapabilities {
    return switch (mode) {
        .ia32 => .{
            .mode = .ia32,
            .gpr_width = .dword,
            .stack_width = .dword,
            .ip_width = .dword,
            .has_rex = false,
            .has_rip_relative = false,
            .uses_flat_long_mode = false,
        },
        .x64 => .{
            .mode = .x64,
            .gpr_width = .qword,
            .stack_width = .qword,
            .ip_width = .qword,
            .has_rex = true,
            .has_rip_relative = true,
            .uses_flat_long_mode = true,
        },
    };
}

test "mode capabilities reflect ia32 and x64" {
    const ia32 = capabilitiesFor(.ia32);
    try std.testing.expectEqual(OperandWidth.dword, ia32.gpr_width);
    try std.testing.expect(!ia32.has_rex);

    const x64 = capabilitiesFor(.x64);
    try std.testing.expectEqual(OperandWidth.qword, x64.gpr_width);
    try std.testing.expect(x64.has_rip_relative);
}
