const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");
const core = @import("../../core.zig");
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

pub fn tableCount() usize {
    return specs.len;
}

pub fn findByPath(path: []const u8) ?core.InstructionMathSpec {
    for (specs) |instruction_spec| {
        if (std.mem.eql(u8, instruction_spec.meta.path, path)) return instruction_spec;
    }
    return null;
}

pub fn validateAll() void {
    for (specs) |instruction_spec| validateSpec(instruction_spec);
}

pub fn exerciseAll() !void {
    for (specs) |instruction_spec| try core.exerciseSpec(instruction_spec);
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

test "x86 math specs cover current ISA tables" {
    try std.testing.expectEqual(@as(usize, 26), tableCount());
    validateAll();
    try exerciseAll();
}
