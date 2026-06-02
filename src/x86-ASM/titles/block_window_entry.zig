const title_runtime = @import("../title_runtime.zig");
const program = @import("block_window_program.zig");
const thunks = @import("block_window_thunks.zig");
const state = @import("block_window_state.zig");

extern "C" fn rosetta3_cli_init() void;
extern "C" fn rosetta3_cli_deinit() void;

pub export fn rosetta3_run_win32_tetris() void {
    rosetta3_cli_init();
    defer rosetta3_cli_deinit();
    rosetta3_run_win32_tetris_core_inner();
}

fn rosetta3_run_win32_tetris_core_inner() void {
    title_runtime.runTitle(.{
        .register_thunks = thunks.registerThunks,
        .load_program = program.loadProgram,
        .grid_offset = state.GRID,
        .grid_width = @as(u32, @intCast(state.GRID_WIDTH)),
        .grid_height = @as(u32, @intCast(state.GRID_HEIGHT)),
        .active_type_offset = state.ACTIVE_COLOR_INDEX,
    });
}

pub export fn rosetta3_run_win32_tetris_core() void {
    rosetta3_run_win32_tetris_core_inner();
}
