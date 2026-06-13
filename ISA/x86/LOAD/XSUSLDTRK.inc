// LOAD/XSUSLDTRK.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/XSUSLDTRK.inc.
// Source contract: XSUSLDTRK — Suspend Tracking Load Addresses.

name = "XSUSLDTRK"
category = "tsx_system"
feature = "TSXLDTRK"
element_type = "none"
element_size = 0

encodings = [
  { opcode = "F2 0F 01 E8", form = "XSUSLDTRK", op_en = "ZO" }
]

operand_encoding = {
  ZO = []
}

reads = []
writes = ["SUSLDTRK_ACTIVE"]
flags_written = []

semantic = """
IF RTM_ACTIVE = 1:
    IF SUSLDTRK_ACTIVE = 0:
        SUSLDTRK_ACTIVE := 1
    ELSE:
        RTM_ABORT
ELSE:
    NOP
"""

handler = "x86_xsusldtrk"
jit_lowering = "arm64_xsusldtrk"

neon_register_model = """
XSUSLDTRK marks the start of a TSX suspend load address tracking region. ARM64 SMC or emulated RTM lowering must preserve the suspend-load-tracking semantics.
"""

neon_flag_model = """
No x86 flags are modified by XSUSLDTRK.
"""

neon_assembly = """
// XSUSLDTRK: documented ARM64 fallback contract
bl rosette_x86_instruction_fallback
"""

neon_notes = [
  "XSUSLDTRK is only available with TSXLDTRK feature flag.",
  "If used outside a transactional region, it behaves like a NOP.",
  "ARM64 lowering uses SMC or lightweight emulation with documented contract."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
