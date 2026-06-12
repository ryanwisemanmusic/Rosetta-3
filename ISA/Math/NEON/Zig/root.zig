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
const bls_blsi = @import("BLS/BLSI.zig");
const bls_blsmsk = @import("BLS/BLSMSK.zig");
const bls_blsr = @import("BLS/BLSR.zig");
const bs_bsf = @import("BS/BSF.zig");
const bs_bsr = @import("BS/BSR.zig");
const bs_bswap = @import("BS/BSWAP.zig");
const bt_bt = @import("BT/BT.zig");
const bt_btc = @import("BT/BTC.zig");
const bt_btr = @import("BT/BTR.zig");
const bt_bts = @import("BT/BTS.zig");
const cache_cldemote = @import("CACHE/CLDEMOTE.zig");
const cache_clflush = @import("CACHE/CLFLUSH.zig");
const cache_clflushopt = @import("CACHE/CLFLUSHOPT.zig");
const sha_sha1msg1 = @import("SHA/SHA1MSG1.zig");
const sha_sha1msg2 = @import("SHA/SHA1MSG2.zig");
const sha_sha1nexte = @import("SHA/SHA1NEXTE.zig");
const sha_sha1rnds4 = @import("SHA/SHA1RNDS4.zig");
const sha_sha256msg1 = @import("SHA/SHA256MSG1.zig");
const sha_sha256msg2 = @import("SHA/SHA256MSG2.zig");
const sha_sha256rnds2 = @import("SHA/SHA256RNDS2.zig");
const terminate_endbr32 = @import("TERMINATE/ENDBR32.zig");
const terminate_endbr64 = @import("TERMINATE/ENDBR64.zig");
const shuffle_shufpd = @import("SHUFFLE/SHUFPD.zig");
const shuffle_shufps = @import("SHUFFLE/SHUFPS.zig");

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
    spec(call_ret_call.meta),
    spec(call_ret_leave.meta),
    spec(call_ret_ret.meta),
    spec(cmp_cmp.meta),
    spec(cmp_cmppd.meta),
    spec(cmp_cmpps.meta),
    spec(cmp_cmpsd.meta),
    spec(cmp_cmpss.meta),
    spec(div_div.meta),
    spec(div_divpd.meta),
    spec(div_divps.meta),
    spec(div_divsd.meta),
    spec(div_divss.meta),
    spec(div_idiv.meta),
    spec(inc_dec_dec.meta),
    spec(inc_dec_inc.meta),
    spec(jmp_ja.meta),
    spec(jmp_jae.meta),
    spec(jmp_jb.meta),
    spec(jmp_jbe.meta),
    spec(jmp_jc.meta),
    spec(jmp_jcxz.meta),
    spec(jmp_je.meta),
    spec(jmp_jecxz.meta),
    spec(jmp_jg.meta),
    spec(jmp_jge.meta),
    spec(jmp_jl.meta),
    spec(jmp_jle.meta),
    spec(jmp_jmp.meta),
    spec(jmp_jna.meta),
    spec(jmp_jnae.meta),
    spec(jmp_jnb.meta),
    spec(jmp_jnbe.meta),
    spec(jmp_jnc.meta),
    spec(jmp_jne.meta),
    spec(jmp_jng.meta),
    spec(jmp_jnge.meta),
    spec(jmp_jnl.meta),
    spec(jmp_jnle.meta),
    spec(jmp_jno.meta),
    spec(jmp_jnp.meta),
    spec(jmp_jns.meta),
    spec(jmp_jnz.meta),
    spec(jmp_jo.meta),
    spec(jmp_jp.meta),
    spec(jmp_jpe.meta),
    spec(jmp_jpo.meta),
    spec(jmp_jrcxz.meta),
    spec(jmp_js.meta),
    spec(jmp_jz.meta),
    spec(load_lahf.meta),
    spec(load_lar.meta),
    spec(load_lddqu.meta),
    spec(load_ldmxcsr.meta),
    spec(load_lds.meta),
    spec(load_ldtilecfg.meta),
    spec(load_lea.meta),
    spec(load_les.meta),
    spec(load_lfence.meta),
    spec(load_lfs.meta),
    spec(load_lgdt.meta),
    spec(load_lgs.meta),
    spec(load_lidt.meta),
    spec(load_lldt.meta),
    spec(load_lmsw.meta),
    spec(load_loadiwkey.meta),
    spec(load_lods.meta),
    spec(load_lodsb.meta),
    spec(load_lodsd.meta),
    spec(load_lodsq.meta),
    spec(load_lodsw.meta),
    spec(load_lsl.meta),
    spec(load_lss.meta),
    spec(load_ltr.meta),
    spec(mov_mov.meta),
    spec(mov_movapd.meta),
    spec(mov_movaps.meta),
    spec(mov_movbe.meta),
    spec(mov_movd.meta),
    spec(mov_movddup.meta),
    spec(mov_movdir64b.meta),
    spec(mov_movdiri.meta),
    spec(mov_movdq2q.meta),
    spec(mov_movdqa.meta),
    spec(mov_movdqu.meta),
    spec(mov_movhlps.meta),
    spec(mov_movhpd.meta),
    spec(mov_movhps.meta),
    spec(mov_movlhps.meta),
    spec(mov_movlpd.meta),
    spec(mov_movlps.meta),
    spec(mov_movmskpd.meta),
    spec(mov_movmskps.meta),
    spec(mov_movntdq.meta),
    spec(mov_movntdqa.meta),
    spec(mov_movnti.meta),
    spec(mov_movntpd.meta),
    spec(mov_movntps.meta),
    spec(mov_movntq.meta),
    spec(mov_movq.meta),
    spec(mov_movq2dq.meta),
    spec(mov_movs.meta),
    spec(mov_movsb.meta),
    spec(mov_movsd.meta),
    spec(mov_movshdup.meta),
    spec(mov_movsldup.meta),
    spec(mov_movsq.meta),
    spec(mov_movss.meta),
    spec(mov_movsw.meta),
    spec(mov_movsx.meta),
    spec(mov_movsxd.meta),
    spec(mov_movupd.meta),
    spec(mov_movups.meta),
    spec(mov_movzx.meta),
    spec(mov_vmovapd.meta),
    spec(mov_vmovaps.meta),
    spec(mov_vmovd.meta),
    spec(mov_vmovddup.meta),
    spec(mov_vmovdqa.meta),
    spec(mov_vmovdqa32.meta),
    spec(mov_vmovdqa64.meta),
    spec(mov_vmovdqu.meta),
    spec(mov_vmovdqu16.meta),
    spec(mov_vmovdqu32.meta),
    spec(mov_vmovdqu64.meta),
    spec(mov_vmovdqu8.meta),
    spec(mov_vmovhlps.meta),
    spec(mov_vmovhpd.meta),
    spec(mov_vmovhps.meta),
    spec(mov_vmovlhps.meta),
    spec(mov_vmovlpd.meta),
    spec(mov_vmovlps.meta),
    spec(mov_vmovmskpd.meta),
    spec(mov_vmovmskps.meta),
    spec(mov_vmovntdq.meta),
    spec(mov_vmovntdqa.meta),
    spec(mov_vmovntpd.meta),
    spec(mov_vmovntps.meta),
    spec(mov_vmovq.meta),
    spec(mov_vmovsd.meta),
    spec(mov_vmovshdup.meta),
    spec(mov_vmovsldup.meta),
    spec(mov_vmovss.meta),
    spec(mov_vmovupd.meta),
    spec(mov_vmovups.meta),
    spec(mul_imul.meta),
    spec(mul_mul.meta),
    spec(mul_mulpd.meta),
    spec(mul_mulps.meta),
    spec(mul_mulsd.meta),
    spec(mul_mulss.meta),
    spec(mul_mulx.meta),
    spec(or_or.meta),
    spec(or_orpd.meta),
    spec(or_orps.meta),
    spec(pop_pop.meta),
    spec(pop_popa.meta),
    spec(pop_popad.meta),
    spec(pop_popcnt.meta),
    spec(push_push.meta),
    spec(push_pusha.meta),
    spec(push_pushad.meta),
    spec(rotate_rcl.meta),
    spec(rotate_rcr.meta),
    spec(rotate_rol.meta),
    spec(rotate_ror.meta),
    spec(sub_sub.meta),
    spec(sub_subpd.meta),
    spec(sub_subps.meta),
    spec(sub_subsd.meta),
    spec(sub_subss.meta),
    spec(test_test.meta),
    spec(test_testui.meta),
    spec(xor_xor.meta),
    spec(xor_xorpd.meta),
    spec(xor_xorps.meta),
    spec(and_and.meta),
    spec(and_andn.meta),
    spec(and_andps.meta),
    spec(and_andpd.meta),
    spec(and_andnps.meta),
    spec(and_andnpd.meta),
    spec(blend_blendpd.meta),
    spec(blend_blendps.meta),
    spec(blend_blendvpd.meta),
    spec(blend_blendvps.meta),
    spec(bls_blsi.meta),
    spec(bls_blsmsk.meta),
    spec(bls_blsr.meta),
    spec(bs_bsf.meta),
    spec(bs_bsr.meta),
    spec(bs_bswap.meta),
    spec(bt_bt.meta),
    spec(bt_btc.meta),
    spec(bt_btr.meta),
    spec(bt_bts.meta),
    spec(cache_cldemote.meta),
    spec(cache_clflush.meta),
    spec(cache_clflushopt.meta),
    spec(sha_sha1msg1.meta),
    spec(sha_sha1msg2.meta),
    spec(sha_sha1nexte.meta),
    spec(sha_sha1rnds4.meta),
    spec(sha_sha256msg1.meta),
    spec(sha_sha256msg2.meta),
    spec(sha_sha256rnds2.meta),
    spec(terminate_endbr32.meta),
    spec(terminate_endbr64.meta),
    spec(sys_syscall.meta),
    spec(sys_sysenter.meta),
    spec(sys_sysexit.meta),
    spec(sys_sysret.meta),
    spec(shuffle_shufpd.meta),
    spec(shuffle_shufps.meta),
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
    call_ret_call.proof_report,
    call_ret_leave.proof_report,
    call_ret_ret.proof_report,
    cmp_cmp.proof_report,
    cmp_cmppd.proof_report,
    cmp_cmpps.proof_report,
    cmp_cmpsd.proof_report,
    cmp_cmpss.proof_report,
    div_div.proof_report,
    div_divpd.proof_report,
    div_divps.proof_report,
    div_divsd.proof_report,
    div_divss.proof_report,
    div_idiv.proof_report,
    inc_dec_dec.proof_report,
    inc_dec_inc.proof_report,
    jmp_ja.proof_report,
    jmp_jae.proof_report,
    jmp_jb.proof_report,
    jmp_jbe.proof_report,
    jmp_jc.proof_report,
    jmp_jcxz.proof_report,
    jmp_je.proof_report,
    jmp_jecxz.proof_report,
    jmp_jg.proof_report,
    jmp_jge.proof_report,
    jmp_jl.proof_report,
    jmp_jle.proof_report,
    jmp_jmp.proof_report,
    jmp_jna.proof_report,
    jmp_jnae.proof_report,
    jmp_jnb.proof_report,
    jmp_jnbe.proof_report,
    jmp_jnc.proof_report,
    jmp_jne.proof_report,
    jmp_jng.proof_report,
    jmp_jnge.proof_report,
    jmp_jnl.proof_report,
    jmp_jnle.proof_report,
    jmp_jno.proof_report,
    jmp_jnp.proof_report,
    jmp_jns.proof_report,
    jmp_jnz.proof_report,
    jmp_jo.proof_report,
    jmp_jp.proof_report,
    jmp_jpe.proof_report,
    jmp_jpo.proof_report,
    jmp_jrcxz.proof_report,
    jmp_js.proof_report,
    jmp_jz.proof_report,
    load_lahf.proof_report,
    load_lar.proof_report,
    load_lddqu.proof_report,
    load_ldmxcsr.proof_report,
    load_lds.proof_report,
    load_ldtilecfg.proof_report,
    load_lea.proof_report,
    load_les.proof_report,
    load_lfence.proof_report,
    load_lfs.proof_report,
    load_lgdt.proof_report,
    load_lgs.proof_report,
    load_lidt.proof_report,
    load_lldt.proof_report,
    load_lmsw.proof_report,
    load_loadiwkey.proof_report,
    load_lods.proof_report,
    load_lodsb.proof_report,
    load_lodsd.proof_report,
    load_lodsq.proof_report,
    load_lodsw.proof_report,
    load_lsl.proof_report,
    load_lss.proof_report,
    load_ltr.proof_report,
    mov_mov.proof_report,
    mov_movapd.proof_report,
    mov_movaps.proof_report,
    mov_movbe.proof_report,
    mov_movd.proof_report,
    mov_movddup.proof_report,
    mov_movdir64b.proof_report,
    mov_movdiri.proof_report,
    mov_movdq2q.proof_report,
    mov_movdqa.proof_report,
    mov_movdqu.proof_report,
    mov_movhlps.proof_report,
    mov_movhpd.proof_report,
    mov_movhps.proof_report,
    mov_movlhps.proof_report,
    mov_movlpd.proof_report,
    mov_movlps.proof_report,
    mov_movmskpd.proof_report,
    mov_movmskps.proof_report,
    mov_movntdq.proof_report,
    mov_movntdqa.proof_report,
    mov_movnti.proof_report,
    mov_movntpd.proof_report,
    mov_movntps.proof_report,
    mov_movntq.proof_report,
    mov_movq.proof_report,
    mov_movq2dq.proof_report,
    mov_movs.proof_report,
    mov_movsb.proof_report,
    mov_movsd.proof_report,
    mov_movshdup.proof_report,
    mov_movsldup.proof_report,
    mov_movsq.proof_report,
    mov_movss.proof_report,
    mov_movsw.proof_report,
    mov_movsx.proof_report,
    mov_movsxd.proof_report,
    mov_movupd.proof_report,
    mov_movups.proof_report,
    mov_movzx.proof_report,
    mov_vmovapd.proof_report,
    mov_vmovaps.proof_report,
    mov_vmovd.proof_report,
    mov_vmovddup.proof_report,
    mov_vmovdqa.proof_report,
    mov_vmovdqa32.proof_report,
    mov_vmovdqa64.proof_report,
    mov_vmovdqu.proof_report,
    mov_vmovdqu16.proof_report,
    mov_vmovdqu32.proof_report,
    mov_vmovdqu64.proof_report,
    mov_vmovdqu8.proof_report,
    mov_vmovhlps.proof_report,
    mov_vmovhpd.proof_report,
    mov_vmovhps.proof_report,
    mov_vmovlhps.proof_report,
    mov_vmovlpd.proof_report,
    mov_vmovlps.proof_report,
    mov_vmovmskpd.proof_report,
    mov_vmovmskps.proof_report,
    mov_vmovntdq.proof_report,
    mov_vmovntdqa.proof_report,
    mov_vmovntpd.proof_report,
    mov_vmovntps.proof_report,
    mov_vmovq.proof_report,
    mov_vmovsd.proof_report,
    mov_vmovshdup.proof_report,
    mov_vmovsldup.proof_report,
    mov_vmovss.proof_report,
    mov_vmovupd.proof_report,
    mov_vmovups.proof_report,
    mul_imul.proof_report,
    mul_mul.proof_report,
    mul_mulpd.proof_report,
    mul_mulps.proof_report,
    mul_mulsd.proof_report,
    mul_mulss.proof_report,
    mul_mulx.proof_report,
    or_or.proof_report,
    or_orpd.proof_report,
    or_orps.proof_report,
    pop_pop.proof_report,
    pop_popa.proof_report,
    pop_popad.proof_report,
    pop_popcnt.proof_report,
    push_push.proof_report,
    push_pusha.proof_report,
    push_pushad.proof_report,
    rotate_rcl.proof_report,
    rotate_rcr.proof_report,
    rotate_rol.proof_report,
    rotate_ror.proof_report,
    sub_sub.proof_report,
    sub_subpd.proof_report,
    sub_subps.proof_report,
    sub_subsd.proof_report,
    sub_subss.proof_report,
    test_test.proof_report,
    test_testui.proof_report,
    xor_xor.proof_report,
    xor_xorpd.proof_report,
    xor_xorps.proof_report,
    and_and.proof_report,
    and_andn.proof_report,
    and_andps.proof_report,
    and_andpd.proof_report,
    and_andnps.proof_report,
    and_andnpd.proof_report,
    blend_blendpd.proof_report,
    blend_blendps.proof_report,
    blend_blendvpd.proof_report,
    blend_blendvps.proof_report,
    bls_blsi.proof_report,
    bls_blsmsk.proof_report,
    bls_blsr.proof_report,
    bs_bsf.proof_report,
    bs_bsr.proof_report,
    bs_bswap.proof_report,
    bt_bt.proof_report,
    bt_btc.proof_report,
    bt_btr.proof_report,
    bt_bts.proof_report,
    cache_cldemote.proof_report,
    cache_clflush.proof_report,
    cache_clflushopt.proof_report,
    sha_sha1msg1.proof_report,
    sha_sha1msg2.proof_report,
    sha_sha1nexte.proof_report,
    sha_sha1rnds4.proof_report,
    sha_sha256msg1.proof_report,
    sha_sha256msg2.proof_report,
    sha_sha256rnds2.proof_report,
    terminate_endbr32.proof_report,
    terminate_endbr64.proof_report,
    sys_syscall.proof_report,
    sys_sysenter.proof_report,
    sys_sysexit.proof_report,
    sys_sysret.proof_report,
    shuffle_shufpd.proof_report,
    shuffle_shufps.proof_report,
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
    try std.testing.expectEqual(tableCount(), proofReportCount());
    try std.testing.expect(proofCaseCount() >= tableCount() * 2);
    validateAll();
    try exerciseAll();
    try exerciseMirrors();
}
