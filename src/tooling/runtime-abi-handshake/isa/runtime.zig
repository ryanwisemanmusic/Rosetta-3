const common = @import("../common.zig");

pub const X86TableShape = struct {
    name: []const u8,
    category: []const u8,
    handler: []const u8,
    jit_lowering: []const u8,
    source_path: []const u8,
    encoding_count: usize,
    has_semantic: bool,
    has_flags: bool,
};

pub const NeonMirrorShape = struct {
    x86_path: []const u8,
    neon_path: []const u8,
    declared_x86_table: []const u8,
    x86_name: []const u8,
    neon_name: []const u8,
    x86_lowering: []const u8,
    neon_lowering: []const u8,
    x86_encoding_count: usize,
    neon_encoding_count: usize,
    x86_has_semantic: bool,
    neon_has_semantic: bool,
    x86_has_flags: bool,
    neon_has_flags: bool,
    neon_has_register_model: bool,
    neon_has_flag_model: bool,
    neon_has_assembly: bool,
};

pub const NeonLoweringShape = struct {
    name: []const u8,
    jit_lowering: []const u8,
    kind: []const u8,
    assembly: []const u8,
    can_lower: bool,
};

pub fn init() void {
    common.acquire();
}

pub fn deinit() void {
    common.release();
}

pub fn validateX86Table(shape: X86TableShape) void {
    common.noteValidation();
    if (shape.name.len == 0)
        common.violation("isa-x86", "missing_name", "table={s} has no instruction name", .{shape.source_path});
    if (shape.category.len == 0 or isPlaceholder(shape.category))
        common.violation("isa-x86", "missing_category", "table={s} name={s} has no category", .{ shape.source_path, shape.name });
    if (shape.handler.len == 0)
        common.violation("isa-x86", "missing_handler", "table={s} name={s} has no x86 handler", .{ shape.source_path, shape.name });
    if (shape.jit_lowering.len == 0)
        common.violation("isa-x86", "missing_lowering", "table={s} name={s} has no jit_lowering", .{ shape.source_path, shape.name });
    if (shape.encoding_count == 0)
        common.violation("isa-x86", "missing_encodings", "table={s} name={s} has no encodings", .{ shape.source_path, shape.name });
    if (!shape.has_semantic)
        common.violation("isa-x86", "missing_semantic", "table={s} name={s} has no semantic block", .{ shape.source_path, shape.name });
    if (!shape.has_flags)
        common.violation("isa-x86", "missing_flags", "table={s} name={s} has no flag contract", .{ shape.source_path, shape.name });
}

pub fn validateNoDuplicateInstruction(name: []const u8, lhs_path: []const u8, rhs_path: []const u8) void {
    common.noteValidation();
    common.violation("isa-x86", "duplicate_instruction", "name={s} appears in {s} and {s}", .{ name, lhs_path, rhs_path });
}

pub fn validateMirrorTableCounts(x86_count: usize, neon_count: usize) void {
    common.noteValidation();
    if (x86_count != neon_count)
        common.violation("isa-neon", "mirror_count", "x86 table count {d} differs from NEON mirror count {d}", .{ x86_count, neon_count });
}

pub fn validateMissingNeonMirror(x86_path: []const u8) void {
    common.noteValidation();
    common.violation("isa-neon", "missing_mirror", "x86 table {s} has no NEON mirror table", .{x86_path});
}

pub fn validateNeonMirror(shape: NeonMirrorShape) void {
    common.noteValidation();
    if (!samePathLeaf(shape.x86_path, shape.neon_path))
        common.violation("isa-neon", "mirror_path", "x86={s} neon={s} do not mirror the same instruction folder/name", .{ shape.x86_path, shape.neon_path });
    if (!samePathLeaf(shape.x86_path, shape.declared_x86_table))
        common.violation("isa-neon", "declared_x86_table", "neon={s} declares x86_table={s}, expected {s}", .{ shape.neon_path, shape.declared_x86_table, shape.x86_path });
    if (!asciiEql(shape.x86_name, shape.neon_name))
        common.violation("isa-neon", "mirror_name", "x86={s} neon={s} names differ ({s} vs {s})", .{ shape.x86_path, shape.neon_path, shape.x86_name, shape.neon_name });
    if (!asciiEql(shape.x86_lowering, shape.neon_lowering))
        common.violation("isa-neon", "lowering_tag", "x86={s} neon={s} lowering tags differ ({s} vs {s})", .{ shape.x86_path, shape.neon_path, shape.x86_lowering, shape.neon_lowering });
    if (shape.x86_encoding_count != shape.neon_encoding_count)
        common.violation("isa-neon", "encoding_scope", "x86={s} neon={s} encoding rows differ ({d} vs {d})", .{ shape.x86_path, shape.neon_path, shape.x86_encoding_count, shape.neon_encoding_count });
    if (shape.x86_has_semantic and !shape.neon_has_semantic)
        common.violation("isa-neon", "semantic_scope", "neon={s} dropped x86 semantic contract", .{shape.neon_path});
    if (shape.x86_has_flags and !shape.neon_has_flags)
        common.violation("isa-neon", "flag_scope", "neon={s} dropped x86 flag/MXCSR contract", .{shape.neon_path});
    if (!shape.neon_has_register_model)
        common.violation("isa-neon", "register_model", "neon={s} has no ARM64/NEON register model", .{shape.neon_path});
    if (!shape.neon_has_flag_model)
        common.violation("isa-neon", "flag_model", "neon={s} has no ARM64/NEON flag model", .{shape.neon_path});
    if (!shape.neon_has_assembly)
        common.violation("isa-neon", "assembly_contract", "neon={s} has no ARM64/NEON assembly contract", .{shape.neon_path});
}

pub fn validateNeonLowering(shape: NeonLoweringShape) void {
    common.noteValidation();
    if (shape.jit_lowering.len == 0)
        common.violation("isa-neon", "empty_lowering_tag", "name={s} has no lowering tag", .{shape.name});
    if (shape.kind.len == 0)
        common.violation("isa-neon", "empty_lowering_kind", "name={s} lowering={s} has no lowering kind", .{ shape.name, shape.jit_lowering });
    if (shape.can_lower and shape.assembly.len == 0)
        common.violation("isa-neon", "empty_assembly", "name={s} lowering={s} can_lower=true but has no assembly template", .{ shape.name, shape.jit_lowering });
    if (!shape.can_lower and shape.assembly.len == 0)
        common.violation("isa-neon", "empty_fallback", "name={s} lowering={s} fallback has no fallback call", .{ shape.name, shape.jit_lowering });
    if (shape.can_lower and !looksLikeArm64Assembly(shape.assembly))
        common.violation("isa-neon", "assembly_shape", "name={s} lowering={s} assembly template lacks ARM64/NEON opcodes", .{ shape.name, shape.jit_lowering });
}

fn isPlaceholder(value: []const u8) bool {
    return asciiEql(value, "uncategorized") or asciiEql(value, "unknown");
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

fn samePathLeaf(a: []const u8, b: []const u8) bool {
    return asciiEql(a, b);
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

fn looksLikeArm64Assembly(assembly: []const u8) bool {
    const opcodes = [_][]const u8{
        "adds",
        "adcs",
        "subs",
        "fadd",
        "fsub",
        "mul",
        "umulh",
        "smull",
        "udiv",
        "sdiv",
        "ldr",
        "str",
        "bsl",
        "msub",
        "msr",
        "mrs",
    };
    for (opcodes) |opcode| {
        if (contains(assembly, opcode)) return true;
    }
    return false;
}

test "ISA ABI lowering validator accepts ARM64 skeleton" {
    validateNeonLowering(.{
        .name = "ADDPS",
        .jit_lowering = "arm64_neon_fadd_ps",
        .kind = "neon_vector",
        .assembly = "fadd vD.4s, vN.4s, vM.4s",
        .can_lower = true,
    });
}
