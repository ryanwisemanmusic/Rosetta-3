const std = @import("std");

pub const SimdDomain = enum {
    x87,
    sse,
    sse2,
    avx,
    avx2,
    neon_lowering,
};

pub const SupportStage = enum {
    placeholder,
    decode_scaffold,
    semantic_stub,
    lowering_stub,
};

pub const SimdFeature = struct {
    domain: SimdDomain,
    stage: SupportStage,
    note: []const u8,
};

pub const roadmap = [_]SimdFeature{
    .{ .domain = .x87, .stage = .placeholder, .note = "Reserve x87 stack/FPU environment handling." },
    .{ .domain = .sse, .stage = .decode_scaffold, .note = "Decode XMM register forms and packed scalar widths." },
    .{ .domain = .sse2, .stage = .decode_scaffold, .note = "Add integer SIMD semantics and memory forms." },
    .{ .domain = .avx, .stage = .placeholder, .note = "Reserve VEX/three-operand scaffolding." },
    .{ .domain = .avx2, .stage = .placeholder, .note = "Reserve wider vector lowering." },
    .{ .domain = .neon_lowering, .stage = .lowering_stub, .note = "Map eventual SSE/AVX ops onto ARM64 NEON backends." },
};

test "simd roadmap keeps neon lowering in scope" {
    try std.testing.expectEqual(SimdDomain.neon_lowering, roadmap[5].domain);
}
