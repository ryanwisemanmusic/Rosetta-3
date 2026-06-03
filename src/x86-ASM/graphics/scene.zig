const runtime_abi = @import("runtime_abi_handshake");

pub const RectCommand = extern struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,
    color: u32,
};

pub const TextCommand = extern struct {
    x: i32,
    y: i32,
    fg_color: u32,
    bg_color: u32,
    len: u32,
    bytes: [96]u8,
};

const raw_set_canvas_size = @extern(*const fn (width: u32, height: u32) callconv(.c) void, .{
    .name = "rosetta3_gfx_scene_set_canvas_size",
});
const raw_get_canvas_width = @extern(*const fn () callconv(.c) u32, .{
    .name = "rosetta3_gfx_scene_get_canvas_width",
});
const raw_get_canvas_height = @extern(*const fn () callconv(.c) u32, .{
    .name = "rosetta3_gfx_scene_get_canvas_height",
});
const raw_is_available = @extern(*const fn () callconv(.c) bool, .{
    .name = "rosetta3_gfx_scene_is_available",
});
const raw_clear = @extern(*const fn () callconv(.c) void, .{
    .name = "rosetta3_gfx_scene_clear",
});
const raw_fill_rect = @extern(*const fn (x: i32, y: i32, width: i32, height: i32, color: u32) callconv(.c) void, .{
    .name = "rosetta3_gfx_scene_fill_rect",
});
const raw_stroke_rect = @extern(*const fn (x: i32, y: i32, width: i32, height: i32, thickness: i32, color: u32) callconv(.c) void, .{
    .name = "rosetta3_gfx_scene_stroke_rect",
});
const raw_draw_text = @extern(*const fn (x: i32, y: i32, fg_color: u32, bg_color: u32, text_ptr: [*]const u8, len: u32) callconv(.c) void, .{
    .name = "rosetta3_gfx_scene_draw_text",
});
const raw_rect_count = @extern(*const fn () callconv(.c) u32, .{
    .name = "rosetta3_gfx_scene_rect_count",
});
const raw_text_count = @extern(*const fn () callconv(.c) u32, .{
    .name = "rosetta3_gfx_scene_text_count",
});
const raw_get_rect = @extern(*const fn (index: u32, out_rect: *RectCommand) callconv(.c) bool, .{
    .name = "rosetta3_gfx_scene_get_rect",
});
const raw_get_text = @extern(*const fn (index: u32, out_text: *TextCommand) callconv(.c) bool, .{
    .name = "rosetta3_gfx_scene_get_text",
});

pub fn rosetta3_gfx_scene_set_canvas_size(width: u32, height: u32) void {
    runtime_abi.graphics.validateCanvas(width, height);
    raw_set_canvas_size(width, height);
}

pub fn rosetta3_gfx_scene_get_canvas_width() u32 {
    return raw_get_canvas_width();
}

pub fn rosetta3_gfx_scene_get_canvas_height() u32 {
    return raw_get_canvas_height();
}

pub fn rosetta3_gfx_scene_is_available() bool {
    return raw_is_available();
}

fn sceneCanvasReady() bool {
    if (!raw_is_available()) return false;
    return raw_get_canvas_width() > 0 and raw_get_canvas_height() > 0;
}

pub fn rosetta3_gfx_scene_clear() void {
    if (!sceneCanvasReady()) return;
    runtime_abi.graphics.validateCanvas(raw_get_canvas_width(), raw_get_canvas_height());
    raw_clear();
}

pub fn rosetta3_gfx_scene_fill_rect(x: i32, y: i32, width: i32, height: i32, color: u32) void {
    if (!sceneCanvasReady()) return;
    runtime_abi.graphics.validateSceneRect("fill_rect", raw_get_canvas_width(), raw_get_canvas_height(), x, y, width, height);
    runtime_abi.graphics.validateFramebufferAccess(.write, raw_get_canvas_width(), raw_get_canvas_height(), @intCast(@max(x, 0)), @intCast(@max(y, 0)), color);
    raw_fill_rect(x, y, width, height, color);
}

pub fn rosetta3_gfx_scene_stroke_rect(x: i32, y: i32, width: i32, height: i32, thickness: i32, color: u32) void {
    if (!sceneCanvasReady()) return;
    runtime_abi.graphics.validateSceneRect("stroke_rect", raw_get_canvas_width(), raw_get_canvas_height(), x, y, width, height);
    if (thickness <= 0) {
        runtime_abi.common.violation("graphics", "stroke_thickness", "stroke_rect invalid thickness {d} for rect ({d},{d},{d},{d})", .{ thickness, x, y, width, height });
    }
    raw_stroke_rect(x, y, width, height, thickness, color);
}

pub fn rosetta3_gfx_scene_draw_text(x: i32, y: i32, fg_color: u32, bg_color: u32, text_ptr: [*]const u8, len: u32) void {
    if (!sceneCanvasReady()) return;
    runtime_abi.graphics.validateSceneText(raw_get_canvas_width(), raw_get_canvas_height(), x, y, len);
    raw_draw_text(x, y, fg_color, bg_color, text_ptr, len);
}

pub fn rosetta3_gfx_scene_rect_count() u32 {
    return raw_rect_count();
}

pub fn rosetta3_gfx_scene_text_count() u32 {
    return raw_text_count();
}

pub fn rosetta3_gfx_scene_get_rect(index: u32, out_rect: *RectCommand) bool {
    return raw_get_rect(index, out_rect);
}

pub fn rosetta3_gfx_scene_get_text(index: u32, out_text: *TextCommand) bool {
    return raw_get_text(index, out_text);
}
