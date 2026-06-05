#ifndef ROSETTE_LAYOUT_H
#define ROSETTE_LAYOUT_H

/*
 * rosette_layout.h — Canvas layout contract
 *
 * Pixel layout constants for the rendered window. These macros are
 * the C/ObjC side of the layout handshake.  The Zig side defines
 * matching `pub const` values in `src/x86-ASM/graphics/layout.zig`,
 * and the ABI validation (abi.zig) verifies both sides agree.
 *
 *    Zig is the AUTHORITATIVE source of truth.
 *    These macros must be manually kept in sync.
 *    `zig build check` fails if they diverge.
 */

/* Game block size in pixels (square) */
#define ROSETTE_LAYOUT_BLOCK_SIZE               24

/* Padding from window edge to content area */
#define ROSETTE_LAYOUT_CANVAS_MARGIN             4

/* Horizontal gap between block grid and text panel */
#define ROSETTE_LAYOUT_TEXT_PANEL_GAP           12

/* Minimum width for the text panel */
#define ROSETTE_LAYOUT_TEXT_PANEL_MIN_WIDTH    160

/* Block grid pixel position in the window */
#define ROSETTE_LAYOUT_GRID_LEFT                 4   /* == CANVAS_MARGIN */
#define ROSETTE_LAYOUT_GRID_TOP                  4   /* == CANVAS_MARGIN */

/* Default font cell dimensions (Menlo 14pt — rough average) */
#define ROSETTE_LAYOUT_FONT_CELL_WIDTH           9
#define ROSETTE_LAYOUT_FONT_CELL_HEIGHT         17

/* Console character column/row where the game grid starts */
#define ROSETTE_LAYOUT_GRID_CONSOLE_START_COL    1
#define ROSETTE_LAYOUT_GRID_CONSOLE_START_ROW    1

#endif /* ROSETTE_LAYOUT_H */
