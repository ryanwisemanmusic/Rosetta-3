const std = @import("std");
const debug = @import("debug.zig");

/// Color stored as 0xRRGGBBAA (C-friendly: >>24=R, >>16=G, >>8=B, >>0=A)
pub const Color = u32;

/// Standard Tetris piece colors. Indexed by piece type 0-6: I, O, T, S, Z, J, L
pub const tetris_piece_colors: [7]Color = .{
    0x00FFFFFF, // I - Cyan       (R=0,   G=255, B=255)
    0xFFFF00FF, // O - Yellow     (R=255, G=255, B=0  )
    0xFF00FFFF, // T - Magenta    (R=255, G=0,   B=255)
    0x00FF00FF, // S - Green      (R=0,   G=255, B=0  )
    0xFF0000FF, // Z - Red        (R=255, G=0,   B=0  )
    0x0000FFFF, // J - Blue       (R=0,   G=0,   B=255)
    0xFF8800FF, // L - Orange     (R=255, G=136, B=0  )
};

/// Dim (locked) variants — roughly 60% brightness
pub const tetris_piece_dim_colors: [7]Color = .{
    0x009999FF, // I - Dark Cyan
    0x999900FF, // O - Dark Yellow
    0x990099FF, // T - Dark Magenta
    0x009900FF, // S - Dark Green
    0x990000FF, // Z - Dark Red
    0x000099FF, // J - Dark Blue
    0x995200FF, // L - Dark Orange
};

pub const COLOR_BORDER: Color = 0x666666FF;
pub const COLOR_BG: Color = 0x1A1A2EFF;
pub const COLOR_GRID_BG: Color = 0x0F0F1AFF;
pub const COLOR_TEXT: Color = 0xFFFFFFFF;
pub const COLOR_TEXT_DIM: Color = 0x888888FF;
pub const COLOR_GHOST: Color = 0x333355FF;
pub const COLOR_NEXT_LABEL: Color = 0xFFAA00FF;

/// Build a Color from RGBA components
pub inline fn rgba(r: u8, g: u8, b: u8, a: u8) Color {
    return @as(Color, @intCast(r)) << 24 |
           @as(Color, @intCast(g)) << 16 |
           @as(Color, @intCast(b)) << 8 |
           @as(Color, @intCast(a));
}

/// C API — get piece color by index
export fn rosetta3_palette_get_piece_color(piece_idx: u32, dim: bool) u32 {
    const c = if (piece_idx >= 7) 0xFF00FFFF else if (dim) tetris_piece_dim_colors[piece_idx] else tetris_piece_colors[piece_idx];
    debug.log(.spam, "palette_get_piece_color(idx={d}, dim={}) = 0x{x}", .{ piece_idx, dim, c });
    return c;
}

/// C API — get UI color by ID (0=border, 1=bg, 2=grid_bg, 3=text, 4=text_dim, 5=ghost, 6=next_label)
export fn rosetta3_palette_get_ui(ui_id: u32) u32 {
    const c = switch (ui_id) {
        0 => COLOR_BORDER,
        1 => COLOR_BG,
        2 => COLOR_GRID_BG,
        3 => COLOR_TEXT,
        4 => COLOR_TEXT_DIM,
        5 => COLOR_GHOST,
        6 => COLOR_NEXT_LABEL,
        else => 0xFF000000,
    };
    debug.log(.spam, "palette_get_ui(id={d}) = 0x{x}", .{ ui_id, c });
    return c;
}
