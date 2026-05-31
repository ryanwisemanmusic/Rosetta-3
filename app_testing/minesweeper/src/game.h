/****************/
/* file: game.h */
/****************/

/*
 * Game logic interface and data structure definitions
 * 
 * Core concepts:
 * 
 * Cell state encoding (8-bit bitmasked):
 * - Bit 7 (0x80): MaskBomb - cell contains mine
 * - Bit 6 (0x40): MaskVisit - cell has been revealed
 * - Bits 5-0 (0x1F): MaskData - cell visual type (0-15)
 * 
 * Cell types (iBlk constants):
 * - 0-8: Blank or numbers showing adjacent mine count
 * - 9-15: Special states (flags, question marks, bombs)
 * 
 * Status flags (bitmasked game state):
 * - fPlay: Game in progress
 * - fPause: Game paused (menu open, minimized)
 * - fIcon: Window iconified
 * - fDemo: Demo mode (unused in current version)
 * 
 * Macros provide type-safe access to cell data with bounds checking
 */

/*** Bitmaps ***/


/* Blocks */

/* Cell visual types (lower 5 bits of cell state byte) */
#define iBlkBlank    0   /* Revealed blank cell (0 adjacent mines) */
#define iBlk1        1   /* 1 adjacent mine */
#define iBlk2        2   /* 2 adjacent mines */
#define iBlk8        8   /* 8 adjacent mines (maximum) */
#define iBlkGuessDn  9   /* Question mark (pressed state) */
#define iBlkBombDn  10   /* Revealed mine */
#define iBlkWrong   11   /* Wrong flag placement (mine revealed but was flagged) */
#define iBlkExplode 12   /* Detonated mine (game over) */
#define iBlkGuessUp 13   /* Question mark (normal state) */
#define iBlkBombUp  14   /* Flagged cell */
#define iBlkBlankUp 15   /* Unrevealed cell */

#define iBlkMax 16

/* Cell state bitmasks */
#define MaskBomb  0x80   /* Bit 7: Cell contains mine */
#define MaskVisit 0x40   /* Bit 6: Cell has been revealed */
#define MaskFlags 0xE0   /* Bits 5-7: All flag bits */
#define MaskData  0x1F   /* Bits 0-4: Visual cell type */

#define NOTMaskBomb 0x7F /* Inverted bomb mask for clearing */

/* Maximum grid size: 40x40 = 1600 cells */
#define cBlkMax (40*40)


/* Leds */

#define iLed0         0
#define iLed1         1
#define iLed9         9
#define iLedBlank    10
#define iLedNegative 11

#define iLedMax 12


/* Buttons */

#define iButtonHappy   0
#define iButtonCaution 1
#define iButtonLose    2
#define iButtonWin     3
#define iButtonDown    4

#define iButtonMax 5



#define wGameBegin  0
#define wGameInter  1
#define wGameExpert 2
#define wGameOther  3



/*** Macros ***/

/*
 * Cell access and manipulation macros
 * 
 * Grid coordinate system:
 * - (1,1) = top-left playable cell
 * - (g_GridWidth, g_GridHeight) = bottom-right playable cell
 * - (0,*) and (g_GridWidth+1,*) = vertical borders
 * - (*,0) and (*,g_GridHeight+1) = horizontal borders
 * 
 * Array indexing:
 * - Uses formula: index = (y << 5) + x
 * - Equivalent to: index = y * 32 + x
 * - Assumes maximum width of 32 (actual limit is 30)
 */

/* Bounds checking - returns TRUE if coordinates are within playable area */
#define IsValidPosition(x,y)   (((x)>0) && ((y)>0) && ((x)<=g_GridWidth) && ((y)<=g_GridHeight))

/* Direct cell data access (returns full 8-bit state byte) */
#define CELL_DATA(x,y)    (g_GameGrid[ ((y)<<5) + (x)])

/* Extract visual cell type (lower 5 bits) */
#define GET_CELL_TYPE(x,y)    ( (CELL_DATA(x,y) & MaskData) )

/* Border cell operations (border cells marked with iBlkMax=16) */
#define MarkBorderCell(x,y) (CELL_DATA(x,y) =  iBlkMax)
#define IsBorderCell(x,y)   (CELL_DATA(x,y) == iBlkMax)

/* Mine manipulation */
#define PlaceMine(x,y)   (CELL_DATA(x,y) |= MaskBomb)    /* Set bomb bit */
#define RemoveMine(x,y) (CELL_DATA(x,y) &= NOTMaskBomb)  /* Clear bomb bit */
#define HasMine(x,y)   ((CELL_DATA(x,y) & MaskBomb) != 0) /* Test bomb bit */

/* Visited state */
#define MarkCellVisited(x,y)  (CELL_DATA(x,y) |= MaskVisit)
#define IsCellVisited(x,y)    ((CELL_DATA(x,y) & MaskVisit) != 0)

/* Flag and marker testing */
#define IsCellFlagged(x,y)  (GET_CELL_TYPE(x,y) == iBlkBombUp)
#define IsCellMarked(x,y)  (GET_CELL_TYPE(x,y) == iBlkGuessUp)

/* Update cell visual type while preserving flag bits */
#define SetCellData(x,y,blk)  (CELL_DATA(x,y) = (char) ((CELL_DATA(x,y) & MaskFlags) | blk))


/*** Status Stuff ***/

#define fPlay      0x01		/* ON if playing game, OFF if game over */
#define fPause     0x02		/* ON if paused */
#define fPanic     0x04		/* ON if panic  */
#define fIcon      0x08    /* ON if iconic */
#define fDemo      0x10		/* ON if demo   */

#define fStatusIcon    (g_GameStatus & fIcon)
#define fStatusPlay    (g_GameStatus & fPlay)
#define fStatusPanic   (g_GameStatus & fPanic)
#define fStatusPause   (g_GameStatus & fPause)
#define fStatusDemo    (g_GameStatus & fDemo)

#define SetStatusPlay  (g_GameStatus = fPlay)
#define SetStatusPause (g_GameStatus |= fPause)
#define SetStatusPanic (g_GameStatus |= fPanic)
#define SetStatusIcon  (g_GameStatus |= fIcon)
#define SetStatusDemo  (g_GameStatus = fDemo)

#define ClrStatusPlay  (g_GameStatus &= 0xFE)
#define ClrStatusPause (g_GameStatus &= 0xFD)
#define ClrStatusPanic (g_GameStatus &= 0xFB)
#define ClrStatusIcon  (g_GameStatus &= 0xF7)
#define ClrStatusDemo  (g_GameStatus &= 0xEF)

#define fLose  FALSE
#define fWin   TRUE


typedef INT BLK;



/*** Routines ***/

VOID InitializeGameBoard(VOID);
VOID StopGame(VOID);
VOID UpdateGameTimer(VOID);

VOID UpdateCursorPosition(INT, INT);
VOID HandleLeftButtonRelease(VOID);
VOID ToggleCellMarker(INT, INT);

VOID SuspendGameState(VOID);
VOID RestoreGameState(VOID);
VOID ResetGameGrid(VOID);

VOID CalcFrameRect(VOID);
VOID UpdateMineCount(INT);
