const std = @import("std");

pub const BinaryMode = enum {
    win32_pe,
    win64_pe,
};

pub const LoaderSeparation = struct {
    binary_mode: BinaryMode,
    dedicated_loader: bool,
    imported_function_table: bool,
    abi_bridge: bool,
    api_bridge: bool,
};

pub const ImportSymbol = struct {
    library: []const u8,
    name: []const u8,
    ordinal: ?u16 = null,
};

pub const RuntimeBridgePlan = struct {
    loader: LoaderSeparation,
    symbols: []const ImportSymbol,
    mandatory_disassembly: bool = true,
};

test "runtime scaffold defaults to mandatory disassembly for exe intake" {
    const plan = RuntimeBridgePlan{
        .loader = .{
            .binary_mode = .win32_pe,
            .dedicated_loader = true,
            .imported_function_table = true,
            .abi_bridge = true,
            .api_bridge = true,
        },
        .symbols = &[_]ImportSymbol{},
    };
    try std.testing.expect(plan.mandatory_disassembly);
}
