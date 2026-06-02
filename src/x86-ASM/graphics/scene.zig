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

pub extern "C" fn rosetta3_gfx_scene_set_canvas_size(width: u32, height: u32) void;
pub extern "C" fn rosetta3_gfx_scene_get_canvas_width() u32;
pub extern "C" fn rosetta3_gfx_scene_get_canvas_height() u32;
pub extern "C" fn rosetta3_gfx_scene_is_available() bool;
pub extern "C" fn rosetta3_gfx_scene_clear() void;
pub extern "C" fn rosetta3_gfx_scene_fill_rect(x: i32, y: i32, width: i32, height: i32, color: u32) void;
pub extern "C" fn rosetta3_gfx_scene_stroke_rect(x: i32, y: i32, width: i32, height: i32, thickness: i32, color: u32) void;
pub extern "C" fn rosetta3_gfx_scene_draw_text(x: i32, y: i32, fg_color: u32, bg_color: u32, text_ptr: [*]const u8, len: u32) void;
pub extern "C" fn rosetta3_gfx_scene_rect_count() u32;
pub extern "C" fn rosetta3_gfx_scene_text_count() u32;
pub extern "C" fn rosetta3_gfx_scene_get_rect(index: u32, out_rect: *RectCommand) bool;
pub extern "C" fn rosetta3_gfx_scene_get_text(index: u32, out_text: *TextCommand) bool;
