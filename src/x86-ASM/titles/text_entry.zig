const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");
const detection = @import("../assembly_detection.zig");
const assets = @import("../assembly_assets.zig");

extern fn usleep(usec: c_uint) c_int;
extern fn rosette_runtime_abi_host_violation(domain: [*:0]const u8, check: [*:0]const u8, detail: [*:0]const u8) void;
extern fn rosette_window_width_or(default_value: c_int) c_int;
extern fn rosette_window_height_or(default_value: c_int) c_int;
extern fn rosette_canvas_width_or(default_value: c_uint) c_uint;
extern fn rosette_canvas_height_or(default_value: c_uint) c_uint;
extern fn rosette_window_title_or(default_value: [*:0]const u8) [*:0]const u8;
extern fn rosette_cli_clear() void;
extern fn rosette_cli_move_cursor(x: c_int, y: c_int) void;
extern fn rosette_cli_write_text(text: [*]const u8, len: c_int) void;
extern fn rosette_cli_get_key() c_int;
extern fn rosette_cli_begin_frame() void;
extern fn rosette_cli_end_frame() void;
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

const max_name_len = 24;
const max_hostile_actors = 3;
const hostile_actor_glyphs = [_]u8{ '#', '&', '@' };

const View = enum {
    intro,
    name_prompt,
    menu,
    instructions,
    records,
    level_start,
    game,
    pause,
    game_over,
    objective_complete,
};

const HostileActor = struct {
    x: i32 = 1,
    y: i32 = 1,
    active: bool = false,
};

const Level = struct {
    rows: std.ArrayListUnmanaged([]u8) = .empty,
    collectible_target: i32 = 0,

    fn deinit(self: *Level, allocator: std.mem.Allocator) void {
        for (self.rows.items) |row| allocator.free(row);
        self.rows.deinit(allocator);
    }

    fn width(self: *const Level) usize {
        return if (self.rows.items.len == 0) 0 else self.rows.items[0].len;
    }

    fn collectibleCount(self: *const Level) i32 {
        var count: i32 = 0;
        for (self.rows.items) |row| {
            for (row) |cell| {
                if (cell == '.') count += 1;
            }
        }
        return count;
    }
};

const RunnerState = struct {
    allocator: std.mem.Allocator,
    bundle: assets.AssetBundle,
    intro_text: []u8,
    menu_text: []u8,
    instruction_text: []u8,
    records_text: []u8,
    pause_text: []u8,
    objective_complete_text: []u8,
    game_over_text: []u8,
    level_start_texts: [3][]u8,
    levels: []Level,
    initial_player_x: i32 = 1,
    initial_player_y: i32 = 1,
    max_level_index: usize = 0,
    user_prompt: []u8,
    user_name: [max_name_len]u8 = [_]u8{0} ** max_name_len,
    user_name_len: usize = 0,
    view: View = .intro,
    current_level: usize = 0,
    player_x: i32 = 1,
    player_y: i32 = 1,
    hostile_actors: [max_hostile_actors]HostileActor = [_]HostileActor{.{}} ** max_hostile_actors,
    hostile_actor_count: usize = 1,
    hostile_actor_tick: usize = 0,
    score: i32 = 0,
    lives: i32 = 3,
    collectibles_collected: i32 = 0,
    collectible_goal: i32 = 0,

    fn deinit(self: *RunnerState) void {
        for (self.levels) |*level| level.deinit(self.allocator);
        self.allocator.free(self.levels);
        self.allocator.free(self.intro_text);
        self.allocator.free(self.menu_text);
        self.allocator.free(self.instruction_text);
        self.allocator.free(self.records_text);
        self.allocator.free(self.pause_text);
        self.allocator.free(self.objective_complete_text);
        self.allocator.free(self.game_over_text);
        self.allocator.free(self.user_prompt);
        for (self.level_start_texts) |text| self.allocator.free(text);
        self.bundle.deinit();
    }

    fn currentLevelPtr(self: *RunnerState) *Level {
        return &self.levels[self.current_level];
    }

    fn currentLevelConst(self: *const RunnerState) *const Level {
        return &self.levels[self.current_level];
    }

    fn userNameSlice(self: *const RunnerState) []const u8 {
        if (self.user_name_len == 0) return "PLAYER";
        return self.user_name[0..self.user_name_len];
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

fn beginTextFrame() void {
    rosette_cli_begin_frame();
}

fn endTextFrame() void {
    rosette_cli_end_frame();
}

fn runnerViolation(comptime check: []const u8, comptime fmt: []const u8, args: anytype) noreturn {
    var detail_buf: [512]u8 = undefined;
    const detail = std.fmt.bufPrintZ(&detail_buf, fmt, args) catch "runner violation";
    const check_z: [:0]const u8 = check ++ "";
    rosette_runtime_abi_host_violation("irvine32-text-title", check_z.ptr, detail.ptr);
    unreachable;
}

fn fallbackOwned(allocator: std.mem.Allocator, maybe_text: ?[]u8, fallback: []const u8) ![]u8 {
    if (maybe_text) |text| return text;
    return try allocator.dupe(u8, fallback);
}

fn cloneAssetText(allocator: std.mem.Allocator, bundle: assets.AssetBundle, name: []const u8, fallback: []const u8) ![]u8 {
    if (bundle.findText(name)) |text| return try allocator.dupe(u8, text);
    return try allocator.dupe(u8, fallback);
}

fn validateRequiredTexts(bundle: assets.AssetBundle) void {
    if (bundle.findFirstTextWithPrefix("intro") == null) {
        runnerViolation("missing_intro", "assembly source did not expose intro text", .{});
    }
    if (bundle.findText("mainMenu1") == null or bundle.findText("mainMenu2") == null) {
        runnerViolation("missing_main_menu", "assembly source did not expose main menu text", .{});
    }
    if (bundle.findText("userNamePrompt") == null) {
        runnerViolation("missing_user_prompt", "assembly source did not expose name prompt text", .{});
    }
}

fn buildLevels(allocator: std.mem.Allocator, bundle: assets.AssetBundle) ![]Level {
    const max_level_scalar = bundle.findScalar("maxLevel") orelse 0;
    if (max_level_scalar < 0 or max_level_scalar > 7) {
        runnerViolation("max_level_range", "maxLevel scalar out of supported range: {d}", .{max_level_scalar});
    }

    const level_count: usize = @intCast(max_level_scalar + 1);
    if (level_count == 0) {
        runnerViolation("level_count_zero", "assembly source reported zero levels", .{});
    }

    const levels = try allocator.alloc(Level, level_count);
    errdefer {
        for (levels) |*level| level.deinit(allocator);
        allocator.free(levels);
    }
    for (levels) |*level| level.* = .{};

    const collectible_targets = bundle.findArray("levelCoins");

    for (levels, 0..) |*level, idx| {
        var prefix_buf: [32]u8 = undefined;
        const prefix = try std.fmt.bufPrint(&prefix_buf, "Level{d}Row", .{idx + 1});
        const level_text = bundle.joinTextsWithPrefix(allocator, prefix) catch null;
        if (level_text == null) {
            runnerViolation("missing_level_rows", "missing level text rows for prefix {s}", .{prefix});
        }
        defer allocator.free(level_text.?);

        var lines = std.mem.splitScalar(u8, level_text.?, '\n');
        while (lines.next()) |line| {
            if (line.len == 0) continue;
            try level.rows.append(allocator, try allocator.dupe(u8, line));
        }

        if (level.rows.items.len == 0) {
            runnerViolation("empty_level_rows", "level {d} parsed with zero rows", .{idx + 1});
        }

        const detected_collectibles = level.collectibleCount();
        level.collectible_target = detected_collectibles;
        if (collectible_targets) |targets| {
            if (idx < targets.len and targets[idx] > 0) {
                level.collectible_target = @intCast(targets[idx]);
            }
        }

        if (level.collectible_target <= 0) {
            runnerViolation("level_collectible_target", "level {d} has invalid collectible target {d}", .{ idx + 1, level.collectible_target });
        }
    }

    return levels;
}

fn ensureBoardShape(state: *const RunnerState) void {
    for (state.levels, 0..) |*level, level_idx| {
        const width = level.width();
        if (width == 0) {
            runnerViolation("board_width_zero", "level {d} has zero width", .{level_idx + 1});
        }
        for (level.rows.items, 0..) |row, row_idx| {
            if (row.len != width) {
                runnerViolation("board_ragged", "level {d} row {d} has width {d}, expected {d}", .{ level_idx + 1, row_idx, row.len, width });
            }
        }
    }
}

fn isWalkable(state: *const RunnerState, x: i32, y: i32) bool {
    const level = state.currentLevelConst();
    if (y < 0 or y >= level.rows.items.len) return false;
    const row = level.rows.items[@intCast(y)];
    if (x < 0 or x >= row.len) return false;
    return row[@intCast(x)] != '#';
}

fn wrapRowPosition(state: *RunnerState, x: *i32, y: i32) void {
    const level = state.currentLevelConst();
    if (y < 0 or y >= level.rows.items.len) return;
    const row = level.rows.items[@intCast(y)];
    if (row.len == 0) return;
    if (x.* < 0) {
        x.* = @intCast(row.len - 1);
    } else if (x.* >= row.len) {
        x.* = 0;
    }
}

fn tryMove(state: *RunnerState, x: *i32, y: *i32, dx: i32, dy: i32) bool {
    var nx = x.* + dx;
    const ny = y.* + dy;
    if (dx != 0 and dy == 0) {
        wrapRowPosition(state, &nx, y.*);
    }
    if (!isWalkable(state, nx, ny)) return false;
    x.* = nx;
    y.* = ny;
    return true;
}

fn setupHostileActorsForLevel(state: *RunnerState) void {
    state.hostile_actor_count = @min(max_hostile_actors, state.current_level + 1);
    const level = state.currentLevelConst();
    const height: i32 = @intCast(level.rows.items.len);
    const width: i32 = @intCast(level.width());
    const candidates = [_][2]i32{
        .{ @divTrunc(width, 2), @divTrunc(height, 2) },
        .{ 2, 2 },
        .{ width - 3, 2 },
        .{ 2, height - 3 },
        .{ width - 3, height - 3 },
    };

    var actor_index: usize = 0;
    while (actor_index < max_hostile_actors) : (actor_index += 1) {
        state.hostile_actors[actor_index] = .{};
        if (actor_index >= state.hostile_actor_count) continue;

        var placed = false;
        for (candidates) |candidate| {
            if (isWalkable(state, candidate[0], candidate[1]) and !(candidate[0] == state.player_x and candidate[1] == state.player_y)) {
                state.hostile_actors[actor_index] = .{
                    .x = candidate[0] + @as(i32, @intCast(actor_index % 2)),
                    .y = candidate[1] + @as(i32, @intCast(actor_index / 2)),
                    .active = true,
                };
                if (!isWalkable(state, state.hostile_actors[actor_index].x, state.hostile_actors[actor_index].y)) {
                    state.hostile_actors[actor_index].x = candidate[0];
                    state.hostile_actors[actor_index].y = candidate[1];
                }
                placed = true;
                break;
            }
        }
        if (!placed) {
            runnerViolation("actor_spawn", "unable to place hostile actor {d} on level {d}", .{ actor_index, state.current_level + 1 });
        }
    }
}

fn startLevel(state: *RunnerState) void {
    state.player_x = state.initial_player_x;
    state.player_y = state.initial_player_y;
    state.collectibles_collected = 0;
    state.hostile_actor_tick = 0;
    state.collectible_goal = state.currentLevelConst().collectible_target;

    const level = state.currentLevelConst();
    if (state.player_x < 0 or state.player_y < 0 or
        state.player_y >= @as(i32, @intCast(level.rows.items.len)) or
        state.player_x >= @as(i32, @intCast(level.width())))
    {
        runnerViolation("player_spawn_bounds", "initial player position ({d},{d}) is outside level {d}", .{ state.player_x, state.player_y, state.current_level + 1 });
    }

    setupHostileActorsForLevel(state);
}

fn renderBoard(state: *const RunnerState) void {
    const level = state.currentLevelConst();
    for (level.rows.items, 0..) |row, row_index| {
        var line = state.allocator.dupe(u8, row) catch continue;
        defer state.allocator.free(line);

        if (@as(i32, @intCast(row_index)) == state.player_y and state.player_x >= 0 and state.player_x < line.len) {
            line[@intCast(state.player_x)] = 'C';
        }

        for (state.hostile_actors, 0..) |actor, actor_index| {
            if (!actor.active) continue;
            if (@as(i32, @intCast(row_index)) == actor.y and actor.x >= 0 and actor.x < line.len) {
                line[@intCast(actor.x)] = hostile_actor_glyphs[actor_index];
            }
        }
        writeAt(0, @intCast(row_index + 4), line);
    }
}

fn drawHud(state: *const RunnerState) void {
    var hud_buf: [192]u8 = undefined;
    const hud = std.fmt.bufPrint(&hud_buf, "Player: {s}  Score: {d}  Lives: {d}  Level: {d}/{d}  Coins: {d}/{d}", .{
        state.userNameSlice(),
        state.score,
        state.lives,
        state.current_level + 1,
        state.max_level_index + 1,
        state.collectibles_collected,
        state.collectible_goal,
    }) catch "TITLE";
    writeAt(0, 0, hud);
    writeAt(0, 1, "W/A/S/D move  P pause  I instructions  X/Q quit");
}

fn drawIntro(state: *const RunnerState) void {
    beginTextFrame();
    defer endTextFrame();
    rosette_cli_clear();
    writeMultiline(0, 0, state.intro_text);
    writeAt(0, 24, "Press any key to continue.");
}

fn drawNamePrompt(state: *const RunnerState) void {
    beginTextFrame();
    defer endTextFrame();
    rosette_cli_clear();
    writeMultiline(0, 0, state.intro_text);
    writeAt(0, 24, state.user_prompt);
    writeAt(@intCast(state.user_prompt.len), 24, state.userNameSlice());
    writeAt(0, 26, "Type your name and press ENTER.");
}

fn drawMenu(state: *const RunnerState) void {
    beginTextFrame();
    defer endTextFrame();
    rosette_cli_clear();
    writeAt(0, 0, state.bundle.findText("mainMenu1") orelse "Welcome, ");
    writeAt(9, 0, state.userNameSlice());
    writeMultiline(0, 2, state.menu_text);
    writeAt(0, 20, "Press 1 to start, 2 for instructions, 3 for hall of records, Q to quit.");
}

fn drawTextScreen(text: []const u8, footer: []const u8) void {
    beginTextFrame();
    defer endTextFrame();
    rosette_cli_clear();
    writeMultiline(0, 0, text);
    writeAt(0, 26, footer);
}

fn drawPause(state: *const RunnerState) void {
    beginTextFrame();
    defer endTextFrame();
    rosette_cli_clear();
    drawHud(state);
    renderBoard(state);
    writeMultiline(0, 31, state.pause_text);
}

fn drawLevelStart(state: *const RunnerState) void {
    beginTextFrame();
    defer endTextFrame();
    rosette_cli_clear();
    if (state.current_level < state.level_start_texts.len) {
        writeMultiline(0, 0, state.level_start_texts[state.current_level]);
    } else {
        var buf: [64]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "Starting level {d}", .{state.current_level + 1}) catch "Starting level";
        writeAt(0, 0, msg);
    }
    writeAt(0, 18, "Press any key to begin.");
}

fn anyCollectiblesRemain(state: *const RunnerState) bool {
    return state.currentLevelConst().collectibleCount() > 0;
}

fn collectCollectibleIfPresent(state: *RunnerState) void {
    const level = state.currentLevelPtr();
    const row = &level.rows.items[@intCast(state.player_y)];
    if (state.player_x < 0 or state.player_x >= row.len) return;
    if (row.*[@intCast(state.player_x)] == '.') {
        row.*[@intCast(state.player_x)] = ' ';
        state.score += 1;
        state.collectibles_collected += 1;
    }
}

fn moveHostileActor(state: *RunnerState, actor_index: usize) void {
    if (actor_index >= state.hostile_actor_count) return;
    var actor = &state.hostile_actors[actor_index];
    if (!actor.active) return;

    const options = [_][2]i32{
        .{ std.math.sign(state.player_x - actor.x), 0 },
        .{ 0, std.math.sign(state.player_y - actor.y) },
        .{ if (actor_index % 2 == 0) 1 else -1, 0 },
        .{ 0, if (actor_index % 2 == 0) -1 else 1 },
    };
    for (options) |step| {
        if (step[0] == 0 and step[1] == 0) continue;
        if (tryMove(state, &actor.x, &actor.y, step[0], step[1])) return;
    }
}

fn stepHostileActors(state: *RunnerState) void {
    state.hostile_actor_tick += 1;
    if (state.hostile_actor_tick % 2 != 0) return;
    var idx: usize = 0;
    while (idx < state.hostile_actor_count) : (idx += 1) moveHostileActor(state, idx);
}

fn checkHostileActorCollision(state: *RunnerState) bool {
    for (state.hostile_actors[0..state.hostile_actor_count]) |actor| {
        if (!actor.active) continue;
        if (actor.x == state.player_x and actor.y == state.player_y) return true;
    }
    return false;
}

fn advanceLevelOrWin(state: *RunnerState) void {
    if (state.current_level >= state.max_level_index) {
        state.view = .objective_complete;
        return;
    }
    state.current_level += 1;
    startLevel(state);
    state.view = .level_start;
}

fn resetAfterLifeLoss(state: *RunnerState) void {
    if (state.lives <= 0) {
        state.view = .game_over;
        return;
    }
    startLevel(state);
}

fn handleNameInput(state: *RunnerState, key: c_int) void {
    switch (key) {
        '\r', '\n' => state.view = .menu,
        8, 127 => {
            if (state.user_name_len > 0) state.user_name_len -= 1;
        },
        else => {
            if (key >= 32 and key < 127 and state.user_name_len < max_name_len) {
                state.user_name[state.user_name_len] = @intCast(key);
                state.user_name_len += 1;
            }
        },
    }
}

fn handleGameInput(state: *RunnerState, key: c_int) void {
    switch (key) {
        'q', 'Q', 'x', 'X' => state.view = .menu,
        'w', 'W' => _ = tryMove(state, &state.player_x, &state.player_y, 0, -1),
        's', 'S' => _ = tryMove(state, &state.player_x, &state.player_y, 0, 1),
        'a', 'A' => _ = tryMove(state, &state.player_x, &state.player_y, -1, 0),
        'd', 'D' => _ = tryMove(state, &state.player_x, &state.player_y, 1, 0),
        'p', 'P' => {
            state.view = .pause;
            return;
        },
        'i', 'I' => {
            state.view = .instructions;
            return;
        },
        else => {},
    }

    collectCollectibleIfPresent(state);
    stepHostileActors(state);

    if (checkHostileActorCollision(state)) {
        state.lives -= 1;
        resetAfterLifeLoss(state);
        return;
    }

    if (state.collectibles_collected >= state.collectible_goal or !anyCollectiblesRemain(state)) {
        advanceLevelOrWin(state);
    }
}

fn runTextAssembly(arg: ?*anyopaque) callconv(.c) void {
    const state: *RunnerState = @ptrCast(@alignCast(arg.?));
    while (true) {
        switch (state.view) {
            .intro => {
                drawIntro(state);
                _ = rosette_cli_get_key();
                state.view = .name_prompt;
            },
            .name_prompt => {
                drawNamePrompt(state);
                handleNameInput(state, rosette_cli_get_key());
            },
            .menu => {
                drawMenu(state);
                switch (rosette_cli_get_key()) {
                    '1', '\r', '\n' => {
                        state.current_level = 0;
                        state.score = 0;
                        state.lives = @intCast(state.bundle.findScalar("lives") orelse 3);
                        startLevel(state);
                        state.view = .level_start;
                    },
                    '2' => state.view = .instructions,
                    '3' => state.view = .records,
                    'q', 'Q', 27 => return,
                    else => {},
                }
            },
            .instructions => {
                drawTextScreen(state.instruction_text, "Press B, M, or ESC to go back.");
                const key = rosette_cli_get_key();
                if (key == 'b' or key == 'B' or key == 'm' or key == 'M' or key == 27) state.view = .menu;
            },
            .records => {
                drawTextScreen(state.records_text, "Press M, B, or ESC to go back.");
                const key = rosette_cli_get_key();
                if (key == 'm' or key == 'M' or key == 'b' or key == 'B' or key == 27) state.view = .menu;
            },
            .level_start => {
                drawLevelStart(state);
                _ = rosette_cli_get_key();
                state.view = .game;
            },
            .game => {
                beginTextFrame();
                rosette_cli_clear();
                drawHud(state);
                renderBoard(state);
                endTextFrame();
                handleGameInput(state, rosette_cli_get_key());
                sleepMs(40);
            },
            .pause => {
                drawPause(state);
                const key = rosette_cli_get_key();
                if (key == 'p' or key == 'P' or key == 27) state.view = .game;
                if (key == 'q' or key == 'Q') state.view = .menu;
            },
            .game_over => {
                drawTextScreen(state.game_over_text, "Press M for menu or Q to quit.");
                const key = rosette_cli_get_key();
                if (key == 'm' or key == 'M') state.view = .menu;
                if (key == 'q' or key == 'Q' or key == 27) return;
            },
            .objective_complete => {
                drawTextScreen(state.objective_complete_text, "Press M for menu or Q to quit.");
                const key = rosette_cli_get_key();
                if (key == 'm' or key == 'M') state.view = .menu;
                if (key == 'q' or key == 'Q' or key == 27) return;
            },
        }
    }
}

fn loadStateFromSource(allocator: std.mem.Allocator, source: []const u8) !RunnerState {
    const profile = detection.detectSourceProfile(source);
    if (profile.runtime != .irvine32_text_mode) {
        runnerViolation("unsupported_profile", "expected irvine32_text_mode profile, got {s}", .{@tagName(profile.runtime)});
    }

    var bundle = try assets.parseSource(allocator, source);
    errdefer bundle.deinit();
    validateRequiredTexts(bundle);

    const intro_text = try fallbackOwned(allocator, try bundle.joinTextsWithPrefix(allocator, "intro"), "Assembly intro text not detected.");
    errdefer allocator.free(intro_text);
    const menu_text = try fallbackOwned(allocator, try bundle.joinTextsWithPrefix(allocator, "mainMenu"), "1. Start\n2. Instructions\n3. Records");
    errdefer allocator.free(menu_text);
    const instruction_text = try fallbackOwned(allocator, try bundle.joinTextsWithPrefix(allocator, "instructionMenu"), "Instructions were not extracted from the assembly source.");
    errdefer allocator.free(instruction_text);
    const records_text = try fallbackOwned(allocator, try bundle.joinTextsWithPrefix(allocator, "hallOfFameMenu"), "Record data is not yet surfaced.");
    errdefer allocator.free(records_text);
    const pause_text = try fallbackOwned(allocator, try bundle.joinTextsWithPrefix(allocator, "pauseMenu"), "Game Paused. Press P to Resume");
    errdefer allocator.free(pause_text);
    const objective_complete_text = try cloneAssetText(allocator, bundle, "gameWon", "Objective complete!");
    errdefer allocator.free(objective_complete_text);
    const game_over_text = try cloneAssetText(allocator, bundle, "gameOver", "Game over!");
    errdefer allocator.free(game_over_text);
    const user_prompt = try cloneAssetText(allocator, bundle, "userNamePrompt", "Enter Your Name: ");
    errdefer allocator.free(user_prompt);

    const level1_start = try cloneAssetText(allocator, bundle, "level1StartMsg", "Level 1");
    errdefer allocator.free(level1_start);
    const level2_start = try cloneAssetText(allocator, bundle, "level2StartMsg", "Level 2");
    errdefer allocator.free(level2_start);
    const level3_start = try cloneAssetText(allocator, bundle, "level3StartMsg", "Level 3");
    errdefer allocator.free(level3_start);
    const level_start_texts = [_][]u8{ level1_start, level2_start, level3_start };

    const levels = try buildLevels(allocator, bundle);
    errdefer {
        for (levels) |*level| level.deinit(allocator);
        allocator.free(levels);
    }

    var state = RunnerState{
        .allocator = allocator,
        .bundle = bundle,
        .intro_text = intro_text,
        .menu_text = menu_text,
        .instruction_text = instruction_text,
        .records_text = records_text,
        .pause_text = pause_text,
        .objective_complete_text = objective_complete_text,
        .game_over_text = game_over_text,
        .level_start_texts = level_start_texts,
        .levels = levels,
        .initial_player_x = @intCast(stateValueOr(bundle.findScalar("initialXPos"), 44)),
        .initial_player_y = @intCast(stateValueOr(bundle.findScalar("initialYPos"), 12)),
        .max_level_index = levels.len - 1,
        .user_prompt = user_prompt,
        .lives = @intCast(stateValueOr(bundle.findScalar("lives"), 3)),
    };

    ensureBoardShape(&state);
    startLevel(&state);
    return state;
}

fn stateValueOr(value: ?i64, fallback: i64) i64 {
    return value orelse fallback;
}

pub export fn rosette_run_pacman_text_runner() void {
    rosette_run_irvine32_text_title();
}

pub export fn rosette_run_irvine32_text_title() void {
    runtime_abi.x86.init();
    defer runtime_abi.x86.deinit();

    const allocator = std.heap.page_allocator;
    const source = @embedFile("PacmanSource.asm");
    var state = loadStateFromSource(allocator, source) catch |err| {
        var buf: [160]u8 = undefined;
        const msg = std.fmt.bufPrintZ(&buf, "text title load failed: {s}", .{@errorName(err)}) catch "text title load failed";
        rosette_runtime_abi_host_violation("irvine32-text-title", "load_state", msg.ptr);
        return;
    };
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
        rosette_window_title_or("Irvine32 Text Title"),
        runTextAssembly,
        &state,
    );
}
