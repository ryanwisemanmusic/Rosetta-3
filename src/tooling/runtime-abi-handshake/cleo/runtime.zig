const common = @import("../common.zig");

pub const WideInstructionShape = struct {
    name: []const u8,
    family: []const u8,
    source_path: []const u8,
    required_feature: []const u8,
    operation: []const u8,
    max_width_bits: usize,
    element_bits: usize,
    block_bits: usize,
    block_count: usize,
    uses_neon_blocks: bool,
    requires_scalar_fixup: bool,
    supports_masking: bool,
    supports_broadcast: bool,
    asm_template_present: bool,
};

pub fn init() void {
    common.acquire();
}

pub fn deinit() void {
    common.release();
}

pub fn validateWideInstruction(shape: WideInstructionShape) void {
    common.noteValidation();
    if (shape.name.len == 0)
        common.violation("cleo", "missing_name", "source={s} has no instruction name", .{shape.source_path});
    if (shape.family.len == 0)
        common.violation("cleo", "missing_family", "instruction={s} source={s} has no ISA family", .{ shape.name, shape.source_path });
    if (shape.source_path.len == 0)
        common.violation("cleo", "missing_source", "instruction={s} has no x86/AVX source path", .{shape.name});
    if (shape.required_feature.len == 0)
        common.violation("cleo", "missing_feature", "instruction={s} source={s} has no required CPU feature", .{ shape.name, shape.source_path });
    if (shape.operation.len == 0)
        common.violation("cleo", "missing_operation", "instruction={s} source={s} has no semantic operation", .{ shape.name, shape.source_path });
    if (shape.max_width_bits <= 128 or shape.max_width_bits % 128 != 0)
        common.violation("cleo", "wide_width", "instruction={s} width={d} does not split into >128-bit NEON blocks", .{ shape.name, shape.max_width_bits });
    if (shape.max_width_bits != 256 and shape.max_width_bits != 512 and shape.max_width_bits != 1024)
        common.violation("cleo", "supported_width", "instruction={s} width={d} is outside CLEO supported wide widths", .{ shape.name, shape.max_width_bits });
    if (shape.element_bits == 0 or shape.max_width_bits % shape.element_bits != 0)
        common.violation("cleo", "element_width", "instruction={s} element_bits={d} does not divide width={d}", .{ shape.name, shape.element_bits, shape.max_width_bits });
    if (shape.block_bits != 128)
        common.violation("cleo", "neon_block_size", "instruction={s} block_bits={d}, expected 128", .{ shape.name, shape.block_bits });
    if (shape.block_count == 0 or shape.block_count != shape.max_width_bits / 128)
        common.violation("cleo", "block_count", "instruction={s} block_count={d}, expected {d}", .{ shape.name, shape.block_count, shape.max_width_bits / 128 });
    if (!shape.uses_neon_blocks)
        common.violation("cleo", "neon_lowering", "instruction={s} source={s} does not declare NEON block lowering", .{ shape.name, shape.source_path });
    if (!shape.asm_template_present)
        common.violation("cleo", "asm_contract", "instruction={s} source={s} has no Zig/ASM lowering contract", .{ shape.name, shape.source_path });

    if (shape.max_width_bits >= 512 and !shape.supports_masking and contains(shape.family, "AVX512"))
        common.violation("cleo", "avx512_masking", "instruction={s} source={s} is AVX512 width but masking is not declared", .{ shape.name, shape.source_path });
    if (shape.supports_broadcast and shape.element_bits == 0)
        common.violation("cleo", "broadcast_element", "instruction={s} declares broadcast without an element width", .{shape.name});
}

pub fn validateRegistry(total_count: usize, completed_count: usize, progress_permille: u16) void {
    common.noteValidation();
    if (total_count == 0)
        common.violation("cleo", "empty_registry", "CLEO registry has no wide instruction entries", .{});
    if (completed_count != total_count)
        common.violation("cleo", "incomplete_registry", "CLEO completed {d}/{d} wide instruction entries", .{ completed_count, total_count });
    if (progress_permille != 1000)
        common.violation("cleo", "progress", "CLEO progress is {d}/1000, expected 1000/1000", .{progress_permille});
}

fn contains(haystack: []const u8, needle: []const u8) bool {
    if (needle.len == 0) return true;
    if (haystack.len < needle.len) return false;
    var i: usize = 0;
    while (i + needle.len <= haystack.len) : (i += 1) {
        if (asciiEql(haystack[i .. i + needle.len], needle)) return true;
    }
    return false;
}

fn asciiEql(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |lhs, rhs| {
        const l = if (lhs >= 'A' and lhs <= 'Z') lhs + 32 else lhs;
        const r = if (rhs >= 'A' and rhs <= 'Z') rhs + 32 else rhs;
        if (l != r) return false;
    }
    return true;
}

test "CLEO ABI registry summary accepts complete coverage" {
    init();
    defer deinit();
    validateRegistry(1, 1, 1000);
}
