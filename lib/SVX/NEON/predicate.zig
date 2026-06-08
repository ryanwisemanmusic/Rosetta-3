const svx = @import("../types.zig");

pub const Predicate16 = svx.Predicate16;

pub fn vctp16q(remaining: usize) Predicate16 {
    return Predicate16.tail(@min(remaining, svx.lanesFor(i16)));
}

pub fn vctp32q(remaining: usize) Predicate16 {
    return Predicate16.tail(@min(remaining, svx.lanesFor(i32)));
}

pub fn not(predicate: Predicate16) Predicate16 {
    return predicate.invert();
}

pub fn and_(a: Predicate16, b: Predicate16) Predicate16 {
    return a.intersect(b);
}

pub fn or_(a: Predicate16, b: Predicate16) Predicate16 {
    return a.unite(b);
}

pub fn bic(a: Predicate16, b: Predicate16) Predicate16 {
    return a.difference(b);
}

pub fn select(comptime T: type, predicate: Predicate16, if_true: svx.Vec(T), if_false: svx.Vec(T)) svx.Vec(T) {
    var result: svx.Vec(T) = undefined;
    const lane_count = comptime svx.lanesFor(T);
    inline for (0..lane_count) |lane| {
        result[lane] = if (predicate.active(lane)) if_true[lane] else if_false[lane];
    }
    return result;
}

pub fn merge(comptime T: type, inactive: svx.Vec(T), active: svx.Vec(T), predicate: Predicate16) svx.Vec(T) {
    return select(T, predicate, active, inactive);
}
