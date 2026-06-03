const palette = @import("palette.zig");
const fb = @import("framebuffer.zig");
const layout = @import("layout.zig");
const debug = @import("debug.zig");
const scene = @import("scene.zig");
const runtime_abi = @import("runtime_abi_handshake");

var active_piece: i32 = -1;
var grid_ptr: ?[*]u8 = null;
var grid_width: u32 = 0;
var grid_height: u32 = 0;
var gfx_cursor_x: i32 = 0;
var gfx_cursor_y: i32 = 0;
var active_type_offset: u32 = 0;
var frame_count: u64 = 0;

fn blockCanvasReady() bool {
    return fb.rosetta3_gfx_get_width() > 0 and fb.rosetta3_gfx_get_height() > 0;
}

pub fn rosetta3_gfx_set_active_piece(piece_type: i32) callconv(.c) void {
    debug.log(.verbose, "set_active_piece({d})", .{piece_type});
    active_piece = piece_type;
}

pub fn rosetta3_gfx_set_grid_source(ptr: [*]u8, w: u32, h: u32) callconv(.c) void {
    debug.log(.info, "set_grid_source(ptr=0x{x}, w={d}, h={d})", .{
        @intFromPtr(ptr), w, h,
    });
    runtime_abi.graphics.validateGridSource(@intFromPtr(ptr), w, h);
    grid_ptr = ptr;
    grid_width = w;
    grid_height = h;
}

pub fn rosetta3_gfx_clear_grid_source() callconv(.c) void {
    debug.log(.verbose, "clear_grid_source()", .{});
    grid_ptr = null;
    grid_width = 0;
    grid_height = 0;
}

pub fn rosetta3_gfx_set_active_piece_offset(offset: u32) callconv(.c) void {
    debug.log(.info, "set_active_piece_offset(0x{x})", .{offset});
    runtime_abi.graphics.validateActivePieceOffset(offset, grid_width, grid_height);
    active_type_offset = offset;
}

pub fn rosetta3_gfx_begin_frame() callconv(.c) void {
    frame_count += 1;
    debug.log(.spam, "begin_frame #{d}", .{frame_count});
    if (blockCanvasReady()) {
        runtime_abi.graphics.validateCanvas(fb.rosetta3_gfx_get_width(), fb.rosetta3_gfx_get_height());
    }

    if (grid_ptr) |ptr| {
        if (active_type_offset < 1024 * 1024) {
            const raw_byte = ptr[active_type_offset];
            active_piece = @as(i32, @intCast(raw_byte));
            debug.log(.spam, "  active_piece={d} (raw_byte=0x{x}) at offset 0x{x}", .{
                active_piece, raw_byte, active_type_offset,
            });

            if (active_piece >= 0 and active_piece < 7) {
                debug.log(.verbose, "frame #{d}: active piece type={d} '{s}'", .{
                    frame_count, active_piece, switch (active_piece) {
                        0 => "I", 1 => "O", 2 => "T", 3 => "S", 4 => "Z", 5 => "J", 6 => "L",
                        else => "?",
                    },
                });
            }
        } else {
            debug.log(.spam, "  active_type_offset 0x{x} out of range, using -1", .{active_type_offset});
            active_piece = -1;
        }
    } else {
        debug.log(.spam, "  no grid_ptr, active_piece=-1", .{});
        active_piece = -1;
    }
    gfx_cursor_x = 0;
    gfx_cursor_y = 0;
    if (blockCanvasReady()) {
        fb.rosetta3_gfx_clear(palette.COLOR_GRID_BG);
    }
    scene.rosetta3_gfx_scene_clear();
}

fn char_lookup_color(byte: u8, x: i32, y: i32) palette.Color {
    const gs_col = @as(i32, @intCast(layout.GRID_CONSOLE_START_COL));
    const gs_row = @as(i32, @intCast(layout.GRID_CONSOLE_START_ROW));

    if (byte == '.') return palette.COLOR_GRID_BG;
    if (byte == '|' or byte == '+' or byte == '-') return palette.COLOR_BORDER;

    const is_grid = x >= gs_col and
        x < gs_col + @as(i32, @intCast(grid_width)) and
        y >= gs_row and
        y < gs_row + @as(i32, @intCast(grid_height));

    switch (byte) {
        '#' => {
            if (active_piece >= 0 and active_piece < 7) {
                const c = palette.tetris_piece_colors[@as(usize, @intCast(active_piece))];
                debug.log(.spam, "  '#' at ({d},{d}) → active piece color 0x{x}", .{ x, y, c });
                return c;
            }
            if (is_grid) {
                if (grid_ptr) |ptr| {
                    const gx = @as(u32, @intCast(@as(u32, @intCast(x)) - layout.GRID_CONSOLE_START_COL));
                    const gy = @as(u32, @intCast(@as(u32, @intCast(y)) - layout.GRID_CONSOLE_START_ROW));
                    const cell = ptr[gy * grid_width + gx];
                    if (cell > 0 and cell <= 7) {
                        const c = palette.tetris_piece_colors[cell - 1];
                        debug.log(.spam, "  '#' at ({d},{d}) → grid cell[{d},{d}]={d} → color 0x{x}", .{ x, y, gx, gy, cell, c });
                        return c;
                    }
                    debug.log(.spam, "  '#' at ({d},{d}) → grid cell[{d},{d}]={d} (out of range 1-7)", .{ x, y, gx, gy, cell });
                }
            }
            debug.log(.spam, "  '#' at ({d},{d}) → FALLBACK MAGENTA", .{ x, y });
            return 0xFF00FFFF;
        },
        'O' => {
            if (is_grid) {
                if (grid_ptr) |ptr| {
                    const gx = @as(u32, @intCast(@as(u32, @intCast(x)) - layout.GRID_CONSOLE_START_COL));
                    const gy = @as(u32, @intCast(@as(u32, @intCast(y)) - layout.GRID_CONSOLE_START_ROW));
                    const cell = ptr[gy * grid_width + gx];
                    if (cell > 0 and cell <= 7) {
                        const c = palette.tetris_piece_dim_colors[cell - 1];
                        debug.log(.spam, "  'O' at ({d},{d}) → grid cell[{d},{d}]={d} → dim color 0x{x}", .{ x, y, gx, gy, cell, c });
                        return c;
                    }
                    debug.log(.spam, "  'O' at ({d},{d}) → grid cell[{d},{d}]={d} (out of range 1-7)", .{ x, y, gx, gy, cell });
                }
            }
            debug.log(.spam, "  'O' at ({d},{d}) → FALLBACK DARK MAGENTA", .{ x, y });
            return 0x990099FF;
        },
        else => {
            debug.log(.spam, "  byte 0x{x} '{c}' at ({d},{d}) → default TEXT color", .{ byte, byte, x, y });
            return palette.COLOR_TEXT;
        },
    }
}

pub fn rosetta3_gfx_write_byte(byte: u8) callconv(.c) void {
    const x = gfx_cursor_x;
    const y = gfx_cursor_y;
    const gs_col = @as(i32, @intCast(layout.GRID_CONSOLE_START_COL));
    const gs_row = @as(i32, @intCast(layout.GRID_CONSOLE_START_ROW));
    const gfx_w = @as(i32, @intCast(fb.rosetta3_gfx_get_width()));
    const gfx_h = @as(i32, @intCast(fb.rosetta3_gfx_get_height()));

    if (x >= gs_col and x < gs_col + gfx_w and
        y >= gs_row and y < gs_row + gfx_h)
    {
        const bx = @as(u32, @intCast(@as(u32, @intCast(x)) - layout.GRID_CONSOLE_START_COL));
        const by = @as(u32, @intCast(@as(u32, @intCast(y)) - layout.GRID_CONSOLE_START_ROW));
        const color = char_lookup_color(byte, x, y);
        fb.rosetta3_gfx_set_block(bx, by, color);
        debug.log(.spam, "  → block[{d},{d}] = 0x{x}", .{ bx, by, color });
    } else {
        debug.log(.spam, "write_byte byte 0x{x} at ({d},{d}) OUTSIDE grid bounds (cols {d}-{d}, rows {d}-{d})", .{
            byte, x, y, gs_col, gs_col + gfx_w - 1, gs_row, gs_row + gfx_h - 1,
        });
    }

    gfx_cursor_x += 1;
}

pub fn rosetta3_gfx_write_text(text: [*]const u8, len: u32) callconv(.c) void {
    debug.log(.spam, "write_text len={d} at cursor ({d},{d})", .{ len, gfx_cursor_x, gfx_cursor_y });
    if (blockCanvasReady()) {
        runtime_abi.graphics.validateSceneText(fb.rosetta3_gfx_get_width(), fb.rosetta3_gfx_get_height(), gfx_cursor_x, gfx_cursor_y, len);
    }
    var i: u32 = 0;
    while (i < len) : (i += 1) {
        const byte = text[i];
        if (byte == '\n') {
            gfx_cursor_y += 1;
            gfx_cursor_x = 0;
        } else if (byte == '\r') {
            gfx_cursor_x = 0;
        } else {
            rosetta3_gfx_write_byte(byte);
        }
    }
    debug.log(.spam, "  write_text done → cursor now ({d},{d})", .{ gfx_cursor_x, gfx_cursor_y });
}

pub fn rosetta3_gfx_move_cursor(x: i32, y: i32) callconv(.c) void {
    debug.log(.spam, "move_cursor({d},{d})", .{ x, y });
    runtime_abi.graphics.validateCursor(x, y);
    gfx_cursor_x = x;
    gfx_cursor_y = y;
}

comptime {
    @export(&rosetta3_gfx_set_active_piece, .{ .name = "rosetta3_gfx_set_active_piece", .linkage = .strong });
    @export(&rosetta3_gfx_set_grid_source, .{ .name = "rosetta3_gfx_set_grid_source", .linkage = .strong });
    @export(&rosetta3_gfx_clear_grid_source, .{ .name = "rosetta3_gfx_clear_grid_source", .linkage = .strong });
    @export(&rosetta3_gfx_set_active_piece_offset, .{ .name = "rosetta3_gfx_set_active_piece_offset", .linkage = .strong });
    @export(&rosetta3_gfx_begin_frame, .{ .name = "rosetta3_gfx_begin_frame", .linkage = .strong });
    @export(&rosetta3_gfx_write_byte, .{ .name = "rosetta3_gfx_write_byte", .linkage = .strong });
    @export(&rosetta3_gfx_write_text, .{ .name = "rosetta3_gfx_write_text", .linkage = .strong });
    @export(&rosetta3_gfx_move_cursor, .{ .name = "rosetta3_gfx_move_cursor", .linkage = .strong });
}
