const std = @import("std");
const Executor = @import("../instruction_operations.zig").Executor;
const state = @import("stack_state.zig");
const ThunkTable = @import("../execution_engine.zig").ThunkTable;
const cli = @import("../cli_host.zig");

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
    cli.moveCursor(0, 0);

    var buf: [256]u8 = undefined;
    const header = std.fmt.bufPrint(&buf, "Score: {d}  Level: {d}  Lines: {d}\r\n", .{ score, level, lines }) catch "Score info\r\n";
    cli.writeText(header);

    var y: i32 = 0;
    while (y < state.GRID_HEIGHT) : (y += 1) {
        cli.moveCursor(0, y + 1);
        cli.writeText("|");
        var x: i32 = 0;
        while (x < state.GRID_WIDTH) : (x += 1) {
            const cell = get_cell(ex, x, y);
            const is_active = blk: {
                if (active_type < 0 or active_type >= 7) break :blk false;
                const shape = piece_shapes[@as(usize, @intCast(active_type))][@as(usize, @intCast(active_rot))];
                var found = false;
                for (shape) |cell_off| {
                    const cx = active_x + cell_off[0];
                    const cy = active_y + cell_off[1];
                    if (cx == x and cy == y) { found = true; break; }
                }
                break :blk found;
            };
            const ch: u8 = if (is_active) '#' else if (cell != 0) 'O' else '.';
            cli.writeByte(ch);
        }
        cli.writeText("|\r\n");
    }

    cli.writeText("+");
    var bx: i32 = 0;
    while (bx < state.GRID_WIDTH) : (bx += 1) cli.writeText("-");
    cli.writeText("+\r\n");

    if (next_type >= 0 and next_type < 7) {
        cli.writeText("Next: ");
        const shape = piece_shapes[@as(usize, @intCast(next_type))][0];
        var ny: i32 = 0;
        while (ny < 4) : (ny += 1) {
            cli.moveCursor(0, state.GRID_HEIGHT + 3 + ny);
            cli.writeText("      ");
            cli.moveCursor(6, state.GRID_HEIGHT + 3 + ny);
            var nx: i32 = 0;
            while (nx < 4) : (nx += 1) {
                var filled = false;
                for (shape) |cell_off| {
                    if (cell_off[0] == nx and cell_off[1] == ny) { filled = true; break; }
                }
                cli.writeByte(if (filled) '#' else ' ');
            }
            cli.writeText("\r\n");
        }
    }

    cli.moveCursor(0, state.GRID_HEIGHT + 8);
    cli.writeText("A/D: move  W: rotate  S: soft drop  Q: quit\r\n");

    if (game_over != 0) {
        cli.moveCursor(0, state.GRID_HEIGHT + 10);
        cli.writeText("GAME OVER! Press any key to exit...\r\n");
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
