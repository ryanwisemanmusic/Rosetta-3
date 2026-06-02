const isa = @import("../instruction_set.zig");
const InstructionDef = isa.InstructionDef;
const Register = isa.Register;
const state = @import("block_window_state.zig");
const Executor = @import("../instruction_operations.zig").Executor;
const scripted = @import("../scripted_program.zig");

fn R(reg: Register) i32 {
    return scripted.registerOperand(reg);
}

fn ADDR(off: u32) i32 {
    return scripted.addressOperand(off);
}

fn T(idx: usize) i32 {
    return scripted.instructionAddress(state.PROGRAM_BASE, idx);
}

const inst = struct {
    fn mov_reg_mem(dst: Register, addr: u32) InstructionDef {
        return .{ .opcode = .mov_reg_mem, .op1 = R(dst), .op2 = ADDR(addr) };
    }
    fn mov_reg_imm(dst: Register, val: i32) InstructionDef {
        return .{ .opcode = .mov_reg_imm, .op1 = R(dst), .op2 = val };
    }
    fn cmp_reg_imm(reg: Register, val: i32) InstructionDef {
        return .{ .opcode = .cmp_reg_imm, .op1 = R(reg), .op2 = val };
    }
    fn jmp(target_idx: usize) InstructionDef {
        return .{ .opcode = .jmp, .op1 = T(target_idx), .op2 = 0 };
    }
    fn je(target_idx: usize) InstructionDef {
        return .{ .opcode = .je, .op1 = T(target_idx), .op2 = 0 };
    }
    fn call_thunk(id: u32) InstructionDef {
        return .{ .opcode = .call_thunk, .op1 = @as(i32, @bitCast(id)), .op2 = 0 };
    }
    fn exit() InstructionDef {
        return .{ .opcode = .exit, .op1 = 0, .op2 = 0 };
    }
};

const MAIN_LOOP: usize = 1;
const EXIT_LOOP: usize = 8;

pub const program_defs = [_]InstructionDef{
    inst.call_thunk(state.THUNK_INIT_GAME),

    inst.call_thunk(state.THUNK_PROCESS_FRAME),
    inst.mov_reg_mem(.eax, state.GAME_OVER),
    inst.cmp_reg_imm(.eax, 1),
    inst.je(EXIT_LOOP),
    inst.mov_reg_imm(.eax, 50),
    inst.call_thunk(state.THUNK_SLEEP),
    inst.jmp(MAIN_LOOP),

    inst.mov_reg_mem(.eax, state.SCORE),
    inst.call_thunk(state.THUNK_GAME_OVER),
    inst.exit(),
};

pub fn loadProgram(ex: *Executor) !u32 {
    const image = scripted.ProgramImage{
        .program_base = state.PROGRAM_BASE,
        .defs = program_defs[0..],
    };
    return image.load(ex);
}
