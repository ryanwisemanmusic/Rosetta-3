const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");
const x86 = @import("../../x86/Zig/root.zig");
const add_adc = @import("ADD/ADC.zig");
const add_adcx = @import("ADD/ADCX.zig");
const add_add = @import("ADD/ADD.zig");
const add_addpd = @import("ADD/ADDPD.zig");
const add_addps = @import("ADD/ADDPS.zig");
const add_addsd = @import("ADD/ADDSD.zig");
const add_addss = @import("ADD/ADDSS.zig");
const add_addsubpd = @import("ADD/ADDSUBPD.zig");
const add_addsubps = @import("ADD/ADDSUBPS.zig");
const add_adox = @import("ADD/ADOX.zig");
const ascii_aaa = @import("ASCII/AAA.zig");
const ascii_aad = @import("ASCII/AAD.zig");
const ascii_aam = @import("ASCII/AAM.zig");
const ascii_aas = @import("ASCII/AAS.zig");
const div_div = @import("DIV/DIV.zig");
const div_idiv = @import("DIV/IDIV.zig");
const inc_dec_dec = @import("INC-DEC/DEC.zig");
const inc_dec_inc = @import("INC-DEC/INC.zig");
const mov_mov = @import("MOV/MOV.zig");
const mul_imul = @import("MUL/IMUL.zig");
const mul_mul = @import("MUL/MUL.zig");
const sub_sub = @import("SUB/SUB.zig");
const sub_subpd = @import("SUB/SUBPD.zig");
const sub_subps = @import("SUB/SUBPS.zig");
const sub_subsd = @import("SUB/SUBSD.zig");
const sub_subss = @import("SUB/SUBSS.zig");

pub const LoweringKind = enum {
    arm64_scalar,
    neon_vector,
    neon_scalar,
    system_dispatch,
    fallback,
};

pub const MirrorTable = struct {
    path: []const u8,
    source: []const u8,

    pub fn name(self: MirrorTable) []const u8 {
        return stringAssignment(self.source, "name") orelse mnemonicFromPath(self.path);
    }

    pub fn x86TablePath(self: MirrorTable) []const u8 {
        return stringAssignment(self.source, "x86_table") orelse "";
    }

    pub fn neonLowering(self: MirrorTable) []const u8 {
        return stringAssignment(self.source, "neon_lowering") orelse "";
    }

    pub fn encodingCount(self: MirrorTable) usize {
        return countEncodingRows(self.source);
    }

    pub fn hasSemantic(self: MirrorTable) bool {
        return hasAnyAssignment(self.source, &[_][]const u8{
            "semantic",
            "semantic_general",
            "semantic_legacy",
            "semantic_one_operand",
        });
    }

    pub fn hasFlags(self: MirrorTable) bool {
        return hasAnyAssignment(self.source, &[_][]const u8{
            "flags",
            "flags_written",
            "flags_affected",
            "flags_set_or_cleared",
            "mxcsr_used",
            "simd_fp_exceptions",
        });
    }

    pub fn hasNeonRegisterModel(self: MirrorTable) bool {
        return hasAssignment(self.source, "neon_register_model");
    }

    pub fn hasNeonFlagModel(self: MirrorTable) bool {
        return hasAssignment(self.source, "neon_flag_model");
    }

    pub fn hasNeonAssembly(self: MirrorTable) bool {
        return hasAssignment(self.source, "neon_assembly");
    }
};

pub const LoweringPlan = struct {
    x86_name: []const u8,
    x86_lowering: []const u8,
    kind: LoweringKind,
    assembly: []const u8,
    can_lower: bool = true,
};

pub const mirror_tables = [_]MirrorTable{
    mirror(add_adc.path, add_adc.source),
    mirror(add_adcx.path, add_adcx.source),
    mirror(add_add.path, add_add.source),
    mirror(add_addpd.path, add_addpd.source),
    mirror(add_addps.path, add_addps.source),
    mirror(add_addsd.path, add_addsd.source),
    mirror(add_addss.path, add_addss.source),
    mirror(add_addsubpd.path, add_addsubpd.source),
    mirror(add_addsubps.path, add_addsubps.source),
    mirror(add_adox.path, add_adox.source),
    mirror(ascii_aaa.path, ascii_aaa.source),
    mirror(ascii_aad.path, ascii_aad.source),
    mirror(ascii_aam.path, ascii_aam.source),
    mirror(ascii_aas.path, ascii_aas.source),
    mirror(div_div.path, div_div.source),
    mirror(div_idiv.path, div_idiv.source),
    mirror(inc_dec_dec.path, inc_dec_dec.source),
    mirror(inc_dec_inc.path, inc_dec_inc.source),
    mirror(mov_mov.path, mov_mov.source),
    mirror(mul_imul.path, mul_imul.source),
    mirror(mul_mul.path, mul_mul.source),
    mirror(sub_sub.path, sub_sub.source),
    mirror(sub_subpd.path, sub_subpd.source),
    mirror(sub_subps.path, sub_subps.source),
    mirror(sub_subsd.path, sub_subsd.source),
    mirror(sub_subss.path, sub_subss.source),
};

pub fn tableCount() usize {
    return mirror_tables.len;
}

pub fn findMirror(path: []const u8) ?MirrorTable {
    for (mirror_tables) |table| {
        if (std.mem.eql(u8, table.path, path)) return table;
    }
    return null;
}

pub fn planFor(table: x86.InstructionTable) LoweringPlan {
    const meta = table.metadata();
    const mapped = mappedLowering(meta.jit_lowering);
    return .{
        .x86_name = meta.name,
        .x86_lowering = meta.jit_lowering,
        .kind = mapped.kind,
        .assembly = mapped.assembly,
        .can_lower = mapped.can_lower,
    };
}

pub fn validateAll() void {
    runtime_abi.isa.validateMirrorTableCounts(x86.tableCount(), tableCount());
    for (x86.tables) |table| {
        const meta = table.metadata();
        const mirror_table = findMirror(table.path) orelse {
            runtime_abi.isa.validateMissingNeonMirror(table.path);
            continue;
        };
        runtime_abi.isa.validateNeonMirror(.{
            .x86_path = table.path,
            .neon_path = mirror_table.path,
            .declared_x86_table = mirror_table.x86TablePath(),
            .x86_name = meta.name,
            .neon_name = mirror_table.name(),
            .x86_lowering = meta.jit_lowering,
            .neon_lowering = mirror_table.neonLowering(),
            .x86_encoding_count = meta.encoding_count,
            .neon_encoding_count = mirror_table.encodingCount(),
            .x86_has_semantic = meta.has_semantic,
            .neon_has_semantic = mirror_table.hasSemantic(),
            .x86_has_flags = meta.has_flags,
            .neon_has_flags = mirror_table.hasFlags(),
            .neon_has_register_model = mirror_table.hasNeonRegisterModel(),
            .neon_has_flag_model = mirror_table.hasNeonFlagModel(),
            .neon_has_assembly = mirror_table.hasNeonAssembly(),
        });

        const plan = planFor(table);
        runtime_abi.isa.validateNeonLowering(.{
            .name = plan.x86_name,
            .jit_lowering = plan.x86_lowering,
            .kind = @tagName(plan.kind),
            .assembly = plan.assembly,
            .can_lower = plan.can_lower,
        });
    }
}

fn mirror(path: []const u8, source: []const u8) MirrorTable {
    return .{ .path = path, .source = source };
}

const MappedLowering = struct {
    kind: LoweringKind,
    assembly: []const u8,
    can_lower: bool = true,
};

fn mappedLowering(lowering: []const u8) MappedLowering {
    if (std.mem.eql(u8, lowering, "arm64_add_with_x86_flags")) return .{ .kind = .arm64_scalar, .assembly = "adds xD, xN, xM\nmrs xFLAGS, nzcv\nbl rosette_pack_x86_add_flags" };
    if (std.mem.eql(u8, lowering, "arm64_adc_with_x86_flags")) return .{ .kind = .arm64_scalar, .assembly = "msr nzcv, x86_carry_to_nzcv(CF)\nadcs xD, xN, xM\nmrs xFLAGS, nzcv\nbl rosette_pack_x86_adc_flags" };
    if (std.mem.eql(u8, lowering, "fallback_or_arm64_adcs_preserve_other_flags")) return .{ .kind = .arm64_scalar, .assembly = "msr nzcv, x86_carry_to_nzcv(CF)\nadcs xD, xN, xM\nbl rosette_preserve_non_cf_status_flags" };
    if (std.mem.eql(u8, lowering, "arm64_add_imm_1_preserve_cf")) return .{ .kind = .arm64_scalar, .assembly = "adds xD, xN, #1\nbl rosette_pack_x86_inc_flags_preserve_cf" };
    if (std.mem.eql(u8, lowering, "arm64_sub_imm_1_preserve_cf")) return .{ .kind = .arm64_scalar, .assembly = "subs xD, xN, #1\nbl rosette_pack_x86_dec_flags_preserve_cf" };
    if (std.mem.eql(u8, lowering, "arm64_sub")) return .{ .kind = .arm64_scalar, .assembly = "subs xD, xN, xM\nmrs xFLAGS, nzcv\nbl rosette_pack_x86_sub_flags" };
    if (std.mem.eql(u8, lowering, "arm64_signed_multiply")) return .{ .kind = .arm64_scalar, .assembly = "smull xTMP, wN, wM\nmul xLO, xN, xM\nasr xHI, xTMP, #32\nbl rosette_pack_x86_imul_flags" };
    if (std.mem.eql(u8, lowering, "arm64_unsigned_multiply")) return .{ .kind = .arm64_scalar, .assembly = "umulh xHI, xN, xM\nmul xLO, xN, xM\nbl rosette_pack_x86_mul_flags" };
    if (std.mem.eql(u8, lowering, "arm64_unsigned_divide")) return .{ .kind = .arm64_scalar, .assembly = "cbz xDIVISOR, rosette_raise_de\nudiv xQ, xDIVIDEND, xDIVISOR\nmsub xR, xQ, xDIVISOR, xDIVIDEND" };
    if (std.mem.eql(u8, lowering, "arm64_signed_divide")) return .{ .kind = .arm64_scalar, .assembly = "cbz xDIVISOR, rosette_raise_de\nsdiv xQ, xDIVIDEND, xDIVISOR\nmsub xR, xQ, xDIVISOR, xDIVIDEND" };
    if (std.mem.eql(u8, lowering, "arm64_mov_or_system_register_dispatch")) return .{ .kind = .system_dispatch, .assembly = "ldr xTMP, [xSRC]\nstr xTMP, [xDST]\nbl rosette_dispatch_system_register_move_if_needed" };
    if (std.mem.eql(u8, lowering, "arm64_neon_fadd_ps")) return .{ .kind = .neon_vector, .assembly = "fadd vD.4s, vN.4s, vM.4s\nbl rosette_apply_mxcsr_float_exceptions" };
    if (std.mem.eql(u8, lowering, "arm64_neon_fadd_pd")) return .{ .kind = .neon_vector, .assembly = "fadd vD.2d, vN.2d, vM.2d\nbl rosette_apply_mxcsr_float_exceptions" };
    if (std.mem.eql(u8, lowering, "arm64_scalar_fadd_s")) return .{ .kind = .neon_scalar, .assembly = "fadd sD, sN, sM\nbl rosette_apply_mxcsr_float_exceptions" };
    if (std.mem.eql(u8, lowering, "arm64_scalar_fadd_d")) return .{ .kind = .neon_scalar, .assembly = "fadd dD, dN, dM\nbl rosette_apply_mxcsr_float_exceptions" };
    if (std.mem.eql(u8, lowering, "arm64_neon_fadd_fsub_by_lane_pattern")) return .{ .kind = .neon_vector, .assembly = "fadd vTMP.4s, vN.4s, vM.4s\nfsub vALT.4s, vN.4s, vM.4s\nbsl vMASK.16b, vTMP.16b, vALT.16b" };
    if (std.mem.eql(u8, lowering, "arm64_neon_fsub_ps")) return .{ .kind = .neon_vector, .assembly = "fsub vD.4s, vN.4s, vM.4s\nbl rosette_apply_mxcsr_float_exceptions" };
    if (std.mem.eql(u8, lowering, "arm64_neon_fsub_pd")) return .{ .kind = .neon_vector, .assembly = "fsub vD.2d, vN.2d, vM.2d\nbl rosette_apply_mxcsr_float_exceptions" };
    if (std.mem.eql(u8, lowering, "arm64_neon_fsub_ss")) return .{ .kind = .neon_scalar, .assembly = "fsub sD, sN, sM\nbl rosette_merge_scalar_high_lanes\nbl rosette_apply_mxcsr_float_exceptions" };
    if (std.mem.eql(u8, lowering, "arm64_neon_fsub_sd")) return .{ .kind = .neon_scalar, .assembly = "fsub dD, dN, dM\nbl rosette_merge_scalar_high_lanes\nbl rosette_apply_mxcsr_float_exceptions" };
    if (std.mem.eql(u8, lowering, "fallback")) return .{ .kind = .fallback, .assembly = "bl rosette_x86_instruction_fallback", .can_lower = false };
    return .{ .kind = .fallback, .assembly = "", .can_lower = false };
}

fn stripLineComment(line: []const u8) []const u8 {
    const idx = std.mem.indexOf(u8, line, "//") orelse return line;
    return line[0..idx];
}

fn stringAssignment(source: []const u8, key: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, source, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, stripLineComment(raw_line), " \t\r");
        if (!std.mem.startsWith(u8, line, key)) continue;
        const rest = std.mem.trim(u8, line[key.len..], " \t");
        if (!std.mem.startsWith(u8, rest, "=")) continue;
        const value = std.mem.trim(u8, rest[1..], " \t");
        if (value.len < 2 or value[0] != '"') continue;
        const end = std.mem.indexOfScalar(u8, value[1..], '"') orelse continue;
        return value[1 .. 1 + end];
    }
    return null;
}

fn hasAnyAssignment(source: []const u8, keys: []const []const u8) bool {
    for (keys) |key| {
        if (hasAssignment(source, key)) return true;
    }
    return false;
}

fn hasAssignment(source: []const u8, key: []const u8) bool {
    var lines = std.mem.splitScalar(u8, source, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, stripLineComment(raw_line), " \t\r");
        if (!std.mem.startsWith(u8, line, key)) continue;
        const rest = std.mem.trim(u8, line[key.len..], " \t");
        if (std.mem.startsWith(u8, rest, "=")) return true;
    }
    return false;
}

fn countEncodingRows(source: []const u8) usize {
    const block_start = std.mem.indexOf(u8, source, "encodings") orelse return 0;
    const bracket_rel = std.mem.indexOfScalar(u8, source[block_start..], '[') orelse return 0;
    const body_start = block_start + bracket_rel + 1;
    const body_end_rel = std.mem.indexOfScalar(u8, source[body_start..], ']') orelse return 0;
    const body = source[body_start .. body_start + body_end_rel];

    var count: usize = 0;
    var lines = std.mem.splitScalar(u8, body, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, stripLineComment(raw_line), " \t\r");
        if (std.mem.startsWith(u8, line, "{")) count += 1;
    }
    return count;
}

fn mnemonicFromPath(path: []const u8) []const u8 {
    const slash = std.mem.lastIndexOfScalar(u8, path, '/') orelse 0;
    const start = if (path[slash] == '/') slash + 1 else slash;
    const dot = std.mem.lastIndexOfScalar(u8, path, '.') orelse path.len;
    return path[start..dot];
}

test "NEON mirrors every x86 instruction table" {
    try std.testing.expectEqual(x86.tableCount(), tableCount());
    validateAll();
    const add = x86.findByName("ADD") orelse return error.MissingAdd;
    const plan = planFor(add);
    try std.testing.expectEqual(LoweringKind.arm64_scalar, plan.kind);
    try std.testing.expect(std.mem.indexOf(u8, plan.assembly, "adds") != null);
}
