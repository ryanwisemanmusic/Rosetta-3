const std = @import("std");
const builtin = @import("builtin");

comptime {
    if (builtin.is_test) {
        _ = @import("nasm_core.zig");
        _ = @import("directives.zig");
        _ = @import("operands.zig");
        _ = @import("encoding.zig");
        _ = @import("segments.zig");
        _ = @import("preprocessor.zig");
        _ = @import("symbols.zig");
        _ = @import("output.zig");
        _ = @import("listing.zig");
        _ = @import("assembler.zig");
    }
}
