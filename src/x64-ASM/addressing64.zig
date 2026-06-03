const std = @import("std");
const state = @import("x64_state.zig");
const runtime_abi = @import("runtime_abi_handshake");

pub const Scale64 = enum(u2) {
    x1 = 0,
    x2 = 1,
    x4 = 2,
    x8 = 3,

    pub fn factor(self: Scale64) u64 {
        return switch (self) {
            .x1 => 1,
            .x2 => 2,
            .x4 => 4,
            .x8 => 8,
        };
    }
};

pub const Address64 = union(enum) {
    register: state.Register64,
    indirect: state.Register64,
    base_index_scale_disp: struct {
        base: ?state.Register64,
        index: ?state.Register64,
        scale: Scale64 = .x1,
        displacement: i32 = 0,
    },
    rip_relative: i32,
};

pub fn compute(state64: *const state.RegisterFile64, ip_after_decode: u64, addr: Address64) u64 {
    const computed = switch (addr) {
        .register => |reg| state64.get(reg),
        .indirect => |reg| state64.get(reg),
        .base_index_scale_disp => |spec| blk: {
            var result: u64 = 0;
            if (spec.base) |base| result +%= state64.get(base);
            if (spec.index) |index| result +%= state64.get(index) *% spec.scale.factor();
            result +%= @as(u64, @bitCast(@as(i64, spec.displacement)));
            break :blk result;
        },
        .rip_relative => |disp| ip_after_decode +% @as(u64, @bitCast(@as(i64, disp))),
    };
    runtime_abi.x64.validateAddressing(ip_after_decode, computed);
    return computed;
}

test "x64 addressing computes rip-relative and extended base addressing" {
    var regs: state.RegisterFile64 = .{};
    regs.rip = 0x1400_1000;
    regs.r12 = 0x2000;
    regs.r9 = 4;

    const mem = compute(&regs, 0x1400_1010, .{
        .base_index_scale_disp = .{
            .base = .r12,
            .index = .r9,
            .scale = .x8,
            .displacement = 0x20,
        },
    });
    try std.testing.expectEqual(@as(u64, 0x2040), mem);

    const rip_rel = compute(&regs, 0x1400_1010, .{ .rip_relative = 0x30 });
    try std.testing.expectEqual(@as(u64, 0x1400_1040), rip_rel);
}
