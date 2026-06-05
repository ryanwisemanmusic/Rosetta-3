const title_runtime = @import("../title_runtime.zig");
const program = @import("stack_program.zig");
const thunks = @import("stack_thunks.zig");
const state = @import("stack_state.zig");
const bss_init = @import("entrypoint_bss_init_x86");

extern "C" fn rosette_cli_init() void;
extern "C" fn rosette_cli_deinit() void;

const bss_sections = [_]bss_init.SectionZero{
    .{ .offset = state.GRID, .size = state.PROGRAM_BASE, .label = "dos_tetris_state" },
};

fn initializeBss(memory: []u8) void {
    bss_init.apply(memory, &bss_sections);
}

pub export fn rosette_run_tetrisx86() void {
    rosette_cli_init();
    defer rosette_cli_deinit();
    rosette_run_tetrisx86_core_inner();
}

fn rosette_run_tetrisx86_core_inner() void {
    title_runtime.runTitle(.{
        .initialize_bss = initializeBss,
        .register_thunks = thunks.registerThunks,
        .load_program = program.loadProgram,
        .grid_offset = state.GRID,
        .grid_width = @as(u32, @intCast(state.GRID_WIDTH)),
        .grid_height = @as(u32, @intCast(state.GRID_HEIGHT)),
        .active_type_offset = state.ACTIVE_TYPE,
    });
}

pub export fn rosette_run_tetrisx86_core() void {
    rosette_run_tetrisx86_core_inner();
}
