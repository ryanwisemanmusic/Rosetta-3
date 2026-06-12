const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");
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
const call_ret_call = @import("CALL-RET/CALL.zig");
const call_ret_leave = @import("CALL-RET/LEAVE.zig");
const call_ret_ret = @import("CALL-RET/RET.zig");
const cmp_cmp = @import("CMP/CMP.zig");
const cmp_cmppd = @import("CMP/CMPPD.zig");
const cmp_cmpps = @import("CMP/CMPPS.zig");
const cmp_cmpsd = @import("CMP/CMPSD.zig");
const cmp_cmpss = @import("CMP/CMPSS.zig");
const div_div = @import("DIV/DIV.zig");
const div_divpd = @import("DIV/DIVPD.zig");
const div_divps = @import("DIV/DIVPS.zig");
const div_divsd = @import("DIV/DIVSD.zig");
const div_divss = @import("DIV/DIVSS.zig");
const div_idiv = @import("DIV/IDIV.zig");
const inc_dec_dec = @import("INC-DEC/DEC.zig");
const inc_dec_inc = @import("INC-DEC/INC.zig");
const jmp_ja = @import("JMP/JA.zig");
const jmp_jae = @import("JMP/JAE.zig");
const jmp_jb = @import("JMP/JB.zig");
const jmp_jbe = @import("JMP/JBE.zig");
const jmp_jc = @import("JMP/JC.zig");
const jmp_jcxz = @import("JMP/JCXZ.zig");
const jmp_je = @import("JMP/JE.zig");
const jmp_jecxz = @import("JMP/JECXZ.zig");
const jmp_jg = @import("JMP/JG.zig");
const jmp_jge = @import("JMP/JGE.zig");
const jmp_jl = @import("JMP/JL.zig");
const jmp_jle = @import("JMP/JLE.zig");
const jmp_jmp = @import("JMP/JMP.zig");
const jmp_jna = @import("JMP/JNA.zig");
const jmp_jnae = @import("JMP/JNAE.zig");
const jmp_jnb = @import("JMP/JNB.zig");
const jmp_jnbe = @import("JMP/JNBE.zig");
const jmp_jnc = @import("JMP/JNC.zig");
const jmp_jne = @import("JMP/JNE.zig");
const jmp_jng = @import("JMP/JNG.zig");
const jmp_jnge = @import("JMP/JNGE.zig");
const jmp_jnl = @import("JMP/JNL.zig");
const jmp_jnle = @import("JMP/JNLE.zig");
const jmp_jno = @import("JMP/JNO.zig");
const jmp_jnp = @import("JMP/JNP.zig");
const jmp_jns = @import("JMP/JNS.zig");
const jmp_jnz = @import("JMP/JNZ.zig");
const jmp_jo = @import("JMP/JO.zig");
const jmp_jp = @import("JMP/JP.zig");
const jmp_jpe = @import("JMP/JPE.zig");
const jmp_jpo = @import("JMP/JPO.zig");
const jmp_jrcxz = @import("JMP/JRCXZ.zig");
const jmp_js = @import("JMP/JS.zig");
const jmp_jz = @import("JMP/JZ.zig");
const load_lahf = @import("LOAD/LAHF.zig");
const load_lar = @import("LOAD/LAR.zig");
const load_lddqu = @import("LOAD/LDDQU.zig");
const load_ldmxcsr = @import("LOAD/LDMXCSR.zig");
const load_lds = @import("LOAD/LDS.zig");
const load_ldtilecfg = @import("LOAD/LDTILECFG.zig");
const load_lea = @import("LOAD/LEA.zig");
const load_les = @import("LOAD/LES.zig");
const load_lfence = @import("LOAD/LFENCE.zig");
const load_lfs = @import("LOAD/LFS.zig");
const load_lgdt = @import("LOAD/LGDT.zig");
const load_lgs = @import("LOAD/LGS.zig");
const load_lidt = @import("LOAD/LIDT.zig");
const load_lldt = @import("LOAD/LLDT.zig");
const load_lmsw = @import("LOAD/LMSW.zig");
const load_loadiwkey = @import("LOAD/LOADIWKEY.zig");
const load_lods = @import("LOAD/LODS.zig");
const load_lodsb = @import("LOAD/LODSB.zig");
const load_lodsd = @import("LOAD/LODSD.zig");
const load_lodsq = @import("LOAD/LODSQ.zig");
const load_lodsw = @import("LOAD/LODSW.zig");
const load_lsl = @import("LOAD/LSL.zig");
const load_lss = @import("LOAD/LSS.zig");
const load_ltr = @import("LOAD/LTR.zig");
const mov_mov = @import("MOV/MOV.zig");
const mov_movapd = @import("MOV/MOVAPD.zig");
const mov_movaps = @import("MOV/MOVAPS.zig");
const mov_movbe = @import("MOV/MOVBE.zig");
const mov_movd = @import("MOV/MOVD.zig");
const mov_movddup = @import("MOV/MOVDDUP.zig");
const mov_movdir64b = @import("MOV/MOVDIR64B.zig");
const mov_movdiri = @import("MOV/MOVDIRI.zig");
const mov_movdq2q = @import("MOV/MOVDQ2Q.zig");
const mov_movdqa = @import("MOV/MOVDQA.zig");
const mov_movdqu = @import("MOV/MOVDQU.zig");
const mov_movhlps = @import("MOV/MOVHLPS.zig");
const mov_movhpd = @import("MOV/MOVHPD.zig");
const mov_movhps = @import("MOV/MOVHPS.zig");
const mov_movlhps = @import("MOV/MOVLHPS.zig");
const mov_movlpd = @import("MOV/MOVLPD.zig");
const mov_movlps = @import("MOV/MOVLPS.zig");
const mov_movmskpd = @import("MOV/MOVMSKPD.zig");
const mov_movmskps = @import("MOV/MOVMSKPS.zig");
const mov_movntdq = @import("MOV/MOVNTDQ.zig");
const mov_movntdqa = @import("MOV/MOVNTDQA.zig");
const mov_movnti = @import("MOV/MOVNTI.zig");
const mov_movntpd = @import("MOV/MOVNTPD.zig");
const mov_movntps = @import("MOV/MOVNTPS.zig");
const mov_movntq = @import("MOV/MOVNTQ.zig");
const mov_movq = @import("MOV/MOVQ.zig");
const mov_movq2dq = @import("MOV/MOVQ2DQ.zig");
const mov_movs = @import("MOV/MOVS.zig");
const mov_movsb = @import("MOV/MOVSB.zig");
const mov_movsd = @import("MOV/MOVSD.zig");
const mov_movshdup = @import("MOV/MOVSHDUP.zig");
const mov_movsldup = @import("MOV/MOVSLDUP.zig");
const mov_movsq = @import("MOV/MOVSQ.zig");
const mov_movss = @import("MOV/MOVSS.zig");
const mov_movsw = @import("MOV/MOVSW.zig");
const mov_movsx = @import("MOV/MOVSX.zig");
const mov_movsxd = @import("MOV/MOVSXD.zig");
const mov_movupd = @import("MOV/MOVUPD.zig");
const mov_movups = @import("MOV/MOVUPS.zig");
const mov_movzx = @import("MOV/MOVZX.zig");
const mov_vmovapd = @import("MOV/VMOVAPD.zig");
const mov_vmovaps = @import("MOV/VMOVAPS.zig");
const mov_vmovd = @import("MOV/VMOVD.zig");
const mov_vmovddup = @import("MOV/VMOVDDUP.zig");
const mov_vmovdqa = @import("MOV/VMOVDQA.zig");
const mov_vmovdqa32 = @import("MOV/VMOVDQA32.zig");
const mov_vmovdqa64 = @import("MOV/VMOVDQA64.zig");
const mov_vmovdqu = @import("MOV/VMOVDQU.zig");
const mov_vmovdqu16 = @import("MOV/VMOVDQU16.zig");
const mov_vmovdqu32 = @import("MOV/VMOVDQU32.zig");
const mov_vmovdqu64 = @import("MOV/VMOVDQU64.zig");
const mov_vmovdqu8 = @import("MOV/VMOVDQU8.zig");
const mov_vmovhlps = @import("MOV/VMOVHLPS.zig");
const mov_vmovhpd = @import("MOV/VMOVHPD.zig");
const mov_vmovhps = @import("MOV/VMOVHPS.zig");
const mov_vmovlhps = @import("MOV/VMOVLHPS.zig");
const mov_vmovlpd = @import("MOV/VMOVLPD.zig");
const mov_vmovlps = @import("MOV/VMOVLPS.zig");
const mov_vmovmskpd = @import("MOV/VMOVMSKPD.zig");
const mov_vmovmskps = @import("MOV/VMOVMSKPS.zig");
const mov_vmovntdq = @import("MOV/VMOVNTDQ.zig");
const mov_vmovntdqa = @import("MOV/VMOVNTDQA.zig");
const mov_vmovntpd = @import("MOV/VMOVNTPD.zig");
const mov_vmovntps = @import("MOV/VMOVNTPS.zig");
const mov_vmovq = @import("MOV/VMOVQ.zig");
const mov_vmovsd = @import("MOV/VMOVSD.zig");
const mov_vmovshdup = @import("MOV/VMOVSHDUP.zig");
const mov_vmovsldup = @import("MOV/VMOVSLDUP.zig");
const mov_vmovss = @import("MOV/VMOVSS.zig");
const mov_vmovupd = @import("MOV/VMOVUPD.zig");
const mov_vmovups = @import("MOV/VMOVUPS.zig");
const mul_imul = @import("MUL/IMUL.zig");
const mul_mul = @import("MUL/MUL.zig");
const mul_mulpd = @import("MUL/MULPD.zig");
const mul_mulps = @import("MUL/MULPS.zig");
const mul_mulsd = @import("MUL/MULSD.zig");
const mul_mulss = @import("MUL/MULSS.zig");
const mul_mulx = @import("MUL/MULX.zig");
const or_or = @import("OR/OR.zig");
const or_orpd = @import("OR/ORPD.zig");
const or_orps = @import("OR/ORPS.zig");
const pop_pop = @import("POP/POP.zig");
const pop_popa = @import("POP/POPA.zig");
const pop_popad = @import("POP/POPAD.zig");
const pop_popcnt = @import("POP/POPCNT.zig");
const push_push = @import("PUSH/PUSH.zig");
const push_pusha = @import("PUSH/PUSHA.zig");
const push_pushad = @import("PUSH/PUSHAD.zig");
const rotate_rcl = @import("ROTATE/RCL.zig");
const rotate_rcr = @import("ROTATE/RCR.zig");
const rotate_rol = @import("ROTATE/ROL.zig");
const rotate_ror = @import("ROTATE/ROR.zig");
const sub_sub = @import("SUB/SUB.zig");
const sub_subpd = @import("SUB/SUBPD.zig");
const sub_subps = @import("SUB/SUBPS.zig");
const sub_subsd = @import("SUB/SUBSD.zig");
const sub_subss = @import("SUB/SUBSS.zig");
const test_test = @import("TEST/TEST.zig");
const test_testui = @import("TEST/TESTUI.zig");
const xor_xor = @import("XOR/XOR.zig");
const xor_xorpd = @import("XOR/XORPD.zig");
const xor_xorps = @import("XOR/XORPS.zig");
const and_and = @import("AND/AND.zig");
const and_andn = @import("AND/ANDN.zig");
const and_andps = @import("AND/ANDPS.zig");
const and_andpd = @import("AND/ANDPD.zig");
const and_andnps = @import("AND/ANDNPS.zig");
const and_andnpd = @import("AND/ANDNPD.zig");
const sys_syscall = @import("SYS/SYSCALL.zig");
const sys_sysenter = @import("SYS/SYSENTER.zig");
const sys_sysexit = @import("SYS/SYSEXIT.zig");
const sys_sysret = @import("SYS/SYSRET.zig");
const blend_blendpd = @import("BLEND/BLENDPD.zig");
const blend_blendps = @import("BLEND/BLENDPS.zig");
const blend_blendvpd = @import("BLEND/BLENDVPD.zig");
const blend_blendvps = @import("BLEND/BLENDVPS.zig");

pub const documented_reference_mnemonics = [_][]const u8{
    "AAA",
    "AAD",
    "AAM",
    "AAS",
    "ADC",
    "ADCX",
    "ADD",
    "ADDPD",
    "ADDPS",
    "ADDSD",
    "ADDSS",
    "ADDSUBPD",
    "ADDSUBPS",
    "ADOX",
    "CALL",
    "CMP",
    "CMPPD",
    "CMPPS",
    "CMPSD",
    "CMPSS",
    "DEC",
    "DIV",
    "DIVPD",
    "DIVPS",
    "DIVSD",
    "DIVSS",
    "IDIV",
    "IMUL",
    "INC",
    "JA",
    "JAE",
    "JB",
    "JBE",
    "JC",
    "JCXZ",
    "JE",
    "JECXZ",
    "JG",
    "JGE",
    "JL",
    "JLE",
    "JMP",
    "JNA",
    "JNAE",
    "JNB",
    "JNBE",
    "JNC",
    "JNE",
    "JNG",
    "JNGE",
    "JNL",
    "JNLE",
    "JNO",
    "JNP",
    "JNS",
    "JNZ",
    "JO",
    "JP",
    "JPE",
    "JPO",
    "JRCXZ",
    "JS",
    "JZ",
    "LAHF",
    "LAR",
    "LDDQU",
    "LDMXCSR",
    "LDS",
    "LDTILECFG",
    "LEA",
    "LEAVE",
    "LES",
    "LFENCE",
    "LFS",
    "LGDT",
    "LGS",
    "LIDT",
    "LLDT",
    "LMSW",
    "LOADIWKEY",
    "LODS",
    "LODSB",
    "LODSD",
    "LODSQ",
    "LODSW",
    "LSL",
    "LSS",
    "LTR",
    "MOV",
    "MOVAPD",
    "MOVAPS",
    "MOVBE",
    "MOVD",
    "MOVDDUP",
    "MOVDIR64B",
    "MOVDIRI",
    "MOVDQ2Q",
    "MOVDQA",
    "MOVDQU",
    "MOVHLPS",
    "MOVHPD",
    "MOVHPS",
    "MOVLHPS",
    "MOVLPD",
    "MOVLPS",
    "MOVMSKPD",
    "MOVMSKPS",
    "MOVNTDQ",
    "MOVNTDQA",
    "MOVNTI",
    "MOVNTPD",
    "MOVNTPS",
    "MOVNTQ",
    "MOVQ",
    "MOVQ2DQ",
    "MOVS",
    "MOVSB",
    "MOVSD",
    "MOVSHDUP",
    "MOVSLDUP",
    "MOVSQ",
    "MOVSS",
    "MOVSW",
    "MOVSX",
    "MOVSXD",
    "MOVUPD",
    "MOVUPS",
    "MOVZX",
    "MUL",
    "MULPD",
    "MULPS",
    "MULSD",
    "MULSS",
    "MULX",
    "OR",
    "ORPD",
    "ORPS",
    "POP",
    "POPA",
    "POPAD",
    "POPCNT",
    "PUSH",
    "PUSHA",
    "PUSHAD",
    "RCL",
    "RCR",
    "RET",
    "ROL",
    "ROR",
    "SUB",
    "SUBPD",
    "SUBPS",
    "SUBSD",
    "SUBSS",
    "TEST",
    "TESTUI",
    "VMOVAPD",
    "VMOVAPS",
    "VMOVD",
    "VMOVDDUP",
    "VMOVDQA",
    "VMOVDQA32",
    "VMOVDQA64",
    "VMOVDQU",
    "VMOVDQU16",
    "VMOVDQU32",
    "VMOVDQU64",
    "VMOVDQU8",
    "VMOVHLPS",
    "VMOVHPD",
    "VMOVHPS",
    "VMOVLHPS",
    "VMOVLPD",
    "VMOVLPS",
    "VMOVMSKPD",
    "VMOVMSKPS",
    "VMOVNTDQ",
    "VMOVNTDQA",
    "VMOVNTPD",
    "VMOVNTPS",
    "VMOVQ",
    "VMOVSD",
    "VMOVSHDUP",
    "VMOVSLDUP",
    "VMOVSS",
    "VMOVUPD",
    "VMOVUPS",
    "XOR",
    "XORPD",
    "XORPS",
    "AND",
    "ANDN",
    "ANDPD",
    "ANDPS",
    "ANDNPD",
    "ANDNPS",
    "BLENDPD",
    "BLENDPS",
    "BLENDVPD",
    "BLENDVPS",
    "SYSCALL",
    "SYSENTER",
    "SYSEXIT",
    "SYSRET",
};

pub const TableMetadata = struct {
    name: []const u8,
    category: []const u8,
    handler: []const u8,
    jit_lowering: []const u8,
    encoding_count: usize,
    source_path: []const u8,
    has_semantic: bool,
    has_flags: bool,
};

pub const InstructionTable = struct {
    family: []const u8,
    path: []const u8,
    source: []const u8,

    pub fn metadata(self: InstructionTable) TableMetadata {
        return .{
            .name = anyStringAssignment(self.source, &[_][]const u8{ "name", "instruction" }) orelse mnemonicFromPath(self.path),
            .category = stringAssignment(self.source, "category") orelse "documented_contract",
            .handler = anyStringAssignment(self.source, &[_][]const u8{ "handler", "x86_handler" }) orelse "x86_documented_contract_handler",
            .jit_lowering = anyStringAssignment(self.source, &[_][]const u8{ "jit_lowering", "neon_lowering", "arm64_lowering" }) orelse "arm64_documented_contract_fallback",
            .encoding_count = countEncodingRows(self.source),
            .source_path = self.path,
            .has_semantic = hasAnyAssignment(self.source, &[_][]const u8{
                "semantic",
                "semantic_general",
                "semantic_legacy",
                "semantic_one_operand",
                "source_contract",
                "operation",
            }),
            .has_flags = hasAnyAssignment(self.source, &[_][]const u8{
                "flags",
                "flags_read",
                "flags_written",
                "flags_affected",
                "flags_set_or_cleared",
                "flags_model",
                "mxcsr_used",
                "simd_fp_exceptions",
            }),
        };
    }

    pub fn validate(self: InstructionTable) void {
        const meta = self.metadata();
        runtime_abi.isa.validateX86Table(.{
            .name = meta.name,
            .category = meta.category,
            .handler = meta.handler,
            .jit_lowering = meta.jit_lowering,
            .source_path = meta.source_path,
            .encoding_count = meta.encoding_count,
            .has_semantic = meta.has_semantic,
            .has_flags = meta.has_flags,
        });
    }
};

pub const tables = [_]InstructionTable{
    entry(add_adc.family, add_adc.path, add_adc.source),
    entry(add_adcx.family, add_adcx.path, add_adcx.source),
    entry(add_add.family, add_add.path, add_add.source),
    entry(add_addpd.family, add_addpd.path, add_addpd.source),
    entry(add_addps.family, add_addps.path, add_addps.source),
    entry(add_addsd.family, add_addsd.path, add_addsd.source),
    entry(add_addss.family, add_addss.path, add_addss.source),
    entry(add_addsubpd.family, add_addsubpd.path, add_addsubpd.source),
    entry(add_addsubps.family, add_addsubps.path, add_addsubps.source),
    entry(add_adox.family, add_adox.path, add_adox.source),
    entry(ascii_aaa.family, ascii_aaa.path, ascii_aaa.source),
    entry(ascii_aad.family, ascii_aad.path, ascii_aad.source),
    entry(ascii_aam.family, ascii_aam.path, ascii_aam.source),
    entry(ascii_aas.family, ascii_aas.path, ascii_aas.source),
    entry(call_ret_call.family, call_ret_call.path, call_ret_call.source),
    entry(call_ret_leave.family, call_ret_leave.path, call_ret_leave.source),
    entry(call_ret_ret.family, call_ret_ret.path, call_ret_ret.source),
    entry(cmp_cmp.family, cmp_cmp.path, cmp_cmp.source),
    entry(cmp_cmppd.family, cmp_cmppd.path, cmp_cmppd.source),
    entry(cmp_cmpps.family, cmp_cmpps.path, cmp_cmpps.source),
    entry(cmp_cmpsd.family, cmp_cmpsd.path, cmp_cmpsd.source),
    entry(cmp_cmpss.family, cmp_cmpss.path, cmp_cmpss.source),
    entry(div_div.family, div_div.path, div_div.source),
    entry(div_divpd.family, div_divpd.path, div_divpd.source),
    entry(div_divps.family, div_divps.path, div_divps.source),
    entry(div_divsd.family, div_divsd.path, div_divsd.source),
    entry(div_divss.family, div_divss.path, div_divss.source),
    entry(div_idiv.family, div_idiv.path, div_idiv.source),
    entry(inc_dec_dec.family, inc_dec_dec.path, inc_dec_dec.source),
    entry(inc_dec_inc.family, inc_dec_inc.path, inc_dec_inc.source),
    entry(jmp_ja.family, jmp_ja.path, jmp_ja.source),
    entry(jmp_jae.family, jmp_jae.path, jmp_jae.source),
    entry(jmp_jb.family, jmp_jb.path, jmp_jb.source),
    entry(jmp_jbe.family, jmp_jbe.path, jmp_jbe.source),
    entry(jmp_jc.family, jmp_jc.path, jmp_jc.source),
    entry(jmp_jcxz.family, jmp_jcxz.path, jmp_jcxz.source),
    entry(jmp_je.family, jmp_je.path, jmp_je.source),
    entry(jmp_jecxz.family, jmp_jecxz.path, jmp_jecxz.source),
    entry(jmp_jg.family, jmp_jg.path, jmp_jg.source),
    entry(jmp_jge.family, jmp_jge.path, jmp_jge.source),
    entry(jmp_jl.family, jmp_jl.path, jmp_jl.source),
    entry(jmp_jle.family, jmp_jle.path, jmp_jle.source),
    entry(jmp_jmp.family, jmp_jmp.path, jmp_jmp.source),
    entry(jmp_jna.family, jmp_jna.path, jmp_jna.source),
    entry(jmp_jnae.family, jmp_jnae.path, jmp_jnae.source),
    entry(jmp_jnb.family, jmp_jnb.path, jmp_jnb.source),
    entry(jmp_jnbe.family, jmp_jnbe.path, jmp_jnbe.source),
    entry(jmp_jnc.family, jmp_jnc.path, jmp_jnc.source),
    entry(jmp_jne.family, jmp_jne.path, jmp_jne.source),
    entry(jmp_jng.family, jmp_jng.path, jmp_jng.source),
    entry(jmp_jnge.family, jmp_jnge.path, jmp_jnge.source),
    entry(jmp_jnl.family, jmp_jnl.path, jmp_jnl.source),
    entry(jmp_jnle.family, jmp_jnle.path, jmp_jnle.source),
    entry(jmp_jno.family, jmp_jno.path, jmp_jno.source),
    entry(jmp_jnp.family, jmp_jnp.path, jmp_jnp.source),
    entry(jmp_jns.family, jmp_jns.path, jmp_jns.source),
    entry(jmp_jnz.family, jmp_jnz.path, jmp_jnz.source),
    entry(jmp_jo.family, jmp_jo.path, jmp_jo.source),
    entry(jmp_jp.family, jmp_jp.path, jmp_jp.source),
    entry(jmp_jpe.family, jmp_jpe.path, jmp_jpe.source),
    entry(jmp_jpo.family, jmp_jpo.path, jmp_jpo.source),
    entry(jmp_jrcxz.family, jmp_jrcxz.path, jmp_jrcxz.source),
    entry(jmp_js.family, jmp_js.path, jmp_js.source),
    entry(jmp_jz.family, jmp_jz.path, jmp_jz.source),
    entry(load_lahf.family, load_lahf.path, load_lahf.source),
    entry(load_lar.family, load_lar.path, load_lar.source),
    entry(load_lddqu.family, load_lddqu.path, load_lddqu.source),
    entry(load_ldmxcsr.family, load_ldmxcsr.path, load_ldmxcsr.source),
    entry(load_lds.family, load_lds.path, load_lds.source),
    entry(load_ldtilecfg.family, load_ldtilecfg.path, load_ldtilecfg.source),
    entry(load_lea.family, load_lea.path, load_lea.source),
    entry(load_les.family, load_les.path, load_les.source),
    entry(load_lfence.family, load_lfence.path, load_lfence.source),
    entry(load_lfs.family, load_lfs.path, load_lfs.source),
    entry(load_lgdt.family, load_lgdt.path, load_lgdt.source),
    entry(load_lgs.family, load_lgs.path, load_lgs.source),
    entry(load_lidt.family, load_lidt.path, load_lidt.source),
    entry(load_lldt.family, load_lldt.path, load_lldt.source),
    entry(load_lmsw.family, load_lmsw.path, load_lmsw.source),
    entry(load_loadiwkey.family, load_loadiwkey.path, load_loadiwkey.source),
    entry(load_lods.family, load_lods.path, load_lods.source),
    entry(load_lodsb.family, load_lodsb.path, load_lodsb.source),
    entry(load_lodsd.family, load_lodsd.path, load_lodsd.source),
    entry(load_lodsq.family, load_lodsq.path, load_lodsq.source),
    entry(load_lodsw.family, load_lodsw.path, load_lodsw.source),
    entry(load_lsl.family, load_lsl.path, load_lsl.source),
    entry(load_lss.family, load_lss.path, load_lss.source),
    entry(load_ltr.family, load_ltr.path, load_ltr.source),
    entry(mov_mov.family, mov_mov.path, mov_mov.source),
    entry(mov_movapd.family, mov_movapd.path, mov_movapd.source),
    entry(mov_movaps.family, mov_movaps.path, mov_movaps.source),
    entry(mov_movbe.family, mov_movbe.path, mov_movbe.source),
    entry(mov_movd.family, mov_movd.path, mov_movd.source),
    entry(mov_movddup.family, mov_movddup.path, mov_movddup.source),
    entry(mov_movdir64b.family, mov_movdir64b.path, mov_movdir64b.source),
    entry(mov_movdiri.family, mov_movdiri.path, mov_movdiri.source),
    entry(mov_movdq2q.family, mov_movdq2q.path, mov_movdq2q.source),
    entry(mov_movdqa.family, mov_movdqa.path, mov_movdqa.source),
    entry(mov_movdqu.family, mov_movdqu.path, mov_movdqu.source),
    entry(mov_movhlps.family, mov_movhlps.path, mov_movhlps.source),
    entry(mov_movhpd.family, mov_movhpd.path, mov_movhpd.source),
    entry(mov_movhps.family, mov_movhps.path, mov_movhps.source),
    entry(mov_movlhps.family, mov_movlhps.path, mov_movlhps.source),
    entry(mov_movlpd.family, mov_movlpd.path, mov_movlpd.source),
    entry(mov_movlps.family, mov_movlps.path, mov_movlps.source),
    entry(mov_movmskpd.family, mov_movmskpd.path, mov_movmskpd.source),
    entry(mov_movmskps.family, mov_movmskps.path, mov_movmskps.source),
    entry(mov_movntdq.family, mov_movntdq.path, mov_movntdq.source),
    entry(mov_movntdqa.family, mov_movntdqa.path, mov_movntdqa.source),
    entry(mov_movnti.family, mov_movnti.path, mov_movnti.source),
    entry(mov_movntpd.family, mov_movntpd.path, mov_movntpd.source),
    entry(mov_movntps.family, mov_movntps.path, mov_movntps.source),
    entry(mov_movntq.family, mov_movntq.path, mov_movntq.source),
    entry(mov_movq.family, mov_movq.path, mov_movq.source),
    entry(mov_movq2dq.family, mov_movq2dq.path, mov_movq2dq.source),
    entry(mov_movs.family, mov_movs.path, mov_movs.source),
    entry(mov_movsb.family, mov_movsb.path, mov_movsb.source),
    entry(mov_movsd.family, mov_movsd.path, mov_movsd.source),
    entry(mov_movshdup.family, mov_movshdup.path, mov_movshdup.source),
    entry(mov_movsldup.family, mov_movsldup.path, mov_movsldup.source),
    entry(mov_movsq.family, mov_movsq.path, mov_movsq.source),
    entry(mov_movss.family, mov_movss.path, mov_movss.source),
    entry(mov_movsw.family, mov_movsw.path, mov_movsw.source),
    entry(mov_movsx.family, mov_movsx.path, mov_movsx.source),
    entry(mov_movsxd.family, mov_movsxd.path, mov_movsxd.source),
    entry(mov_movupd.family, mov_movupd.path, mov_movupd.source),
    entry(mov_movups.family, mov_movups.path, mov_movups.source),
    entry(mov_movzx.family, mov_movzx.path, mov_movzx.source),
    entry(mov_vmovapd.family, mov_vmovapd.path, mov_vmovapd.source),
    entry(mov_vmovaps.family, mov_vmovaps.path, mov_vmovaps.source),
    entry(mov_vmovd.family, mov_vmovd.path, mov_vmovd.source),
    entry(mov_vmovddup.family, mov_vmovddup.path, mov_vmovddup.source),
    entry(mov_vmovdqa.family, mov_vmovdqa.path, mov_vmovdqa.source),
    entry(mov_vmovdqa32.family, mov_vmovdqa32.path, mov_vmovdqa32.source),
    entry(mov_vmovdqa64.family, mov_vmovdqa64.path, mov_vmovdqa64.source),
    entry(mov_vmovdqu.family, mov_vmovdqu.path, mov_vmovdqu.source),
    entry(mov_vmovdqu16.family, mov_vmovdqu16.path, mov_vmovdqu16.source),
    entry(mov_vmovdqu32.family, mov_vmovdqu32.path, mov_vmovdqu32.source),
    entry(mov_vmovdqu64.family, mov_vmovdqu64.path, mov_vmovdqu64.source),
    entry(mov_vmovdqu8.family, mov_vmovdqu8.path, mov_vmovdqu8.source),
    entry(mov_vmovhlps.family, mov_vmovhlps.path, mov_vmovhlps.source),
    entry(mov_vmovhpd.family, mov_vmovhpd.path, mov_vmovhpd.source),
    entry(mov_vmovhps.family, mov_vmovhps.path, mov_vmovhps.source),
    entry(mov_vmovlhps.family, mov_vmovlhps.path, mov_vmovlhps.source),
    entry(mov_vmovlpd.family, mov_vmovlpd.path, mov_vmovlpd.source),
    entry(mov_vmovlps.family, mov_vmovlps.path, mov_vmovlps.source),
    entry(mov_vmovmskpd.family, mov_vmovmskpd.path, mov_vmovmskpd.source),
    entry(mov_vmovmskps.family, mov_vmovmskps.path, mov_vmovmskps.source),
    entry(mov_vmovntdq.family, mov_vmovntdq.path, mov_vmovntdq.source),
    entry(mov_vmovntdqa.family, mov_vmovntdqa.path, mov_vmovntdqa.source),
    entry(mov_vmovntpd.family, mov_vmovntpd.path, mov_vmovntpd.source),
    entry(mov_vmovntps.family, mov_vmovntps.path, mov_vmovntps.source),
    entry(mov_vmovq.family, mov_vmovq.path, mov_vmovq.source),
    entry(mov_vmovsd.family, mov_vmovsd.path, mov_vmovsd.source),
    entry(mov_vmovshdup.family, mov_vmovshdup.path, mov_vmovshdup.source),
    entry(mov_vmovsldup.family, mov_vmovsldup.path, mov_vmovsldup.source),
    entry(mov_vmovss.family, mov_vmovss.path, mov_vmovss.source),
    entry(mov_vmovupd.family, mov_vmovupd.path, mov_vmovupd.source),
    entry(mov_vmovups.family, mov_vmovups.path, mov_vmovups.source),
    entry(mul_imul.family, mul_imul.path, mul_imul.source),
    entry(mul_mul.family, mul_mul.path, mul_mul.source),
    entry(mul_mulpd.family, mul_mulpd.path, mul_mulpd.source),
    entry(mul_mulps.family, mul_mulps.path, mul_mulps.source),
    entry(mul_mulsd.family, mul_mulsd.path, mul_mulsd.source),
    entry(mul_mulss.family, mul_mulss.path, mul_mulss.source),
    entry(mul_mulx.family, mul_mulx.path, mul_mulx.source),
    entry(or_or.family, or_or.path, or_or.source),
    entry(or_orpd.family, or_orpd.path, or_orpd.source),
    entry(or_orps.family, or_orps.path, or_orps.source),
    entry(pop_pop.family, pop_pop.path, pop_pop.source),
    entry(pop_popa.family, pop_popa.path, pop_popa.source),
    entry(pop_popad.family, pop_popad.path, pop_popad.source),
    entry(pop_popcnt.family, pop_popcnt.path, pop_popcnt.source),
    entry(push_push.family, push_push.path, push_push.source),
    entry(push_pusha.family, push_pusha.path, push_pusha.source),
    entry(push_pushad.family, push_pushad.path, push_pushad.source),
    entry(rotate_rcl.family, rotate_rcl.path, rotate_rcl.source),
    entry(rotate_rcr.family, rotate_rcr.path, rotate_rcr.source),
    entry(rotate_rol.family, rotate_rol.path, rotate_rol.source),
    entry(rotate_ror.family, rotate_ror.path, rotate_ror.source),
    entry(sub_sub.family, sub_sub.path, sub_sub.source),
    entry(sub_subpd.family, sub_subpd.path, sub_subpd.source),
    entry(sub_subps.family, sub_subps.path, sub_subps.source),
    entry(sub_subsd.family, sub_subsd.path, sub_subsd.source),
    entry(sub_subss.family, sub_subss.path, sub_subss.source),
    entry(test_test.family, test_test.path, test_test.source),
    entry(test_testui.family, test_testui.path, test_testui.source),
    entry(xor_xor.family, xor_xor.path, xor_xor.source),
    entry(xor_xorpd.family, xor_xorpd.path, xor_xorpd.source),
    entry(xor_xorps.family, xor_xorps.path, xor_xorps.source),
    entry(and_and.family, and_and.path, and_and.source),
    entry(and_andn.family, and_andn.path, and_andn.source),
    entry(and_andps.family, and_andps.path, and_andps.source),
    entry(and_andpd.family, and_andpd.path, and_andpd.source),
    entry(and_andnps.family, and_andnps.path, and_andnps.source),
    entry(and_andnpd.family, and_andnpd.path, and_andnpd.source),
    entry(blend_blendpd.family, blend_blendpd.path, blend_blendpd.source),
    entry(blend_blendps.family, blend_blendps.path, blend_blendps.source),
    entry(blend_blendvpd.family, blend_blendvpd.path, blend_blendvpd.source),
    entry(blend_blendvps.family, blend_blendvps.path, blend_blendvps.source),
    entry(sys_syscall.family, sys_syscall.path, sys_syscall.source),
    entry(sys_sysenter.family, sys_sysenter.path, sys_sysenter.source),
    entry(sys_sysexit.family, sys_sysexit.path, sys_sysexit.source),
    entry(sys_sysret.family, sys_sysret.path, sys_sysret.source),
};

pub fn tableCount() usize {
    return tables.len;
}

pub fn findByName(name: []const u8) ?InstructionTable {
    for (tables) |table| {
        const meta = table.metadata();
        if (std.ascii.eqlIgnoreCase(meta.name, name)) return table;
    }
    return null;
}

pub fn validateAll() void {
    for (tables) |table| table.validate();
    validateUniqueNames();
    validateDocumentedReferences();
}

fn entry(family: []const u8, path: []const u8, source: []const u8) InstructionTable {
    return .{ .family = family, .path = path, .source = source };
}

fn validateUniqueNames() void {
    for (tables, 0..) |lhs, i| {
        const lhs_name = lhs.metadata().name;
        for (tables[i + 1 ..]) |rhs| {
            const rhs_name = rhs.metadata().name;
            if (std.ascii.eqlIgnoreCase(lhs_name, rhs_name)) {
                runtime_abi.isa.validateNoDuplicateInstruction(lhs_name, lhs.path, rhs.path);
            }
        }
    }
}

fn validateDocumentedReferences() void {
    for (documented_reference_mnemonics) |name| {
        if (findByName(name) == null) runtime_abi.isa.validateMissingNeonMirror(name);
    }
}

fn stripLineComment(line: []const u8) []const u8 {
    const idx = std.mem.indexOf(u8, line, "//") orelse return line;
    return line[0..idx];
}

fn assignmentName(line: []const u8) ?[]const u8 {
    const eq = std.mem.indexOfScalar(u8, line, '=') orelse return null;
    return std.mem.trim(u8, line[0..eq], " \t\r");
}

fn stringAssignment(source: []const u8, key: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, source, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, stripLineComment(raw_line), " \t\r");
        const name = assignmentName(line) orelse continue;
        if (!std.mem.eql(u8, name, key)) continue;
        const eq = std.mem.indexOfScalar(u8, line, '=') orelse continue;
        const value = std.mem.trim(u8, line[eq + 1 ..], " \t");
        if (value.len < 2 or value[0] != '"') continue;
        const end = std.mem.indexOfScalar(u8, value[1..], '"') orelse continue;
        return value[1 .. 1 + end];
    }
    return null;
}

fn anyStringAssignment(source: []const u8, keys: []const []const u8) ?[]const u8 {
    for (keys) |key| if (stringAssignment(source, key)) |value| return value;
    return null;
}

fn hasAnyAssignment(source: []const u8, keys: []const []const u8) bool {
    for (keys) |key| if (hasAssignment(source, key)) return true;
    return false;
}

fn hasAssignment(source: []const u8, key: []const u8) bool {
    var lines = std.mem.splitScalar(u8, source, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, stripLineComment(raw_line), " \t\r");
        const name = assignmentName(line) orelse continue;
        if (std.mem.eql(u8, name, key)) return true;
    }
    return false;
}

fn countEncodingRows(source: []const u8) usize {
    if (countToken(source, "X86_INST(") > 0) return countToken(source, "X86_INST(");
    if (countStructuredEncodingRows(source, '[')) |count| return count;
    if (countStructuredEncodingRows(source, '{')) |count| return count;
    if (countSourceContractOpcodeRows(source)) |count| return count;
    return if (hasAnyAssignment(source, &[_][]const u8{ "semantic", "source_contract", "operation" })) 1 else 0;
}

fn countToken(source: []const u8, needle: []const u8) usize {
    var count: usize = 0;
    var start: usize = 0;
    while (std.mem.indexOf(u8, source[start..], needle)) |rel| {
        count += 1;
        start += rel + needle.len;
    }
    return count;
}

fn countStructuredEncodingRows(source: []const u8, opener: u8) ?usize {
    const block_start = std.mem.indexOf(u8, source, "encodings") orelse return null;
    const open_rel = std.mem.indexOfScalar(u8, source[block_start..], opener) orelse return null;
    const closer: u8 = if (opener == '[') ']' else '}';
    const body_start = block_start + open_rel + 1;
    const body_end_rel = std.mem.indexOfScalar(u8, source[body_start..], closer) orelse return null;
    const body = source[body_start .. body_start + body_end_rel];
    var count: usize = 0;
    var lines = std.mem.splitScalar(u8, body, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, stripLineComment(raw_line), " \t\r");
        if (std.mem.startsWith(u8, line, "{")) count += 1;
    }
    return count;
}

fn countSourceContractOpcodeRows(source: []const u8) ?usize {
    const key = "source_contract";
    const block_start = std.mem.indexOf(u8, source, key) orelse return null;
    const triple_rel = std.mem.indexOf(u8, source[block_start..], "\"\"\"") orelse return null;
    const body_start = block_start + triple_rel + 3;
    const body_end_rel = std.mem.indexOf(u8, source[body_start..], "\"\"\"") orelse return null;
    const body = source[body_start .. body_start + body_end_rel];
    var count: usize = 0;
    var lines = std.mem.splitScalar(u8, body, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \t\r");
        if (looksLikeOpcodeRow(line)) count += 1;
    }
    return if (count == 0) null else count;
}

fn looksLikeOpcodeRow(line: []const u8) bool {
    if (line.len == 0) return false;
    if (line[0] >= '0' and line[0] <= '9') return true;
    return std.mem.startsWith(u8, line, "REX") or
        std.mem.startsWith(u8, line, "VEX") or
        std.mem.startsWith(u8, line, "EVEX") or
        std.mem.startsWith(u8, line, "F2") or
        std.mem.startsWith(u8, line, "F3") or
        std.mem.startsWith(u8, line, "66 ");
}

fn mnemonicFromPath(path: []const u8) []const u8 {
    const slash = std.mem.lastIndexOfScalar(u8, path, '/') orelse 0;
    const start = if (path[slash] == '/') slash + 1 else slash;
    const dot = std.mem.lastIndexOfScalar(u8, path, '.') orelse path.len;
    return path[start..dot];
}

test "x86 ISA tables expose required metadata" {
    try std.testing.expectEqual(@as(usize, 204), tableCount());
    validateAll();
    for (documented_reference_mnemonics) |name| try std.testing.expect(findByName(name) != null);
    const add = (findByName("ADD") orelse return error.MissingAdd).metadata();
    try std.testing.expectEqualStrings("x86_add", add.handler);
    try std.testing.expect(add.encoding_count >= 1);
}
