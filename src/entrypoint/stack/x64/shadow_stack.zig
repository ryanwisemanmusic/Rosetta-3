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
    return common.initShadowStack("entrypoint-x64-shadow-stack", memory, placement);
}

pub const push = common.pushEntry;
pub const pop = common.popEntry;
pub const peek = common.peekEntry;
pub const validate = common.validateEntry;

test "x64 shadow stack init dispatches correctly" {
    var memory = [_]u8{0xFF} ** 64;
    const placement = ShadowStackPlacement{
        .base = 0,
        .size = 48,
        .entry_size = 8,
    };
    const state = init(&memory, placement);
    try std.testing.expectEqual(@as(u64, 48), state.ssp);
    try std.testing.expectEqual(@as(u32, 0), state.depth);
    try std.testing.expectEqual(@as(u8, 0), memory[0]);
}

test "x64 shadow stack push and pop 8-byte" {
    var memory = [_]u8{0} ** 32;
    var state = init(&memory, .{
        .base = 0,
        .size = 24,
        .entry_size = 8,
    });
    push(&state, &memory, 0xAABBCCDD);
    try std.testing.expectEqual(@as(u64, 0xAABBCCDD), peek(&state, &memory));
    try std.testing.expectEqual(@as(u64, 0xAABBCCDD), pop(&state, &memory));
    try std.testing.expectEqual(@as(u32, 0), state.depth);
}
