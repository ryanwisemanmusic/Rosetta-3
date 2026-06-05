const common = @import("../common.zig");

pub const PixelAccessKind = enum { read, write };

pub fn init() void {
    common.acquire();
}

pub fn deinit() void {
    common.release();
}

pub fn validateFramebufferInit(w: u32, h: u32) void {
    common.noteValidation();
    if ((w == 0) != (h == 0))
        common.violation("graphics", "framebuffer_zero_pair", "framebuffer dimensions mismatch w={d} h={d}", .{ w, h });
    if (w > 4096 or h > 4096)
        common.violation("graphics", "framebuffer_size", "framebuffer dimensions too large w={d} h={d}", .{ w, h });
}

pub fn validateFramebufferAccess(kind: PixelAccessKind, w: u32, h: u32, x: u32, y: u32, rgba: ?u32) void {
    common.noteValidation();
    if (x >= w or y >= h)
        common.violation("graphics", "framebuffer_bounds", "{s} at ({d},{d}) outside ({d},{d})", .{ @tagName(kind), x, y, w, h });
    if (rgba) |color| {
        if ((color & 0xFF) == 0)
            common.violation("graphics", "alpha_zero", "{s} at ({d},{d}) uses transparent color 0x{x}", .{ @tagName(kind), x, y, color });
    }
}

pub fn validateGridSource(ptr_addr: usize, w: u32, h: u32) void {
    common.noteValidation();
    if (ptr_addr == 0)
        common.violation("graphics", "grid_pointer", "grid source pointer is null", .{});
    if (w == 0 or h == 0)
        common.violation("graphics", "grid_dimensions", "grid dimensions invalid {d}x{d}", .{ w, h });
    if (w > 512 or h > 512)
        common.violation("graphics", "grid_dimensions", "grid dimensions too large {d}x{d}", .{ w, h });
}

pub fn validateActivePieceOffset(offset: u32, grid_w: u32, grid_h: u32) void {
    common.noteValidation();
    const grid_cells = @as(u64, grid_w) * @as(u64, grid_h);
    if (grid_cells == 0) {
        common.violation("graphics", "active_piece_offset", "active piece offset 0x{x} with zero-sized grid", .{offset});
        return;
    }
    if (offset > grid_cells + 4096)
        common.violation("graphics", "active_piece_offset", "active piece offset 0x{x} suspicious for grid cells {d}", .{ offset, grid_cells });
}

pub fn validateSceneRect(kind: []const u8, canvas_w: u32, canvas_h: u32, x: i32, y: i32, w: i32, h: i32) void {
    common.noteValidation();
    if (w <= 0 or h <= 0)
        common.violation("graphics", "scene_rect_size", "{s} invalid rect size {d}x{d} at ({d},{d})", .{ kind, w, h, x, y });
    if (x < 0 or y < 0)
        common.violation("graphics", "scene_rect_origin", "{s} negative origin ({d},{d})", .{ kind, x, y });
    if (x + w > @as(i32, @intCast(canvas_w)) or y + h > @as(i32, @intCast(canvas_h)))
        common.violation("graphics", "scene_rect_bounds", "{s} rect ({d},{d},{d},{d}) outside canvas {d}x{d}", .{ kind, x, y, w, h, canvas_w, canvas_h });
}

pub fn validateSceneText(canvas_w: u32, canvas_h: u32, x: i32, y: i32, len: u32) void {
    common.noteValidation();
    if (len == 0)
        common.violation("graphics", "scene_text_length", "text draw at ({d},{d}) has zero length", .{ x, y });
    if (x < 0 or y < 0 or x > @as(i32, @intCast(canvas_w)) or y > @as(i32, @intCast(canvas_h)))
        common.violation("graphics", "scene_text_bounds", "text draw at ({d},{d}) outside canvas {d}x{d}", .{ x, y, canvas_w, canvas_h });
}

pub fn validateCursor(x: i32, y: i32) void {
    common.noteValidation();
    if (x < 0 or y < 0)
        common.violation("graphics", "cursor_negative", "cursor moved to negative position ({d},{d})", .{ x, y });
}

pub fn validateCanvas(width: u32, height: u32) void {
    common.noteValidation();
    if (width == 0 or height == 0)
        common.violation("graphics", "canvas_zero", "canvas size invalid {d}x{d}", .{ width, height });
    if (width > 8192 or height > 8192)
        common.violation("graphics", "canvas_size", "canvas too large {d}x{d}", .{ width, height });
}
