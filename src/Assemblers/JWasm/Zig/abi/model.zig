pub const AssemblerEvent = enum(u8) {
    assembly_start,
    assembly_pass,
    instruction_encoded,
    data_emitted,
    symbol_defined,
    segment_opened,
    segment_closed,
    model_directive,
    directive_processed,
    macro_expanded,
    output_flushed,
    assembly_complete,
};

pub const ValidationDomain = enum(u8) {
    instruction_encoding,
    data_definition,
    alignment,
    segment_layout,
    symbol_resolution,
    pass_convergence,
    output_format,
    abi_constraint,
    memory_model,
    label_usage,
};

pub const AssemblerEventRecord = struct {
    event: AssemblerEvent,
    domain: ValidationDomain,
    pass: u32,
    address: u64,
    size: u32 = 0,
    detail: []const u8 = "",
};
