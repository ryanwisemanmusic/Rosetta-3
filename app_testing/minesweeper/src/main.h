/* MINESWEEPER HEADER FILE */

/*
 * Main application constants and global definitions
 * 
 * Contents:
 * - Menu system constants (visibility flags, accelerator IDs)
 * - Window resize flags (fCalc, fResize, fDisplay)
 * - Coordinate conversion macros (pixel to grid conversion)
 * - Registry key path
 * - Minimum/default grid dimensions
 * 
 * Grid constraints:
 * - Minimum 9x9 (prevents title bar clipping)
 * - Maximum 30x24 (limited by screen size and rendering performance)
 * - Default 9x9 for beginner difficulty
 */

#ifdef DEBUG
#define CHEAT
#endif

/*** Constants ***/

#define cchMsgMax  128          /* Maximum message string length */
#define cchMaxPathname 250      /* Maximum file path length */

#define ID_TIMER 1              /* Timer ID for game clock updates */

/* Menu visibility modes */
#define fmenuAlwaysOn 0x00      /* Menu permanently visible */
#define fmenuOff      0x01      /* Menu hidden */
#define fmenuOn       0x02      /* Menu visible (toggleable) */

/* Menu state testing macros */
#define FMenuSwitchable()   (g_GameConfig.fMenu != fmenuAlwaysOn)
#define FMenuOn()          ((g_GameConfig.fMenu &  0x01) == 0)

/* Window adjustment flags (can be OR'd together) */
#define fCalc    0x01           /* Recalculate dimensions */
#define fResize  0x02           /* Resize and reposition window */
#define fDisplay 0x04           /* Invalidate and repaint */

/* Coordinate conversion: pixel position to grid cell index */
/* Accounts for grid offset and cell size (24x24 pixels) */
#define xBoxFromXpos(x) ( ((x)-(dxGridOff-dxBlk)) / dxBlk )
#define yBoxFromYpos(y) ( ((y)-(dyGridOff-dyBlk)) / dyBlk )

/* Registry storage location for game settings */
#define SZWINMINEREG   TEXT("Software\\MinesweeperGame\\Settings")

/* Grid size constraints */
#define MINWIDTH 9    /* Minimum width (prevents UI clipping) */
#define DEFWIDTH 9    /* Default width */
#define MINHEIGHT 9   /* Minimum height */
#define DEFHEIGHT 9   /* Default height */


VOID ResizeGameWindow(INT);
VOID UpdateMenuStates(VOID);
VOID ShowNameEntryDialog(VOID);
VOID ShowHighScoresDialog(VOID);
