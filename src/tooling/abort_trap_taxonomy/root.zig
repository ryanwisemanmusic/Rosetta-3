const std = @import("std");

pub const AbortTrap = enum {
    UnsupportedInstruction,
    BadMemoryAccess,
    StackMismatch,
    FlagMismatch,
    RegisterDivergence,
    DivideError,
    UnimplementedWin32,
    BadExecutableFormat,
    BadInstructionPointer,
    InstructionPointerDivergence,
};

pub fn description(kind: AbortTrap) []const u8 {
    return switch (kind) {
        .UnsupportedInstruction => "decoded x86 instruction has no executable lowering yet",
        .BadMemoryAccess => "memory access is outside the active address space or violates permissions",
        .StackMismatch => "x86 stack state diverged from the ABI contract",
        .FlagMismatch => "x86 flag state diverged from the expected ABI state",
        .RegisterDivergence => "general-purpose register state diverged across the ABI boundary",
        .DivideError => "x86 divide exception (#DE)",
        .UnimplementedWin32 => "Win32 API surface is not implemented by the thunk layer",
        .BadExecutableFormat => "input executable cannot be represented by the current PE intake model",
        .BadInstructionPointer => "EIP does not point at executable image text",
        .InstructionPointerDivergence => "source and translated instruction pointers disagree",
    };
}

pub fn pendingException(kind: AbortTrap) u32 {
    return switch (kind) {
        .DivideError => 0,
        .BadMemoryAccess => 0xC000_0005,
        .BadExecutableFormat => 0xC000_007B,
        .UnsupportedInstruction,
        .BadInstructionPointer,
        .InstructionPointerDivergence,
        .UnimplementedWin32,
        .StackMismatch,
        .FlagMismatch,
        .RegisterDivergence,
        => 6,
    };
}

pub fn isInstructionPointerTrap(kind: AbortTrap) bool {
    return switch (kind) {
        .BadInstructionPointer, .InstructionPointerDivergence => true,
        else => false,
    };
}

pub fn formatLabel(buffer: []u8, kind: AbortTrap) ![]const u8 {
    return std.fmt.bufPrint(buffer, "{s}", .{@tagName(kind)});
}

test "taxonomy exposes requested trap names" {
    try std.testing.expectEqualStrings("UnsupportedInstruction", @tagName(AbortTrap.UnsupportedInstruction));
    try std.testing.expectEqualStrings("BadMemoryAccess", @tagName(AbortTrap.BadMemoryAccess));
    try std.testing.expectEqualStrings("StackMismatch", @tagName(AbortTrap.StackMismatch));
    try std.testing.expectEqualStrings("FlagMismatch", @tagName(AbortTrap.FlagMismatch));
    try std.testing.expectEqualStrings("RegisterDivergence", @tagName(AbortTrap.RegisterDivergence));
    try std.testing.expectEqualStrings("DivideError", @tagName(AbortTrap.DivideError));
    try std.testing.expectEqualStrings("UnimplementedWin32", @tagName(AbortTrap.UnimplementedWin32));
    try std.testing.expectEqualStrings("BadExecutableFormat", @tagName(AbortTrap.BadExecutableFormat));
}
