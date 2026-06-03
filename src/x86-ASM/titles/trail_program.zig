const isa = @import("../instruction_set.zig");
const InstructionDef = isa.InstructionDef;
const Register = isa.Register;
const state = @import("trail_state.zig");
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
    fn mov_mem_imm(addr: u32, val: i32) InstructionDef {
        return .{ .opcode = .mov_mem_imm, .op1 = ADDR(addr), .op2 = val };
    }
    fn mov_reg_mem(dst: Register, addr: u32) InstructionDef {
        return .{ .opcode = .mov_reg_mem, .op1 = R(dst), .op2 = ADDR(addr) };
    }
    fn mov_mem_reg(addr: u32, src: Register) InstructionDef {
        return .{ .opcode = .mov_mem_reg, .op1 = ADDR(addr), .op2 = R(src) };
    }
    fn mov_reg_imm(dst: Register, val: i32) InstructionDef {
        return .{ .opcode = .mov_reg_imm, .op1 = R(dst), .op2 = val };
    }
    fn add_reg_imm(dst: Register, val: i32) InstructionDef {
        return .{ .opcode = .add_reg_imm, .op1 = R(dst), .op2 = val };
    }
    fn add_reg_reg(dst: Register, src: Register) InstructionDef {
        return .{ .opcode = .add_reg_reg, .op1 = R(dst), .op2 = R(src) };
    }
    fn cmp_reg_imm(reg: Register, val: i32) InstructionDef {
        return .{ .opcode = .cmp_reg_imm, .op1 = R(reg), .op2 = val };
    }
    fn cmp_reg_reg(a: Register, b: Register) InstructionDef {
        return .{ .opcode = .cmp_reg_reg, .op1 = R(a), .op2 = R(b) };
    }
    fn jmp(target_idx: usize) InstructionDef {
        return .{ .opcode = .jmp, .op1 = T(target_idx), .op2 = 0 };
    }
    fn je(target_idx: usize) InstructionDef {
        return .{ .opcode = .je, .op1 = T(target_idx), .op2 = 0 };
    }
    fn jne(target_idx: usize) InstructionDef {
        return .{ .opcode = .jne, .op1 = T(target_idx), .op2 = 0 };
    }
    fn jle(target_idx: usize) InstructionDef {
        return .{ .opcode = .jle, .op1 = T(target_idx), .op2 = 0 };
    }
    fn jge(target_idx: usize) InstructionDef {
        return .{ .opcode = .jge, .op1 = T(target_idx), .op2 = 0 };
    }
    fn call_thunk(id: u32) InstructionDef {
        return .{ .opcode = .call_thunk, .op1 = @as(i32, @bitCast(id)), .op2 = 0 };
    }
    fn mul_reg(src: Register) InstructionDef {
        return .{ .opcode = .mul_reg, .op1 = R(src), .op2 = 0 };
    }
    fn div_reg(src: Register) InstructionDef {
        return .{ .opcode = .div_reg, .op1 = R(src), .op2 = 0 };
    }
    fn xor_reg_reg(dst: Register, src: Register) InstructionDef {
        return .{ .opcode = .xor_reg_reg, .op1 = R(dst), .op2 = R(src) };
    }
    fn exit() InstructionDef {
        return .{ .opcode = .exit, .op1 = 0, .op2 = 0 };
    }
};

const MAIN_LOOP: usize = 8;
const AFTER_INPUT: usize = 32;
const NO_TARGET: usize = 81;
const FINISH: usize = 85;

pub const program_defs = [_]InstructionDef{
    inst.mov_mem_imm(state.HEAD_X, 10),
    inst.mov_mem_imm(state.HEAD_Y, 10),
    inst.mov_mem_imm(state.TARGET_X, 20),
    inst.mov_mem_imm(state.TARGET_Y, 5),
    inst.mov_mem_imm(state.SCORE, 0),
    inst.mov_mem_imm(state.VEL_X, 1),
    inst.mov_mem_imm(state.VEL_Y, 0),
    inst.mov_mem_imm(state.RNG_STATE, 12345),

    inst.call_thunk(state.THUNK_READ_KEY),
    inst.cmp_reg_imm(.eax, -1),
    inst.je(AFTER_INPUT),

    inst.cmp_reg_imm(.eax, 'q'),
    inst.je(FINISH),

    inst.cmp_reg_imm(.eax, 'w'),
    inst.jne(18),
    inst.mov_mem_imm(state.VEL_X, 0),
    inst.mov_mem_imm(state.VEL_Y, -1),
    inst.jmp(AFTER_INPUT),

    inst.cmp_reg_imm(.eax, 's'),
    inst.jne(23),
    inst.mov_mem_imm(state.VEL_X, 0),
    inst.mov_mem_imm(state.VEL_Y, 1),
    inst.jmp(AFTER_INPUT),

    inst.cmp_reg_imm(.eax, 'a'),
    inst.jne(28),
    inst.mov_mem_imm(state.VEL_X, -1),
    inst.mov_mem_imm(state.VEL_Y, 0),
    inst.jmp(AFTER_INPUT),

    inst.cmp_reg_imm(.eax, 'd'),
    inst.jne(AFTER_INPUT),
    inst.mov_mem_imm(state.VEL_X, 1),
    inst.mov_mem_imm(state.VEL_Y, 0),

    inst.mov_reg_mem(.eax, state.VEL_X),
    inst.mov_reg_mem(.ebx, state.HEAD_X),
    inst.add_reg_reg(.ebx, .eax),
    inst.mov_mem_reg(state.HEAD_X, .ebx),

    inst.mov_reg_mem(.eax, state.VEL_Y),
    inst.mov_reg_mem(.ebx, state.HEAD_Y),
    inst.add_reg_reg(.ebx, .eax),
    inst.mov_mem_reg(state.HEAD_Y, .ebx),

    inst.mov_reg_mem(.eax, state.HEAD_X),
    inst.cmp_reg_imm(.eax, 0),
    inst.jle(FINISH),
    inst.cmp_reg_imm(.eax, 59),
    inst.jge(FINISH),

    inst.mov_reg_mem(.eax, state.HEAD_Y),
    inst.cmp_reg_imm(.eax, 0),
    inst.jle(FINISH),
    inst.cmp_reg_imm(.eax, 19),
    inst.jge(FINISH),

    inst.mov_reg_mem(.eax, state.HEAD_X),
    inst.mov_reg_mem(.ebx, state.TARGET_X),
    inst.cmp_reg_reg(.eax, .ebx),
    inst.jne(NO_TARGET),

    inst.mov_reg_mem(.eax, state.HEAD_Y),
    inst.mov_reg_mem(.ebx, state.TARGET_Y),
    inst.cmp_reg_reg(.eax, .ebx),
    inst.jne(NO_TARGET),

    inst.mov_reg_mem(.eax, state.SCORE),
    inst.add_reg_imm(.eax, 10),
    inst.mov_mem_reg(state.SCORE, .eax),

    inst.mov_reg_mem(.eax, state.RNG_STATE),
    inst.mov_reg_imm(.ecx, 1103515245),
    inst.mul_reg(.ecx),
    inst.add_reg_imm(.eax, 12345),
    inst.mov_mem_reg(state.RNG_STATE, .eax),

    inst.xor_reg_reg(.edx, .edx),
    inst.mov_reg_imm(.ecx, 58),
    inst.div_reg(.ecx),
    inst.add_reg_imm(.edx, 1),
    inst.mov_mem_reg(state.TARGET_X, .edx),

    inst.mov_reg_mem(.eax, state.RNG_STATE),
    inst.mov_reg_imm(.ecx, 1103515245),
    inst.mul_reg(.ecx),
    inst.add_reg_imm(.eax, 12345),
    inst.mov_mem_reg(state.RNG_STATE, .eax),

    inst.xor_reg_reg(.edx, .edx),
    inst.mov_reg_imm(.ecx, 18),
    inst.div_reg(.ecx),
    inst.add_reg_imm(.edx, 1),
    inst.mov_mem_reg(state.TARGET_Y, .edx),

    inst.call_thunk(state.THUNK_RENDER),
    inst.mov_reg_imm(.eax, 100),
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
