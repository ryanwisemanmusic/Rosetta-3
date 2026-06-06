const std = @import("std");
const text = @import("text_mode.zig");
const suite_asm = @import("suite_asm.zig");
const assets = @import("assets.zig");

const View = enum {
    prompt,
    start_screen,
    play_screen,
    game_over,
};

const HorizontalDirection = enum(u1) {
    left = 0,
    right = 1,
};

const target_body_width: i32 = 4;

const TargetActionRuntime = struct {
    initial_lives: i32 = 6,
    player_col: i32 = 40,
    target_col_left: i32 = 78,
    target_col_center: i32 = 79,
    target_col_right: i32 = 80,
    target_row: i32 = 15,
    target_direction: HorizontalDirection = .left,
    projectile_active: bool = false,
    projectile_row: i32 = 0,
    projectile_col: i32 = 0,
    lives: i32 = 6,
    targets_hit: i32 = 0,
    projectiles_missed: i32 = 0,
    frame_counter: u32 = 0,
    rng_state: u64 = 0x866d_2026_5eed,
    game_over: bool = false,

    fn init(bundle: *const assets.AssetBundle) TargetActionRuntime {
        var game = TargetActionRuntime{};
        game.initial_lives = clampI32(scalarAsI32(bundle, "lifes", 6), 1, 9);
        game.lives = game.initial_lives;
        game.player_col = clampI32(scalarAsI32(bundle, "ShooterCol", 40), 0, 79);
        game.target_row = clampI32(scalarAsI32(bundle, "RocketRow", 15), 3, 22);
        game.rng_state ^= @as(u64, @intCast(game.player_col + game.target_row * 131 + game.initial_lives * 8191));
        game.resetTarget();
        return game;
    }

    fn resetForNewGame(self: *TargetActionRuntime) void {
        self.player_col = 40;
        self.projectile_active = false;
        self.projectile_row = 0;
        self.projectile_col = 0;
        self.lives = self.initial_lives;
        self.targets_hit = 0;
        self.projectiles_missed = 0;
        self.frame_counter = 0;
        self.game_over = false;
        self.resetTarget();
    }

    fn movePlayerLeft(self: *TargetActionRuntime) void {
        if (self.player_col > 0) self.player_col -= 1;
    }

    fn movePlayerRight(self: *TargetActionRuntime) void {
        if (self.player_col < 79) self.player_col += 1;
    }

    fn fire(self: *TargetActionRuntime) void {
        if (self.projectile_active or self.game_over) return;
        self.projectile_active = true;
        self.projectile_col = self.player_col;
        self.projectile_row = 23;
    }

    fn tick(self: *TargetActionRuntime) void {
        if (self.game_over) return;

        self.frame_counter +%= 1;
        if (@mod(self.frame_counter, self.targetFrameInterval()) == 0) {
            self.moveTarget();
        }

        if (!self.projectile_active) return;
        self.checkProjectileStatus();
        if (!self.projectile_active) return;
        self.projectile_row -= 1;
        if (self.projectile_row <= 2) self.registerProjectileMiss();
    }

    fn moveTarget(self: *TargetActionRuntime) void {
        switch (self.target_direction) {
            .left => {
                self.target_col_left -= 1;
                self.target_col_right -= 1;
                self.target_col_center -= 1;
                if (self.target_col_left <= 0) self.resetTarget();
            },
            .right => {
                self.target_col_left += 1;
                self.target_col_right += 1;
                self.target_col_center += 1;
                if (self.target_col_right >= 79) self.resetTarget();
            },
        }
    }

    fn checkProjectileStatus(self: *TargetActionRuntime) void {
        if (!self.projectile_active) return;
        if (self.projectile_row != self.target_row + 1 and self.projectile_row != self.target_row) return;

        const start = self.targetBodyStart();
        if (self.projectile_col >= start and self.projectile_col < start + target_body_width) self.registerTargetHit();
    }

    fn registerTargetHit(self: *TargetActionRuntime) void {
        self.targets_hit += 1;
        self.lives += 1;
        self.resetProjectile();
        self.resetTarget();
    }

    fn registerProjectileMiss(self: *TargetActionRuntime) void {
        self.projectiles_missed += 1;
        self.lives -= 1;
        self.resetProjectile();
        if (self.lives <= 0) self.game_over = true;
    }

    fn resetProjectile(self: *TargetActionRuntime) void {
        self.projectile_active = false;
        self.projectile_row = 0;
        self.projectile_col = 0;
    }

    fn resetTarget(self: *TargetActionRuntime) void {
        self.target_direction = if ((self.nextRandom() & 1) == 0) .left else .right;
        self.target_row = 3 + @as(i32, @intCast(@mod(self.nextRandom(), 20)));
        if (self.target_direction == .right) {
            self.target_col_left = 0;
            self.target_col_center = 1;
            self.target_col_right = 2;
        } else {
            self.target_col_left = 77;
            self.target_col_center = 78;
            self.target_col_right = 79;
        }
    }

    fn targetBodyStart(self: *const TargetActionRuntime) i32 {
        return switch (self.target_direction) {
            .left => self.target_col_left - 1,
            .right => self.target_col_left,
        };
    }

    fn targetBodyText(self: *const TargetActionRuntime) []const u8 {
        return switch (self.target_direction) {
            .left => "<<<<",
            .right => ">>>>",
        };
    }

    fn difficultyLabel(self: *const TargetActionRuntime) []const u8 {
        if (self.targets_hit > 10) return "Extreme Mode";
        if (self.targets_hit > 5) return "Hard Mode";
        return "Easy Mode";
    }

    fn targetFrameInterval(self: *const TargetActionRuntime) u32 {
        if (self.targets_hit > 10) return 2;
        if (self.targets_hit > 5) return 3;
        return 4;
    }

    fn nextRandom(self: *TargetActionRuntime) u64 {
        self.rng_state = self.rng_state *% 6364136223846793005 +% 1442695040888963407;
        return self.rng_state >> 32;
    }
};

const DosTextProfile = struct {
    intro_text: []const u8,
    prompt_text: ?[]const u8,
    title_text: ?[]const u8,
    instruction_text: ?[]const u8,
    hud_texts: [8]?[]const u8 = [_]?[]const u8{null} ** 8,
    footer_text: ?[]const u8,
};

const RunnerState = struct {
    allocator: std.mem.Allocator,
    bundle: assets.AssetBundle,
    profile: DosTextProfile,
    plan: DisplayPlan,
    view: View = .start_screen,
    input_buffer: [32]u8 = [_]u8{0} ** 32,
    input_len: usize = 0,
    last_key: ?[]const u8 = null,
    action_runtime: ?TargetActionRuntime = null,

    fn deinit(self: *RunnerState) void {
        self.plan.deinit(self.allocator);
        self.bundle.deinit();
    }
};

const DisplayPhase = enum {
    prompt,
    start_screen,
    play_screen,
};

const GlyphOp = struct {
    row: i32,
    col: i32,
    ch: u8,
};

const DrawOp = union(enum) {
    text_asset: struct {
        row: i32,
        col: i32,
        asset_name: []u8,
    },
    literal_text: struct {
        row: i32,
        col: i32,
        text: []u8,
    },
    glyph: GlyphOp,
    horizontal_fill: struct {
        row: i32,
        start_col: i32,
        count: i32,
        ch: u8,
    },
};

const PhasePlan = struct {
    ops: std.ArrayListUnmanaged(DrawOp) = .empty,

    fn deinit(self: *PhasePlan, allocator: std.mem.Allocator) void {
        for (self.ops.items) |op| {
            switch (op) {
                .text_asset => |entry| allocator.free(entry.asset_name),
                .literal_text => |entry| allocator.free(entry.text),
                else => {},
            }
        }
        self.ops.deinit(allocator);
    }
};

const DisplayPlan = struct {
    width: i32 = 80,
    height: i32 = 25,
    prompt: PhasePlan = .{},
    start_screen: PhasePlan = .{},
    play_screen: PhasePlan = .{},

    fn deinit(self: *DisplayPlan, allocator: std.mem.Allocator) void {
        self.prompt.deinit(allocator);
        self.start_screen.deinit(allocator);
        self.play_screen.deinit(allocator);
    }

    fn phasePtr(self: *DisplayPlan, phase: DisplayPhase) *PhasePlan {
        return switch (phase) {
            .prompt => &self.prompt,
            .start_screen => &self.start_screen,
            .play_screen => &self.play_screen,
        };
    }
};

fn drawCenteredText(top_row: i32, text_block: []const u8, max_width: i32) void {
    var lines = std.mem.splitScalar(u8, text_block, '\n');
    var row = top_row;
    while (lines.next()) |line| : (row += 1) {
        if (line.len == 0) continue;
        const width: i32 = @intCast(line.len);
        const x = @max(0, @divTrunc(max_width - width, 2));
        text.writeAt(x, row, line);
    }
}

fn detectProfile(bundle: *const assets.AssetBundle) DosTextProfile {
    var profile = DosTextProfile{
        .intro_text = selectPrimaryScreen(bundle) orelse "DOS screen text not detected.",
        .prompt_text = selectPrompt(bundle),
        .title_text = selectTitle(bundle),
        .instruction_text = selectInstruction(bundle),
        .footer_text = selectFooter(bundle),
    };

    var hud_index: usize = 0;
    for (bundle.texts) |entry| {
        if (hud_index >= profile.hud_texts.len) break;
        if (entry.text.len == 0) continue;
        if (std.mem.indexOfScalar(u8, entry.text, '\n') != null) continue;
        if (profile.prompt_text != null and std.mem.eql(u8, entry.text, profile.prompt_text.?)) continue;
        if (profile.title_text != null and std.mem.eql(u8, entry.text, profile.title_text.?)) continue;
        if (profile.instruction_text != null and std.mem.eql(u8, entry.text, profile.instruction_text.?)) continue;
        if (entry.text.len > 40) continue;
        profile.hud_texts[hud_index] = entry.text;
        hud_index += 1;
    }

    return profile;
}

fn buildDisplayPlan(allocator: std.mem.Allocator, source: []const u8, bundle: *const assets.AssetBundle) !DisplayPlan {
    var plan = DisplayPlan{};
    detectTextBounds(source, &plan);

    try extractProcedureOps(allocator, source, "StartMenu", &plan, bundle, .prompt, .start_screen);
    try extractProcedureOps(allocator, source, "DrawInterface", &plan, bundle, .play_screen, null);
    try extractMainStartupOps(allocator, source, &plan, bundle);

    return plan;
}

fn detectTextBounds(source: []const u8, plan: *DisplayPlan) void {
    var lines = std.mem.splitScalar(u8, source, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, assets.stripComment(raw_line), " \t\r");
        if (line.len == 0) continue;
        if (std.ascii.indexOfIgnoreCase(line, "mov dl,") != null) {
            if (parseMovImmediate(line, "mov dl,")) |value| {
                if (value >= 40 and value <= 255) plan.width = value;
            }
        } else if (std.ascii.indexOfIgnoreCase(line, "mov dh,") != null) {
            if (parseMovImmediate(line, "mov dh,")) |value| {
                if (value >= 20 and value <= 255) plan.height = value;
            }
        }
    }
}

fn parseMovImmediate(line: []const u8, needle: []const u8) ?i32 {
    const idx = std.ascii.indexOfIgnoreCase(line, needle) orelse return null;
    const rest = std.mem.trim(u8, line[idx + needle.len ..], " \t");
    const token = rest[0 .. std.mem.indexOfAny(u8, rest, " \t;") orelse rest.len];
    return if (parseIntToken(token)) |value| @intCast(value) else null;
}

fn extractProcedureOps(
    allocator: std.mem.Allocator,
    source: []const u8,
    proc_name: []const u8,
    plan: *DisplayPlan,
    bundle: *const assets.AssetBundle,
    primary_phase: DisplayPhase,
    secondary_phase: ?DisplayPhase,
) !void {
    const body = extractProcedureBody(source, proc_name) orelse return;
    var phase = primary_phase;
    var lines = std.mem.splitScalar(u8, body, '\n');
    var current_loop: ?LoopPattern = null;
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, assets.stripComment(raw_line), " \t\r");
        if (line.len == 0) continue;

        if (secondary_phase != null and std.ascii.indexOfIgnoreCase(line, "PrintText 1,1,StartScreen") != null) {
            phase = secondary_phase.?;
        }

        if (tryParseLoopStart(line)) |loop| {
            current_loop = loop;
            continue;
        }
        if (current_loop) |loop| {
            if (tryUpdateLoopPattern(loop, line)) |updated| {
                current_loop = updated;
                continue;
            }
            if (std.ascii.indexOfIgnoreCase(line, "loop ") != null) {
                try appendLoopOp(allocator, plan.phasePtr(phase), loop);
                current_loop = null;
                continue;
            }
        }

        if (tryParsePrintText(line, bundle)) |entry| {
            try plan.phasePtr(phase).ops.append(allocator, .{
                .text_asset = .{
                    .row = entry.row,
                    .col = entry.col,
                    .asset_name = try allocator.dupe(u8, entry.asset_name),
                },
            });
            continue;
        }

        if (tryParsePlayerGlyph(line, bundle)) |glyph| {
            try plan.phasePtr(phase).ops.append(allocator, .{ .glyph = glyph });
            continue;
        }
        if (tryParseProjectileGlyph(line, bundle)) |glyph| {
            try plan.phasePtr(phase).ops.append(allocator, .{ .glyph = glyph });
            continue;
        }
    }
}

fn extractMainStartupOps(
    allocator: std.mem.Allocator,
    source: []const u8,
    plan: *DisplayPlan,
    bundle: *const assets.AssetBundle,
) !void {
    const body = extractProcedureBody(source, "MAIN") orelse return;
    var lines = std.mem.splitScalar(u8, body, '\n');
    var before_main_loop = true;
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, assets.stripComment(raw_line), " \t\r");
        if (line.len == 0) continue;
        if (std.mem.endsWith(u8, line, "MainLoop:")) {
            before_main_loop = false;
        }
        if (!before_main_loop) continue;

        if (tryParsePlayerGlyph(line, bundle)) |glyph| {
            try plan.play_screen.ops.append(allocator, .{ .glyph = glyph });
        }
    }
}

const LoopPattern = struct {
    row: i32,
    start_col: i32,
    count: i32,
    ch: u8,
};

fn tryParseLoopStart(line: []const u8) ?LoopPattern {
    if (std.ascii.indexOfIgnoreCase(line, "mov cx,") == null) return null;
    const count = parseMovImmediate(line, "mov cx,") orelse return null;
    return .{
        .row = -1,
        .start_col = 0,
        .count = count,
        .ch = ' ',
    };
}

fn tryUpdateLoopPattern(loop: LoopPattern, line: []const u8) ?LoopPattern {
    var updated = loop;
    if (std.ascii.indexOfIgnoreCase(line, "Print ") == null) return null;
    const args = lineAfterToken(line, "Print") orelse return null;
    const parts = splitCsv3(args);
    updated.row = @intCast(parseIntToken(parts.a) orelse return null);
    if (std.ascii.eqlIgnoreCase(std.mem.trim(u8, parts.b, " \t"), "al")) {
        updated.start_col = 0;
    } else {
        updated.start_col = @intCast(parseIntToken(std.mem.trim(u8, parts.b, " \t")) orelse 0);
    }
    updated.ch = ' ';
    return updated;
}

fn appendLoopOp(allocator: std.mem.Allocator, phase: *PhasePlan, loop: LoopPattern) !void {
    if (loop.row < 0 or loop.count <= 0) return;
    try phase.ops.append(allocator, .{
        .horizontal_fill = .{
            .row = loop.row,
            .start_col = loop.start_col,
            .count = loop.count,
            .ch = loop.ch,
        },
    });
}

fn tryParsePrintText(line: []const u8, bundle: *const assets.AssetBundle) ?struct { row: i32, col: i32, asset_name: []const u8 } {
    if (std.ascii.indexOfIgnoreCase(line, "PrintText") == null) return null;
    const args = lineAfterToken(line, "PrintText") orelse return null;
    const parts = splitCsv3(args);
    const row = resolveCoord(parts.a, bundle) orelse return null;
    const col = resolveCoord(parts.b, bundle) orelse return null;
    const asset_name = std.mem.trim(u8, parts.c, " \t");
    if (asset_name.len == 0) return null;
    return .{ .row = row, .col = col, .asset_name = asset_name };
}

fn tryParsePlayerGlyph(line: []const u8, bundle: *const assets.AssetBundle) ?GlyphOp {
    if (std.ascii.indexOfIgnoreCase(line, "PrintShooter") == null) return null;
    const args = lineAfterToken(line, "PrintShooter") orelse return null;
    const col = resolveCoord(args, bundle) orelse return null;
    return .{
        .row = 24,
        .col = col,
        .ch = 127,
    };
}

fn tryParseProjectileGlyph(line: []const u8, bundle: *const assets.AssetBundle) ?GlyphOp {
    if (std.ascii.indexOfIgnoreCase(line, "PrintShot") == null) return null;
    const args = lineAfterToken(line, "PrintShot") orelse return null;
    const parts = splitCsv2(args);
    const row = resolveCoord(parts.a, bundle) orelse return null;
    const col = resolveCoord(parts.b, bundle) orelse return null;
    return .{
        .row = row,
        .col = col,
        .ch = 254,
    };
}

fn extractProcedureBody(source: []const u8, proc_name: []const u8) ?[]const u8 {
    const start_marker = tryJoinProcMarker(proc_name, "Proc");
    defer std.heap.page_allocator.free(start_marker);
    const end_marker = tryJoinProcMarker(proc_name, "ENDP");
    defer std.heap.page_allocator.free(end_marker);

    const start_idx = std.ascii.indexOfIgnoreCase(source, start_marker) orelse return null;
    const after_start = source[start_idx + start_marker.len ..];
    const end_rel = std.ascii.indexOfIgnoreCase(after_start, end_marker) orelse return null;
    return after_start[0..end_rel];
}

fn tryJoinProcMarker(proc_name: []const u8, suffix: []const u8) []u8 {
    return std.fmt.allocPrint(std.heap.page_allocator, "{s} {s}", .{ proc_name, suffix }) catch unreachable;
}

fn lineAfterToken(line: []const u8, token: []const u8) ?[]const u8 {
    const idx = std.ascii.indexOfIgnoreCase(line, token) orelse return null;
    return std.mem.trim(u8, line[idx + token.len ..], " \t");
}

fn splitCsv2(args: []const u8) struct { a: []const u8, b: []const u8 } {
    const first = std.mem.indexOfScalar(u8, args, ',') orelse return .{ .a = args, .b = "" };
    return .{
        .a = std.mem.trim(u8, args[0..first], " \t"),
        .b = std.mem.trim(u8, args[first + 1 ..], " \t"),
    };
}

fn splitCsv3(args: []const u8) struct { a: []const u8, b: []const u8, c: []const u8 } {
    const first = std.mem.indexOfScalar(u8, args, ',') orelse return .{ .a = args, .b = "", .c = "" };
    const rest = args[first + 1 ..];
    const second_rel = std.mem.indexOfScalar(u8, rest, ',') orelse return .{
        .a = std.mem.trim(u8, args[0..first], " \t"),
        .b = std.mem.trim(u8, rest, " \t"),
        .c = "",
    };
    return .{
        .a = std.mem.trim(u8, args[0..first], " \t"),
        .b = std.mem.trim(u8, rest[0..second_rel], " \t"),
        .c = std.mem.trim(u8, rest[second_rel + 1 ..], " \t"),
    };
}

fn resolveCoord(token: []const u8, bundle: *const assets.AssetBundle) ?i32 {
    const trimmed = std.mem.trim(u8, token, " \t");
    if (trimmed.len == 0) return null;
    if (parseIntToken(trimmed)) |value| return @intCast(value);
    if (bundle.findScalar(trimmed)) |value| return @intCast(value);
    return null;
}

fn parseIntToken(token: []const u8) ?i64 {
    if (token.len == 0) return null;
    if (token[token.len - 1] == 'h' or token[token.len - 1] == 'H') {
        return std.fmt.parseInt(i64, token[0 .. token.len - 1], 16) catch null;
    }
    return std.fmt.parseInt(i64, token, 10) catch null;
}

fn scalarAsI32(bundle: *const assets.AssetBundle, name: []const u8, fallback: i32) i32 {
    const value = bundle.findScalar(name) orelse return fallback;
    if (value < std.math.minInt(i32) or value > std.math.maxInt(i32)) return fallback;
    return @intCast(value);
}

fn clampI32(value: i32, low: i32, high: i32) i32 {
    return @min(@max(value, low), high);
}

fn renderPhase(state: *RunnerState, phase: DisplayPhase) void {
    renderPhaseFiltered(state, phase, false);
}

fn renderPhaseFiltered(state: *RunnerState, phase: DisplayPhase, skip_glyphs: bool) void {
    const phase_plan = state.plan.phasePtr(phase);
    for (phase_plan.ops.items) |op| {
        switch (op) {
            .text_asset => |entry| {
                const value = state.bundle.findText(entry.asset_name) orelse continue;
                text.writeMultiline(entry.col, entry.row, value);
            },
            .literal_text => |entry| {
                text.writeAt(entry.col, entry.row, entry.text);
            },
            .glyph => |entry| {
                if (skip_glyphs) continue;
                var buf = [1]u8{entry.ch};
                text.writeAt(entry.col, entry.row, buf[0..]);
            },
            .horizontal_fill => |entry| {
                if (entry.count <= 0) continue;
                var line_buf = std.ArrayListUnmanaged(u8).empty;
                defer line_buf.deinit(state.allocator);
                for (0..@intCast(entry.count)) |_| {
                    line_buf.append(state.allocator, entry.ch) catch break;
                }
                text.writeAt(entry.start_col, entry.row, line_buf.items);
            },
        }
    }
}

fn beginTextFrame() void {
    text.rosette_cli_begin_frame();
}

fn endTextFrame() void {
    text.rosette_cli_end_frame();
}

fn selectPrimaryScreen(bundle: *const assets.AssetBundle) ?[]const u8 {
    var best: ?[]const u8 = null;
    var best_score: usize = 0;
    for (bundle.texts) |entry| {
        const score = scoreScreenCandidate(entry.text);
        if (score <= best_score) continue;
        best = entry.text;
        best_score = score;
    }
    return best;
}

fn scoreScreenCandidate(text_block: []const u8) usize {
    if (text_block.len == 0) return 0;
    const lines = countLines(text_block);
    if (lines < 3) return 0;
    return text_block.len + (lines * 20);
}

fn selectPrompt(bundle: *const assets.AssetBundle) ?[]const u8 {
    for (bundle.texts) |entry| {
        if (entry.text.len == 0) continue;
        if (std.mem.indexOfScalar(u8, entry.text, '\n') != null) continue;
        if (std.mem.indexOfScalar(u8, entry.text, ':') != null) return entry.text;
    }
    return null;
}

fn selectTitle(bundle: *const assets.AssetBundle) ?[]const u8 {
    for (bundle.texts) |entry| {
        if (entry.text.len == 0 or entry.text.len > 40) continue;
        if (std.mem.indexOfScalar(u8, entry.text, '\n') != null) continue;
        if (std.mem.indexOf(u8, entry.text, ">>") != null) return entry.text;
    }
    return null;
}

fn selectInstruction(bundle: *const assets.AssetBundle) ?[]const u8 {
    for (bundle.texts) |entry| {
        if (entry.text.len == 0) continue;
        if (std.mem.indexOfScalar(u8, entry.text, '\n') != null) continue;
        if (std.ascii.indexOfIgnoreCase(entry.text, "press ") != null) return entry.text;
    }
    return null;
}

fn selectFooter(bundle: *const assets.AssetBundle) ?[]const u8 {
    for (bundle.texts) |entry| {
        if (entry.text.len == 0) continue;
        if (std.mem.indexOfScalar(u8, entry.text, '\n') != null) continue;
        if (std.mem.indexOf(u8, entry.text, ">>") != null and entry.text.len <= 8) return entry.text;
    }
    return null;
}

fn countLines(text_block: []const u8) usize {
    var lines: usize = 1;
    for (text_block) |ch| {
        if (ch == '\n') lines += 1;
    }
    return lines;
}

fn drawPromptScreen(state: *RunnerState) void {
    beginTextFrame();
    defer endTextFrame();

    text.rosette_cli_clear();
    renderPhase(state, .prompt);
    if (state.plan.prompt.ops.items.len == 0) {
        drawCenteredText(2, state.profile.intro_text, state.plan.width);
        if (state.profile.prompt_text) |prompt| {
            text.writeAt(8, 19, prompt);
        }
    }
    text.writeAt(8, 20, state.input_buffer[0..state.input_len]);
    text.writeAt(8, 22, "Enter = continue, Backspace = edit, Esc = quit");
}

fn drawStartScreen(state: *RunnerState) void {
    beginTextFrame();
    defer endTextFrame();

    text.rosette_cli_clear();
    renderPhase(state, .start_screen);
    if (state.plan.start_screen.ops.items.len == 0) {
        drawCenteredText(1, state.profile.intro_text, state.plan.width);
    }
    text.writeAt(8, 22, "Enter = start, Esc = quit");
}

fn drawPlayScreen(state: *RunnerState) void {
    beginTextFrame();
    defer endTextFrame();

    text.rosette_cli_clear();
    if (state.action_runtime) |*game| {
        drawTargetActionPlayScreen(state, game);
        return;
    }

    renderPhase(state, .play_screen);

    if (state.plan.play_screen.ops.items.len == 0) {
        if (state.profile.title_text) |title| {
            const x = @max(0, @divTrunc(state.plan.width - @as(i32, @intCast(title.len)), 2));
            text.writeAt(x, 0, title);
        }
    }

    if (state.input_len > 0 and state.plan.play_screen.ops.items.len == 0) {
        text.writeAt(0, 1, "Player: ");
        text.writeAt(8, 1, state.input_buffer[0..state.input_len]);
    }

    if (state.plan.play_screen.ops.items.len == 0) {
        var hud_row: i32 = 1;
        for (state.profile.hud_texts) |maybe_hud| {
            const hud = maybe_hud orelse continue;
            if (hud_row >= 8) break;
            text.writeAt(48, hud_row, hud);
            hud_row += 1;
        }
    }

    if (state.profile.instruction_text) |instruction| {
        text.writeAt(0, 23, instruction);
    }
    if (state.profile.footer_text) |footer| {
        text.writeAt(0, 24, footer);
    }

    if (state.last_key) |key_text| {
        text.writeAt(0, 21, "Last input: ");
        text.writeAt(12, 21, key_text);
    } else {
        text.writeAt(0, 21, "Arrow keys, Space, Enter, and Esc are forwarded through the DOS input layer.");
    }
}

fn drawTargetActionPlayScreen(state: *RunnerState, game: *const TargetActionRuntime) void {
    renderPhaseFiltered(state, .play_screen, true);

    text.writeAt(0, 1, playerName(state));

    var score_buf: [32]u8 = undefined;
    const score_text = std.fmt.bufPrint(&score_buf, "Score: {d:0>2}", .{game.targets_hit}) catch "Score: 00";
    text.writeAt(56, 1, score_text);

    var lives_buf: [16]u8 = undefined;
    const lives_text = std.fmt.bufPrint(&lives_buf, "lifes: {d}", .{@max(game.lives, 0)}) catch "lifes: 0";
    text.writeAt(70, 1, lives_text);
    text.writeAt(70, 0, game.difficultyLabel());

    const target_text = game.targetBodyText();
    const target_col = clampI32(game.targetBodyStart(), 0, state.plan.width - @as(i32, @intCast(target_text.len)));
    text.writeAt(target_col, game.target_row, target_text);

    if (game.projectile_active and game.projectile_row >= 2 and game.projectile_row < state.plan.height) {
        text.writeAt(clampI32(game.projectile_col, 0, state.plan.width - 1), game.projectile_row, "|");
    }

    text.writeAt(clampI32(game.player_col, 0, state.plan.width - 1), 24, "^");
    text.writeAt(0, 2, "Left/Right move  Space fire  Esc game over");
}

fn drawTargetActionGameOver(state: *RunnerState, game: *const TargetActionRuntime) void {
    beginTextFrame();
    defer endTextFrame();

    text.rosette_cli_clear();
    if (state.bundle.findText("GameoverScreen")) |screen| {
        text.writeMultiline(5, 5, screen);
    } else {
        text.writeAt(28, 5, ">> GAMEOVER <<");
    }

    text.writeAt(24, 8, playerName(state));
    var final_buf: [64]u8 = undefined;
    const final_text = std.fmt.bufPrint(&final_buf, "Your final score is: {d}", .{game.targets_hit}) catch "Your final score is: 0";
    text.writeAt(24, 10, final_text);

    var misses_buf: [48]u8 = undefined;
    const misses_text = std.fmt.bufPrint(&misses_buf, "Hits {d}  Misses {d}", .{ game.targets_hit, game.projectiles_missed }) catch "Hits 0  Misses 0";
    text.writeAt(24, 12, misses_text);
    text.writeAt(18, 16, "Enter/Space = restart, Esc/Q = quit");
}

fn playerName(state: *const RunnerState) []const u8 {
    if (state.input_len > 0) return state.input_buffer[0..state.input_len];
    return "Player";
}

fn handlePromptInput(state: *RunnerState, key: i32) bool {
    if (text.isEscapeKey(key)) return false;
    if (text.isEnterKey(key)) {
        state.view = .start_screen;
        return true;
    }
    if (text.isBackspaceKey(key)) {
        if (state.input_len > 0) state.input_len -= 1;
        return true;
    }
    if (text.isPrintableAscii(key) and state.input_len < state.input_buffer.len - 1) {
        state.input_buffer[state.input_len] = @intCast(key);
        state.input_len += 1;
    }
    return true;
}

fn updateLastKey(state: *RunnerState, key: i32) void {
    state.last_key = switch (key) {
        75 => "LEFT",
        77 => "RIGHT",
        72 => "UP",
        80 => "DOWN",
        32 => "SPACE",
        13 => "ENTER",
        27 => "ESC",
        else => blk: {
            if (text.isPrintableAscii(key)) {
                state.input_buffer[state.input_len] = state.input_buffer[state.input_len];
            }
            break :blk "KEY";
        },
    };
}

fn startPlay(state: *RunnerState) void {
    if (state.action_runtime) |*game| game.resetForNewGame();
    state.view = .play_screen;
}

fn handleTargetActionInput(state: *RunnerState, game: *TargetActionRuntime, key: i32) bool {
    if (key < 0) return true;
    updateLastKey(state, key);

    switch (key) {
        75, 'a', 'A' => game.movePlayerLeft(),
        77, 'd', 'D' => game.movePlayerRight(),
        32 => game.fire(),
        27 => {
            game.game_over = true;
            state.view = .game_over;
        },
        'q', 'Q' => return false,
        else => {},
    }
    return true;
}

fn pumpTargetActionInput(state: *RunnerState, game: *TargetActionRuntime) bool {
    while (true) {
        const key = text.rosette_cli_get_key();
        if (key < 0) return true;
        if (!handleTargetActionInput(state, game, key)) return false;
        if (state.view != .play_screen) return true;
    }
}

fn tickTargetActionRuntime(state: *RunnerState) void {
    if (state.action_runtime) |*game| {
        game.tick();
        if (game.game_over) state.view = .game_over;
    }
}

fn run(arg: ?*anyopaque) callconv(.c) void {
    const state: *RunnerState = @ptrCast(@alignCast(arg.?));
    state.view = if (state.profile.prompt_text != null) .prompt else .start_screen;

    while (true) {
        switch (state.view) {
            .prompt => {
                drawPromptScreen(state);
                const key = text.rosette_cli_get_key_blocking();
                if (!handlePromptInput(state, key)) break;
            },
            .start_screen => {
                drawStartScreen(state);
                const key = text.rosette_cli_get_key_blocking();
                if (text.isEscapeKey(key)) break;
                if (text.isEnterKey(key) or text.isSpaceKey(key)) {
                    startPlay(state);
                }
            },
            .play_screen => {
                drawPlayScreen(state);
                if (state.action_runtime) |*game| {
                    if (!pumpTargetActionInput(state, game)) break;
                    if (state.view == .play_screen) tickTargetActionRuntime(state);
                    text.sleepMs(40);
                } else {
                    const key = text.rosette_cli_get_key_blocking();
                    if (text.isEscapeKey(key)) break;
                    updateLastKey(state, key);
                }
            },
            .game_over => {
                if (state.action_runtime) |*game| {
                    drawTargetActionGameOver(state, game);
                    const key = text.rosette_cli_get_key_blocking();
                    if (text.isEscapeKey(key) or key == 'q' or key == 'Q') break;
                    if (text.isEnterKey(key) or text.isSpaceKey(key)) startPlay(state);
                } else {
                    state.view = .start_screen;
                }
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

    const asm_path = try suite_asm.locateAssemblySource(allocator, init.io, if (argv0) |buf| buf else "");
    defer allocator.free(asm_path);

    const source = try std.Io.Dir.cwd().readFileAlloc(init.io, asm_path, allocator, .limited(4 * 1024 * 1024));
    defer allocator.free(source);

    if (!looksLikeDosTextProgram(source)) return error.UnsupportedAssemblyProfile;

    var bundle = try assets.parseDosAsmSource(allocator, source);
    errdefer bundle.deinit();
    const dos_profile = detectProfile(&bundle);
    const plan = try buildDisplayPlan(allocator, source, &bundle);
    const action_runtime = if (looksLikeTargetActionProgram(source)) TargetActionRuntime.init(&bundle) else null;
    var state = RunnerState{
        .allocator = allocator,
        .bundle = bundle,
        .profile = dos_profile,
        .plan = plan,
        .action_runtime = action_runtime,
    };
    defer state.deinit();

    text.rosette_debug_bootstrap_from_argv(if (argv0) |buf| buf.ptr else null);
    const font_cell_w = 9;
    const font_cell_h = 17;
    text.rosette_gfx_scene_set_canvas_size(
        text.rosette_canvas_width_or(@intCast(@max(640, state.plan.width * font_cell_w + 8))),
        text.rosette_canvas_height_or(@intCast(@max(400, state.plan.height * font_cell_h + 8))),
    );
    text.rosette_windowed_run(
        text.rosette_window_width_or(@intCast(state.plan.width)),
        text.rosette_window_height_or(@intCast(state.plan.height)),
        0,
        0,
        text.rosette_window_title_or("DOS Text Mode"),
        run,
        &state,
    );
}

fn looksLikeDosTextProgram(source: []const u8) bool {
    return std.ascii.indexOfIgnoreCase(source, "int 10h") != null or
        std.ascii.indexOfIgnoreCase(source, "int 21h") != null or
        std.ascii.indexOfIgnoreCase(source, "int 16h") != null or
        std.ascii.indexOfIgnoreCase(source, "printtext macro") != null;
}

fn looksLikeTargetActionProgram(source: []const u8) bool {
    return std.ascii.indexOfIgnoreCase(source, "RocketMoveLeft Proc") != null and
        std.ascii.indexOfIgnoreCase(source, "MoveShooterLeft") != null and
        std.ascii.indexOfIgnoreCase(source, "MoveShot  Proc") != null and
        std.ascii.indexOfIgnoreCase(source, "CheckShotStatus") != null;
}
