const std = @import("std");
const reg_map = @import("register_mapping.zig");
pub const Register = reg_map.Register;
pub const Memory = reg_map.Memory;

pub const INSTRUCTION_SIZE: u32 = 12;

pub const Opcode = enum(u8) {
    nop = 0,
    mov_reg_imm = 1,
    mov_reg_reg = 2,
    mov_mem_imm = 3,
    mov_mem_reg = 4,
    mov_reg_mem = 5,
    movzx_reg_mem = 6,
    mov_mem_reg8 = 7,
    lea_reg_mem = 8,
    add_reg_imm = 9,
    add_reg_reg = 10,
    sub_reg_imm = 11,
    sub_reg_reg = 12,
    inc_reg = 13,
    dec_reg = 14,
    mul_reg = 15,
    imul_reg = 16,
    div_reg = 17,
    xor_reg_reg = 18,
    and_reg_reg = 19,
    or_reg_reg = 20,
    not_reg = 21,
    neg_reg = 22,
    shl_reg_cl = 23,
    shr_reg_cl = 24,
    cmp_reg_imm = 25,
    cmp_reg_reg = 26,
    test_reg_reg = 27,
    jmp = 28,
    je = 29,
    jne = 30,
    jl = 31,
    jge = 32,
    jg = 33,
    jle = 34,
    call = 35,
    ret = 36,
    ret_imm = 37,
    push_reg = 38,
    pop_reg = 39,
    call_thunk = 40,
    exit = 41,
};

pub const InstructionDef = struct {
    opcode: Opcode,
    op1: i32,
    op2: i32,
};

pub fn encode(buf: []u8, inst: InstructionDef) void {
    buf[0] = @intFromEnum(inst.opcode);
    std.mem.writeInt(i32, buf[1..5], inst.op1, .little);
    std.mem.writeInt(i32, buf[5..9], inst.op2, .little);
    buf[9] = 0;
    buf[10] = 0;
    buf[11] = 0;
}

pub fn decode(buf: []const u8) InstructionDef {
    return .{
        .opcode = @enumFromInt(buf[0]),
        .op1 = std.mem.readInt(i32, buf[1..5], .little),
        .op2 = std.mem.readInt(i32, buf[5..9], .little),
    };
}
