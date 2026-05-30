const std = @import("std");
const Executor = @import("instruction_operations.zig").Executor;
const reg_map = @import("register_mapping.zig");
const Memory = reg_map.Memory;

pub const LoadOptions = struct {
    entry_point: u32,
    load_address: u32 = 0,
    stack_top: u32 = 0,
    cs: u32 = 0,
    ds: u32 = 0,
    ss: u32 = 0,
};

/// Load raw x86 binary code into the executor's memory and set up initial state.
/// The binary is copied verbatim at load_address. Entry point defaults to load_address.
pub fn loadBinary(ex: *Executor, code: []const u8, options: LoadOptions) !u32 {
    const base = options.load_address - ex.mem.base;
    if (base + code.len > ex.mem.data.len) return error.ProgramTooLarge;
    @memcpy(ex.mem.data[base..][0..code.len], code);

    ex.regs.eip = options.entry_point;
    ex.regs.cs = options.cs;
    ex.regs.ds = options.ds;
    ex.regs.ss = options.ss;

    if (options.stack_top != 0) {
        ex.regs.esp = options.stack_top;
    }

    return options.entry_point;
}

/// Load an array of instruction-sized chunks as a program.
/// Each chunk is INSTRUCTION_SIZE bytes. They are loaded sequentially at load_address.
pub fn loadInstructions(ex: *Executor, instructions: []const u8, options: LoadOptions) !u32 {
    if (instructions.len % 12 != 0) return error.InvalidInstructionData;
    return loadBinary(ex, instructions, options);
}
