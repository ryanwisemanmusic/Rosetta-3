const std = @import("std");
const Executor = @import("instruction_operations.zig").Executor;
const engine = @import("execution_engine.zig");
const ThunkTable = engine.ThunkTable;
const trace = @import("instruction_trace.zig");
const gfx = @import("graphics/renderer.zig");
const runtime_abi = @import("runtime_abi_handshake");

pub const TitleSpec = struct {
    memory_size: u32 = 1024 * 1024,
    stack_top: ?u32 = null,
    install_imports: ?*const fn (*Executor) void = null,
    register_thunks: *const fn (*ThunkTable) void,
    load_program: *const fn (*Executor) anyerror!u32,
    /// Grid source config for color-accurate block rendering.
    /// Set to zero/null to skip (no grid source = fallback colors).
    grid_offset: u32 = 0,
    grid_width: u32 = 0,
    grid_height: u32 = 0,
    /// Emulator memory offset for the active piece type (i32).
    active_type_offset: u32 = 0,
};

pub fn runTitle(spec: TitleSpec) void {
    trace.initFromHostConfig();
    defer trace.deinit();
    runtime_abi.x86.init();
    defer runtime_abi.x86.deinit();

    const allocator = std.heap.page_allocator;
    var ex = Executor.init(allocator, spec.memory_size);
    defer ex.deinit();

    ex.regs.esp = spec.stack_top orelse spec.memory_size;
    runtime_abi.x86.validateTitleSpec(
        spec.memory_size,
        ex.regs.esp,
        spec.grid_offset,
        spec.grid_width,
        spec.grid_height,
        spec.active_type_offset,
    );

    // Set up grid source for the renderer so it can look up piece colors
    // by reading emulator grid memory on each write_byte call.
    if (spec.grid_width > 0 and spec.grid_height > 0) {
        const grid_byte_count = spec.grid_width * spec.grid_height;
        const grid_end = spec.grid_offset +% grid_byte_count;
        if (grid_end <= ex.mem.data.len and grid_end > spec.grid_offset) {
            const grid_slice = ex.mem.data[spec.grid_offset .. spec.grid_offset + grid_byte_count];
            gfx.rosetta3_gfx_set_grid_source(grid_slice.ptr, spec.grid_width, spec.grid_height);
        }
        gfx.rosetta3_gfx_set_active_piece_offset(spec.active_type_offset -% spec.grid_offset);
    }

    if (spec.install_imports) |install_imports| {
        install_imports(&ex);
    }

    var tt = engine.ThunkTable{};
    spec.register_thunks(&tt);

    const entry = spec.load_program(&ex) catch return;
    ex.regs.eip = entry;
    runtime_abi.x86.validateExecutorState("post-init", ex.mem.base, ex.mem.data.len, ex.regs.eip, ex.regs.esp, ex.regs.ebp, ex.regs.flags.raw());
    engine.run(&ex, &tt);
}
