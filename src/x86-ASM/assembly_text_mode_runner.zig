const std = @import("std");
const detection = @import("assembly_detection.zig");
const assets = @import("assembly_assets.zig");

extern fn usleep(usec: c_uint) c_int;

extern fn rosette_debug_bootstrap_from_argv(argv0: ?[*:0]const u8) void;
extern fn rosette_window_width_or(default_value: c_int) c_int;
extern fn rosette_window_height_or(default_value: c_int) c_int;
extern fn rosette_canvas_width_or(default_value: c_uint) c_uint;
extern fn rosette_canvas_height_or(default_value: c_uint) c_uint;
extern fn rosette_window_title_or(default_value: [*:0]const u8) [*:0]const u8;

extern fn rosette_cli_clear() void;
extern fn rosette_cli_move_cursor(x: c_int, y: c_int) void;
extern fn rosette_cli_write_text(text: [*]const u8, len: c_int) void;
extern fn rosette_cli_get_key() c_int;
extern fn rosette_windowed_run(
    grid_w: c_int,
    grid_h: c_int,
    block_w: c_int,
    block_h: c_int,
    title: [*:0]const u8,
    game_func: ?*const fn (?*anyopaque) callconv(.c) void,
    arg: ?*anyopaque,
) void;
extern fn rosette_gfx_scene_set_canvas_size(width: c_uint, height: c_uint) void;

const View = enum {
    intro,
    menu,
    instructions,
    fame,
    game,
};

const RunnerState = struct {
    allocator: std.mem.Allocator,
    bundle: assets.AssetBundle,
    intro_text: []u8,
    menu_text: []u8,
    instruction_text: []u8,
    fame_text: []u8,
    board: std.ArrayListUnmanaged([]u8) = .empty,
    view: View = .intro,
    player_x: i32 = 1,
    player_y: i32 = 1,
    ghost_x: i32 = 1,
    ghost_y: i32 = 1,
    score: i32 = 0,
    ghost_delay: i32 = 20,

    fn deinit(self: *RunnerState) void {
        for (self.board.items) |line| self.allocator.free(line);
        self.board.deinit(self.allocator);
        self.allocator.free(self.intro_text);
        self.allocator.free(self.menu_text);
        self.allocator.free(self.instruction_text);
        self.allocator.free(self.fame_text);
        self.bundle.deinit();
    }
};

fn sleepMs(ms: u64) void {
    _ = usleep(@intCast(ms * 1000));
}

fn writeAt(x: i32, y: i32, text: []const u8) void {
    rosette_cli_move_cursor(@intCast(x), @intCast(y));
    rosette_cli_write_text(text.ptr, @intCast(text.len));
}

fn writeMultiline(x: i32, y: i32, text: []const u8) void {
    var lines = std.mem.splitScalar(u8, text, '\n');
    var row = y;
    while (lines.next()) |line| : (row += 1) {
        if (line.len == 0) continue;
        writeAt(x, row, line);
    }
}

fn locateAssemblySource(allocator: std.mem.Allocator, io: std.Io, argv0: []const u8) ![]u8 {
    const suite_dir = std.fs.path.dirname(argv0) orelse return error.NoSuiteDirectory;

    const explicit = try readSuiteCfgSourcePath(allocator, io, suite_dir);
    if (explicit) |path| return path;

    const preferred = [_][]const u8{ "Source.asm", "main.asm" };
    for (preferred) |name| {
        const full = try std.fs.path.join(allocator, &.{ suite_dir, name });
        errdefer allocator.free(full);
        std.Io.Dir.accessAbsolute(io, full, .{}) catch {
            allocator.free(full);
            continue;
        };
        return full;
    }
    return error.NoAssemblySourceFound;
}

fn readSuiteCfgSourcePath(allocator: std.mem.Allocator, io: std.Io, suite_dir: []const u8) !?[]u8 {
    const cfg_path = try std.fs.path.join(allocator, &.{ suite_dir, "suite.cfg" });
    defer allocator.free(cfg_path);

    std.Io.Dir.accessAbsolute(io, cfg_path, .{}) catch return null;

    const cwd = std.Io.Dir.cwd();
    const contents = try cwd.readFileAlloc(io, cfg_path, allocator, .limited(64 * 1024));
    defer allocator.free(contents);

    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trim(u8, raw, " \t\r");
        if (!std.mem.startsWith(u8, line, "ASM_SOURCE=")) continue;
        const rel = line["ASM_SOURCE=".len..];
        return try std.fs.path.join(allocator, &.{ suite_dir, rel });
    }
    return null;
}

fn fallbackOwned(allocator: std.mem.Allocator, maybe_text: ?[]u8, fallback: []const u8) ![]u8 {
    if (maybe_text) |text| return text;
    return try allocator.dupe(u8, fallback);
}

fn loadState(allocator: std.mem.Allocator, io: std.Io, argv0: []const u8) !RunnerState {
    const asm_path = try locateAssemblySource(allocator, io, argv0);
    defer allocator.free(asm_path);

    const source = try std.Io.Dir.cwd().readFileAlloc(io, asm_path, allocator, .limited(4 * 1024 * 1024));
    defer allocator.free(source);

    const profile = detection.detectSourceProfile(source);
    if (profile.runtime != .irvine32_text_mode) return error.UnsupportedAssemblyProfile;

    var bundle = try assets.parseSource(allocator, source);
    errdefer bundle.deinit();

    const intro_text = try fallbackOwned(allocator, try bundle.joinTextsWithPrefix(allocator, "intro"), "Assembly intro text not detected.");
    errdefer allocator.free(intro_text);
    const menu_text = try fallbackOwned(allocator, try bundle.joinTextsWithPrefix(allocator, "mainMenu"), "1. Start Game\n2. Instructions\n3. Hall of Fame\nQ. Quit");
    errdefer allocator.free(menu_text);
    const instruction_text = try fallbackOwned(allocator, try bundle.joinTextsWithPrefix(allocator, "instructionMenu"), "Instructions were not extracted from the assembly source.");
    errdefer allocator.free(instruction_text);
    const fame_text = try fallbackOwned(allocator, try bundle.joinTextsWithPrefix(allocator, "hallOfFameMenu"), "Hall of Fame data is not yet surfaced.");
    errdefer allocator.free(fame_text);

    var state = RunnerState{
        .allocator = allocator,
        .bundle = bundle,
        .intro_text = intro_text,
        .menu_text = menu_text,
        .instruction_text = instruction_text,
        .fame_text = fame_text,
        .board = .empty,
    };
    errdefer state.deinit();

    try loadBoardFromAssets(&state);
    initializeActors(&state);
    return state;
}

fn loadBoardFromAssets(state: *RunnerState) !void {
    const level_text = state.bundle.findFirstTextWithPrefix("Level1Row") orelse return;
    var lines = std.mem.splitScalar(u8, level_text, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        try state.board.append(state.allocator, try state.allocator.dupe(u8, line));
    }
}

fn initializeActors(state: *RunnerState) void {
    if (state.bundle.findScalar("initialXPos")) |x| state.player_x = @intCast(x);
    if (state.bundle.findScalar("initialYPos")) |y| state.player_y = @intCast(y);

    if (state.board.items.len == 0) return;
    const fallback_y: i32 = @intCast(@divTrunc(@as(i32, @intCast(state.board.items.len)), 2));
    state.ghost_y = fallback_y;
    const line = state.board.items[@intCast(fallback_y)];
    state.ghost_x = @intCast(@divTrunc(@as(i32, @intCast(line.len)), 2));
    if (!isWalkable(state, state.ghost_x, state.ghost_y)) {
        state.ghost_x = 1;
        state.ghost_y = 1;
    }
}

fn isWalkable(state: *RunnerState, x: i32, y: i32) bool {
    if (y < 0 or y >= state.board.items.len) return false;
    const row = state.board.items[@intCast(y)];
    if (x < 0 or x >= row.len) return false;
    return row[@intCast(x)] != '#';
}

fn tryMove(state: *RunnerState, x: *i32, y: *i32, dx: i32, dy: i32) bool {
    const nx = x.* + dx;
    const ny = y.* + dy;
    if (!isWalkable(state, nx, ny)) return false;
    x.* = nx;
    y.* = ny;
    return true;
}

fn renderBoard(state: *RunnerState) void {
    var row_index: usize = 0;
    while (row_index < state.board.items.len) : (row_index += 1) {
        const row = state.board.items[row_index];
        var line = state.allocator.dupe(u8, row) catch continue;
        defer state.allocator.free(line);
        if (@as(i32, @intCast(row_index)) == state.player_y and state.player_x >= 0 and state.player_x < line.len) {
            line[@intCast(state.player_x)] = 'C';
        }
        if (@as(i32, @intCast(row_index)) == state.ghost_y and state.ghost_x >= 0 and state.ghost_x < line.len) {
            line[@intCast(state.ghost_x)] = 'G';
        }
        writeAt(0, @intCast(row_index + 3), line);
    }
}

fn stepGhost(state: *RunnerState) void {
    if (state.ghost_delay > 0) {
        state.ghost_delay -= 1;
        return;
    }

    var moved = false;
    const dx = state.player_x - state.ghost_x;
    const dy = state.player_y - state.ghost_y;
    if (dx < 0) moved = tryMove(state, &state.ghost_x, &state.ghost_y, -1, 0)
    else if (dx > 0) moved = tryMove(state, &state.ghost_x, &state.ghost_y, 1, 0);

    if (!moved) {
        if (dy < 0) moved = tryMove(state, &state.ghost_x, &state.ghost_y, 0, -1)
        else if (dy > 0) moved = tryMove(state, &state.ghost_x, &state.ghost_y, 0, 1);
    }
}

fn drawIntro(state: *RunnerState) void {
    rosette_cli_clear();
    writeMultiline(0, 0, state.intro_text);
    writeAt(0, 20, "Press any key to continue.");
}

fn drawMenu(state: *RunnerState) void {
    rosette_cli_clear();
    writeMultiline(0, 0, state.menu_text);
    writeAt(0, 18, "Press 1 to start, 2 for instructions, 3 for hall of fame, Q to quit.");
}

fn drawTextScreen(text: []const u8, footer: []const u8) void {
    rosette_cli_clear();
    writeMultiline(0, 0, text);
    writeAt(0, 20, footer);
}

fn runTextAssembly(arg: ?*anyopaque) callconv(.c) void {
    const state: *RunnerState = @ptrCast(@alignCast(arg.?));
    while (true) {
        switch (state.view) {
            .intro => {
                drawIntro(state);
                _ = rosette_cli_get_key();
                state.view = .menu;
            },
            .menu => {
                drawMenu(state);
                const key = rosette_cli_get_key();
                switch (key) {
                    '1', '\r', '\n' => state.view = .game,
                    '2' => state.view = .instructions,
                    '3' => state.view = .fame,
                    'q', 'Q', 27 => return,
                    else => {},
                }
            },
            .instructions => {
                drawTextScreen(state.instruction_text, "Press B or ESC to go back.");
                const key = rosette_cli_get_key();
                if (key == 'b' or key == 'B' or key == 27) state.view = .menu;
            },
            .fame => {
                drawTextScreen(state.fame_text, "Press M, B, or ESC to go back.");
                const key = rosette_cli_get_key();
                if (key == 'm' or key == 'M' or key == 'b' or key == 'B' or key == 27) state.view = .menu;
            },
            .game => {
                const key = rosette_cli_get_key();
                if (key == 'q' or key == 'Q' or key == 'x' or key == 'X') return;
                if (key == 'w' or key == 'W') _ = tryMove(state, &state.player_x, &state.player_y, 0, -1);
                if (key == 's' or key == 'S') _ = tryMove(state, &state.player_x, &state.player_y, 0, 1);
                if (key == 'a' or key == 'A') _ = tryMove(state, &state.player_x, &state.player_y, -1, 0);
                if (key == 'd' or key == 'D') _ = tryMove(state, &state.player_x, &state.player_y, 1, 0);
                if (state.board.items.len > 0) {
                    const row = state.board.items[@intCast(state.player_y)];
                    if (state.player_x >= 0 and state.player_x < row.len and row[@intCast(state.player_x)] == '.') {
                        row[@intCast(state.player_x)] = ' ';
                        state.score += 10;
                    }
                }
                stepGhost(state);
                rosette_cli_clear();
                writeAt(0, 0, "Assembly text-mode profile");
                var hud: [64]u8 = undefined;
                const hud_text = std.fmt.bufPrint(&hud, "Score: {d}  Q/X quit", .{state.score}) catch "Score: 0";
                writeAt(0, 1, hud_text);
                renderBoard(state);
                if (state.player_x == state.ghost_x and state.player_y == state.ghost_y) {
                    writeAt(0, @intCast(state.board.items.len + 5), "Ghost collision. Press Q to leave.");
                }
                sleepMs(80);
            },
        }
    }
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    var args_it = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args_it.deinit();

    const first_arg = args_it.next();
    const argv0 = if (first_arg) |arg| try allocator.dupeZ(u8, arg) else null;
    defer if (argv0) |buf| allocator.free(buf);
    rosette_debug_bootstrap_from_argv(if (argv0) |buf| buf.ptr else null);

    var state = try loadState(allocator, init.io, if (argv0) |buf| buf else "");
    defer state.deinit();

    rosette_gfx_scene_set_canvas_size(
        rosette_canvas_width_or(880),
        rosette_canvas_height_or(520),
    );
    rosette_windowed_run(
        rosette_window_width_or(100),
        rosette_window_height_or(34),
        0,
        0,
        rosette_window_title_or("Assembly Text Mode"),
        runTextAssembly,
        &state,
    );
}
