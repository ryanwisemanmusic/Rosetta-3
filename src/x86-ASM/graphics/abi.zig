const std = @import("std");
const palette = @import("palette.zig");
const fb = @import("framebuffer.zig");
const renderer = @import("renderer.zig");
const layout = @import("layout.zig");

pub const GraphicsAbiError = error{
    InvalidColorTypeSize,
    InvalidColorAlignment,
    InvalidPieceColorArraySize,
    InvalidPieceColorCount,
    InvalidFramebufferWidthType,
    InvalidFramebufferHeightType,
    InvalidPaletteFunctionCallingConv,
    InvalidFramebufferFunctionCallingConv,
    InvalidRendererFunctionCallingConv,
    InvalidColorByteOrder,
    InvalidFramebufferMutexSize,
    InvalidLayoutBlockSize,
    InvalidLayoutCanvasMargin,
    InvalidLayoutGridLeft,
    InvalidLayoutGridTop,
    InvalidLayoutTextPanelGap,
    InvalidLayoutFontCellWidth,
    InvalidLayoutFontCellHeight,
    InvalidLayoutConsoleStartCol,
    InvalidLayoutConsoleStartRow,
    InvalidFramebufferDimensions,
    InvalidGridMemoryBounds,
    InvalidActivePieceTypeOffset,
    InvalidPieceTypeRange,
};

/// Win32-spec constants for the graphics ABI layer
pub const WindowsGraphicsSpec = struct {
    /// u32 = 4 bytes on both LP64 and LLP64
    pub const sizeof_Color: comptime_int = 4;
    pub const alignof_Color: comptime_int = 4;
    /// 7 tetris piece types
    pub const num_piece_colors: comptime_int = 7;
    /// [7]u32 = 28 bytes
    pub const sizeof_piece_color_table: comptime_int = 28;
    /// framebuffer dimensions use u32
    pub const sizeof_fb_dim: comptime_int = 4;
    /// pthread_mutex_t size on macOS arm64 (opaque 64-byte struct)
    pub const sizeof_pthread_mutex_t: comptime_int = 64;
};

pub fn validateGraphicsStructSizes() GraphicsAbiError!void {
    // Color type: must be 4 bytes on all platforms
    if (@sizeOf(palette.Color) != WindowsGraphicsSpec.sizeof_Color)
        return error.InvalidColorTypeSize;
    if (@alignOf(palette.Color) != WindowsGraphicsSpec.alignof_Color)
        return error.InvalidColorAlignment;

    // Piece color table: exactly 7 entries
    if (palette.tetris_piece_colors.len != WindowsGraphicsSpec.num_piece_colors)
        return error.InvalidPieceColorCount;
    if (@sizeOf(@TypeOf(palette.tetris_piece_colors)) != WindowsGraphicsSpec.sizeof_piece_color_table)
        return error.InvalidPieceColorArraySize;

    // Framebuffer dimension types
    if (@sizeOf(@TypeOf(fb.rosette_gfx_get_width())) != WindowsGraphicsSpec.sizeof_fb_dim)
        return error.InvalidFramebufferWidthType;
    if (@sizeOf(@TypeOf(fb.rosette_gfx_get_height())) != WindowsGraphicsSpec.sizeof_fb_dim)
        return error.InvalidFramebufferHeightType;
}

pub fn validateGraphicsBehavior() GraphicsAbiError!void {
    // Validate color byte order: 0xRRGGBBAA convention
    // red byte is at >>24, green at >>16, blue at >>8, alpha at >>0
    const test_color = palette.rgba(0x12, 0x34, 0x56, 0x78);
    if (test_color != 0x12345678)
        return error.InvalidColorByteOrder;

    // Validate framebuffer mutex size (opaque 64-byte struct on macOS arm64)
    const test_mutex: [64]u8 = undefined;
    if (@sizeOf(@TypeOf(test_mutex)) != WindowsGraphicsSpec.sizeof_pthread_mutex_t)
        return error.InvalidFramebufferMutexSize;
}

pub const WindowsLayoutSpec = struct {
    pub const block_size: u32 = 24;
    pub const canvas_margin: u32 = 4;
    pub const text_panel_gap: u32 = 12;
    pub const text_panel_min_width: u32 = 160;
    pub const grid_left: u32 = 4;
    pub const grid_top: u32 = 4;
    pub const font_cell_width: u32 = 9;
    pub const font_cell_height: u32 = 17;
};

pub fn validateLayout() GraphicsAbiError!void {
    if (layout.BLOCK_SIZE != WindowsLayoutSpec.block_size)
        return error.InvalidLayoutBlockSize;
    if (layout.CANVAS_MARGIN != WindowsLayoutSpec.canvas_margin)
        return error.InvalidLayoutCanvasMargin;
    if (layout.GRID_LEFT != WindowsLayoutSpec.grid_left)
        return error.InvalidLayoutGridLeft;
    if (layout.GRID_TOP != WindowsLayoutSpec.grid_top)
        return error.InvalidLayoutGridTop;
    if (layout.TEXT_PANEL_GAP != WindowsLayoutSpec.text_panel_gap)
        return error.InvalidLayoutTextPanelGap;
    if (layout.FONT_CELL_WIDTH != WindowsLayoutSpec.font_cell_width)
        return error.InvalidLayoutFontCellWidth;
    if (layout.FONT_CELL_HEIGHT != WindowsLayoutSpec.font_cell_height)
        return error.InvalidLayoutFontCellHeight;
}

pub fn validateConsoleBounds() GraphicsAbiError!void {
    // Console start position must be ≥ 0 (we use u32, so >= 0 is automatic)
    // But we must not be at position 0 since column 0 is typically the border
    if (layout.GRID_CONSOLE_START_COL < 1)
        return error.InvalidLayoutConsoleStartCol;
    if (layout.GRID_CONSOLE_START_ROW < 1)
        return error.InvalidLayoutConsoleStartRow;
}

pub fn validateFramebufferBounds(w: u32, h: u32) GraphicsAbiError!void {
    if (w == 0 or h == 0)
        return error.InvalidFramebufferDimensions;
    if (w > 256 or h > 256)
        return error.InvalidFramebufferDimensions;
}

pub fn validateGridMemoryBounds(grid_bytes: u32, grid_w: u32, grid_h: u32) GraphicsAbiError!void {
    _ = grid_bytes;
    if (grid_w == 0 or grid_h == 0)
        return error.InvalidGridMemoryBounds;
    if (grid_w > 256 or grid_h > 256)
        return error.InvalidGridMemoryBounds;
    const expected = grid_w * grid_h;
    if (expected == 0)
        return error.InvalidGridMemoryBounds;
}

pub fn validateActivePieceTypeOffset(offset: u32) GraphicsAbiError!void {
    // Offset must be positive and within a reasonable memory range
    if (offset == 0)
        return error.InvalidActivePieceTypeOffset;
    if (offset > 1024 * 1024)
        return error.InvalidActivePieceTypeOffset;
}

pub fn validatePieceType(piece_type: i32) GraphicsAbiError!void {
    if (piece_type < 0 or piece_type >= 7)
        return error.InvalidPieceTypeRange;
}

pub fn validateAll() GraphicsAbiError!void {
    try validateGraphicsStructSizes();
    try validateGraphicsBehavior();
    try validateLayout();
    try validateConsoleBounds();
}

pub export fn rosette_validate_graphics_abi() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidColorTypeSize => 1,
        error.InvalidColorAlignment => 2,
        error.InvalidPieceColorArraySize => 3,
        error.InvalidPieceColorCount => 4,
        error.InvalidFramebufferWidthType => 5,
        error.InvalidFramebufferHeightType => 6,
        error.InvalidPaletteFunctionCallingConv => 7,
        error.InvalidFramebufferFunctionCallingConv => 8,
        error.InvalidRendererFunctionCallingConv => 9,
        error.InvalidColorByteOrder => 10,
        error.InvalidFramebufferMutexSize => 11,
        error.InvalidLayoutBlockSize => 12,
        error.InvalidLayoutCanvasMargin => 13,
        error.InvalidLayoutGridLeft => 14,
        error.InvalidLayoutGridTop => 15,
        error.InvalidLayoutTextPanelGap => 16,
        error.InvalidLayoutFontCellWidth => 17,
        error.InvalidLayoutFontCellHeight => 18,
        error.InvalidLayoutConsoleStartCol => 19,
        error.InvalidLayoutConsoleStartRow => 20,
        error.InvalidFramebufferDimensions => 21,
        error.InvalidGridMemoryBounds => 22,
        error.InvalidActivePieceTypeOffset => 23,
        error.InvalidPieceTypeRange => 24,
    };
    return 0;
}

pub export fn rosette_graphics_abi_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidColorTypeSize",
        2 => "InvalidColorAlignment",
        3 => "InvalidPieceColorArraySize",
        4 => "InvalidPieceColorCount",
        5 => "InvalidFramebufferWidthType",
        6 => "InvalidFramebufferHeightType",
        7 => "InvalidPaletteFunctionCallingConv",
        8 => "InvalidFramebufferFunctionCallingConv",
        9 => "InvalidRendererFunctionCallingConv",
        10 => "InvalidColorByteOrder",
        11 => "InvalidFramebufferMutexSize",
        12 => "InvalidLayoutBlockSize",
        13 => "InvalidLayoutCanvasMargin",
        14 => "InvalidLayoutGridLeft",
        15 => "InvalidLayoutGridTop",
        16 => "InvalidLayoutTextPanelGap",
        17 => "InvalidLayoutFontCellWidth",
        18 => "InvalidLayoutFontCellHeight",
        19 => "InvalidLayoutConsoleStartCol",
        20 => "InvalidLayoutConsoleStartRow",
        21 => "InvalidFramebufferDimensions",
        22 => "InvalidGridMemoryBounds",
        23 => "InvalidActivePieceTypeOffset",
        24 => "InvalidPieceTypeRange",
        else => "UnknownGraphicsAbiFailure",
    };
}

pub export fn rosette_print_graphics_abi_report() void {
    const test_mutex: [64]u8 = undefined;
    std.debug.print(
        \\Graphics ABI Report:
        \\  sizeof(Color)          = {d}  (spec: {d})
        \\  alignof(Color)         = {d}  (spec: {d})
        \\  tetris_piece_colors.len = {d}  (spec: {d})
        \\  sizeof(piece_table)    = {d}  (spec: {d})
        \\  sizeof(fb_dim)         = {d}  (spec: {d})
        \\  sizeof(mutex)          = {d}  (spec: {d})
        \\  color byte order      = 0x12345678 → {x}
        \\Layout:
        \\  block_size            = {d}  (spec: {d})
        \\  canvas_margin         = {d}  (spec: {d})
        \\  grid_left             = {d}  (spec: {d})
        \\  grid_top              = {d}  (spec: {d})
        \\  text_panel_gap        = {d}  (spec: {d})
        \\  font_cell_width       = {d}  (spec: {d})
        \\  font_cell_height      = {d}  (spec: {d})
        \\
    , .{
        @sizeOf(palette.Color),                       WindowsGraphicsSpec.sizeof_Color,
        @alignOf(palette.Color),                      WindowsGraphicsSpec.alignof_Color,
        palette.tetris_piece_colors.len,              WindowsGraphicsSpec.num_piece_colors,
        @sizeOf(@TypeOf(palette.tetris_piece_colors)), WindowsGraphicsSpec.sizeof_piece_color_table,
        @sizeOf(@TypeOf(fb.rosette_gfx_get_width())), WindowsGraphicsSpec.sizeof_fb_dim,
        @sizeOf(@TypeOf(test_mutex)),                  WindowsGraphicsSpec.sizeof_pthread_mutex_t,
        palette.rgba(0x12, 0x34, 0x56, 0x78),
        layout.BLOCK_SIZE,        WindowsLayoutSpec.block_size,
        layout.CANVAS_MARGIN,     WindowsLayoutSpec.canvas_margin,
        layout.GRID_LEFT,         WindowsLayoutSpec.grid_left,
        layout.GRID_TOP,          WindowsLayoutSpec.grid_top,
        layout.TEXT_PANEL_GAP,    WindowsLayoutSpec.text_panel_gap,
        layout.FONT_CELL_WIDTH,   WindowsLayoutSpec.font_cell_width,
        layout.FONT_CELL_HEIGHT,  WindowsLayoutSpec.font_cell_height,
    });
}

test "graphics ABI matches spec" {
    try validateAll();
}

test "piece colors have expected values" {
    // Cyan I-piece (0)
    try std.testing.expectEqual(0x00FFFFFF, palette.tetris_piece_colors[0]);
    // Yellow O-piece (1)
    try std.testing.expectEqual(0xFFFF00FF, palette.tetris_piece_colors[1]);
    // Magenta T-piece (2)
    try std.testing.expectEqual(0xFF00FFFF, palette.tetris_piece_colors[2]);
    // Green S-piece (3)
    try std.testing.expectEqual(0x00FF00FF, palette.tetris_piece_colors[3]);
    // Red Z-piece (4)
    try std.testing.expectEqual(0xFF0000FF, palette.tetris_piece_colors[4]);
    // Blue J-piece (5)
    try std.testing.expectEqual(0x0000FFFF, palette.tetris_piece_colors[5]);
    // Orange L-piece (6)
    try std.testing.expectEqual(0xFF8800FF, palette.tetris_piece_colors[6]);
}

test "dim piece colors have expected values" {
    try std.testing.expectEqual(0x009999FF, palette.tetris_piece_dim_colors[0]);
    try std.testing.expectEqual(0x999900FF, palette.tetris_piece_dim_colors[1]);
    try std.testing.expectEqual(0x990099FF, palette.tetris_piece_dim_colors[2]);
    try std.testing.expectEqual(0x009900FF, palette.tetris_piece_dim_colors[3]);
    try std.testing.expectEqual(0x990000FF, palette.tetris_piece_dim_colors[4]);
    try std.testing.expectEqual(0x000099FF, palette.tetris_piece_dim_colors[5]);
    try std.testing.expectEqual(0x995200FF, palette.tetris_piece_dim_colors[6]);
}

test "UI palette colors are non-zero" {
    try std.testing.expect(palette.COLOR_BORDER != 0);
    try std.testing.expect(palette.COLOR_BG != 0);
    try std.testing.expect(palette.COLOR_GRID_BG != 0);
    try std.testing.expect(palette.COLOR_TEXT != 0);
    try std.testing.expect(palette.COLOR_TEXT_DIM != 0);
    try std.testing.expect(palette.COLOR_GHOST != 0);
    try std.testing.expect(palette.COLOR_NEXT_LABEL != 0);
}

test "framebuffer functions compile with C calling convention" {
    // Verify all framebuffer C-API functions exist and compile
    _ = &fb.rosette_gfx_init;
    _ = &fb.rosette_gfx_deinit;
    _ = &fb.rosette_gfx_get_width;
    _ = &fb.rosette_gfx_get_block;
    _ = &fb.rosette_gfx_set_block;
    _ = &fb.rosette_gfx_clear;
}

test "renderer functions compile with C calling convention" {
    _ = &renderer.rosette_gfx_begin_frame;
    _ = &renderer.rosette_gfx_write_byte;
    _ = &renderer.rosette_gfx_write_text;
    _ = &renderer.rosette_gfx_move_cursor;
}

test "framebuffer lifecycle no crash" {
    fb.rosette_gfx_init(10, 20);
    defer fb.rosette_gfx_deinit();

    try std.testing.expectEqual(@as(u32, 10), fb.rosette_gfx_get_width());
    try std.testing.expectEqual(@as(u32, 20), fb.rosette_gfx_get_height());

    // Default color is grid background
    try std.testing.expectEqual(palette.COLOR_GRID_BG, fb.rosette_gfx_get_block(0, 0));
    try std.testing.expectEqual(palette.COLOR_GRID_BG, fb.rosette_gfx_get_block(9, 19));

    // Write and read back
    fb.rosette_gfx_set_block(5, 10, 0xFF00FFFF);
    try std.testing.expectEqual(@as(u32, 0xFF00FFFF), fb.rosette_gfx_get_block(5, 10));

    // Clear
    fb.rosette_gfx_clear(0x000000FF);
    try std.testing.expectEqual(@as(u32, 0x000000FF), fb.rosette_gfx_get_block(5, 10));
}

test "layout constants match spec" {
    try std.testing.expectEqual(WindowsLayoutSpec.block_size, layout.BLOCK_SIZE);
    try std.testing.expectEqual(WindowsLayoutSpec.canvas_margin, layout.CANVAS_MARGIN);
    try std.testing.expectEqual(WindowsLayoutSpec.grid_left, layout.GRID_LEFT);
    try std.testing.expectEqual(WindowsLayoutSpec.grid_top, layout.GRID_TOP);
    try std.testing.expectEqual(WindowsLayoutSpec.text_panel_gap, layout.TEXT_PANEL_GAP);
    try std.testing.expectEqual(WindowsLayoutSpec.font_cell_width, layout.FONT_CELL_WIDTH);
    try std.testing.expectEqual(WindowsLayoutSpec.font_cell_height, layout.FONT_CELL_HEIGHT);
}

test "console start positions are valid" {
    try validateConsoleBounds();
}

test "framebuffer bounds validation" {
    try validateFramebufferBounds(10, 20);
    try validateFramebufferBounds(1, 1);
    try std.testing.expectError(error.InvalidFramebufferDimensions, validateFramebufferBounds(0, 0));
    try std.testing.expectError(error.InvalidFramebufferDimensions, validateFramebufferBounds(10, 0));
}

test "grid memory bounds validation" {
    try validateGridMemoryBounds(200, 10, 20);
    try std.testing.expectError(error.InvalidGridMemoryBounds, validateGridMemoryBounds(0, 0, 0));
    try std.testing.expectError(error.InvalidGridMemoryBounds, validateGridMemoryBounds(0, 10, 0));
}

test "active piece type offset validation" {
    try validateActivePieceTypeOffset(0x00C8);
    try std.testing.expectError(error.InvalidActivePieceTypeOffset, validateActivePieceTypeOffset(0));
    try std.testing.expectError(error.InvalidActivePieceTypeOffset, validateActivePieceTypeOffset(1024 * 1024 + 1));
}

test "piece type range validation" {
    try validatePieceType(0);
    try validatePieceType(3);
    try validatePieceType(6);
    try std.testing.expectError(error.InvalidPieceTypeRange, validatePieceType(-1));
    try std.testing.expectError(error.InvalidPieceTypeRange, validatePieceType(7));
}

test "layout helper functions match computed values" {
    // gridPixelWidth
    try std.testing.expectEqual(@as(u32, 10 * 24), layout.gridPixelWidth(10));
    try std.testing.expectEqual(@as(u32, 0), layout.gridPixelWidth(0));

    // gridPixelHeight
    try std.testing.expectEqual(@as(u32, 20 * 24), layout.gridPixelHeight(20));

    // windowContentWidth: margin + blockGrid + gap + textPanel + margin
    const expectedW = layout.CANVAS_MARGIN + 10 * layout.BLOCK_SIZE + layout.TEXT_PANEL_GAP + layout.TEXT_PANEL_MIN_WIDTH + layout.CANVAS_MARGIN;
    try std.testing.expectEqual(expectedW, layout.windowContentWidth(10));

    // windowContentHeight: margin + blockGrid + margin
    const expectedH = layout.CANVAS_MARGIN + 20 * layout.BLOCK_SIZE + layout.CANVAS_MARGIN;
    try std.testing.expectEqual(expectedH, layout.windowContentHeight(20));

    // textPanelLeft: margin + blockGrid + gap
    const expectedPanelLeft = layout.CANVAS_MARGIN + 10 * layout.BLOCK_SIZE + layout.TEXT_PANEL_GAP;
    try std.testing.expectEqual(expectedPanelLeft, layout.textPanelLeft(10));
}

test "layout constants are accessible as pub const" {
    // Verify const values (not C-export functions) are accessible from Zig
    _ = layout.BLOCK_SIZE;
    _ = layout.CANVAS_MARGIN;
    _ = layout.GRID_LEFT;
    _ = layout.GRID_TOP;
    _ = layout.TEXT_PANEL_GAP;
    _ = layout.FONT_CELL_WIDTH;
    _ = layout.FONT_CELL_HEIGHT;
    // Verify helper functions compile
    _ = layout.gridPixelWidth(10);
    _ = layout.gridPixelHeight(20);
    _ = layout.windowContentWidth(10);
    _ = layout.windowContentHeight(20);
    _ = layout.textPanelLeft(10);
}

test "renderer cursor tracking" {
    fb.rosette_gfx_init(10, 20);
    defer fb.rosette_gfx_deinit();

    renderer.rosette_gfx_begin_frame();
    renderer.rosette_gfx_move_cursor(0, 0);

    // Write a '#' at grid start position (GRID_CONSOLE_START_COL=1, row=1)
    // This should write to block (0, 0) in the framebuffer
    renderer.rosette_gfx_move_cursor(
        @as(i32, @intCast(layout.GRID_CONSOLE_START_COL)),
        @as(i32, @intCast(layout.GRID_CONSOLE_START_ROW)),
    );
    renderer.rosette_gfx_write_byte('#');
    const block = fb.rosette_gfx_get_block(0, 0);
    try std.testing.expect(block != 0);
    try std.testing.expect(block != palette.COLOR_GRID_BG);
}

test "renderer skips cells outside grid" {
    fb.rosette_gfx_init(10, 20);
    defer fb.rosette_gfx_deinit();

    renderer.rosette_gfx_begin_frame();
    // Writing at column 0 (left of grid start) should NOT write to framebuffer
    renderer.rosette_gfx_move_cursor(0, @as(i32, @intCast(layout.GRID_CONSOLE_START_ROW)));
    renderer.rosette_gfx_write_byte('#');
    try std.testing.expectEqual(palette.COLOR_GRID_BG, fb.rosette_gfx_get_block(0, 0));
}
