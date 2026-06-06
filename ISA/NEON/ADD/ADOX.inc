// ADD/ADOX.inc
// ARM64/NEON translation mirror generated from ISA/x86/ADD/ADOX.inc.
// This file preserves the full x86 instruction contract, then appends the ARM64/NEON lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "ADD/ADOX.inc"
x86_handler = "x86_adox"
neon_lowering = "fallback"
lowering_kind = "fallback"


name = "ADOX"
category = "adx_overflow_chain"
feature = "ADX"
operation = "dest = dest + src + OF"

encodings = [
  { opcode = "F3 0F 38 F6 /r", form = "ADOX r32, r/m32", op_en = "RM" },
  { opcode = "F3 REX.W 0F 38 F6 /r", form = "ADOX r64, r/m64", op_en = "RM" }
]

reads = ["DEST", "SRC", "OF"]
writes = ["DEST", "OF"]
flags_written = ["OF"]
flags_unchanged = ["CF", "SF", "ZF", "AF", "PF"]

semantic = """
carry = OF ? 1 : 0;
wide = DEST + SRC + carry;
DEST = truncate(wide, operand_size);
OF = carry_out_unsigned(wide, operand_size);
"""

exceptions = [
  { condition = "LOCK prefix used", exception = "#UD" },
  { condition = "CPUID ADX unavailable", exception = "#UD" }
]

handler = "x86_adox"
jit_lowering = "fallback"

neon_register_model = """
x86 general-purpose operands are mapped through the Rosette register file into ARM64 temporaries with explicit writeback.
"""

neon_flag_model = """
Flags are delegated to the x86 fallback interpreter for legacy or unsupported lowering.
"""

neon_assembly = """
bl rosette_x86_instruction_fallback
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "The ARM64/NEON lowering must not weaken the x86 register, flag, exception, lock-prefix, MXCSR, or implicit-operand behavior.",
  "Runtime ABI validation checks both the x86 table shape and this NEON lowering shape."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
