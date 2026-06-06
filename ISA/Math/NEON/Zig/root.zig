const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");
const core = @import("../../core.zig");
const proofs = @import("../../proofs.zig");
const x86_math = @import("../../x86/Zig/root.zig");
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

pub const specs = [_]core.InstructionMathSpec{
    spec(add_adc.meta),
    spec(add_adcx.meta),
    spec(add_add.meta),
    spec(add_addpd.meta),
    spec(add_addps.meta),
    spec(add_addsd.meta),
    spec(add_addss.meta),
    spec(add_addsubpd.meta),
    spec(add_addsubps.meta),
    spec(add_adox.meta),
    spec(ascii_aaa.meta),
    spec(ascii_aad.meta),
    spec(ascii_aam.meta),
    spec(ascii_aas.meta),
    spec(div_div.meta),
    spec(div_idiv.meta),
    spec(inc_dec_dec.meta),
    spec(inc_dec_inc.meta),
    spec(mov_mov.meta),
    spec(mul_imul.meta),
    spec(mul_mul.meta),
    spec(sub_sub.meta),
    spec(sub_subpd.meta),
    spec(sub_subps.meta),
    spec(sub_subsd.meta),
    spec(sub_subss.meta),
};

pub const proof_reports = [_]proofs.ProofReport{
    add_adc.proof_report,
    add_adcx.proof_report,
    add_add.proof_report,
    add_addpd.proof_report,
    add_addps.proof_report,
    add_addsd.proof_report,
    add_addss.proof_report,
    add_addsubpd.proof_report,
    add_addsubps.proof_report,
    add_adox.proof_report,
    ascii_aaa.proof_report,
    ascii_aad.proof_report,
    ascii_aam.proof_report,
    ascii_aas.proof_report,
    div_div.proof_report,
    div_idiv.proof_report,
    inc_dec_dec.proof_report,
    inc_dec_inc.proof_report,
    mov_mov.proof_report,
    mul_imul.proof_report,
    mul_mul.proof_report,
    sub_sub.proof_report,
    sub_subpd.proof_report,
    sub_subps.proof_report,
    sub_subsd.proof_report,
    sub_subss.proof_report,
};

pub fn tableCount() usize {
    return specs.len;
}

pub fn proofReportCount() usize {
    return proof_reports.len;
}

pub fn proofCaseCount() usize {
    var count: usize = 0;
    for (proof_reports) |report| count += report.caseCount();
    return count;
}

pub fn findByPath(path: []const u8) ?core.InstructionMathSpec {
    for (specs) |instruction_spec| {
        if (std.mem.eql(u8, instruction_spec.meta.path, path)) return instruction_spec;
    }
    return null;
}

pub fn validateAll() void {
    runtime_abi.isa.validateMirrorTableCounts(x86_math.tableCount(), tableCount());
    for (specs) |instruction_spec| {
        validateSpec(instruction_spec);
        const x86_spec = x86_math.findByPath(instruction_spec.meta.path) orelse continue;
        runtime_abi.isa.validateMathMirror(.{
            .x86_path = x86_spec.meta.path,
            .neon_path = instruction_spec.meta.path,
            .neon_source_table_path = instruction_spec.meta.source_table_path,
            .x86_name = x86_spec.meta.name,
            .neon_name = instruction_spec.meta.name,
            .x86_operation = @tagName(x86_spec.meta.operation),
            .neon_operation = @tagName(instruction_spec.meta.operation),
            .x86_register_model = @tagName(x86_spec.meta.register_model),
            .neon_register_model = @tagName(instruction_spec.meta.register_model),
            .x86_flag_model = @tagName(x86_spec.meta.flag_model),
            .neon_flag_model = @tagName(instruction_spec.meta.flag_model),
            .x86_edge_case_count = x86_spec.edgeCaseCount(),
            .neon_edge_case_count = instruction_spec.edgeCaseCount(),
        });
    }
}

pub fn exerciseAll() !void {
    for (specs) |instruction_spec| try core.exerciseSpec(instruction_spec);
    try verifyProofsAll();
}

pub fn exerciseMirrors() !void {
    try std.testing.expectEqual(x86_math.tableCount(), tableCount());
    try std.testing.expectEqual(x86_math.proofReportCount(), proofReportCount());
    try std.testing.expectEqual(x86_math.proofCaseCount(), proofCaseCount());
    for (x86_math.specs) |x86_spec| {
        const neon_spec = findByPath(x86_spec.meta.path) orelse return error.MissingNeonMathMirror;
        try std.testing.expectEqualStrings(x86_spec.meta.name, neon_spec.meta.name);
        try std.testing.expectEqual(x86_spec.meta.operation, neon_spec.meta.operation);
        try std.testing.expectEqual(x86_spec.meta.register_model, neon_spec.meta.register_model);
        try std.testing.expectEqual(x86_spec.meta.flag_model, neon_spec.meta.flag_model);
        try std.testing.expectEqual(x86_spec.edgeCaseCount(), neon_spec.edgeCaseCount());
    }
}

pub fn verifyProofsAll() !void {
    for (proof_reports) |report| try proofs.verifyReport(report);
}

fn spec(meta: core.InstructionMathMeta) core.InstructionMathSpec {
    return core.specFromMeta(meta);
}

fn validateSpec(instruction_spec: core.InstructionMathSpec) void {
    runtime_abi.isa.validateMathSpec(.{
        .target_isa = @tagName(instruction_spec.meta.target_isa),
        .instruction_name = instruction_spec.meta.name,
        .path = instruction_spec.meta.path,
        .source_table_path = instruction_spec.meta.source_table_path,
        .operation = @tagName(instruction_spec.meta.operation),
        .register_model = @tagName(instruction_spec.meta.register_model),
        .flag_model = @tagName(instruction_spec.meta.flag_model),
        .edge_case_count = instruction_spec.edgeCaseCount(),
        .validates_registers = instruction_spec.validatesRegisters(),
        .validates_flags = instruction_spec.validatesFlags(),
        .validates_overflow = instruction_spec.validatesOverflow(),
        .validates_traps = instruction_spec.validatesTraps(),
    });
}

test "NEON math specs mirror x86 value and flag coverage" {
    try std.testing.expectEqual(x86_math.tableCount(), tableCount());
    validateAll();
    try exerciseAll();
    try exerciseMirrors();
}
