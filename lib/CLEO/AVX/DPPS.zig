const Impl = @import("../wrapper.zig").BinaryInstruction(.{
    .name = "DPPS",
    .family = "DOT_PRODUCT",
    .source_path = "ISA/x86/DOT_PRODUCT/DPPS.inc",
    .required_feature = .avx,
    .max_width_bits = 256,
    .element_bits = 32,
    .operation = .dpps,
    .alignment = .any,
    .supports_masking = false,
    .supports_broadcast = false,
});

pub const meta = Impl.meta;
pub const plan = Impl.plan;
pub const safety = Impl.safety;
pub const validate = Impl.validate;
pub const execute = Impl.execute;
pub const executeImmediate = Impl.executeImmediate;
pub const executeAccumulate = Impl.executeAccumulate;
pub const executeMasked = Impl.executeMasked;
pub const executeMaskedImmediate = Impl.executeMaskedImmediate;
pub const executeAccumulateMasked = Impl.executeAccumulateMasked;
pub const move = Impl.move;
pub const movMask = Impl.movMask;
