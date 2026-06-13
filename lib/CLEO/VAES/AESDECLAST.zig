const Impl = @import("../wrapper.zig").BinaryInstruction(.{
    .name = "AESDECLAST",
    .family = "AES",
    .source_path = "ISA/x86/AES/AESDECLAST.inc",
    .required_feature = .vaes,
    .max_width_bits = 512,
    .element_bits = 128,
    .operation = .aesdeclast,
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
