const std = @import("std");
const builtin = @import("builtin");

comptime {
    _ = @import("fasm_core.zig");
    _ = @import("memory.zig");
    _ = @import("errors.zig");
    _ = @import("symbols.zig");
    _ = @import("tables.zig");
    _ = @import("expr_parser.zig");
    _ = @import("expr_calc.zig");
    _ = @import("preprocessor.zig");
    _ = @import("parser.zig");
    _ = @import("assembler.zig");
    _ = @import("abi.zig");
}

test {
    _ = @import("fasm_core.zig");
    _ = @import("memory.zig");
    _ = @import("errors.zig");
    _ = @import("symbols.zig");
    _ = @import("tables.zig");
    _ = @import("expr_parser.zig");
    _ = @import("expr_calc.zig");
    _ = @import("preprocessor.zig");
    _ = @import("parser.zig");
    _ = @import("assembler.zig");
    _ = @import("abi.zig");
}
