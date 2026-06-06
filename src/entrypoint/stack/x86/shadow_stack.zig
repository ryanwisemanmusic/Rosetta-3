const std = @import("std");
const common = @import("entrypoint_shadow_stack_common");
const builtin = @import("builtin");
const neon = @import("entrypoint_shadow_stack_neon");

pub const ShadowStackPlacement = common.ShadowStackPlacement;
pub const ShadowStackState = common.ShadowStackState;

pub fn init(memory: []u8, placement: ShadowStackPlacement) ShadowStackState {
    if (builtin.cpu.arch == .aarch64) {
        return neon.init(memory, placement);
    }
    return common.initShadowStack("entrypoint-x86-shadow-stack", memory, placement);
}

pub const push = common.pushEntry;
pub const pop = common.popEntry;
pub const peek = common.peekEntry;
pub const validate = common.validateEntry;

test "x86 shadow stack init dispatches correctly" {
    var memory = [_]u8{0xFF} ** 32;
    const placement = ShadowStackPlacement{
        .base = 8,
        .size = 16,
        .entry_size = 4,
    };
    const state = init(&memory, placement);
    try std.testing.expectEqual(@as(u64, 24), state.ssp);
    try std.testing.expectEqual(@as(u32, 0), state.depth);
    try std.testing.expectEqual(@as(u8, 0), memory[8]);
}

test "x86 shadow stack push and pop 4-byte" {
    var memory = [_]u8{0} ** 32;
    var state = init(&memory, .{
        .base = 8,
        .size = 16,
        .entry_size = 4,
    });
    push(&state, &memory, 0x1234);
    try std.testing.expectEqual(@as(u64, 0x1234), peek(&state, &memory));
    try std.testing.expectEqual(@as(u64, 0x1234), pop(&state, &memory));
    try std.testing.expectEqual(@as(u32, 0), state.depth);
}
