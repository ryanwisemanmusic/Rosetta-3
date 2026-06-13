pub const AssemblerEvent = enum(u8) {
    assembly_start,
    command_parsed,
    source_profile_detected,
    assembly_pass,
    section_opened,
    label_defined,
    instruction_encoded,
    data_emitted,
    listing_emitted,
    artifact_validated,
    output_flushed,
    assembly_complete,
};

pub const ValidationDomain = enum(u8) {
    command_line,
    source_profile,
    instruction_encoding,
    data_definition,
    alignment,
    section_layout,
    symbol_resolution,
    pass_convergence,
    output_format,
    artifact_format,
    abi_constraint,
    bits_mode,
};

pub const AssemblerEventRecord = struct {
    event: AssemblerEvent,
    domain: ValidationDomain,
    pass: u32,
    address: u64,
    size: u32 = 0,
    detail: []const u8 = "",
};
