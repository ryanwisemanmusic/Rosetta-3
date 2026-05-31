const std = @import("std");

pub const RexPrefix = packed struct(u8) {
    b: u1,
    x: u1,
    r: u1,
    w: u1,
    fixed: u4,

    pub fn parse(byte: u8) ?RexPrefix {
        if ((byte & 0xF0) != 0x40) return null;
        return @bitCast(byte);
    }

    pub fn extendsOperandWidth(self: RexPrefix) bool {
        return self.w == 1;
    }

    pub fn extendReg(self: RexPrefix, reg3: u3) u4 {
        return reg3 | (@as(u4, self.r) << 3);
    }

    pub fn extendIndex(self: RexPrefix, index3: u3) u4 {
        return index3 | (@as(u4, self.x) << 3);
    }

    pub fn extendBase(self: RexPrefix, base3: u3) u4 {
        return base3 | (@as(u4, self.b) << 3);
    }
};

test "rex parsing recognizes width and register extension bits" {
    const rex = RexPrefix.parse(0x4D).?;
    try std.testing.expect(rex.extendsOperandWidth());
    try std.testing.expectEqual(@as(u4, 9), rex.extendBase(1));
}
