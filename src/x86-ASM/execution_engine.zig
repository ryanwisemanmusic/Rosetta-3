const std = @import("std");
const isa = @import("instruction_set.zig");
const Opcode = isa.Opcode;
const Register = isa.Register;
const InstructionDef = isa.InstructionDef;
const INSTRUCTION_SIZE = isa.INSTRUCTION_SIZE;
const Executor = @import("instruction_operations.zig").Executor;
const trace = @import("instruction_trace.zig");
const runtime_abi = @import("runtime_abi_handshake");
const reg_trace = @import("register-tracing/runtime.zig");
const stack_trace = @import("stack/runtime.zig");
const decode_trace = @import("instruction-decoding/runtime.zig");
const exception_trace = @import("exceptions/runtime.zig");

pub const ThunkHandler = *const fn (*Executor) void;

pub const ThunkTable = struct {
    handlers: [64]?ThunkHandler = [_]?ThunkHandler{null} ** 64,

    pub fn set(self: *ThunkTable, id: usize, handler: ThunkHandler) void {
        self.handlers[id] = handler;
    }

    pub fn call(self: *ThunkTable, id: usize, ex: *Executor) void {
        if (self.handlers[id]) |h| h(ex);
    }
};

const max_opcode = @intFromEnum(Opcode.exit);

pub fn execNext(ex: *Executor, tt: *ThunkTable) bool {
    const start_eip = ex.regs.eip;
    const base = ex.mem.base;
    const offset = start_eip -| base;
    reg_trace.logInstructionBoundary("pre", "decode", start_eip, &ex.regs, ex.mem.base, ex.mem.data.len);
    runtime_abi.x86.validateExecutorState("pre-step", ex.mem.base, ex.mem.data.len, ex.regs.eip, ex.regs.esp, ex.regs.ebp, ex.regs.flags.raw());
    runtime_abi.x86.validateExtendedState("pre-step", ex.mem.base, ex.mem.data.len, ex.regs.eip, ex.regs.esp, ex.regs.ebp, ex.regs.abiState());
    runtime_abi.x86.validateInstructionFetch(start_eip, ex.mem.base, ex.mem.data.len, INSTRUCTION_SIZE);
    if (offset + INSTRUCTION_SIZE > ex.mem.data.len) return false;
    const slice = ex.mem.data[offset .. offset + INSTRUCTION_SIZE];

    if (slice[0] > max_opcode) {
        ex.regs.pending_exception = 6;
        exception_trace.logFault("decode-invalid", .invalid_opcode, 6, slice[0], start_eip, start_eip, &ex.regs);
        decode_trace.validateInstructionWindow("decode-invalid", start_eip, slice, false, null);
        return false;
    }

    const inst = isa.decode(slice);
    defer {
        runtime_abi.x86.validateExecutorState("post-step", ex.mem.base, ex.mem.data.len, ex.regs.eip, ex.regs.esp, ex.regs.ebp, ex.regs.flags.raw());
        runtime_abi.x86.validateExtendedState("post-step", ex.mem.base, ex.mem.data.len, ex.regs.eip, ex.regs.esp, ex.regs.ebp, ex.regs.abiState());
        reg_trace.logInstructionBoundary("post", @tagName(inst.opcode), start_eip, &ex.regs, ex.mem.base, ex.mem.data.len);
    }
    decode_trace.validateInstructionWindow(@tagName(inst.opcode), start_eip, slice, true, inst);
    trace.logInstruction(start_eip, inst, ex);

    switch (inst.opcode) {
        .nop => {},
        .mov_reg_imm => ex.mov_reg_imm(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1))))), @as(u32, @bitCast(inst.op2))),
        .mov_reg_reg => ex.mov_reg_reg(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1))))), @enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op2)))))),
        .mov_mem_imm => ex.mov_mem_imm(@as(u32, @bitCast(inst.op1)), @as(u32, @bitCast(inst.op2))),
        .mov_mem_reg => ex.mov_mem_reg(@as(u32, @bitCast(inst.op1)), @enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op2)))))),
        .mov_reg_mem => ex.mov_reg_mem(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1))))), @as(u32, @bitCast(inst.op2))),
        .movzx_reg_mem => ex.movzx_reg_mem(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1))))), @as(u32, @bitCast(inst.op2))),
        .mov_mem_reg8 => {
            const addr = @as(u32, @bitCast(inst.op1));
            const val = ex.regs.get8(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op2))))));
            ex.mem.write8(addr, val);
        },
        .lea_reg_mem => ex.lea_reg_mem(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1))))), @as(u32, @bitCast(inst.op2))),
        .add_reg_imm => ex.add_reg_imm(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1))))), @as(u32, @bitCast(inst.op2))),
        .add_reg_reg => ex.add_reg_reg(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1))))), @enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op2)))))),
        .sub_reg_imm => ex.sub_reg_imm(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1))))), @as(u32, @bitCast(inst.op2))),
        .sub_reg_reg => ex.sub_reg_reg(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1))))), @enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op2)))))),
        .inc_reg => ex.inc(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1)))))),
        .dec_reg => ex.dec(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1)))))),
        .mul_reg => ex.mul_reg(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1)))))),
        .imul_reg => ex.imul_reg(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1)))))),
        .div_reg => ex.div_reg(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1)))))),
        .xor_reg_reg => ex.xor_reg_reg(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1))))), @enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op2)))))),
        .and_reg_reg => ex.and_reg_reg(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1))))), @enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op2)))))),
        .or_reg_reg => ex.or_reg_reg(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1))))), @enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op2)))))),
        .not_reg => ex.not_reg(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1)))))),
        .neg_reg => ex.neg_reg(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1)))))),
        .shl_reg_cl => ex.shl_reg_cl(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1)))))),
        .shr_reg_cl => ex.shr_reg_cl(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1)))))),
        .cmp_reg_imm => ex.cmp_reg_imm(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1))))), @as(u32, @bitCast(inst.op2))),
        .cmp_reg_reg => ex.cmp_reg_reg(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1))))), @enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op2)))))),
        .test_reg_reg => ex.test_reg_reg(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1))))), @enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op2)))))),

        .jmp => {
            reg_trace.logControlTransfer("jmp", start_eip, @as(u32, @bitCast(inst.op1)), &ex.regs);
            ex.regs.eip = @as(u32, @bitCast(inst.op1));
            return true;
        },
        .je => {
            if (ex.regs.flags.zf == 1) {
                reg_trace.logControlTransfer("je", start_eip, @as(u32, @bitCast(inst.op1)), &ex.regs);
                ex.regs.eip = @as(u32, @bitCast(inst.op1));
                return true;
            }
        },
        .jne => {
            if (ex.regs.flags.zf == 0) {
                reg_trace.logControlTransfer("jne", start_eip, @as(u32, @bitCast(inst.op1)), &ex.regs);
                ex.regs.eip = @as(u32, @bitCast(inst.op1));
                return true;
            }
        },
        .jl => {
            if (ex.regs.flags.sf != ex.regs.flags.of) {
                reg_trace.logControlTransfer("jl", start_eip, @as(u32, @bitCast(inst.op1)), &ex.regs);
                ex.regs.eip = @as(u32, @bitCast(inst.op1));
                return true;
            }
        },
        .jge => {
            if (ex.regs.flags.sf == ex.regs.flags.of) {
                reg_trace.logControlTransfer("jge", start_eip, @as(u32, @bitCast(inst.op1)), &ex.regs);
                ex.regs.eip = @as(u32, @bitCast(inst.op1));
                return true;
            }
        },
        .jg => {
            if (ex.regs.flags.zf == 0 and ex.regs.flags.sf == ex.regs.flags.of) {
                reg_trace.logControlTransfer("jg", start_eip, @as(u32, @bitCast(inst.op1)), &ex.regs);
                ex.regs.eip = @as(u32, @bitCast(inst.op1));
                return true;
            }
        },
        .jle => {
            if (ex.regs.flags.zf == 1 or ex.regs.flags.sf != ex.regs.flags.of) {
                reg_trace.logControlTransfer("jle", start_eip, @as(u32, @bitCast(inst.op1)), &ex.regs);
                ex.regs.eip = @as(u32, @bitCast(inst.op1));
                return true;
            }
        },

        .call => {
            reg_trace.logControlTransfer("call", start_eip, @as(u32, @bitCast(inst.op1)), &ex.regs);
            stack_trace.logState("before_call", .before_call, &ex.regs, &ex.mem);
            ex.push(start_eip + INSTRUCTION_SIZE);
            stack_trace.logState("after_call_push", .after_call, &ex.regs, &ex.mem);
            ex.regs.eip = @as(u32, @bitCast(inst.op1));
            return true;
        },
        .ret => {
            reg_trace.logControlTransfer("ret", start_eip, ex.mem.read32(ex.regs.esp), &ex.regs);
            stack_trace.logState("before_ret", .before_call, &ex.regs, &ex.mem);
            ex.regs.eip = ex.regs.pop(&ex.mem);
            stack_trace.logState("after_ret", .after_call, &ex.regs, &ex.mem);
            return true;
        },
        .ret_imm => {
            reg_trace.logControlTransfer("ret_imm", start_eip, ex.mem.read32(ex.regs.esp), &ex.regs);
            stack_trace.logState("before_ret_imm", .before_call, &ex.regs, &ex.mem);
            ex.regs.eip = ex.regs.pop(&ex.mem);
            ex.regs.esp +|= @as(u32, @bitCast(inst.op1));
            stack_trace.logState("after_ret_imm", .after_call, &ex.regs, &ex.mem);
            return true;
        },
        .push_reg => {
            const val = ex.regs.get(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1))))));
            ex.push(val);
        },
        .pop_reg => {
            const val = ex.regs.pop(&ex.mem);
            ex.regs.set(@enumFromInt(@as(u4, @truncate(@as(u32, @bitCast(inst.op1))))), val);
        },

        .call_thunk => {
            const id = @as(u32, @bitCast(inst.op1));
            reg_trace.logThunkCall(id, &ex.regs);
            stack_trace.logState("before_thunk", .before_call, &ex.regs, &ex.mem);
            ex.regs.eip = start_eip + INSTRUCTION_SIZE;
            tt.call(@intCast(id), ex);
            stack_trace.logState("after_thunk", .after_call, &ex.regs, &ex.mem);
            return true;
        },

        .exit => return false,
    }

    ex.regs.eip = start_eip + INSTRUCTION_SIZE;
    return true;
}

pub fn run(ex: *Executor, tt: *ThunkTable) void {
    while (execNext(ex, tt)) {}
}
