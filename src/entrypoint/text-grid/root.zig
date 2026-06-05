const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");

pub const FONT_CELL_WIDTH: u32 = 9;
pub const FONT_CELL_HEIGHT: u32 = 17;

pub const TextSpan = extern struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,
    cell_x: i32,
    cell_y: i32,
    len: u32,
};

pub fn cellWidth() u32 {
    return FONT_CELL_WIDTH;
}

pub fn cellHeight() u32 {
    return FONT_CELL_HEIGHT;
}

fn snapToCell(coord: i32, comptime cell: u32) i32 {
    const size: i32 = @intCast(cell);
    if (size <= 0) return coord;
    if (coord >= 0) {
        return @divTrunc(coord + @divTrunc(size, 2), size) * size;
    }
    return @divTrunc(coord - @divTrunc(size, 2), size) * size;
}

pub fn snapX(x: i32) i32 {
    return snapToCell(x, FONT_CELL_WIDTH);
}

pub fn snapY(y: i32) i32 {
    return snapToCell(y, FONT_CELL_HEIGHT);
}

pub fn textWidth(len: u32) u32 {
    return len * FONT_CELL_WIDTH;
}

pub fn textHeight() u32 {
    return FONT_CELL_HEIGHT;
}

pub fn normalizeTextSpan(x: i32, y: i32, len: u32) TextSpan {
    runtime_abi.graphics.validateCursor(x, y);
    const snapped_x = snapX(x);
    const snapped_y = snapY(y);
    const width = textWidth(len);
    const height = textHeight();
    return .{
        .x = snapped_x,
        .y = snapped_y,
        .width = @intCast(width),
        .height = @intCast(height),
        .cell_x = @divTrunc(snapped_x, @as(i32, @intCast(FONT_CELL_WIDTH))),
        .cell_y = @divTrunc(snapped_y, @as(i32, @intCast(FONT_CELL_HEIGHT))),
        .len = len,
    };
}

export fn rosette_text_grid_cell_width() u32 {
    return cellWidth();
}

export fn rosette_text_grid_cell_height() u32 {
    return cellHeight();
}

export fn rosette_text_grid_snap_x(x: i32) i32 {
    return snapX(x);
}

export fn rosette_text_grid_snap_y(y: i32) i32 {
    return snapY(y);
}

export fn rosette_text_grid_text_width(len: u32) u32 {
    return textWidth(len);
}

export fn rosette_text_grid_text_height() u32 {
    return textHeight();
}

test "normalize snaps to stable cells" {
    const span = normalizeTextSpan(301, 209, 5);
    try std.testing.expectEqual(@as(i32, 306), span.x);
    try std.testing.expectEqual(@as(i32, 204), span.y);
    try std.testing.expectEqual(@as(i32, 45), span.width);
    try std.testing.expectEqual(@as(i32, 17), span.height);
}
