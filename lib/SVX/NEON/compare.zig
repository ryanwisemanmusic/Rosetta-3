const svx = @import("../types.zig");

pub const CompareOp = enum {
    eq,
    ne,
    ge,
    gt,
    le,
    lt,
};

pub fn compare(comptime T: type, op: CompareOp, a: svx.Vec(T), b: svx.Vec(T)) svx.Predicate16 {
    var result = svx.Predicate16.none;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| {
        const yes = switch (op) {
            .eq => a[lane] == b[lane],
            .ne => a[lane] != b[lane],
            .ge => a[lane] >= b[lane],
            .gt => a[lane] > b[lane],
            .le => a[lane] <= b[lane],
            .lt => a[lane] < b[lane],
        };
        result.set(lane, yes);
    }
    return result;
}

pub fn eq(comptime T: type, a: svx.Vec(T), b: svx.Vec(T)) svx.Predicate16 {
    return compare(T, .eq, a, b);
}

pub fn ne(comptime T: type, a: svx.Vec(T), b: svx.Vec(T)) svx.Predicate16 {
    return compare(T, .ne, a, b);
}

pub fn ge(comptime T: type, a: svx.Vec(T), b: svx.Vec(T)) svx.Predicate16 {
    return compare(T, .ge, a, b);
}

pub fn gt(comptime T: type, a: svx.Vec(T), b: svx.Vec(T)) svx.Predicate16 {
    return compare(T, .gt, a, b);
}

pub fn le(comptime T: type, a: svx.Vec(T), b: svx.Vec(T)) svx.Predicate16 {
    return compare(T, .le, a, b);
}

pub fn lt(comptime T: type, a: svx.Vec(T), b: svx.Vec(T)) svx.Predicate16 {
    return compare(T, .lt, a, b);
}
