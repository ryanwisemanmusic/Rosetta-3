const std = @import("std");
const Executor = @import("../instruction_operations.zig").Executor;
const state = @import("block_window_state.zig");
const ThunkTable = @import("../execution_engine.zig").ThunkTable;
const gfx = @import("../graphics/renderer.zig");
const palette = @import("../graphics/palette.zig");
const cli = @import("../cli_host.zig");
const scene = @import("../graphics/scene.zig");

const gravity_interval_frames: u32 = 20;
const label_max_len: usize = 32;

const AssemblyText = struct {
    buf: [label_max_len]u8 = [_]u8{0} ** label_max_len,
    len: usize = 0,

    fn slice(self: *const AssemblyText) []const u8 {
        return self.buf[0..self.len];
    }
};

fn read32(ex: *Executor, addr: u32) u32 {
    return ex.mem.read32(addr);
}

fn write32(ex: *Executor, addr: u32, val: u32) void {
    ex.mem.write32(addr, val);
}

fn readAssemblyString(ex: *Executor, offset: u32, fallback: []const u8) AssemblyText {
    var result = AssemblyText{};
    const start: usize = @intCast(offset);
    if (start >= ex.mem.data.len) {
        const fallback_len = @min(fallback.len, result.buf.len);
        @memcpy(result.buf[0..fallback_len], fallback[0..fallback_len]);
        result.len = fallback_len;
        return result;
    }

    var i: usize = 0;
    while (i < result.buf.len and start + i < ex.mem.data.len) : (i += 1) {
        const byte = ex.mem.data[start + i];
        if (byte == 0) break;
        result.buf[i] = byte;
    }

    if (i == 0) {
        const fallback_len = @min(fallback.len, result.buf.len);
        @memcpy(result.buf[0..fallback_len], fallback[0..fallback_len]);
        result.len = fallback_len;
        return result;
    }

    result.len = i;
    return result;
}

fn updateScoreTextBuffer(ex: *Executor) void {
    var score_buf: [16]u8 = undefined;
    const score_text = std.fmt.bufPrint(&score_buf, "{d:0>7}", .{read32(ex, state.SCORE)}) catch "0000000";
    const start: usize = @intCast(state.ScoreTextBuffer);
    if (start >= ex.mem.data.len) return;
    const copy_len = @min(score_text.len, ex.mem.data.len - start -| 1);
    if (copy_len > 0) {
        @memcpy(ex.mem.data[start .. start + copy_len], score_text[0..copy_len]);
    }
    if (start + copy_len < ex.mem.data.len) {
        ex.mem.data[start + copy_len] = 0;
    }
}

fn scoreToLines(score: u32) u32 {
    return @min(score / 10, 999);
}

fn scoreToLevel(score: u32) u32 {
    return 1 + @min(score / 80, 98);
}

fn drawBoardCell(col: i32, row: i32, color: u32) void {
    if (col < 0 or col >= state.GRID_WIDTH or row < 0 or row >= state.GRID_HEIGHT) return;

    const board_left: i32 = 36;
    const board_top: i32 = 72;
    const board_cell: i32 = 12;

    scene.rosette_gfx_scene_fill_rect(
        board_left + col * board_cell,
        board_top + row * board_cell,
        board_cell,
        board_cell,
        color,
    );
}

fn getGrid(ex: *Executor, col: i32, row: i32) u8 {
    if (col < 0 or col >= state.GRID_WIDTH or row < 0 or row >= state.GRID_HEIGHT) return 0;
    return ex.mem.data[state.GRID + @as(u32, @intCast(row * state.GRID_WIDTH + col))];
}

fn setGrid(ex: *Executor, col: i32, row: i32, val: u8) void {
    if (col < 0 or col >= state.GRID_WIDTH or row < 0 or row >= state.GRID_HEIGHT) return;
    ex.mem.data[state.GRID + @as(u32, @intCast(row * state.GRID_WIDTH + col))] = val;
}

fn isValidSpace(ex: *Executor, col: i32, row: i32) bool {
    if (col < 0 or col >= state.GRID_WIDTH) return false;
    if (row < 0 or row >= state.GRID_HEIGHT) return false;
    return getGrid(ex, col, row) == 0;
}

fn copyActiveToPredict(ex: *Executor) void {
    var i: u32 = 0;
    while (i < 8) : (i += 1) ex.mem.data[state.PREDICT + i] = ex.mem.data[state.ACTIVE + i];
}

fn checkPredict(ex: *Executor) bool {
    var i: u32 = 0;
    while (i < 8) : (i += 2) {
        const col = @as(i32, @intCast(ex.mem.data[state.PREDICT + i]));
        const row = @as(i32, @intCast(ex.mem.data[state.PREDICT + i + 1]));
        if (!isValidSpace(ex, col, row)) return false;
    }
    return true;
}

fn leftPredict(ex: *Executor) bool {
    copyActiveToPredict(ex);
    for ([4]u32{ 0, 2, 4, 6 }) |off| ex.mem.data[state.PREDICT + off] -|= 1;
    return checkPredict(ex);
}

fn downPredict(ex: *Executor) bool {
    copyActiveToPredict(ex);
    for ([4]u32{ 1, 3, 5, 7 }) |off| ex.mem.data[state.PREDICT + off] +|= 1;
    return checkPredict(ex);
}

fn rightPredict(ex: *Executor) bool {
    copyActiveToPredict(ex);
    for ([4]u32{ 0, 2, 4, 6 }) |off| ex.mem.data[state.PREDICT + off] +|= 1;
    return checkPredict(ex);
}

fn rotatePredict(ex: *Executor) bool {
    const axis_x = @as(i32, @intCast(ex.mem.data[state.AXIS_X]));
    const axis_y = @as(i32, @intCast(ex.mem.data[state.AXIS_Y]));
    var i: u32 = 0;
    while (i < 8) : (i += 2) {
        const px = @as(i32, @intCast(ex.mem.data[state.ACTIVE + i]));
        const py = @as(i32, @intCast(ex.mem.data[state.ACTIVE + i + 1]));
        const dx = px - axis_x;
        const dy = py - axis_y;
        ex.mem.data[state.PREDICT + i] = @as(u8, @intCast(axis_x - dy));
        ex.mem.data[state.PREDICT + i + 1] = @as(u8, @intCast(axis_y + dx));
    }
    return checkPredict(ex);
}

fn setBlock(ex: *Executor) void {
    const color_idx = ex.mem.data[state.ACTIVE_COLOR_INDEX];
    if (color_idx == 0) return;

    var i: u32 = 0;
    while (i < 8) : (i += 2) {
        const col = @as(i32, @intCast(ex.mem.data[state.ACTIVE + i]));
        const row = @as(i32, @intCast(ex.mem.data[state.ACTIVE + i + 1]));
        if (col >= 0 and col < state.GRID_WIDTH and row >= 0 and row < state.GRID_HEIGHT) {
            if (getGrid(ex, col, row) != 0) {
                ex.mem.data[state.GAME_OVER] = 1;
                return;
            }
            setGrid(ex, col, row, color_idx);
        }
    }
    write32(ex, state.SCORE, read32(ex, state.SCORE) + 1);
}

fn checkToClear(ex: *Executor) void {
    var rows_cleared: u32 = 0;
    var row: i32 = state.GRID_HEIGHT - 1;
    while (row >= 1) : (row -= 1) {
        var full = true;
        var col: i32 = 0;
        while (col < state.GRID_WIDTH) : (col += 1) {
            if (getGrid(ex, col, row) == 0) {
                full = false;
                break;
            }
        }
        if (!full) continue;

        rows_cleared += 1;
        var r: i32 = row;
        while (r > 0) : (r -= 1) {
            var c: i32 = 0;
            while (c < state.GRID_WIDTH) : (c += 1) setGrid(ex, c, r, getGrid(ex, c, r - 1));
        }
        var top_col: i32 = 0;
        while (top_col < state.GRID_WIDTH) : (top_col += 1) setGrid(ex, top_col, 0, 0);
        row += 1;
    }

    if (rows_cleared > 0 and rows_cleared <= 4) {
        const line_scores = [_]u32{ 0, 40, 100, 300, 1200 };
        write32(ex, state.SCORE, read32(ex, state.SCORE) + line_scores[rows_cleared]);
    }
}

fn getRandomBlockIndex(ex: *Executor) u8 {
    const counter = read32(ex, 0x00F8);
    const rng = @mod(counter *% 1103515245 +% 12345, 2147483647);
    write32(ex, 0x00F8, rng);
    return @as(u8, @intCast(@mod(rng, 7)));
}

const piece_data = [_]u8{
    4, 2, 5, 2, 6, 2, 7, 2,
    4, 2, 4, 3, 5, 3, 6, 3,
    6, 2, 4, 3, 5, 3, 6, 3,
    4, 2, 4, 3,
    5, 2, 5, 3,
    4, 3, 4, 4, 5, 2, 5, 3,
    4, 3, 5, 2, 5, 3, 6, 3,
    5, 2, 6, 2, 4, 3, 5, 3,
};

fn loadPieceShapes(ex: *Executor) void {
    @memcpy(ex.mem.data[state.Pieces..][0..56], &piece_data);
}

fn newBlock(ex: *Executor) void {
    const prev_next = ex.mem.data[state.NEXT_BLOCK_INDEX];
    ex.mem.data[state.NEXT_BLOCK_INDEX] = getRandomBlockIndex(ex);
    ex.mem.data[state.ACTIVE_COLOR_INDEX] = prev_next + 1;

    const shape_off = @as(u32, prev_next) * 8;
    var i: u32 = 0;
    while (i < 8) : (i += 1) ex.mem.data[state.ACTIVE + i] = ex.mem.data[state.Pieces + shape_off + i];
    for ([4]u32{ 1, 3, 5, 7 }) |off| ex.mem.data[state.ACTIVE + off] -|= 1;
    ex.mem.data[state.AXIS_X] = 5;
    ex.mem.data[state.AXIS_Y] = 2;
}

pub fn renderFrameThunk(ex: *Executor) void {
    gfx.rosette_gfx_begin_frame();
    updateScoreTextBuffer(ex);
    const score = read32(ex, state.SCORE);
    const lines = scoreToLines(score);
    const level = scoreToLevel(score);
    const game_over = ex.mem.data[state.GAME_OVER];
    const active_color = ex.mem.data[state.ACTIVE_COLOR_INDEX];
    const next_idx = ex.mem.data[state.NEXT_BLOCK_INDEX];
    const next_text = readAssemblyString(ex, state.NextText, "Next");
    const score_label_text = readAssemblyString(ex, state.ScoreText, "Score");
    const game_over_text = readAssemblyString(ex, state.GameOverText, "Game Over");
    const score_value_text = readAssemblyString(ex, state.ScoreTextBuffer, "0000000");

    const board_left: i32 = 36;
    const board_top: i32 = 72;
    const board_cell: i32 = 12;
    const border_pad: i32 = 10;
    const board_width_px: i32 = state.GRID_WIDTH * board_cell;
    const board_height_px: i32 = state.GRID_HEIGHT * board_cell;
    const board_outer_x = board_left - border_pad;
    const board_outer_y = board_top - border_pad;
    const board_outer_w = board_width_px + border_pad * 2;
    const board_outer_h = board_height_px + border_pad * 2;
    const panel_left = board_outer_x + board_outer_w + 84;
    const label_box_w: i32 = 84;
    const label_box_h: i32 = 40;
    const score_box_w: i32 = 146;
    const score_box_h: i32 = 42;
    const next_preview_left = panel_left + 20;
    const next_preview_top = board_top + 6;
    const next_preview_cell = 10;
    const canvas_w: i32 = 520;
    const canvas_h: i32 = 400;

    if (!scene.rosette_gfx_scene_is_available()) {
        cli.clearScreen();
        cli.moveCursor(0, 0);
        cli.writeText("Win32 Tetris (CLI)");

        var score_line_buf: [64]u8 = undefined;
        const score_line = std.fmt.bufPrint(&score_line_buf, "Score {d}  Lines {d}  Level {d}", .{ score, lines, level }) catch "Score 0  Lines 0  Level 1";
        cli.moveCursor(0, 1);
        cli.writeText(score_line);

        var border_buf: [state.GRID_WIDTH + 3]u8 = undefined;
        border_buf[0] = '+';
        @memset(border_buf[1 .. state.GRID_WIDTH + 1], '-');
        border_buf[state.GRID_WIDTH + 1] = '+';
        border_buf[state.GRID_WIDTH + 2] = 0;
        cli.moveCursor(0, 2);
        cli.writeText(border_buf[0 .. state.GRID_WIDTH + 2]);

        var row_buf: [state.GRID_WIDTH + 3]u8 = undefined;
        row_buf[0] = '|';
        row_buf[state.GRID_WIDTH + 1] = '|';
        row_buf[state.GRID_WIDTH + 2] = 0;

        var row: i32 = 0;
        while (row < state.GRID_HEIGHT) : (row += 1) {
            var col: i32 = 0;
            while (col < state.GRID_WIDTH) : (col += 1) {
                const cell = getGrid(ex, col, row);
                row_buf[@as(usize, @intCast(col + 1))] = if (cell == 0) '.' else '#';
            }

            if (active_color > 0 and active_color <= 7) {
                var i: u32 = 0;
                while (i < 8) : (i += 2) {
                    const bx = @as(i32, @intCast(ex.mem.data[state.ACTIVE + i]));
                    const by = @as(i32, @intCast(ex.mem.data[state.ACTIVE + i + 1]));
                    if (by == row and bx >= 0 and bx < state.GRID_WIDTH) {
                        row_buf[@as(usize, @intCast(bx + 1))] = '@';
                    }
                }
            }

            cli.moveCursor(0, row + 3);
            cli.writeText(row_buf[0 .. state.GRID_WIDTH + 2]);
        }

        cli.moveCursor(0, state.GRID_HEIGHT + 3);
        cli.writeText(border_buf[0 .. state.GRID_WIDTH + 2]);

        cli.moveCursor(state.GRID_WIDTH + 5, 3);
        cli.writeText(next_text.slice());

        var hud_buf: [64]u8 = undefined;
        const hud_line = std.fmt.bufPrint(&hud_buf, "Lvl {d}  Lines {d}", .{ level, lines }) catch "Lvl 1  Lines 0";
        cli.moveCursor(state.GRID_WIDTH + 5, 5);
        cli.writeText(hud_line);

        cli.moveCursor(state.GRID_WIDTH + 5, 7);
        cli.writeText(score_label_text.slice());
        cli.moveCursor(state.GRID_WIDTH + 5, 8);
        cli.writeText(score_value_text.slice());

        if (game_over != 0) {
            cli.moveCursor(0, state.GRID_HEIGHT + 5);
            cli.writeText(game_over_text.slice());
        }
        return;
    }

    scene.rosette_gfx_scene_fill_rect(0, 0, canvas_w, canvas_h, 0x000000FF);
    scene.rosette_gfx_scene_fill_rect(board_outer_x, board_outer_y, board_outer_w, board_outer_h, 0xA55A00FF);
    scene.rosette_gfx_scene_fill_rect(board_left, board_top, board_width_px, board_height_px, 0x1010D8FF);

    var row: i32 = 0;
    while (row < state.GRID_HEIGHT) : (row += 1) {
        var col: i32 = 0;
        while (col < state.GRID_WIDTH) : (col += 1) {
            const cell = getGrid(ex, col, row);
            if (cell > 0 and cell <= 7) drawBoardCell(col, row, palette.tetris_piece_colors[cell - 1]);
        }
    }

    if (active_color > 0 and active_color <= 7) {
        var i: u32 = 0;
        while (i < 8) : (i += 2) {
            const bx = @as(i32, @intCast(ex.mem.data[state.ACTIVE + i]));
            const by = @as(i32, @intCast(ex.mem.data[state.ACTIVE + i + 1]));
            if (bx >= 0 and bx < state.GRID_WIDTH and by >= 0 and by < state.GRID_HEIGHT) {
                drawBoardCell(bx, by, palette.tetris_piece_colors[active_color - 1]);
            }
        }
    }

    scene.rosette_gfx_scene_fill_rect(panel_left, 0, label_box_w, label_box_h, 0xFFFFFFFF);
    scene.rosette_gfx_scene_draw_text(
        panel_left + 8,
        4,
        0x000000FF,
        0xFFFFFFFF,
        next_text.slice().ptr,
        @intCast(next_text.len),
    );

    if (next_idx < 7) {
        const next_color = palette.tetris_piece_colors[next_idx];
        const shape_off = @as(u32, next_idx) * 8;
        var i: u32 = 0;
        while (i < 8) : (i += 2) {
            const px = @as(i32, @intCast(ex.mem.data[state.Pieces + shape_off + i])) - 4;
            const py = @as(i32, @intCast(ex.mem.data[state.Pieces + shape_off + i + 1])) - 2;
            if (px >= 0 and px < 4 and py >= 0 and py < 4) {
                scene.rosette_gfx_scene_fill_rect(
                    next_preview_left + px * next_preview_cell,
                    next_preview_top + py * next_preview_cell,
                    next_preview_cell,
                    next_preview_cell,
                    next_color,
                );
            }
        }
    }

    const score_label_y = 220;
    const score_value_y = 272;
    scene.rosette_gfx_scene_fill_rect(panel_left, score_label_y, label_box_w, label_box_h, 0xFFFFFFFF);
    scene.rosette_gfx_scene_draw_text(
        panel_left + 8,
        score_label_y + 4,
        0x000000FF,
        0xFFFFFFFF,
        score_label_text.slice().ptr,
        @intCast(score_label_text.len),
    );

    scene.rosette_gfx_scene_fill_rect(panel_left, score_value_y, score_box_w, score_box_h, 0xFFFFFFFF);
    scene.rosette_gfx_scene_draw_text(
        panel_left + 6,
        score_value_y + 3,
        0x000000FF,
        0xFFFFFFFF,
        score_value_text.slice().ptr,
        @intCast(score_value_text.len),
    );

    if (game_over != 0) {
        scene.rosette_gfx_scene_fill_rect(panel_left - 12, 330, 168, 36, 0xFFFFFFFF);
        scene.rosette_gfx_scene_draw_text(
            panel_left - 4,
            332,
            0x000000FF,
            0xFFFFFFFF,
            game_over_text.slice().ptr,
            @intCast(game_over_text.len),
        );
    }

    var hud_buf: [96]u8 = undefined;
    const hud_text = std.fmt.bufPrint(&hud_buf, "Lvl {d}  Lines {d}", .{ level, lines }) catch "Lvl 1  Lines 0";
    scene.rosette_gfx_scene_draw_text(panel_left, 320, palette.COLOR_TEXT, 0x00000000, hud_text.ptr, @intCast(hud_text.len));
}

pub fn readKeyThunk(ex: *Executor) void {
    cli.readKeyToEax(ex);
}

pub fn gameOverThunk(ex: *Executor) void {
    const score = ex.regs.eax;
    cli.clearScreen();
    var buf: [128]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, "Tetris Over! Final Score: {d}\r\n", .{@as(i32, @bitCast(score))}) catch {
        cli.writeText("Game Over!\r\n");
        cli.pauseSeconds(2);
        return;
    };
    cli.writeText(msg);
    cli.pauseSeconds(2);
}

pub fn sleepMsThunk(ex: *Executor) void {
    cli.sleepFromEax(ex);
}

fn updateTick(ex: *Executor) void {
    if (ex.mem.data[state.GAME_OVER] != 0) return;
    const frame_counter = read32(ex, state.TickLo) + 1;
    write32(ex, state.TickLo, frame_counter);
    if (@mod(frame_counter, gravity_interval_frames) != 0) return;
    if (downPredict(ex)) {
        for ([4]u32{ 1, 3, 5, 7 }) |off| ex.mem.data[state.ACTIVE + off] +|= 1;
        ex.mem.data[state.AXIS_Y] +|= 1;
        return;
    }
    setBlock(ex);
    if (ex.mem.data[state.GAME_OVER] != 0) return;
    checkToClear(ex);
    newBlock(ex);
}

extern "C" fn rosette_cli_get_key() c_int;

pub fn processFrameThunk(ex: *Executor) void {
    const key = rosette_cli_get_key();
    if (key >= 0) {
        const k = @as(u8, @intCast(key));
        switch (k) {
            'q' => ex.mem.data[state.GAME_OVER] = 1,
            'a' => moveLeftThunk(ex),
            'd' => moveRightThunk(ex),
            's' => updateTick(ex),
            'w' => rotateThunk(ex),
            ' ' => softDropThunk(ex),
            else => {},
        }
    }

    updateTick(ex);
    renderFrameThunk(ex);
}

pub fn initGameThunk(ex: *Executor) void {
    initializeGame(ex);
}

pub fn moveLeftThunk(ex: *Executor) void {
    if (ex.mem.data[state.GAME_OVER] != 0) return;
    if (!leftPredict(ex)) return;
    for ([4]u32{ 0, 2, 4, 6 }) |off| ex.mem.data[state.ACTIVE + off] -|= 1;
    ex.mem.data[state.AXIS_X] -|= 1;
}

pub fn moveRightThunk(ex: *Executor) void {
    if (ex.mem.data[state.GAME_OVER] != 0) return;
    if (!rightPredict(ex)) return;
    for ([4]u32{ 0, 2, 4, 6 }) |off| ex.mem.data[state.ACTIVE + off] +|= 1;
    ex.mem.data[state.AXIS_X] +|= 1;
}

pub fn rotateThunk(ex: *Executor) void {
    if (ex.mem.data[state.GAME_OVER] != 0) return;
    if (!rotatePredict(ex)) return;
    var i: u32 = 0;
    while (i < 8) : (i += 1) ex.mem.data[state.ACTIVE + i] = ex.mem.data[state.PREDICT + i];
}

pub fn softDropThunk(ex: *Executor) void {
    if (ex.mem.data[state.GAME_OVER] != 0) return;
    while (downPredict(ex)) {
        for ([4]u32{ 1, 3, 5, 7 }) |off| ex.mem.data[state.ACTIVE + off] +|= 1;
        ex.mem.data[state.AXIS_Y] +|= 1;
    }
    setBlock(ex);
    if (ex.mem.data[state.GAME_OVER] != 0) return;
    checkToClear(ex);
    newBlock(ex);
}

fn initializeGame(ex: *Executor) void {
    ex.mem.data[state.GAME_OVER] = 0;
    write32(ex, state.SCORE, 0);
    updateScoreTextBuffer(ex);
    write32(ex, 0x00F8, 12345);
    write32(ex, state.TickLo, 0);
    write32(ex, state.TickHi, 0);

    var i: u32 = 0;
    while (i < 200) : (i += 1) ex.mem.data[state.GRID + i] = 0;

    loadPieceShapes(ex);

    const first_next = getRandomBlockIndex(ex);
    ex.mem.data[state.NEXT_BLOCK_INDEX] = (6 - first_next) % 7;
    newBlock(ex);
}

pub fn registerThunks(tt: *ThunkTable) void {
    tt.set(state.THUNK_READ_KEY, readKeyThunk);
    tt.set(state.THUNK_RENDER, renderFrameThunk);
    tt.set(state.THUNK_GAME_OVER, gameOverThunk);
    tt.set(state.THUNK_SLEEP, sleepMsThunk);
    tt.set(state.THUNK_PROCESS_FRAME, processFrameThunk);
    tt.set(state.THUNK_INIT_GAME, initGameThunk);
    tt.set(state.THUNK_NEW_BLOCK, newBlock);
}
