const std = @import("std");
const x64_state = @import("x64_state.zig");

pub const CallingConvention64 = enum {
    microsoft_x64,
    sysv_x64,
};

pub const ConventionProfile64 = struct {
    convention: CallingConvention64,
    integer_arg_registers: []const x64_state.Register64,
    stack_alignment: u8,
    shadow_space_bytes: u8,
    red_zone_bytes: u8,
};

pub const microsoft_x64 = ConventionProfile64{
    .convention = .microsoft_x64,
    .integer_arg_registers = &[_]x64_state.Register64{ .rcx, .rdx, .r8, .r9 },
    .stack_alignment = 16,
    .shadow_space_bytes = 32,
    .red_zone_bytes = 0,
};

pub const sysv_x64 = ConventionProfile64{
    .convention = .sysv_x64,
    .integer_arg_registers = &[_]x64_state.Register64{ .rdi, .rsi, .rdx, .rcx, .r8, .r9 },
    .stack_alignment = 16,
    .shadow_space_bytes = 0,
    .red_zone_bytes = 128,
};

test "calling convention profiles distinguish microsoft and sysv" {
    try std.testing.expectEqual(@as(usize, 4), microsoft_x64.integer_arg_registers.len);
    try std.testing.expectEqual(@as(u8, 32), microsoft_x64.shadow_space_bytes);
    try std.testing.expectEqual(@as(u8, 128), sysv_x64.red_zone_bytes);
}
