// AAS.inc

// Canonical table metadata for registry-wide .inc validation.
encodings = [
  { opcode = "see preserved_source_contract", form = "AAS documented source contract", op_en = "DOC", mode64 = "see_source_contract", compat = "see_source_contract", handler = "x86_aas" },
]
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]

name = "AAS"
category = "ascii_adjust"
opcode = [0x3F]
op_en = "ZO"
operands = []
valid_modes = ["real16", "protected16", "protected32", "compat"]
invalid_modes = ["long64"]

reads = ["AL", "AH", "AF"]
writes = ["AL", "AH", "AF", "CF"]
flags_set_or_cleared = ["AF", "CF"]
flags_undefined = ["OF", "SF", "ZF", "PF"]

implicit_operands = ["AL", "AH", "AX"]

exceptions = [
  { mode = "any", condition = "lock_prefix", exception = "#UD" },
  { mode = "long64", condition = "always", exception = "#UD" }
]

semantic = """
if ((AL & 0x0F) > 9 || AF == 1) {
    AX = AX - 0x0006;
    AH = AH - 1;
    AF = 1;
    CF = 1;
} else {
    AF = 0;
    CF = 0;
}
AL = AL & 0x0F;
"""

handler = "x86_ascii_aas"
jit_lowering = "fallback"
test_priority = "low_legacy"