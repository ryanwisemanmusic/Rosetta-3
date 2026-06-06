const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");

pub const ShadowStackPlacement = struct {
    base: u64,
    size: u64,
    entry_size: u8,
};

pub const ShadowStackState = struct {
    base: u64,
    size: u64,
    ssp: u64,
    entry_size: u8,
    depth: u32,
};

pub fn computeInitialSsp(placement: ShadowStackPlacement) u64 {
    const top = placement.base + placement.size;
    const align_val: u64 = placement.entry_size;
    if (align_val == 0) return top;
    return top & ~(align_val - 1);
}

fn readEntry(memory: []u8, addr: u64, entry_size: u8) u64 {
    const start: usize = @intCast(addr);
    return switch (entry_size) {
        4 => @as(*align(1) u32, @ptrCast(@as(*u8, @ptrCast(&memory[start])))).*,
        8 => @as(*align(1) u64, @ptrCast(@as(*u8, @ptrCast(&memory[start])))).*,
        else => 0,
    };
}

fn writeEntry(memory: []u8, addr: u64, value: u64, entry_size: u8) void {
    const start: usize = @intCast(addr);
    switch (entry_size) {
        4 => @as(*align(1) u32, @ptrCast(@as(*u8, @ptrCast(&memory[start])))).* = @truncate(value),
        8 => @as(*align(1) u64, @ptrCast(@as(*u8, @ptrCast(&memory[start])))).* = value,
        else => unreachable,
    }
}

pub fn initShadowStack(
    comptime domain: []const u8,
    memory: []u8,
    placement: ShadowStackPlacement,
) ShadowStackState {
    const start: usize = @intCast(placement.base);
    const size: usize = @intCast(placement.size);
    const end = start + size;
    if (end > memory.len) {
        runtime_abi.common.violation(
            domain,
            "shadow_stack_bounds",
            "{s}: base=0x{x} size={d} memory={d}",
            .{ "shadow_stack", placement.base, placement.size, memory.len },
        );
    }
    @memset(memory[start..end], 0);
    const ssp = computeInitialSsp(placement);
    return .{
        .base = placement.base,
        .size = placement.size,
        .ssp = ssp,
        .entry_size = placement.entry_size,
        .depth = 0,
    };
}

pub fn pushEntry(state: *ShadowStackState, memory: []u8, value: u64) void {
    state.ssp -|= state.entry_size;
    writeEntry(memory, state.ssp, value, state.entry_size);
    state.depth +|= 1;
}

pub fn popEntry(state: *ShadowStackState, memory: []u8) u64 {
    const value = readEntry(memory, state.ssp, state.entry_size);
    state.ssp +|= state.entry_size;
    state.depth -|= 1;
    return value;
}

pub fn peekEntry(state: *const ShadowStackState, memory: []u8) u64 {
    return readEntry(memory, state.ssp, state.entry_size);
}

pub fn validateEntry(state: *const ShadowStackState, memory: []u8, expected: u64) bool {
    if (state.depth == 0) return false;
    return peekEntry(state, memory) == expected;
}

test "computeInitialSsp aligns to entry size" {
    try std.testing.expectEqual(@as(u64, 0x1800), computeInitialSsp(.{ .base = 0x1000, .size = 0x800, .entry_size = 4 }));
    try std.testing.expectEqual(@as(u64, 0x1800), computeInitialSsp(.{ .base = 0x1000, .size = 0x800, .entry_size = 8 }));
    try std.testing.expectEqual(@as(u64, 0x1004), computeInitialSsp(.{ .base = 0x1000, .size = 4, .entry_size = 4 }));
}

test "initShadowStack zeros region and returns initial state" {
    var memory = [_]u8{0xFF} ** 32;
    const placement = ShadowStackPlacement{
        .base = 8,
        .size = 16,
        .entry_size = 4,
    };
    const state = initShadowStack("test", &memory, placement);
    try std.testing.expectEqual(@as(u64, 24), state.ssp);
    try std.testing.expectEqual(@as(u8, 4), state.entry_size);
    try std.testing.expectEqual(@as(u32, 0), state.depth);
    try std.testing.expectEqual(@as(u8, 0), memory[8]);
    try std.testing.expectEqual(@as(u8, 0), memory[23]);
    try std.testing.expectEqual(@as(u8, 0xFF), memory[7]);
}

test "push and pop 4-byte entries" {
    var memory = [_]u8{0} ** 32;
    var state = initShadowStack("test", &memory, .{
        .base = 16,
        .size = 16,
        .entry_size = 4,
    });
    try std.testing.expectEqual(@as(u32, 0), state.depth);
    pushEntry(&state, &memory, 0xDEAD);
    try std.testing.expectEqual(@as(u32, 1), state.depth);
    try std.testing.expectEqual(@as(u64, 28), state.ssp);
    pushEntry(&state, &memory, 0xBEEF);
    try std.testing.expectEqual(@as(u32, 2), state.depth);
    try std.testing.expectEqual(@as(u64, 24), state.ssp);
    try std.testing.expectEqual(@as(u64, 0xBEEF), popEntry(&state, &memory));
    try std.testing.expectEqual(@as(u32, 1), state.depth);
    try std.testing.expectEqual(@as(u64, 0xDEAD), popEntry(&state, &memory));
    try std.testing.expectEqual(@as(u32, 0), state.depth);
}

test "push and pop 8-byte entries" {
    var memory = [_]u8{0} ** 32;
    var state = initShadowStack("test", &memory, .{
        .base = 0,
        .size = 32,
        .entry_size = 8,
    });
    pushEntry(&state, &memory, 0x12345678);
    try std.testing.expectEqual(@as(u64, 24), state.ssp);
    pushEntry(&state, &memory, 0x9ABCDEF0);
    try std.testing.expectEqual(@as(u64, 16), state.ssp);
    try std.testing.expectEqual(@as(u64, 0x9ABCDEF0), popEntry(&state, &memory));
    try std.testing.expectEqual(@as(u64, 0x12345678), popEntry(&state, &memory));
}

test "peek returns top without popping" {
    var memory = [_]u8{0} ** 16;
    var state = initShadowStack("test", &memory, .{
        .base = 0,
        .size = 16,
        .entry_size = 4,
    });
    pushEntry(&state, &memory, 0xCAFE);
    try std.testing.expectEqual(@as(u64, 0xCAFE), peekEntry(&state, &memory));
    try std.testing.expectEqual(@as(u32, 1), state.depth);
}

test "validate matches top entry" {
    var memory = [_]u8{0} ** 16;
    var state = initShadowStack("test", &memory, .{
        .base = 0,
        .size = 16,
        .entry_size = 4,
    });
    pushEntry(&state, &memory, 0xF00D);
    try std.testing.expect(validateEntry(&state, &memory, 0xF00D));
    try std.testing.expect(!validateEntry(&state, &memory, 0xBADD));
}

test "validate empty returns false" {
    var memory = [_]u8{0} ** 16;
    var state = initShadowStack("test", &memory, .{
        .base = 0,
        .size = 16,
        .entry_size = 4,
    });
    try std.testing.expect(!validateEntry(&state, &memory, 0));
}
