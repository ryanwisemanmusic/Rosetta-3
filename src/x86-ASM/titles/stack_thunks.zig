const std = @import("std");
const Executor = @import("../instruction_operations.zig").Executor;
const state = @import("stack_state.zig");
const ThunkTable = @import("../execution_engine.zig").ThunkTable;
const cli = @import("../cli_host.zig");
const scene = @import("dos_scene");
const palette = @import("dos_palette");
const gfx = @import("dos_renderer");
const dos_platform = @import("dos_platform");

const PieceShapes = [7][4][4][2]i8;

const piece_shapes: PieceShapes = .{
    .{
        .{ .{0,1}, .{1,1}, .{2,1}, .{3,1} },
        .{ .{2,0}, .{2,1}, .{2,2}, .{2,3} },
        .{ .{0,2}, .{1,2}, .{2,2}, .{3,2} },
        .{ .{1,0}, .{1,1}, .{1,2}, .{1,3} },
    },
    .{
        .{ .{1,0}, .{2,0}, .{1,1}, .{2,1} },
        .{ .{1,0}, .{2,0}, .{1,1}, .{2,1} },
        .{ .{1,0}, .{2,0}, .{1,1}, .{2,1} },
        .{ .{1,0}, .{2,0}, .{1,1}, .{2,1} },
    },
    .{
        .{ .{1,0}, .{0,1}, .{1,1}, .{2,1} },
        .{ .{1,0}, .{1,1}, .{2,1}, .{1,2} },
        .{ .{0,1}, .{1,1}, .{2,1}, .{1,2} },
        .{ .{1,0}, .{0,1}, .{1,1}, .{1,2} },
    },
    .{
        .{ .{1,0}, .{2,0}, .{0,1}, .{1,1} },
        .{ .{1,0}, .{1,1}, .{2,1}, .{2,2} },
        .{ .{1,1}, .{2,1}, .{0,2}, .{1,2} },
        .{ .{0,0}, .{0,1}, .{1,1}, .{1,2} },
    },
    .{
        .{ .{0,0}, .{1,0}, .{1,1}, .{2,1} },
        .{ .{2,0}, .{1,1}, .{2,1}, .{1,2} },
        .{ .{0,1}, .{1,1}, .{1,2}, .{2,2} },
        .{ .{1,0}, .{0,1}, .{1,1}, .{0,2} },
    },
    .{
        .{ .{0,0}, .{0,1}, .{1,1}, .{2,1} },
        .{ .{1,0}, .{2,0}, .{1,1}, .{1,2} },
        .{ .{0,1}, .{1,1}, .{2,1}, .{2,2} },
        .{ .{1,0}, .{1,1}, .{0,2}, .{1,2} },
    },
    .{
        .{ .{2,0}, .{0,1}, .{1,1}, .{2,1} },
        .{ .{1,0}, .{1,1}, .{1,2}, .{2,2} },
        .{ .{0,1}, .{1,1}, .{2,1}, .{0,2} },
        .{ .{0,0}, .{1,0}, .{1,1}, .{1,2} },
    },
};

comptime {
    _ = dos_platform.profile;
}

fn get_cell(ex: *Executor, x: i32, y: i32) u8 {
    if (x < 0 or x >= state.GRID_WIDTH or y < 0 or y >= state.GRID_HEIGHT) return 1;
    const idx = @as(u32, @intCast(y * state.GRID_WIDTH + x));
    return ex.mem.data[state.GRID + idx];
}

fn set_cell(ex: *Executor, x: i32, y: i32, val: u8) void {
    if (x < 0 or x >= state.GRID_WIDTH or y < 0 or y >= state.GRID_HEIGHT) return;
    const idx = @as(u32, @intCast(y * state.GRID_WIDTH + x));
    ex.mem.data[state.GRID + idx] = val;
}

fn read32(ex: *Executor, addr: u32) i32 {
    return @as(i32, @bitCast(ex.mem.read32(addr)));
}

fn write32(ex: *Executor, addr: u32, val: i32) void {
    ex.mem.write32(addr, @as(u32, @bitCast(val)));
}

fn readKeyThunk(ex: *Executor) void {
    cli.readKeyToEax(ex);
}

fn renderFrameThunk(ex: *Executor) void {
    const active_type = read32(ex, state.ACTIVE_TYPE);
    const active_x = read32(ex, state.ACTIVE_X);
    const active_y = read32(ex, state.ACTIVE_Y);
    const active_rot = read32(ex, state.ACTIVE_ROT);
    const next_type = read32(ex, state.NEXT_TYPE);
    const score = read32(ex, state.SCORE);
    const lines = read32(ex, state.LINES);
    const level = read32(ex, state.LEVEL);
    const game_over = read32(ex, state.GAME_OVER_FLAG);

    cli.clearScreen();

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

    if (scene.rosetta3_gfx_scene_is_available()) {
        gfx.rosetta3_gfx_begin_frame();
        scene.rosetta3_gfx_scene_fill_rect(0, 0, canvas_w, canvas_h, 0x000000FF);
        scene.rosetta3_gfx_scene_fill_rect(board_outer_x, board_outer_y, board_outer_w, board_outer_h, 0xA55A00FF);
        scene.rosetta3_gfx_scene_fill_rect(board_left, board_top, board_width_px, board_height_px, 0x1010D8FF);

        var y: i32 = 0;
        while (y < state.GRID_HEIGHT) : (y += 1) {
            var x: i32 = 0;
            while (x < state.GRID_WIDTH) : (x += 1) {
                const cell = get_cell(ex, x, y);
                if (cell != 0 and cell <= 7) {
                    scene.rosetta3_gfx_scene_fill_rect(
                        board_left + x * board_cell,
                        board_top + y * board_cell,
                        board_cell,
                        board_cell,
                        palette.tetris_piece_colors[cell - 1],
                    );
                }
            }
        }

        if (active_type >= 0 and active_type < 7) {
            const shape = piece_shapes[@as(usize, @intCast(active_type))][@as(usize, @intCast(active_rot))];
            for (shape) |cell_off| {
                const draw_x = active_x + cell_off[0];
                const draw_y = active_y + cell_off[1];
                if (draw_x >= 0 and draw_x < state.GRID_WIDTH and draw_y >= 0 and draw_y < state.GRID_HEIGHT) {
                    scene.rosetta3_gfx_scene_fill_rect(
                        board_left + draw_x * board_cell,
                        board_top + draw_y * board_cell,
                        board_cell,
                        board_cell,
                        palette.tetris_piece_colors[@as(usize, @intCast(active_type))],
                    );
                }
            }
        }

        scene.rosetta3_gfx_scene_fill_rect(panel_left, 0, label_box_w, label_box_h, 0xFFFFFFFF);
        scene.rosetta3_gfx_scene_draw_text(panel_left + 8, 4, 0x000000FF, 0xFFFFFFFF, "Next".ptr, 4);

        if (next_type >= 0 and next_type < 7) {
            const shape = piece_shapes[@as(usize, @intCast(next_type))][0];
            for (shape) |cell_off| {
                scene.rosetta3_gfx_scene_fill_rect(
                    next_preview_left + cell_off[0] * next_preview_cell,
                    next_preview_top + cell_off[1] * next_preview_cell,
                    next_preview_cell,
                    next_preview_cell,
                    palette.tetris_piece_colors[@as(usize, @intCast(next_type))],
                );
            }
        }

        const score_label_y = 220;
        const score_value_y = 272;
        scene.rosetta3_gfx_scene_fill_rect(panel_left, score_label_y, label_box_w, label_box_h, 0xFFFFFFFF);
        scene.rosetta3_gfx_scene_draw_text(panel_left + 8, score_label_y + 4, 0x000000FF, 0xFFFFFFFF, "Score".ptr, 5);

        scene.rosetta3_gfx_scene_fill_rect(panel_left, score_value_y, score_box_w, score_box_h, 0xFFFFFFFF);
        var score_buf: [16]u8 = undefined;
        const score_text = std.fmt.bufPrint(&score_buf, "{d:0>7}", .{score}) catch "0000000";
        scene.rosetta3_gfx_scene_draw_text(panel_left + 6, score_value_y + 3, 0x000000FF, 0xFFFFFFFF, score_text.ptr, @intCast(score_text.len));

        if (game_over != 0) {
            scene.rosetta3_gfx_scene_fill_rect(panel_left - 12, 330, 168, 36, 0xFFFFFFFF);
            scene.rosetta3_gfx_scene_draw_text(panel_left - 4, 332, 0x000000FF, 0xFFFFFFFF, "Game Over".ptr, 9);
        }

        var hud_buf: [96]u8 = undefined;
        const hud_text = std.fmt.bufPrint(&hud_buf, "Lvl {d}  Lines {d}", .{ level, lines }) catch "Lvl 1  Lines 0";
        scene.rosetta3_gfx_scene_draw_text(panel_left, 320, palette.COLOR_TEXT, 0x00000000, hud_text.ptr, @intCast(hud_text.len));
        return;
    }

    cli.clearScreen();

    cli.moveCursor(0, 0);
    cli.writeText("Tetris x86 (DOS CLI)");

    var score_line_buf: [64]u8 = undefined;
    const score_line = std.fmt.bufPrint(&score_line_buf, "Score {d}  Lines {d}  Level {d}", .{ score, lines, level }) catch "Score 0  Lines 0  Level 1";
    cli.moveCursor(0, 1);
    cli.writeText(score_line);

    var row_buf: [state.GRID_WIDTH + 3]u8 = undefined;
    row_buf[0] = '|';
    row_buf[state.GRID_WIDTH + 1] = '|';
    row_buf[state.GRID_WIDTH + 2] = 0;

    var y: i32 = 0;
    while (y < state.GRID_HEIGHT) : (y += 1) {
        var x: i32 = 0;
        while (x < state.GRID_WIDTH) : (x += 1) {
            const cell = get_cell(ex, x, y);
            row_buf[@as(usize, @intCast(x + 1))] = if (cell == 0) '.' else '#';
        }

        if (active_type >= 0 and active_type < 7) {
            const shape = piece_shapes[@as(usize, @intCast(active_type))][@as(usize, @intCast(active_rot))];
            for (shape) |cell_off| {
                const draw_x = active_x + cell_off[0];
                const draw_y = active_y + cell_off[1];
                if (draw_y == y and draw_x >= 0 and draw_x < state.GRID_WIDTH) {
                    row_buf[@as(usize, @intCast(draw_x + 1))] = '@';
                }
            }
        }

        cli.moveCursor(0, y + 3);
        cli.writeText(row_buf[0 .. state.GRID_WIDTH + 2]);
    }

    var border_buf: [state.GRID_WIDTH + 3]u8 = undefined;
    border_buf[0] = '+';
    @memset(border_buf[1 .. state.GRID_WIDTH + 1], '-');
    border_buf[state.GRID_WIDTH + 1] = '+';
    border_buf[state.GRID_WIDTH + 2] = 0;
    cli.moveCursor(0, 2);
    cli.writeText(border_buf[0 .. state.GRID_WIDTH + 2]);
    cli.moveCursor(0, state.GRID_HEIGHT + 3);
    cli.writeText(border_buf[0 .. state.GRID_WIDTH + 2]);

    var next_buf: [32]u8 = undefined;
    const next_line = std.fmt.bufPrint(&next_buf, "Next {d}", .{next_type}) catch "Next 0";
    cli.moveCursor(state.GRID_WIDTH + 5, 3);
    cli.writeText(next_line);

    if (game_over != 0) {
        cli.moveCursor(0, state.GRID_HEIGHT + 5);
        cli.writeText("Game Over");
    }
}

fn gameOverThunk(ex: *Executor) void {
    const score = ex.regs.eax;
    cli.clearScreen();
    var buf: [128]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, "Tetris Over! Final Score: {d}\r\n", .{@as(i32, @bitCast(score))}) catch "Game Over!\r\n";
    cli.writeText(msg);
    cli.pauseSeconds(2);
}

fn sleepMsThunk(ex: *Executor) void {
    cli.sleepFromEax(ex);
}

fn tryMoveThunk(ex: *Executor) void {
    const dx = @as(i32, @bitCast(ex.regs.eax));
    const dy = @as(i32, @bitCast(ex.regs.ebx));
    const do_rotate = @as(i32, @bitCast(ex.regs.ecx));

    const ptype = read32(ex, state.ACTIVE_TYPE);
    var px = read32(ex, state.ACTIVE_X);
    var py = read32(ex, state.ACTIVE_Y);
    var prot = read32(ex, state.ACTIVE_ROT);

    if (do_rotate != 0) {
        prot = (prot + 1) & 3;
    } else {
        px += dx;
        py += dy;
    }

    if (ptype < 0 or ptype >= 7) { ex.regs.eax = 1; return; }
    const shape = piece_shapes[@as(usize, @intCast(ptype))][@as(usize, @intCast(prot))];
    for (shape) |cell_off| {
        const cx = px + cell_off[0];
        const cy = py + cell_off[1];
        if (cx < 0 or cx >= state.GRID_WIDTH or cy >= state.GRID_HEIGHT) { ex.regs.eax = 1; return; }
        if (cy >= 0 and get_cell(ex, cx, cy) != 0) { ex.regs.eax = 1; return; }
    }

    write32(ex, state.ACTIVE_X, px);
    write32(ex, state.ACTIVE_Y, py);
    write32(ex, state.ACTIVE_ROT, prot);
    ex.regs.eax = 0;
}

fn lockProcessThunk(ex: *Executor) void {
    var timer = read32(ex, state.DROP_TIMER);
    timer = timer +% 1;
    write32(ex, state.DROP_TIMER, timer);

    const level = read32(ex, state.LEVEL);
    const interval = @max(1, 12 - level);
    if (@mod(timer, interval) != 0) {
        ex.regs.eax = 0;
        return;
    }

    const ptype = read32(ex, state.ACTIVE_TYPE);
    const px = read32(ex, state.ACTIVE_X);
    const py = read32(ex, state.ACTIVE_Y);
    const prot = read32(ex, state.ACTIVE_ROT);

    if (ptype >= 0 and ptype < 7) {
        const shape = piece_shapes[@as(usize, @intCast(ptype))][@as(usize, @intCast(prot))];

        var can_drop = true;
        for (shape) |cell_off| {
            const cx = px + cell_off[0];
            const cy = py + cell_off[1] + 1;
            if (cy >= state.GRID_HEIGHT or (cy >= 0 and get_cell(ex, cx, cy) != 0)) {
                can_drop = false;
                break;
            }
        }
        if (can_drop) {
            write32(ex, state.ACTIVE_Y, py + 1);
            ex.regs.eax = 0;
            return;
        }

        for (shape) |cell_off| {
            const cx = px + cell_off[0];
            const cy = py + cell_off[1];
            if (cy >= 0) {
                set_cell(ex, cx, cy, @as(u8, @intCast(ptype + 1)));
            }
        }
    }

    var cleared: i32 = 0;
    var row: i32 = state.GRID_HEIGHT - 1;
    while (row >= 0) : (row -= 1) {
        var full = true;
        var col: i32 = 0;
        while (col < state.GRID_WIDTH) : (col += 1) {
            if (get_cell(ex, col, row) == 0) { full = false; break; }
        }
        if (full) {
            cleared += 1;
            var r: i32 = row;
            while (r > 0) : (r -= 1) {
                var c: i32 = 0;
                while (c < state.GRID_WIDTH) : (c += 1) {
                    const val = get_cell(ex, c, r - 1);
                    set_cell(ex, c, r, val);
                }
            }
            var c: i32 = 0;
            while (c < state.GRID_WIDTH) : (c += 1) set_cell(ex, c, 0, 0);
            row += 1;
        }
    }

    if (cleared > 0) {
        var score = read32(ex, state.SCORE);
        var lines = read32(ex, state.LINES);
        lines += cleared;
        score += cleared * 100 * (1 + read32(ex, state.LEVEL));
        write32(ex, state.LINES, lines);
        write32(ex, state.SCORE, score);
        write32(ex, state.LEVEL, 1 + @divTrunc(lines, 5));
    }

    const next_type = read32(ex, state.NEXT_TYPE);
    var rng: i64 = @as(i64, read32(ex, state.DROP_COUNTER));
    rng = @mod(rng * 1103515245 + 12345, 2147483647);
    write32(ex, state.DROP_COUNTER, @as(i32, @intCast(rng)));
    write32(ex, state.NEXT_TYPE, @as(i32, @intCast(@mod(rng, 7))));
    write32(ex, state.ACTIVE_TYPE, next_type);
    write32(ex, state.ACTIVE_X, state.GRID_WIDTH / 2 - 2);
    write32(ex, state.ACTIVE_Y, 0);
    write32(ex, state.ACTIVE_ROT, 0);

    if (next_type >= 0 and next_type < 7) {
        const shape = piece_shapes[@as(usize, @intCast(next_type))][0];
        for (shape) |cell_off| {
            const cx = @divTrunc(state.GRID_WIDTH, 2) - 2 + cell_off[0];
            const cy = cell_off[1];
            if (cy >= 0 and get_cell(ex, cx, cy) != 0) {
                write32(ex, state.GAME_OVER_FLAG, 1);
                ex.regs.eax = 1;
                return;
            }
        }
    }

    ex.regs.eax = 0;
}

pub fn registerThunks(tt: *ThunkTable) void {
    tt.set(state.THUNK_READ_KEY, readKeyThunk);
    tt.set(state.THUNK_RENDER, renderFrameThunk);
    tt.set(state.THUNK_GAME_OVER, gameOverThunk);
    tt.set(state.THUNK_SLEEP, sleepMsThunk);
    tt.set(state.THUNK_TRY_MOVE, tryMoveThunk);
    tt.set(state.THUNK_LOCK_PROCESS, lockProcessThunk);
}
