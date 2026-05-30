const std = @import("std");
const Executor = @import("../instruction_operations.zig").Executor;
const state = @import("trail_state.zig");
const ThunkTable = @import("../execution_engine.zig").ThunkTable;
const cli = @import("../cli_host.zig");

fn readKeyThunk(ex: *Executor) void {
    cli.readKeyToEax(ex);
}

fn renderFrameThunk(ex: *Executor) void {
    const head_x = ex.mem.read32(state.HEAD_X);
    const head_y = ex.mem.read32(state.HEAD_Y);
    const target_x = ex.mem.read32(state.TARGET_X);
    const target_y = ex.mem.read32(state.TARGET_Y);
    const score = ex.mem.read32(state.SCORE);

    cli.clearScreen();

    var y: i32 = 0;
    while (y < state.SCREEN_HEIGHT) : (y += 1) {
        cli.moveCursor(0, y);
        var x: i32 = 0;
        while (x < state.SCREEN_WIDTH) : (x += 1) {
            const ch: u8 = if (y == 0 or y == state.SCREEN_HEIGHT - 1 or x == 0 or x == state.SCREEN_WIDTH - 1)
                '#'
            else if (x == head_x and y == head_y)
                'O'
            else if (x == target_x and y == target_y)
                '@'
            else
                ' ';
            cli.writeByte(ch);
        }
    }

    cli.moveCursor(0, 21);
    var buf: [128]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, "Score: {d}  (W/A/S/D to move, Q to quit)\r\n", .{score}) catch "Score Error\r\n";
    cli.writeText(msg);
}

fn gameOverThunk(ex: *Executor) void {
    const score = ex.regs.eax;
    cli.clearScreen();
    var buf: [128]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, "Game Over! Final Score: {d}\r\n", .{score}) catch "Game Over!\r\n";
    cli.writeText(msg);
    cli.pauseSeconds(2);
}

fn sleepMsThunk(ex: *Executor) void {
    cli.sleepFromEax(ex);
}

pub fn registerThunks(tt: *ThunkTable) void {
    tt.set(state.THUNK_READ_KEY, readKeyThunk);
    tt.set(state.THUNK_RENDER, renderFrameThunk);
    tt.set(state.THUNK_GAME_OVER, gameOverThunk);
    tt.set(state.THUNK_SLEEP, sleepMsThunk);
}
