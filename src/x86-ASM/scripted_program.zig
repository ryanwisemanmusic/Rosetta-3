const std = @import("std");
const isa = @import("instruction_set.zig");
const InstructionDef = isa.InstructionDef;
const Register = isa.Register;
const Executor = @import("instruction_operations.zig").Executor;

pub fn registerOperand(reg: Register) i32 {
    return @as(i32, @bitCast(@as(u32, @intFromEnum(reg))));
}

pub fn addressOperand(addr: u32) i32 {
    return @as(i32, @bitCast(addr));
}

pub fn instructionAddress(program_base: u32, index: usize) i32 {
    const addr = program_base + @as(u32, @intCast(index)) * isa.INSTRUCTION_SIZE;
    return @as(i32, @bitCast(addr));
}

pub const ProgramImage = struct {
    program_base: u32,
    defs: []const InstructionDef,

    pub fn load(self: ProgramImage, ex: *Executor) !u32 {
        const mem_offset = self.program_base - ex.mem.base;
        if (mem_offset + self.defs.len * isa.INSTRUCTION_SIZE > ex.mem.data.len) {
            return error.ProgramTooLarge;
        }

        var buf: [isa.INSTRUCTION_SIZE]u8 = undefined;
        for (self.defs, 0..) |def, i| {
            const offset = mem_offset + i * isa.INSTRUCTION_SIZE;
            isa.encode(&buf, def);
            @memcpy(ex.mem.data[offset..][0..isa.INSTRUCTION_SIZE], &buf);
        }
        return self.program_base;
    }
};

test "program image loads instruction stream at configured base" {
    var ex = Executor.init(std.testing.allocator, 4096);
    defer ex.deinit();

    const defs = [_]InstructionDef{
        .{ .opcode = .mov_reg_imm, .op1 = registerOperand(.eax), .op2 = 42 },
        .{ .opcode = .exit, .op1 = 0, .op2 = 0 },
    };
    const image = ProgramImage{
        .program_base = 0x200,
        .defs = defs[0..],
    };

    const entry = try image.load(&ex);
    try std.testing.expectEqual(@as(u32, 0x200), entry);
    try std.testing.expectEqual(isa.Opcode.mov_reg_imm, isa.decode(ex.mem.data[0x200..][0..isa.INSTRUCTION_SIZE]).opcode);
}
