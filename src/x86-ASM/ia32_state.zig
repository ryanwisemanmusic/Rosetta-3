const std = @import("std");
const reg_map = @import("register_mapping.zig");

pub const Ia32State = struct {
    regs: reg_map.RegisterFile = .{},
    cr0: u32 = 0,
    cr2: u32 = 0,
    cr3: u32 = 0,
    cr4: u32 = 0,

    pub fn instructionPointer(self: *Ia32State) *u32 {
        return &self.regs.eip;
    }

    pub fn stackPointer(self: *Ia32State) *u32 {
        return &self.regs.esp;
    }
};

test "ia32 state exposes ip and sp" {
    var state: Ia32State = .{};
    state.regs.eip = 0x401000;
    state.regs.esp = 0x7FF0;
    try std.testing.expectEqual(@as(u32, 0x401000), state.instructionPointer().*);
    try std.testing.expectEqual(@as(u32, 0x7FF0), state.stackPointer().*);
}
