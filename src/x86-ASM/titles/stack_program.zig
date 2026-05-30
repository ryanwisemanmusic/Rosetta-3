const isa = @import("../instruction_set.zig");
const InstructionDef = isa.InstructionDef;
const Register = isa.Register;
const state = @import("stack_state.zig");
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
    fn jne(target_idx: usize) InstructionDef {
        return .{ .opcode = .jne, .op1 = T(target_idx), .op2 = 0 };
    }
    fn call_thunk(id: u32) InstructionDef {
        return .{ .opcode = .call_thunk, .op1 = @as(i32, @bitCast(id)), .op2 = 0 };
    }
    fn exit() InstructionDef {
        return .{ .opcode = .exit, .op1 = 0, .op2 = 0 };
    }
};

const MAIN_LOOP: usize = 12;
const DROP_CHECK: usize = 44;
const EXIT_LOOP: usize = 51;

pub const program_defs = [_]InstructionDef{
    inst.mov_mem_imm(state.SCORE, 0),
    inst.mov_mem_imm(state.LINES, 0),
    inst.mov_mem_imm(state.LEVEL, 1),
    inst.mov_mem_imm(state.GAME_OVER_FLAG, 0),
    inst.mov_mem_imm(state.EXIT_FLAG, 0),
    inst.mov_mem_imm(state.DROP_TIMER, 0),
    inst.mov_mem_imm(state.DROP_COUNTER, 12345),
    inst.mov_mem_imm(state.NEXT_TYPE, 2),
    inst.mov_mem_imm(state.ACTIVE_TYPE, 0),
    inst.mov_mem_imm(state.ACTIVE_X, 3),
    inst.mov_mem_imm(state.ACTIVE_Y, 0),
    inst.mov_mem_imm(state.ACTIVE_ROT, 0),

    inst.call_thunk(state.THUNK_READ_KEY),
    inst.cmp_reg_imm(.eax, -1),
    inst.je(DROP_CHECK),

    inst.cmp_reg_imm(.eax, 'q'),
    inst.je(EXIT_LOOP),

    inst.cmp_reg_imm(.eax, 'a'),
    inst.jne(24),
    inst.mov_reg_imm(.eax, -1),
    inst.mov_reg_imm(.ebx, 0),
    inst.mov_reg_imm(.ecx, 0),
    inst.call_thunk(state.THUNK_TRY_MOVE),
    inst.jmp(DROP_CHECK),

    inst.cmp_reg_imm(.eax, 'd'),
    inst.jne(31),
    inst.mov_reg_imm(.eax, 1),
    inst.mov_reg_imm(.ebx, 0),
    inst.mov_reg_imm(.ecx, 0),
    inst.call_thunk(state.THUNK_TRY_MOVE),
    inst.jmp(DROP_CHECK),

    inst.cmp_reg_imm(.eax, 's'),
    inst.jne(38),
    inst.mov_reg_imm(.eax, 0),
    inst.mov_reg_imm(.ebx, 1),
    inst.mov_reg_imm(.ecx, 0),
    inst.call_thunk(state.THUNK_TRY_MOVE),
    inst.jmp(DROP_CHECK),

    inst.cmp_reg_imm(.eax, 'w'),
    inst.jne(DROP_CHECK),
    inst.mov_reg_imm(.eax, 0),
    inst.mov_reg_imm(.ebx, 0),
    inst.mov_reg_imm(.ecx, 1),
    inst.call_thunk(state.THUNK_TRY_MOVE),

    inst.call_thunk(state.THUNK_LOCK_PROCESS),
    inst.cmp_reg_imm(.eax, 0),
    inst.jne(EXIT_LOOP),

    inst.call_thunk(state.THUNK_RENDER),
    inst.mov_reg_imm(.eax, 50),
    inst.call_thunk(state.THUNK_SLEEP),
    inst.jmp(MAIN_LOOP),

    inst.call_thunk(state.THUNK_RENDER),
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
