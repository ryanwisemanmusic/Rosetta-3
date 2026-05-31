const std = @import("std");
const reg_map = @import("register_mapping.zig");
const core = @import("family_core.zig");

pub const Scale = enum(u2) {
    x1 = 0,
    x2 = 1,
    x4 = 2,
    x8 = 3,

    pub fn factor(self: Scale) u32 {
        return switch (self) {
            .x1 => 1,
            .x2 => 2,
            .x4 => 4,
            .x8 => 8,
        };
    }
};

pub const OperandAddress = union(core.AddressForm) {
    direct: u64,
    register: reg_map.Register,
    indirect: reg_map.Register,
    indexed: struct {
        base: reg_map.Register,
        displacement: i32 = 0,
    },
    base_index_scale_disp: struct {
        base: ?reg_map.Register,
        index: ?reg_map.Register,
        scale: Scale = .x1,
        displacement: i32 = 0,
    },
    rip_relative: i32,
};

pub fn computeIa32(
    regs: *const reg_map.RegisterFile,
    addr: OperandAddress,
) u32 {
    return switch (addr) {
        .direct => |value| @truncate(value),
        .register => |reg| regs.get(reg),
        .indirect => |reg| regs.get(reg),
        .indexed => |spec| regs.get(spec.base) +% @as(u32, @bitCast(spec.displacement)),
        .base_index_scale_disp => |spec| blk: {
            var result: u32 = 0;
            if (spec.base) |base| result +%= regs.get(base);
            if (spec.index) |index| result +%= regs.get(index) *% spec.scale.factor();
            result +%= @as(u32, @bitCast(spec.displacement));
            break :blk result;
        },
        .rip_relative => 0,
    };
}

test "ia32 addressing computes base plus index times scale plus displacement" {
    var regs: reg_map.RegisterFile = .{};
    regs.ebx = 0x1000;
    regs.esi = 3;

    const addr = computeIa32(&regs, .{
        .base_index_scale_disp = .{
            .base = .ebx,
            .index = .esi,
            .scale = .x4,
            .displacement = 0x20,
        },
    });

    try std.testing.expectEqual(@as(u32, 0x102C), addr);
}
