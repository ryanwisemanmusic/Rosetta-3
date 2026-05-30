const std = @import("std");
const Executor = @import("instruction_operations.zig").Executor;
const engine = @import("execution_engine.zig");
const ThunkTable = engine.ThunkTable;

pub const TitleSpec = struct {
    memory_size: u32 = 1024 * 1024,
    stack_top: ?u32 = null,
    install_imports: ?*const fn (*Executor) void = null,
    register_thunks: *const fn (*ThunkTable) void,
    load_program: *const fn (*Executor) anyerror!u32,
};

pub fn runTitle(spec: TitleSpec) void {
    const allocator = std.heap.page_allocator;
    var ex = Executor.init(allocator, spec.memory_size);
    defer ex.deinit();

    ex.regs.esp = spec.stack_top orelse spec.memory_size;

    if (spec.install_imports) |install_imports| {
        install_imports(&ex);
    }

    var tt = engine.ThunkTable{};
    spec.register_thunks(&tt);

    const entry = spec.load_program(&ex) catch return;
    ex.regs.eip = entry;
    engine.run(&ex, &tt);
}
