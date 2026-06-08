const std = @import("std");

pub const MVE_VECTOR_BITS = 128;
pub const MVE_VECTOR_BYTES = MVE_VECTOR_BITS / 8;

pub fn lanesFor(comptime T: type) usize {
    const bytes = @sizeOf(T);
    if (bytes == 0 or bytes > MVE_VECTOR_BYTES or MVE_VECTOR_BYTES % bytes != 0) {
        @compileError("SVX vectors require scalar element types that divide 128 bits");
    }
    return MVE_VECTOR_BYTES / bytes;
}

pub fn Vec(comptime T: type) type {
    return @Vector(lanesFor(T), T);
}

pub const i8x16 = Vec(i8);
pub const u8x16 = Vec(u8);
pub const i16x8 = Vec(i16);
pub const u16x8 = Vec(u16);
pub const i32x4 = Vec(i32);
pub const u32x4 = Vec(u32);
pub const i64x2 = Vec(i64);
pub const u64x2 = Vec(u64);
pub const f16x8 = Vec(f16);
pub const f32x4 = Vec(f32);
pub const f64x2 = Vec(f64);

pub const ElementKind = enum {
    s8,
    u8,
    s16,
    u16,
    s32,
    u32,
    s64,
    u64,
    f16,
    f32,
    f64,
};

pub fn elementKind(comptime T: type) ElementKind {
    return switch (T) {
        i8 => .s8,
        u8 => .u8,
        i16 => .s16,
        u16 => .u16,
        i32 => .s32,
        u32 => .u32,
        i64 => .s64,
        u64 => .u64,
        f16 => .f16,
        f32 => .f32,
        f64 => .f64,
        else => @compileError("unsupported SVX element type"),
    };
}

pub fn isSignedInt(comptime T: type) bool {
    return switch (T) {
        i8, i16, i32, i64 => true,
        else => false,
    };
}

pub fn isUnsignedInt(comptime T: type) bool {
    return switch (T) {
        u8, u16, u32, u64 => true,
        else => false,
    };
}

pub fn isInt(comptime T: type) bool {
    return isSignedInt(T) or isUnsignedInt(T);
}

pub fn isFloat(comptime T: type) bool {
    return switch (T) {
        f16, f32, f64 => true,
        else => false,
    };
}

pub fn Unsigned(comptime T: type) type {
    return switch (T) {
        i8, u8 => u8,
        i16, u16 => u16,
        i32, u32 => u32,
        i64, u64 => u64,
        else => @compileError("unsupported integer element type"),
    };
}

pub fn Signed(comptime T: type) type {
    return switch (T) {
        i8, u8 => i8,
        i16, u16 => i16,
        i32, u32 => i32,
        i64, u64 => i64,
        else => @compileError("unsupported integer element type"),
    };
}

pub fn WideSigned(comptime T: type) type {
    return switch (@bitSizeOf(T)) {
        8 => i16,
        16 => i32,
        32 => i64,
        64 => i128,
        else => @compileError("unsupported integer width"),
    };
}

pub fn WideUnsigned(comptime T: type) type {
    return switch (@bitSizeOf(T)) {
        8 => u16,
        16 => u32,
        32 => u64,
        64 => u128,
        else => @compileError("unsupported integer width"),
    };
}

pub fn Accumulator(comptime T: type) type {
    return if (isSignedInt(T)) WideSigned(T) else WideUnsigned(T);
}

pub const Predicate16 = struct {
    bits: u16,

    pub const none: Predicate16 = .{ .bits = 0 };
    pub const all: Predicate16 = .{ .bits = 0xFFFF };

    pub fn fromBits(bits: u16) Predicate16 {
        return .{ .bits = bits };
    }

    pub fn forLanes(comptime lanes: usize) Predicate16 {
        return tail(lanes);
    }

    pub fn tail(active_lanes: usize) Predicate16 {
        if (active_lanes == 0) return none;
        if (active_lanes >= 16) return all;
        const shift: u4 = @intCast(active_lanes);
        return .{ .bits = (@as(u16, 1) << shift) - 1 };
    }

    pub fn active(self: Predicate16, lane: usize) bool {
        if (lane >= 16) return false;
        const shift: u4 = @intCast(lane);
        return (self.bits & (@as(u16, 1) << shift)) != 0;
    }

    pub fn set(self: *Predicate16, lane: usize, value: bool) void {
        if (lane >= 16) return;
        const shift: u4 = @intCast(lane);
        const bit = @as(u16, 1) << shift;
        if (value) {
            self.bits |= bit;
        } else {
            self.bits &= ~bit;
        }
    }

    pub fn laneMask(self: Predicate16, comptime T: type) u16 {
        const lanes = lanesFor(T);
        if (lanes >= 16) return self.bits;
        const valid = tail(lanes).bits;
        return self.bits & valid;
    }

    pub fn activeCount(self: Predicate16, comptime T: type) usize {
        return @popCount(self.laneMask(T));
    }

    pub fn invert(self: Predicate16) Predicate16 {
        return .{ .bits = ~self.bits };
    }

    pub fn intersect(self: Predicate16, other: Predicate16) Predicate16 {
        return .{ .bits = self.bits & other.bits };
    }

    pub fn unite(self: Predicate16, other: Predicate16) Predicate16 {
        return .{ .bits = self.bits | other.bits };
    }

    pub fn difference(self: Predicate16, other: Predicate16) Predicate16 {
        return .{ .bits = self.bits & ~other.bits };
    }
};

pub fn fromArray(comptime T: type, array: [lanesFor(T)]T) Vec(T) {
    var result: Vec(T) = undefined;
    const lane_count = comptime lanesFor(T);
    inline for (0..lane_count) |lane| result[lane] = array[lane];
    return result;
}

pub fn toArray(comptime T: type, vector: Vec(T)) [lanesFor(T)]T {
    var result: [lanesFor(T)]T = undefined;
    const lane_count = comptime lanesFor(T);
    inline for (0..lane_count) |lane| result[lane] = vector[lane];
    return result;
}

test "SVX type aliases are 128-bit vector shapes" {
    try std.testing.expectEqual(@as(usize, 8), lanesFor(i16));
    try std.testing.expectEqual(@as(usize, 4), lanesFor(u32));
    try std.testing.expectEqual(@as(usize, MVE_VECTOR_BYTES), @sizeOf(i16x8));
    try std.testing.expect(Predicate16.tail(4).active(3));
    try std.testing.expect(!Predicate16.tail(4).active(4));
}
