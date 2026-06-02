const std = @import("std");

pub extern fn usleep(usec: c_uint) c_int;

pub extern fn rosetta3_debug_bootstrap_from_argv(argv0: ?[*:0]const u8) void;
pub extern fn rosetta3_window_width_or(default_value: c_int) c_int;
pub extern fn rosetta3_window_height_or(default_value: c_int) c_int;
pub extern fn rosetta3_canvas_width_or(default_value: c_uint) c_uint;
pub extern fn rosetta3_canvas_height_or(default_value: c_uint) c_uint;
pub extern fn rosetta3_window_title_or(default_value: [*:0]const u8) [*:0]const u8;

pub extern fn rosetta3_cli_clear() void;
pub extern fn rosetta3_cli_move_cursor(x: c_int, y: c_int) void;
pub extern fn rosetta3_cli_write_text(text: [*]const u8, len: c_int) void;
pub extern fn rosetta3_cli_get_key() c_int;

pub extern fn rosetta3_windowed_run(
    grid_w: c_int,
    grid_h: c_int,
    block_w: c_int,
    block_h: c_int,
    title: [*:0]const u8,
    game_func: ?*const fn (?*anyopaque) callconv(.c) void,
    arg: ?*anyopaque,
) void;

pub extern fn rosetta3_gfx_scene_set_canvas_size(width: c_uint, height: c_uint) void;

pub fn sleepMs(ms: u64) void {
    _ = usleep(@intCast(ms * 1000));
}

pub fn rosetta3_cli_get_key_blocking() i32 {
    while (true) {
        const key = rosetta3_cli_get_key();
        if (key >= 0) return key;
        sleepMs(8);
    }
}

pub fn isEnterKey(key: i32) bool {
    return key == 13 or key == 10;
}

pub fn isEscapeKey(key: i32) bool {
    return key == 27;
}

pub fn isBackspaceKey(key: i32) bool {
    return key == 8 or key == 127;
}

pub fn isSpaceKey(key: i32) bool {
    return key == 32;
}

pub fn isPrintableAscii(key: i32) bool {
    return key >= 32 and key <= 126;
}

pub fn writeAt(x: i32, y: i32, text: []const u8) void {
    rosetta3_cli_move_cursor(x, y);
    rosetta3_cli_write_text(text.ptr, @intCast(text.len));
}

pub fn writeMultiline(x: i32, y: i32, text: []const u8) void {
    var lines = std.mem.splitScalar(u8, text, '\n');
    var row = y;
    while (lines.next()) |line| : (row += 1) {
        if (line.len == 0) continue;
        writeAt(x, row, line);
    }
}
