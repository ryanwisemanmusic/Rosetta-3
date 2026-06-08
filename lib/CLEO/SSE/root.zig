const types = @import("../types.zig");

pub const baseline_features = [_]types.Feature{ .sse, .sse2 };

pub fn available(features: types.FeatureSet) bool {
    return features.contains(.sse) and features.contains(.sse2);
}
