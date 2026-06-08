// LOAD/LDTILECFG.inc
// ARM64/NEON translation mirror generated from ISA/x86/LOAD/LDTILECFG.inc.
// Source document: LOAD Instructions(1).md
// Family section: LDTILECFG — Load Tile Configuration
// This file preserves the full x86 source contract for LDTILECFG, then appends the ARM64/NEON lowering contract.

// Canonical table metadata for registry-wide .inc validation.
encodings = [
  { opcode = "see preserved_source_contract", form = "LDTILECFG documented source contract", op_en = "DOC", mode64 = "see_source_contract", compat = "see_source_contract", handler = "x86_ldtilecfg" },
]
operand_encoding = [
  { op_en = "DOC", operand_1 = "see preserved_source_contract", operand_2 = "see preserved_source_contract", operand_3 = "N/A", operand_4 = "N/A" },
]

source_isa = "x86"
target_isa = "arm64_neon"
x86_table = "LOAD/LDTILECFG.inc"
x86_handler = "x86_ldtilecfg"
neon_lowering = "amx_tilecfg_state_write_or_unsupported_trap"
lowering_kind = "amx_tile_config_load"

name = "LDTILECFG"
family = "LDTILECFG"
category = "amx_tile_config_load"
operation = "Load Tile Configuration"

source_section_title = "LDTILECFG — Load Tile Configuration"
source_mnemonics_in_section = ["LDTILECFG"]

implicit_reads = []
flags_model = "preserve exact flag behavior from source_contract"
lock_prefix = "#UD where source_contract specifies LOCK-prefix invalidity"
mode_contract = "preserve valid / invalid / not-encodable mode behavior from source_contract"
exception_contract = "preserve protected, real, virtual-8086, compatibility, 64-bit, numeric, AMX, and other exception behavior exactly as listed in source_contract"

source_contract = """
LDTILECFG — Load Tile Configuration

Opcode/Instruction	                                Op/En	64/32 bit Mode Support	CPUID Feature Flag	    Description
VEX.128.NP.0F38.W0 49 !(11):000:bbb LDTILECFG m512	A	    V/N.E.	                AMX-TILE	            Load tile configuration as specified in m512.

Instruction Operand Encoding:

Op/En	Tuple	Operand 1	    Operand 2	Operand 3	Operand 4
A	    N/A	    ModRM:r/m (r)	N/A	        N/A	        N/A

Description:

The LDTILECFG instruction takes an operand containing a pointer to a 64-byte memory location containing the description of the tiles to be supported. In order to configure the tiles, the AMX-TILE bit in CPUID must be set and the operating system has to have enabled the tiles architecture.

The memory area contains the palette and describes how many tiles are being used and defines each tile in terms of rows and column bytes. Requests must be compatible with the restrictions provided by CPUID; see Table 3-10 below.

Byte(s)	    Field Name	                Description
0	        palette	Palette             selects the supported configuration of the tiles that will be used.
1	        start_row	                start_row is used for storing the restart values for interrupted operations.
2-15	    reserved, must be zero	
16-17	    tile0.colsb	                Tile 0 bytes per row.
18-19	    tile1.colsb	                Tile 1 bytes per row.
20-21	    tile2.colsb	                Tile 2 bytes per row.
...	(sequence continues)	
30-31	    tile7.colsb	                Tile 7 bytes per row.
32-47	    reserved, must be zero	
48	        tile0.rows	                Tile 0 rows.
49	        tile1.rows	                Tile 1 rows.
50	        tile2.rows	                Tile 2 rows.
...	(sequence continues)	
55	        tile7.rows	                Tile 7 rows.
56-63	    reserved, must be zero	
Table 3-10. Memory Area Layout

If a tile row and column pair is not used to specify tile parameters, they must have the value zero. All enabled tiles (based on the palette) must be configured. Specifying tile parameters for more tiles than the implementation limit or the palette limit results in a #GP fault.

If the palette_id is zero, that signifies the INIT state for both TILECFG and TILEDATA. Tiles are zeroed in the INIT state. The only legal non-INIT value for palette_id is 1.

Any attempt to execute the LDTILECFG instruction inside an Intel TSX transaction will result in a transaction abort.

Operation:

LDTILECFG mem:

error := False
buf := read_memory(mem, 64)
temp_tilecfg.palette_id := buf.byte[0]
if temp_tilecfg.palette_id > max_palette:
    error := True
if not xcr0_supports_palette(temp_tilecfg.palette_id):
    error := True
if temp_tilecfg.palette_id !=0:
    temp_tilecfg.start_row := buf.byte[1]
    if buf.byte[2..15] is nonzero:
        error := True
    p := 16
    # configure columns
    for n in 0 ... palette_table[temp_tilecfg.palette_id].max_names-1:
        temp_tilecfg.t[n].colsb:= buf.word[p/2]
        p := p + 2
        if temp_tilecfg.t[n].colsb > palette_table[temp_tilecfg.palette_id].bytes_per_row:
            error := True
    if nonzero(buf[p...47]):
        error := True
    # configure rows
    p := 48
    for n in 0 ... palette_table[temp_tilecfg.palette_id].max_names-1:
        temp_tilecfg.t[n].rows:= buf.byte[p]
        if temp_tilecfg.t[n].rows > palette_table[temp_tilecfg.palette_id].max_rows:
            error := True
        p := p + 1
    if nonzero(buf[p...63]):
        error := True
    # validate each tile's row & col configs are reasonable and enable the valid tiles
    for n in 0 ... palette_table[temp_tilecfg.palette_id].max_names-1:
        if temp_tilecfg.t[n].rows !=0 and temp_tilecfg.t[n].colsb != 0:
            temp_tilecfg.t[n].valid := 1
        elif temp_tilecfg.t[n].rows == 0 and temp_tilecfg.t[n].colsb == 0:
            temp_tilecfg.t[n].valid := 0
        else:
            error := True// one of rows or colsbwas 0 but not both.
if error:
    #GP
elif temp_tilecfg.palette_id == 0:
    TILES_CONFIGURED := 0// init state
    tilecfg := 0// equivalent to 64B of zeros
    zero_all_tile_data()
else:
    tilecfg := temp_tilecfg
    zero_all_tile_data()
    TILES_CONFIGURED := 1

Intel C/C++ Compiler Intrinsic Equivalent:

LDTILECFG void _tile_loadconfig(const void *);

Flags Affected:

None.

Exceptions:

AMX-E1; see Section 2.10, “Intel® AMX Instruction Exception Classes,” for details.
"""

semantic = """
Implement LDTILECFG according to source_contract.
Decode opcode, prefixes, ModRM, operand size, address size, CPUID feature gates, privilege gates, and mode restrictions exactly as described.
Perform architectural reads/writes exactly as the Intel-style operation section specifies.
Do not collapse this instruction into a generic load if source_contract requires descriptor validation, segment-register hidden-cache updates, MXCSR validation, AMX tile configuration, Key Locker state, string-index update, or fence ordering.
"""

arm64_lowering_contract = """
Rosette/Rosetta lowering must mirror the x86 architectural side effects, not merely emit a native load.
Where host ARM64 lacks the x86 architectural facility, route through the emulator/system-state model and raise the matching x86 exception.
For memory operands, run the x86 effective-address, segment, canonicality, alignment, paging, and access checks before host memory access.
For vector/string forms, preserve width, zeroing/unmodified upper-lane behavior, implicit operands, and DF-controlled index update.
For privileged/system forms, require CPL/feature checks before mutating emulated descriptor or control state.
"""

neon_notes = [
  "The complete source section is embedded above so no LOAD-related behavior from the Markdown is dropped.",
  "If this instruction is unsupported by the current Rosette runtime, the decoder should still recognize it and raise the documented x86 exception or unsupported-instruction path.",
  "Runtime ABI validation checks the x86 source table shape, mode restrictions, exception list, implicit operands, and ARM64 lowering shape."
]

abi_contract = ["x86_table_shape", "source_contract_preserved", "arm64_lowering_shape", "full_scope_preserved"]
