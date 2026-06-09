// AND/ANDN.inc
// ARM64/NEON translation mirror generated from ISA/x86/AND/ANDN.inc.
// Source contract: ANDN — Logical AND NOT (BMI1).

name = "ANDN"
aliases = ["VANDN"]
category = "integer_logic_bitwise"
feature = "BMI1"
element_type = "u64"
element_size = 64

encodings = [
  { opcode = "VEX.LZ.0F38.W0 F2 /r", form = "ANDN r32a, r32b, r/m32", op_en = "RVM", feature = "BMI1", vector_length = 0, encoding = "vex" },
  { opcode = "VEX.LZ.0F38.W1 F2 /r", form = "ANDN r64a, r64b, r/m64", op_en = "RVM", feature = "BMI1", vector_length = 0, encoding = "vex" }
]

operand_encoding = {
  RVM = ["ModRM:reg (w)", "VEX.vvvv (r)", "ModRM:r/m (r)"]
}

reads = ["SRC1", "SRC2"]
writes = ["DEST"]
flags_read = []
flags_written = ["SF", "ZF"]
flags_cleared = ["OF", "CF"]
flags_undefined = ["AF", "PF"]

semantic = """
DEST = (~SRC1) & SRC2;
SF = most_significant_bit(DEST);
ZF = (DEST == 0);
OF = 0;
CF = 0;
AF = undefined;
PF = undefined;
"""

exceptions = {
  protected_mode = [
    "#UD if VEX.L != 0",
    "#UD if CR0.EM = 1",
    "#AC(0) if alignment checking is enabled and an unaligned memory reference is made at CPL3",
    "Otherwise, see Table 2-29 Type 13 class exception conditions"
  ],
  real_address_mode = ["#UD"],
  virtual_8086_mode = ["#UD"],
  compatibility_mode = ["same_as_protected_mode"],
  mode64 = [
    "#GP(0) if a memory address referencing SS is non-canonical",
    "#GP(0) if the memory address is non-canonical",
    "#PF(fault-code) if a page fault occurs",
    "#AC(0) if alignment checking is enabled and an unaligned memory reference is made at CPL3",
    "#UD if VEX.L != 0"
  ]
}

handler = "x86_andn"
jit_lowering = "arm64_and_not"

neon_register_model = """
x86 general-purpose operands are mapped through the Rosette register file into ARM64 temporaries with explicit writeback. ANDN is a three-operand BMI1 instruction with no memory destination.
"""

neon_flag_model = """
ARM64 BIC (bitwise clear) followed by flag computation for SF, ZF, and cleared OF/CF.
"""

neon_assembly = """
bic xD, xN, xM
bl rosette_pack_x86_andn_flags
"""

neon_notes = [
  "The x86 encoding, operands, semantic text, exceptions, and notes above are intentionally preserved as the source contract.",
  "ANDN (BMI1) does not modify AF or PF; they are left undefined."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
