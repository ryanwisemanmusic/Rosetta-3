// INC-DEC/DEC.inc
// ARM64/NEON translation mirror generated from ISA/x86/INC-DEC/DEC.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

// Canonical table metadata for registry-wide .inc validation.
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "INC-DEC/DEC.inc"
x86_handler = "x86_dec"
neon_lowering = "arm64_sub_imm_1_preserve_cf"
lowering_kind = "arm64_scalar"


name = "DEC"
category = "integer_decrement"
feature = "BASE"
element_type = "integer"
operation_class = "decrement"
lock_prefix = "valid_if_destination_is_memory"

encodings = [
  { opcode = "FE /1", form = "DEC r/m8", op_en = "M", mode64 = "valid", compat = "valid", handler = "x86_dec_rm8" },
  { opcode = "REX + FE /1", form = "DEC r/m8", op_en = "M", mode64 = "valid", compat = "n.e.", handler = "x86_dec_rm8_rex", notes = ["REX byte registers cannot encode AH/BH/CH/DH"] },
  { opcode = "FF /1", form = "DEC r/m16", op_en = "M", mode64 = "valid", compat = "valid", handler = "x86_dec_rm16" },
  { opcode = "FF /1", form = "DEC r/m32", op_en = "M", mode64 = "valid", compat = "valid", handler = "x86_dec_rm32" },
  { opcode = "REX.W + FF /1", form = "DEC r/m64", op_en = "M", mode64 = "valid", compat = "n.e.", handler = "x86_dec_rm64" },
  { opcode = "48+ rw", form = "DEC r16", op_en = "O", mode64 = "n.e.", compat = "valid", handler = "x86_dec_r16_opcode" },
  { opcode = "48+ rd", form = "DEC r32", op_en = "O", mode64 = "n.e.", compat = "valid", handler = "x86_dec_r32_opcode" }
]

operand_encodings = [
  { op_en = "M", operand1 = "ModRM:r/m (r, w)", operand2 = "N/A", operand3 = "N/A", operand4 = "N/A" },
  { op_en = "O", operand1 = "opcode + rd (r, w)", operand2 = "N/A", operand3 = "N/A", operand4 = "N/A" }
]

semantic = """
DEST = DEST - 1;
"""

flags = {
  unaffected = ["CF"],
  affected = ["OF", "SF", "ZF", "AF", "PF"],
  rule = "DEC updates arithmetic status flags according to the result, but preserves CF."
}

notes = [
  "DEC is useful for loop counters when CF must be preserved.",
  "Use SUB destination, 1 when the carry flag must be updated as a borrow flag.",
  "In 64-bit mode, one-byte register opcodes 48H through 4FH are REX prefixes, so DEC r16/r32 opcode forms are not encodable.",
  "Default operation size in 64-bit mode is 32 bits unless REX.W promotes the operation to 64 bits.",
  "LOCK is valid only when the destination operand is memory."
]

exceptions = {
  protected = ["#GP(0) for non-writable destination segment or segment-limit/null-segment memory access", "#SS(0) for stack segment limit", "#PF(fault-code)", "#AC(0)", "#UD if LOCK prefix is used and destination is not memory"],
  real = ["#GP for segment-limit memory access", "#SS for stack segment limit", "#UD if LOCK prefix is used and destination is not memory"],
  v8086 = ["#GP(0) for segment-limit memory access", "#SS(0) for stack segment limit", "#PF(fault-code)", "#AC(0)", "#UD if LOCK prefix is used and destination is not memory"],
  compatibility = ["same as protected mode"],
  mode64 = ["#SS(0) for non-canonical SS memory address", "#GP(0) for non-canonical memory address", "#PF(fault-code)", "#AC(0)", "#UD if LOCK prefix is used and destination is not memory"]
}

handler = "x86_dec"
jit_lowering = "arm64_sub_imm_1_preserve_cf"


neon_register_model = """
x86 general-purpose operands are mapped through the Rosette register file into ARM64 temporaries with explicit writeback.
"""

neon_flag_model = """
ARM64 NZCV is used for arithmetic status while x86 CF is restored from the original EFLAGS image.
"""

neon_assembly = """
subs xD, xN, #1
bl rosette_pack_x86_dec_flags_preserve_cf
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
