const title_runtime = @import("../title_runtime.zig");
const program = @import("block_window_program.zig");
const thunks = @import("block_window_thunks.zig");
const state = @import("block_window_state.zig");
const data_init = @import("entrypoint_data_init_x86");
const bss_init = @import("entrypoint_bss_init_x86");

extern "C" fn rosette_cli_init() void;
extern "C" fn rosette_cli_deinit() void;

const data_sections = [_]data_init.SectionCopy{
    .{ .offset = state.MyWindowClassName, .bytes = "RosetteTetris", .label = "MyWindowClassName" },
    .{ .offset = state.MyWindowName, .bytes = "Tetris", .label = "MyWindowName" },
    .{ .offset = state.NextText, .bytes = "Next", .label = "NextText" },
    .{ .offset = state.GameOverText, .bytes = "Game Over", .label = "GameOverText" },
    .{ .offset = state.ScoreText, .bytes = "Score", .label = "ScoreText" },
};

const bss_sections = [_]bss_init.SectionZero{
    .{ .offset = state.DATA_BASE, .size = state.DATA_SIZE, .label = "block_window_state" },
};

fn initializeData(memory: []u8) void {
    data_init.apply(memory, &data_sections);
}

fn initializeBss(memory: []u8) void {
    bss_init.apply(memory, &bss_sections);
}

pub export fn rosette_run_win32_tetris() void {
    rosette_cli_init();
    defer rosette_cli_deinit();
    rosette_run_win32_tetris_core_inner();
}

fn rosette_run_win32_tetris_core_inner() void {
    title_runtime.runTitle(.{
        .initialize_data = initializeData,
        .initialize_bss = initializeBss,
        .register_thunks = thunks.registerThunks,
        .load_program = program.loadProgram,
        .grid_offset = state.GRID,
        .grid_width = @as(u32, @intCast(state.GRID_WIDTH)),
        .grid_height = @as(u32, @intCast(state.GRID_HEIGHT)),
        .active_type_offset = state.ACTIVE_COLOR_INDEX,
    });
}

pub export fn rosette_run_win32_tetris_core() void {
    rosette_run_win32_tetris_core_inner();
}
