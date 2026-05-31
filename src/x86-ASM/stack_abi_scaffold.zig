const std = @import("std");

pub const CallingConvention32 = enum {
    cdecl,
    stdcall,
    fastcall,
    thiscall,
};

pub const StackFrameLayout = struct {
    local_bytes: u32 = 0,
    parameter_bytes: u32 = 0,
    callee_cleans_stack: bool = false,

    pub fn cleanupBytes(self: StackFrameLayout) u32 {
        return if (self.callee_cleans_stack) self.parameter_bytes else 0;
    }
};

pub fn conventionLayout(convention: CallingConvention32, parameter_bytes: u32) StackFrameLayout {
    return switch (convention) {
        .cdecl => .{ .parameter_bytes = parameter_bytes, .callee_cleans_stack = false },
        .stdcall => .{ .parameter_bytes = parameter_bytes, .callee_cleans_stack = true },
        .fastcall => .{ .parameter_bytes = parameter_bytes, .callee_cleans_stack = true },
        .thiscall => .{ .parameter_bytes = parameter_bytes, .callee_cleans_stack = true },
    };
}

test "stdcall cleans stack while cdecl does not" {
    try std.testing.expectEqual(@as(u32, 16), conventionLayout(.stdcall, 16).cleanupBytes());
    try std.testing.expectEqual(@as(u32, 0), conventionLayout(.cdecl, 16).cleanupBytes());
}
