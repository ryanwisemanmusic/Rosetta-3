const std = @import("std");

/// Single source of truth for pixel layout of the rendered window.
/// Every layout constant is exported for C/ObjC to read via a C-linkage
/// function, so the Zig renderer and the Cocoa window backend agree
/// on block positions, margins, and the text panel location.

/// Game block size in pixels (square)
pub const BLOCK_SIZE: u32 = 24;

/// Padding from window edge to content area
pub const CANVAS_MARGIN: u32 = 4;

/// Horizontal gap between the block grid and the text panel
pub const TEXT_PANEL_GAP: u32 = 12;

/// Minimum width for the text panel (score, labels, controls)
pub const TEXT_PANEL_MIN_WIDTH: u32 = 160;

/// Block grid position in the window (pixel offset from top-left)
pub const GRID_LEFT: u32 = CANVAS_MARGIN;
pub const GRID_TOP: u32 = CANVAS_MARGIN;

/// Default font cell dimensions (Menlo 14pt — rough average)
/// These are hints; the actual font metrics from AppKit may differ slightly.
pub const FONT_CELL_WIDTH: u32 = 9;
pub const FONT_CELL_HEIGHT: u32 = 17;

/// Console character column where the game grid starts (0-based cursor coordinate)
pub const GRID_CONSOLE_START_COL: u32 = 1;
/// Console character row where the game grid starts
pub const GRID_CONSOLE_START_ROW: u32 = 1;

/// Compute the pixel width of a block grid with `cols` columns
pub fn gridPixelWidth(cols: u32) u32 {
    return cols * BLOCK_SIZE;
}

/// Compute the pixel height of a block grid with `rows` rows
pub fn gridPixelHeight(rows: u32) u32 {
    return rows * BLOCK_SIZE;
}

/// Recommended window content width for a game with a `cols`×`rows` block grid.
/// Includes block grid, gap, and text panel.
pub fn windowContentWidth(blockCols: u32) u32 {
    return CANVAS_MARGIN + blockCols * BLOCK_SIZE + TEXT_PANEL_GAP + TEXT_PANEL_MIN_WIDTH + CANVAS_MARGIN;
}

/// Recommended window content height for a game with a `rows`-tall block grid.
pub fn windowContentHeight(blockRows: u32) u32 {
    return CANVAS_MARGIN + blockRows * BLOCK_SIZE + CANVAS_MARGIN;
}

/// Pixel x-coordinate of the left edge of the text panel
pub fn textPanelLeft(blockCols: u32) u32 {
    return CANVAS_MARGIN + blockCols * BLOCK_SIZE + TEXT_PANEL_GAP;
}

/// C-exported accessors so the window backend reads layout constants from Zig.
/// Uses `export fn` (not `pub fn ... @export`) matching the palette.zig pattern
/// which reliably generates symbols in the library.
export fn rosetta3_layout_block_size() u32 { return BLOCK_SIZE; }
export fn rosetta3_layout_canvas_margin() u32 { return CANVAS_MARGIN; }
export fn rosetta3_layout_grid_left() u32 { return GRID_LEFT; }
export fn rosetta3_layout_grid_top() u32 { return GRID_TOP; }
export fn rosetta3_layout_text_panel_gap() u32 { return TEXT_PANEL_GAP; }
export fn rosetta3_layout_text_panel_min_width() u32 { return TEXT_PANEL_MIN_WIDTH; }
export fn rosetta3_layout_font_cell_width() u32 { return FONT_CELL_WIDTH; }
export fn rosetta3_layout_font_cell_height() u32 { return FONT_CELL_HEIGHT; }
export fn rosetta3_layout_grid_pixel_width(cols: u32) u32 { return gridPixelWidth(cols); }
export fn rosetta3_layout_grid_pixel_height(rows: u32) u32 { return gridPixelHeight(rows); }
export fn rosetta3_layout_window_content_width(blockCols: u32) u32 {
    return windowContentWidth(blockCols);
}
export fn rosetta3_layout_window_content_height(blockRows: u32) u32 {
    return windowContentHeight(blockRows);
}
export fn rosetta3_layout_text_panel_left(blockCols: u32) u32 {
    return textPanelLeft(blockCols);
}
export fn rosetta3_layout_grid_console_start_col() u32 { return GRID_CONSOLE_START_COL; }
export fn rosetta3_layout_grid_console_start_row() u32 { return GRID_CONSOLE_START_ROW; }
