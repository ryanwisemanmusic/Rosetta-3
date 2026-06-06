const std = @import("std");
const common = @import("entrypoint_shadow_stack_common");

pub const ShadowStackPlacement = common.ShadowStackPlacement;
pub const ShadowStackState = common.ShadowStackState;

pub fn init(memory: []u8, placement: ShadowStackPlacement) ShadowStackState {
    const start: usize = @intCast(placement.base);
    const size: usize = @intCast(placement.size);
    const end = start + size;
    if (end > memory.len) {
        return common.initShadowStack("entrypoint-neon-shadow-stack", memory, placement);
    }

    const zero16: @Vector(16, u8) = @splat(0);
    const zero_block: [16]u8 = @bitCast(zero16);
    var i: usize = 0;
    while (i + 16 <= size) : (i += 16) {
        @memcpy(memory[start + i .. start + i + 16], &zero_block);
    }
    while (i < size) : (i += 1) {
        memory[start + i] = 0;
    }

    const ssp = common.computeInitialSsp(placement);
    return .{
        .base = placement.base,
        .size = placement.size,
        .ssp = ssp,
        .entry_size = placement.entry_size,
        .depth = 0,
    };
}

pub const push = common.pushEntry;
pub const pop = common.popEntry;
pub const peek = common.peekEntry;
pub const validate = common.validateEntry;

test "NEON shadow stack init and operations" {
    var memory = [_]u8{0xFF} ** 32;
    const placement = ShadowStackPlacement{
        .base = 4,
        .size = 20,
        .entry_size = 4,
    };
    var state = init(&memory, placement);
    try std.testing.expectEqual(@as(u64, 24), state.ssp);
    try std.testing.expectEqual(@as(u8, 0), memory[4]);
    try std.testing.expectEqual(@as(u8, 0), memory[23]);
    try std.testing.expectEqual(@as(u8, 0xFF), memory[3]);

    push(&state, &memory, 0xABCD);
    try std.testing.expectEqual(@as(u64, 0xABCD), peek(&state, &memory));
    try std.testing.expectEqual(@as(u64, 0xABCD), pop(&state, &memory));
    try std.testing.expectEqual(@as(u32, 0), state.depth);
}
