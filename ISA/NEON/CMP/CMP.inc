// CMP/CMP.inc
// ARM64/NEON mirror generated from ISA/x86/CMP/CMP.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "CMP/CMP.inc"
x86_handler = "x86_cmp"
neon_lowering = "arm64_cmp_subtract_set_x86_flags"
lowering_kind = "arm64_documented_contract"

// CMP/CMP.inc
// ARM64/NEON translation mirror generated from ISA/x86/CMP/CMP.inc.
// This file preserves the full x86 CMP instruction contract, then appends the ARM64/NEON lowering contract.


name = "CMP"
category = "integer_compare"
operation = "compare first operand with second operand by subtracting SRC2 from SRC1 and updating status flags without storing the result"

encodings = [
  { opcode = "3C ib", form = "CMP AL, imm8", op_en = "I", mode64 = "valid", compat = "valid", operand_size = 8, accumulator = "AL", imm = 8, description = "Compare imm8 with AL." },
  { opcode = "3D iw", form = "CMP AX, imm16", op_en = "I", mode64 = "valid", compat = "valid", operand_size = 16, accumulator = "AX", imm = 16, description = "Compare imm16 with AX." },
  { opcode = "3D id", form = "CMP EAX, imm32", op_en = "I", mode64 = "valid", compat = "valid", operand_size = 32, accumulator = "EAX", imm = 32, description = "Compare imm32 with EAX." },
  { opcode = "REX.W + 3D id", form = "CMP RAX, imm32", op_en = "I", mode64 = "valid", compat = "not_encodable", operand_size = 64, accumulator = "RAX", imm = 32, imm_extend = "sign_extend_to_64", description = "Compare imm32 sign-extended to 64 bits with RAX." },

  { opcode = "80 /7 ib", form = "CMP r/m8, imm8", op_en = "MI", mode64 = "valid", compat = "valid", operand_size = 8, modrm_ext = 7, imm = 8, description = "Compare imm8 with r/m8." },
  { opcode = "REX + 80 /7 ib", form = "CMP r/m8*, imm8", op_en = "MI", mode64 = "valid", compat = "not_encodable", operand_size = 8, modrm_ext = 7, imm = 8, rex_byte_register_note = true, description = "Compare imm8 with r/m8 using REX-encoded byte registers where applicable." },
  { opcode = "81 /7 iw", form = "CMP r/m16, imm16", op_en = "MI", mode64 = "valid", compat = "valid", operand_size = 16, modrm_ext = 7, imm = 16, description = "Compare imm16 with r/m16." },
  { opcode = "81 /7 id", form = "CMP r/m32, imm32", op_en = "MI", mode64 = "valid", compat = "valid", operand_size = 32, modrm_ext = 7, imm = 32, description = "Compare imm32 with r/m32." },
  { opcode = "REX.W + 81 /7 id", form = "CMP r/m64, imm32", op_en = "MI", mode64 = "valid", compat = "not_encodable", operand_size = 64, modrm_ext = 7, imm = 32, imm_extend = "sign_extend_to_64", description = "Compare imm32 sign-extended to 64 bits with r/m64." },
  { opcode = "83 /7 ib", form = "CMP r/m16, imm8", op_en = "MI", mode64 = "valid", compat = "valid", operand_size = 16, modrm_ext = 7, imm = 8, imm_extend = "sign_extend_to_operand_size", description = "Compare imm8 sign-extended to 16 bits with r/m16." },
  { opcode = "83 /7 ib", form = "CMP r/m32, imm8", op_en = "MI", mode64 = "valid", compat = "valid", operand_size = 32, modrm_ext = 7, imm = 8, imm_extend = "sign_extend_to_operand_size", description = "Compare imm8 sign-extended to 32 bits with r/m32." },
  { opcode = "REX.W + 83 /7 ib", form = "CMP r/m64, imm8", op_en = "MI", mode64 = "valid", compat = "not_encodable", operand_size = 64, modrm_ext = 7, imm = 8, imm_extend = "sign_extend_to_64", description = "Compare imm8 sign-extended to 64 bits with r/m64." },

  { opcode = "38 /r", form = "CMP r/m8, r8", op_en = "MR", mode64 = "valid", compat = "valid", operand_size = 8, description = "Compare r8 with r/m8." },
  { opcode = "REX + 38 /r", form = "CMP r/m8*, r8*", op_en = "MR", mode64 = "valid", compat = "not_encodable", operand_size = 8, rex_byte_register_note = true, description = "Compare r8 with r/m8 using REX-encoded byte registers where applicable." },
  { opcode = "39 /r", form = "CMP r/m16, r16", op_en = "MR", mode64 = "valid", compat = "valid", operand_size = 16, description = "Compare r16 with r/m16." },
  { opcode = "39 /r", form = "CMP r/m32, r32", op_en = "MR", mode64 = "valid", compat = "valid", operand_size = 32, description = "Compare r32 with r/m32." },
  { opcode = "REX.W + 39 /r", form = "CMP r/m64, r64", op_en = "MR", mode64 = "valid", compat = "not_encodable", operand_size = 64, description = "Compare r64 with r/m64." },

  { opcode = "3A /r", form = "CMP r8, r/m8", op_en = "RM", mode64 = "valid", compat = "valid", operand_size = 8, description = "Compare r/m8 with r8." },
  { opcode = "REX + 3A /r", form = "CMP r8*, r/m8*", op_en = "RM", mode64 = "valid", compat = "not_encodable", operand_size = 8, rex_byte_register_note = true, description = "Compare r/m8 with r8 using REX-encoded byte registers where applicable." },
  { opcode = "3B /r", form = "CMP r16, r/m16", op_en = "RM", mode64 = "valid", compat = "valid", operand_size = 16, description = "Compare r/m16 with r16." },
  { opcode = "3B /r", form = "CMP r32, r/m32", op_en = "RM", mode64 = "valid", compat = "valid", operand_size = 32, description = "Compare r/m32 with r32." },
  { opcode = "REX.W + 3B /r", form = "CMP r64, r/m64", op_en = "RM", mode64 = "valid", compat = "not_encodable", operand_size = 64, description = "Compare r/m64 with r64." }
]

operand_encoding = [
  { op_en = "RM", operand1 = "ModRM:reg (read)", operand2 = "ModRM:r/m (read)", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "MR", operand1 = "ModRM:r/m (read)", operand2 = "ModRM:reg (read)", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "MI", operand1 = "ModRM:r/m (read)", operand2 = "imm8/16/32", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "I", operand1 = "AL/AX/EAX/RAX (read)", operand2 = "imm8/16/32", operand3 = "N/A", operand4 = "N/A" }
]

reads = ["SRC1", "SRC2"]
writes = []
implicit_reads = []
implicit_writes = ["RFLAGS/EFLAGS status flags"]
flags_read = []
flags_written = ["CF", "OF", "SF", "ZF", "AF", "PF"]
flags_affected = "CF, OF, SF, ZF, AF, and PF are set according to the subtraction result; destination operand is not modified"
lock_allowed = false

mode_notes = [
  "In 64-bit mode, default operation size is 32 bits.",
  "REX.R permits access to additional registers R8-R15 where the encoding uses ModRM.reg.",
  "REX.W promotes operation to 64 bits.",
  "When a REX prefix is used in 64-bit mode, r/m8 cannot encode AH, BH, CH, or DH.",
  "Immediate operands are sign-extended to the length of the first operand when required by the encoding."
]

semantic = """
# CMP performs the same flag-producing subtraction as SUB, but discards the arithmetic result.
# SRC1 is operand 1; SRC2 is operand 2.
operand_width = decode_operand_size(mode, prefixes, encoding);
rhs = sign_extend_if_immediate_requires(SRC2, operand_width);
temp = SRC1 - rhs;
update_sub_flags(src1 = SRC1, src2 = rhs, result = temp, width = operand_width);
# No architectural destination writeback occurs.
"""

flag_model = """
CF = borrow_from_subtraction(SRC1, SRC2, operand_width);
OF = signed_overflow_from_subtraction(SRC1, SRC2, result, operand_width);
SF = most_significant_bit(result, operand_width);
ZF = (truncate(result, operand_width) == 0);
AF = auxiliary_borrow_bit3_to_bit4(SRC1, SRC2, result);
PF = parity_even(low8(result));
"""

condition_code_dependents = [
  "Jcc",
  "CMOVcc",
  "SETcc"
]

exceptions = {
  protected_mode = [
    "#GP(0) if a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.",
    "#GP(0) if DS, ES, FS, or GS contains a NULL segment selector while used for memory access.",
    "#SS(0) if a memory operand effective address is outside the SS segment limit.",
    "#PF(fault-code) if a page fault occurs.",
    "#AC(0) if alignment checking is enabled and an unaligned memory reference is made while CPL = 3.",
    "#UD if the LOCK prefix is used."
  ],
  real_address_mode = [
    "#GP if a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.",
    "#SS if a memory operand effective address is outside the SS segment limit."
  ],
  virtual_8086_mode = [
    "#GP(0) if a memory operand effective address is outside the CS, DS, ES, FS, or GS segment limit.",
    "#SS(0) if a memory operand effective address is outside the SS segment limit.",
    "#PF(fault-code) if a page fault occurs.",
    "#AC(0) if alignment checking is enabled and an unaligned memory reference is made.",
    "#UD if the LOCK prefix is used."
  ],
  compatibility_mode = [
    "Same exceptions as protected mode."
  ],
  mode64 = [
    "#SS(0) if a memory address referencing the SS segment is in a non-canonical form.",
    "#GP(0) if the memory address is in a non-canonical form.",
    "#PF(fault-code) if a page fault occurs.",
    "#AC(0) if alignment checking is enabled and an unaligned memory reference is made while CPL = 3.",
    "#UD if the LOCK prefix is used."
  ]
}

handler = "x86_cmp"
jit_lowering = "arm64_cmp_subtract_set_x86_flags"

neon_register_model = """
CMP reads x86 operands through the Rosette register/memory operand decoder and writes no destination operand.
Any memory operand must still be fully addressed, checked, and read so that x86 memory exceptions remain visible.
"""

neon_flag_model = """
ARM64 SUBS/CMP can provide NZCV for N/Z/C/V, but x86 CF has inverted borrow meaning relative to ARM carry after subtraction.
AF and PF are not represented in ARM64 NZCV and must be synthesized from operands/result.
The lowering must pack OF/SF/ZF/AF/CF/PF into the Rosette x86 flag model exactly as SUB would.
"""

neon_assembly = """
# Register-register/register-immediate fast path, schematic only.
subs xTMP, xSRC1, xSRC2       // Sets ARM NZCV for subtraction; result is discarded architecturally.
mrs  xNZCV, nzcv
bl   rosette_pack_x86_sub_flags_for_cmp
# No destination writeback.
"""

lowering_rules = [
  "Do not write SRC1/destination after comparison.",
  "Decode operand order exactly: CMP computes operand1 - operand2.",
  "For MI and I forms, sign-extend immediate operands according to the documented operand width.",
  "For 32-bit operation in 64-bit mode, compare as 32-bit and update flags from the 32-bit result.",
  "For REX byte-register forms, reject or avoid AH/BH/CH/DH encodings when REX is present.",
  "Preserve all x86 memory-address exceptions even though the arithmetic result is discarded.",
  "Reject LOCK prefix with #UD."
]

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, immediate-extension, REX, or memory behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
