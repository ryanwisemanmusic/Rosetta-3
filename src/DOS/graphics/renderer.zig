pub extern "C" fn rosette_gfx_set_active_piece(piece_type: i32) void;
pub extern "C" fn rosette_gfx_set_grid_source(ptr: [*]u8, w: u32, h: u32) void;
pub extern "C" fn rosette_gfx_clear_grid_source() void;
pub extern "C" fn rosette_gfx_set_active_piece_offset(offset: u32) void;
pub extern "C" fn rosette_gfx_begin_frame() void;
pub extern "C" fn rosette_gfx_write_byte(byte: u8) void;
pub extern "C" fn rosette_gfx_write_text(text: [*]const u8, len: u32) void;
pub extern "C" fn rosette_gfx_move_cursor(x: i32, y: i32) void;
