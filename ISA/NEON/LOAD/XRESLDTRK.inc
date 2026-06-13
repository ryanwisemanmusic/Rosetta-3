// LOAD/XRESLDTRK.inc
// ARM64/NEON mirror generated from ISA/x86/LOAD/XRESLDTRK.inc.
// This file preserves the x86 source contract and supplies the ARM64 lowering contract.

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/XRESLDTRK.inc"
x86_handler = "x86_xresldtrk"
neon_lowering = "arm64_xresldtrk"
lowering_kind = "arm64_documented_contract"

// LOAD/XRESLDTRK.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/XRESLDTRK.inc.
// Source contract: XRESLDTRK — Resume Tracking Load Addresses.

name = "XRESLDTRK"
category = "tsx_system"
feature = "TSXLDTRK"
element_type = "none"
element_size = 0

encodings = [
  { opcode = "F2 0F 01 E9", form = "XRESLDTRK", op_en = "ZO" }
]

operand_encoding = {
  ZO = []
}

reads = []
writes = ["SUSLDTRK_ACTIVE"]
flags_written = []

semantic = """
IF RTM_ACTIVE = 1:
    IF SUSLDTRK_ACTIVE = 1:
        SUSLDTRK_ACTIVE := 0
    ELSE:
        RTM_ABORT
ELSE:
    NOP
"""

handler = "x86_xresldtrk"
jit_lowering = "arm64_xresldtrk"

neon_register_model = """
XRESLDTRK marks the end of a TSX suspend load address tracking region. ARM64 SMC or emulated RTM lowering must preserve the suspend-load-tracking semantics.
"""

neon_flag_model = """
No x86 flags are modified by XRESLDTRK.
"""

neon_assembly = """
// XRESLDTRK: documented ARM64 fallback contract
bl rosette_x86_instruction_fallback
"""

neon_notes = [
  "XRESLDTRK is only available with TSXLDTRK feature flag.",
  "If used outside a transactional region, it behaves like a NOP.",
  "ARM64 lowering uses SMC or lightweight emulation with documented contract."
]

abi_contract = ["x86_table_shape", "neon_mirror_shape", "arm64_lowering_shape", "full_scope_preserved"]
