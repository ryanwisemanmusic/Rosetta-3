const std = @import("std");
const calls = @import("calling_conventions.zig");

pub const LoaderKind64 = enum {
    pe32_plus,
    macho_later,
    elf_later,
};

pub const RuntimePlan64 = struct {
    loader: LoaderKind64,
    abi: calls.CallingConvention64,
    imported_function_thunks: bool,
    syscall_bridge: bool,
    api_bridge: bool,
    mandatory_disassembly: bool = true,
};

test "win64 runtime scaffold starts from pe32+ plus microsoft abi" {
    const plan = RuntimePlan64{
        .loader = .pe32_plus,
        .abi = .microsoft_x64,
        .imported_function_thunks = true,
        .syscall_bridge = true,
        .api_bridge = true,
    };
    try std.testing.expect(plan.mandatory_disassembly);
}
