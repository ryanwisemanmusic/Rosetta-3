/**********/
/* game.c */
/**********/

/*
 * Core game logic module - implements Minesweeper mechanics
 * 
 * Key responsibilities:
 * - Game state management (mine placement, cell revelation, victory/loss detection)
 * - Flood-fill algorithm using circular queue for efficient blank cell revelation
 * - Timer management and mine counter updates
 * - Cell state transitions and flag/mark toggling
 * 
 * Architecture notes:
 * - Uses bitmasked cell representation (0x80=bomb, 0x40=visited, 0x1F=data)
 * - Victory condition optimized to O(1) comparison
 * - First-click mine relocation prevents instant loss
 * - Queue-based BFS limits maximum connected region to 1000 cells
 */

#include <windows.h>
#include <windowsx.h>

#include "resource.h"
#include "main.h"
#include "game.h"
#include "utilities.h"
#include "graphics.h"
#include "sound.h"
#include "preferences.h"


/*** External Data ***/

extern HWND   g_MainWindow;

/*** Global/Local Variables ***/

/* Current game configuration loaded from registry */
PREF    g_GameConfig;

/* Grid dimensions - valid range 9-30 width, 9-24 height */
INT     g_GridWidth;                        
INT     g_GridHeight;                        

/* Window dimensions calculated from grid size plus borders */
INT     g_WindowWidth;               
INT     g_WindowHeight;

/* Current difficulty level (0=Beginner, 1=Intermediate, 2=Expert, 3=Custom) */
INT wGameType;          

/* Smiley face button state (Happy, Caution, Lose, Win, Down) */
INT g_CurrentButton = iButtonHappy;

/* Mine tracking - total placed vs remaining unflagged */
INT     g_TotalMines;             
INT     g_RemainingMines;              

/* Progress tracking for victory detection */
INT     g_RevealedCells;              
INT     g_TargetRevealed;   /* Pre-calculated: (width * height) - mines */

/* Elapsed time in seconds (0-999 range) */
INT     g_ElapsedSeconds;                           

/* Timer control flags */
BOOL  g_TimerActive = FALSE;
BOOL  fOldTimerStatus = FALSE;

/* Mouse cursor tracking for visual feedback during drag operations */
INT     g_CursorX = -1;      
INT     g_CursorY = -1;

/* Main game grid: bitmasked cell states (40x40 maximum = 1600 bytes) */
CHAR g_GameGrid[cBlkMax];

/* Circular queue for breadth-first flood fill algorithm */
// Maximum flood-fill queue size = grid area (40×40)
// Prevents stack overflow on pathological mine layouts
#define iStepMax cBlkMax

INT g_FloodQueueX[iStepMax];
INT g_FloodQueueY[iStepMax];
INT g_QueueSize;



/*** Global/External Variables ***/

extern BOOL g_ChordMode;


extern INT g_GameStatus;




/****** F  C H E C K  W I N ******/

/*
 * Victory condition check
 * 
 * Optimized to single integer comparison: player wins when revealed cells
 * equals target (which is pre-calculated as total_cells - total_mines)
 * 
 * This is equivalent to checking if all non-mine cells are revealed,
 * but avoids iteration over the entire grid on every cell reveal.
 */

#if 0

BOOL CheckVictoryCondition(VOID)
{
        if (g_RemainingMines)
                return (FALSE);
        else
                return ((g_RevealedCells + g_TotalMines) == (g_GridWidth*g_GridHeight));

}

#else

#define CheckVictoryCondition()     (g_RevealedCells == g_TargetRevealed)

#endif



/****** C H A N G E  B L K ******/

VOID UpdateCellState(INT x, INT y, INT iBlk)
{

        SetCellData(x,y, iBlk);

        RefreshCell(x,y);
}


/****** C L E A R  F I E L D ******/

VOID ResetGameGrid(VOID)
{
        INT i;

        for (i = cBlkMax; i-- != 0; )                   /* zero all of data */
                g_GameGrid[i] = (CHAR) iBlkBlankUp;

        for (i = g_GridWidth+2; i-- != 0; ) /* initialize border */
                {
                MarkBorderCell(i,0);
                MarkBorderCell(i,g_GridHeight+1);
                }
        for (i = g_GridHeight+2; i-- != 0;)
                {
                MarkBorderCell(0,i);
                MarkBorderCell(g_GridWidth+1,i);
                }
}



/******* C O U N T  B O M B S *******/

/* Count the bombs surrounding the point */

INT CountAdjacentMines(INT xCenter, INT yCenter)
{
        INT    x;
        INT    y;
        INT     cBombs = 0;

        for(y = yCenter-1; y <= yCenter+1; y++)
                for(x = xCenter-1; x <= xCenter+1; x++)
                        if(HasMine(x,y))
                                cBombs++;

        return(cBombs);
}


/****** S H O W  B O M B S ******/

/* Display hidden bombs and wrong bomb guesses */

VOID RevealAllMines(INT iBlk)
{
        INT    x;
        INT    y;

        for(y = 1; y <= g_GridHeight; y++)
                {
                for(x = 1; x <= g_GridWidth; x++)
                        {
                        if (!IsCellVisited(x,y))
                                {
                                if (HasMine(x,y))
                                        {
                                        if (!IsCellFlagged(x,y) )
                                                SetCellData(x,y, iBlk);
                                        }
                                else if (IsCellFlagged(x,y))
                                        SetCellData(x,y, iBlkWrong);
                                }
                        }
                }

        RefreshGameGrid();
}



/****** G A M E  O V E R ******/

VOID EndGame(BOOL fWinLose)
{
        g_TimerActive = FALSE;
        RefreshControlButton(g_CurrentButton = fWinLose ? iButtonWin : iButtonLose);
        RevealAllMines(fWinLose ? iBlkBombUp : iBlkBombDn);
        if (fWinLose && (g_RemainingMines != 0))
                UpdateMineCount(-g_RemainingMines);
        PlayGameSound(fWinLose ? TUNE_WINGAME : TUNE_LOSEGAME);
        SetStatusDemo;

        if (fWinLose && (g_GameConfig.wGameType != wGameOther)
                && (g_ElapsedSeconds < g_GameConfig.rgTime[g_GameConfig.wGameType]))
                {
                g_GameConfig.rgTime[g_GameConfig.wGameType] = g_ElapsedSeconds;
                ShowNameEntryDialog();
                ShowHighScoresDialog();
                }
}


/****** D O  T I M E R ******/

VOID UpdateGameTimer(VOID)
{
        if (g_TimerActive && (g_ElapsedSeconds < 999))
                {
                g_ElapsedSeconds++;
                RefreshTimeDisplay();
                PlayGameSound(TUNE_TICK);
                }
}



/****** S T E P  X Y ******/

VOID RevealCellRecursive(INT x, INT y)
{
        INT cBombs;
        INT iBlk = (y<<5) + x;
        BLK blk = g_GameGrid[iBlk];

        if ( (blk & MaskVisit) ||
                  ((blk &= MaskData) == iBlkMax) ||
                  (blk == iBlkBombUp) )
                return;

        g_RevealedCells++;
        g_GameGrid[iBlk] = (CHAR) (MaskVisit | (cBombs = CountAdjacentMines(x,y)));

//
//      SetDIBitsToDevice(hDCCapture,
//              (x<<4)+(dxGridOff-dxBlk), (y<<4)+(dyGridOff-dyBlk),
//              dxBlk, dyBlk, 0, 0, 0, dyBlk,
//              lpDibBlks + rgDibOff[cBombs],
//              (LPBITMAPINFO) lpDibBlks, DIB_RGB_COLORS);
//
        RefreshCell(x,y);

        if (cBombs != 0)
                return;

        g_FloodQueueX[g_QueueSize] = x;
        g_FloodQueueY[g_QueueSize] = y;

        if (++g_QueueSize == iStepMax)
                g_QueueSize = 0;
}


/****** S T E P  B O X ******/

/*
 * Breadth-first flood fill for revealing connected blank cells
 * 
 * Algorithm:
 * 1. Start with initial cell, push to queue
 * 2. While queue not empty:
 *    - Dequeue cell coordinates
 *    - Reveal 8 neighbors (if blank, they get enqueued)
 *    - Continue until all connected blanks processed
 * 
 * Uses circular queue with fixed 1000-element capacity:
 * - Queue wraps using modulo arithmetic (iStepCur == iStepMax -> 0)
 * - Limits maximum connected blank region to ~1000 cells
 * - Prevents stack overflow compared to recursive implementation
 * 
 * Performance: O(n) where n = size of connected blank region
 */

VOID FloodFillReveal(INT x, INT y)
{
        INT iStepCur = 0;

        g_QueueSize = 1;


        RevealCellRecursive(x,y);

        if (++iStepCur != g_QueueSize)

                while (iStepCur != g_QueueSize)
                        {
                        x = g_FloodQueueX[iStepCur];
                        y = g_FloodQueueY[iStepCur];

                        RevealCellRecursive(x-1, --y);
                        RevealCellRecursive(x,   y);
                        RevealCellRecursive(x+1, y);

                        RevealCellRecursive(x-1, ++y);
                        RevealCellRecursive(x+1, y);

                        RevealCellRecursive(x-1, ++y);
                        RevealCellRecursive(x,   y);
                        RevealCellRecursive(x+1, y);

                        if (++iStepCur == iStepMax)
                                iStepCur = 0;
                        }


}


/****** S T E P  S Q U A R E ******/

/*
 * Handle single cell click (left button release)
 * 
 * Special case: First click mine relocation
 * - If first click hits a mine, scan grid for empty cell
 * - Move mine to first available empty position
 * - Prevents frustrating instant loss on first move
 * 
 * Normal flow:
 * - Click on mine -> explosion, game over
 * - Click on blank -> flood fill reveals connected region
 * - After each reveal, check victory condition
 */

VOID HandleCellClick(INT x, INT y)
{
        if (HasMine(x,y))
                {
                if (g_RevealedCells == 0)
                        {
                        INT xT, yT;
                        for (yT = 1; yT <= g_GridHeight; yT++)
                                  for (xT = 1; xT <= g_GridWidth; xT++)
                                        if (!HasMine(xT,yT))
                                                {
                                                CELL_DATA(x,y) = (CHAR) iBlkBlankUp; /* Move bomb out of way */
                                                PlaceMine(xT, yT);
                                                FloodFillReveal(x,y);
                                                return;
                                                }
                        }
                else
                        {
                        UpdateCellState(x, y, MaskVisit | iBlkExplode);
                        EndGame(fLose);
                        }
                }
        else
                {
                FloodFillReveal(x,y);

                if (CheckVictoryCondition())
                        EndGame(fWin);
                }
}


/******* C O U N T  M A R K S *******/

/* Count the bomb marks surrounding the point */

INT CountAdjacentFlags(INT xCenter, INT yCenter)
{
        INT    x;
        INT    y;
        INT     cBombs = 0;

        for(y = yCenter-1; y <= yCenter+1; y++)
                for(x = xCenter-1; x <= xCenter+1; x++)
                        if (IsCellFlagged(x,y))
                                cBombs++;

        return(cBombs);
}



/****** S T E P  B L O C K ******/

/* Step in a block around a single square */

VOID RevealAdjacentCells(INT xCenter, INT yCenter)
{
        INT    x;
        INT    y;
        BOOL fGameOver = FALSE;

        if (  (!IsCellVisited(xCenter,yCenter))
                        || IsCellFlagged(xCenter,yCenter)
                        || (GET_CELL_TYPE(xCenter,yCenter) < iBlk1 || GET_CELL_TYPE(xCenter,yCenter) > iBlk8)
                        || (GET_CELL_TYPE(xCenter,yCenter) != CountAdjacentFlags(xCenter,yCenter)) )
                                {
                                /* not a safe thing to do */
                                UpdateCursorPosition(-2, -2);     /* pop up the blocks */
                                return;
                                }

        for(y=yCenter-1; y<=yCenter+1; y++)
                for(x=xCenter-1; x<=xCenter+1; x++)
                        {
                        if (!IsCellFlagged(x,y) && HasMine(x,y))
                                {
                                fGameOver = TRUE;
                                UpdateCellState(x, y, MaskVisit | iBlkExplode);
                                }
                        else
                                FloodFillReveal(x,y);
                        }

        if (fGameOver)
                EndGame(fLose);
        else if (CheckVictoryCondition())
                EndGame(fWin);
}


/****** S T A R T  G A M E *******/

VOID InitializeGameBoard(VOID)
{
        BOOL fAdjust;
        INT     x;
        INT     y;

        g_TimerActive = FALSE;

        fAdjust = (g_GameConfig.Width != g_GridWidth || g_GameConfig.Height != g_GridHeight)
                ? (fResize | fDisplay) : fDisplay;

        g_GridWidth = g_GameConfig.Width;
        g_GridHeight = g_GameConfig.Height;

        ResetGameGrid();
        g_CurrentButton = iButtonHappy;

        g_TotalMines = g_GameConfig.Mines;

        do
                {
                do
                        {
                        x = GenerateRandomNumber(g_GridWidth) + 1;
                        y = GenerateRandomNumber(g_GridHeight) + 1;
                        }
                while ( HasMine(x,y) );

                PlaceMine(x,y);
                }
        while(--g_TotalMines);

        g_ElapsedSeconds   = 0;
        g_RemainingMines = g_TotalMines = g_GameConfig.Mines;
        g_RevealedCells = 0;
        g_TargetRevealed = (g_GridWidth * g_GridHeight) - g_RemainingMines;
        SetStatusPlay;

        UpdateMineCount(0);

        ResizeGameWindow(fAdjust);
}


#define fValidStep(x,y)  (! (IsCellVisited(x,y) || IsCellFlagged(x,y)) )



/****** P U S H  B O X ******/

VOID PressCellVisual(INT x, INT y)
{
        BLK iBlk = GET_CELL_TYPE(x,y);

        if (iBlk == iBlkGuessUp)
                iBlk = iBlkGuessDn;
        else if (iBlk == iBlkBlankUp)
                iBlk = iBlkBlank;

        SetCellData(x,y,iBlk);
}


/****** P O P  B O X  U P ******/

VOID ReleaseCellVisual(INT x, INT y)
{
        BLK iBlk = GET_CELL_TYPE(x,y);

        if (iBlk == iBlkGuessDn)
                iBlk = iBlkGuessUp;
        else if (iBlk == iBlkBlank)
                iBlk = iBlkBlankUp;

        SetCellData(x,y,iBlk);
}



/****** T R A C K  M O U S E ******/

VOID UpdateCursorPosition(INT xNew, INT yNew)
{
        if((xNew == g_CursorX) && (yNew == g_CursorY))
                return;

        {
        INT xOld = g_CursorX;
        INT yOld = g_CursorY;

        g_CursorX = xNew;
        g_CursorY = yNew;

        if (g_ChordMode)
                {
                INT x;
                INT y;
                BOOL fValidNew = IsValidPosition(xNew, yNew);
                BOOL fValidOld = IsValidPosition(xOld, yOld);

                INT yOldMin = max(yOld-1,1);
                INT yOldMax = min(yOld+1,g_GridHeight);
                INT yCurMin = max(g_CursorY-1,1);
                INT yCurMax = min(g_CursorY+1,g_GridHeight);
                INT xOldMin = max(xOld-1,1);
                INT xOldMax = min(xOld+1,g_GridWidth);
                INT xCurMin = max(g_CursorX-1,1);
                INT xCurMax = min(g_CursorX+1,g_GridWidth);


                if (fValidOld)
                        for (y=yOldMin; y<=yOldMax; y++)
                                for (x=xOldMin; x<=xOldMax; x++)
                                        if (!IsCellVisited(x,y))
                                                ReleaseCellVisual(x, y);

                if (fValidNew)
                        for (y=yCurMin; y<=yCurMax; y++)
                                for (x=xCurMin; x<=xCurMax; x++)
                                        if (!IsCellVisited(x,y))
                                                PressCellVisual(x, y);

                if (fValidOld)
                        for (y=yOldMin; y<=yOldMax; y++)
                                for (x=xOldMin; x<=xOldMax; x++)
                                        RefreshCell(x, y);

                if (fValidNew)
                        for (y=yCurMin; y<=yCurMax; y++)
                                for (x=xCurMin; x<=xCurMax; x++)
                                        RefreshCell(x, y);
                }
        else
                {
                if (IsValidPosition(xOld, yOld) && !IsCellVisited(xOld,yOld) )
                        {
                        ReleaseCellVisual(xOld, yOld);
                        RefreshCell(xOld, yOld);
                        }
                if (IsValidPosition(xNew, yNew) && fValidStep(xNew, yNew))
                        {
                        PressCellVisual(g_CursorX, g_CursorY);
                        RefreshCell(g_CursorX, g_CursorY);
                        }
                }
        }
}





/****** M A K E  G U E S S ******/

VOID ToggleCellMarker(INT x, INT y)
{
        BLK     iBlk;

        if(IsValidPosition(x,y))
                {
                if(!IsCellVisited(x,y))
                        {
                        if(IsCellFlagged(x,y))
                                {
                                if (g_GameConfig.fMark)
                                        iBlk = iBlkGuessUp;
                                else
                                        iBlk = iBlkBlankUp;
                                UpdateMineCount(+1);
                                }
                        else if(IsCellMarked(x,y))
                                {
                                iBlk = iBlkBlankUp;
                                }
                        else
                                {
                                iBlk = iBlkBombUp;
                                UpdateMineCount(-1);
                                }

                        UpdateCellState(x,y, iBlk);

                        if (IsCellFlagged(x,y) && CheckVictoryCondition())
                                EndGame(fWin);
                        }
                }
}

/****** D O  B U T T O N  1  U P ******/

VOID HandleLeftButtonRelease(VOID)
{
        if (IsValidPosition(g_CursorX, g_CursorY))
                {

                if ((g_RevealedCells == 0) && (g_ElapsedSeconds == 0))
                        {
                        PlayGameSound(TUNE_TICK);
                        g_ElapsedSeconds++;
                        RefreshTimeDisplay();
                        g_TimerActive = TRUE;

                        // Start the timer now. If we had started it earlier,
                        // the interval between tick 1 and 2 is not correct.
                        if (SetTimer(g_MainWindow, ID_TIMER, 1000 , NULL) == 0)
		                    {
		                    DisplayErrorMessage(ID_ERR_TIMER);
		                    }
                        }

                if (!fStatusPlay)
                        g_CursorX = g_CursorY = -2;

                if (g_ChordMode)
                        RevealAdjacentCells(g_CursorX, g_CursorY);
                else
                        if (fValidStep(g_CursorX, g_CursorY))
                                HandleCellClick(g_CursorX, g_CursorY);
                }

        RefreshControlButton(g_CurrentButton);
}


/****** P A U S E  G A M E ******/

VOID SuspendGameState(VOID)
{
        ShutdownAudioSystem();
        // remember the oldtimer status.

	if (!fStatusPause)
        	fOldTimerStatus = g_TimerActive;
        if (fStatusPlay)
                g_TimerActive = FALSE;

        SetStatusPause;
}


/****** R E S U M E  G A M E ******/

VOID RestoreGameState(VOID)
{
        // restore to the old timer status.
        if (fStatusPlay)
                g_TimerActive = fOldTimerStatus;

        ClrStatusPause;
}


/****** U P D A T E  B O M B  C O U N T ******/

VOID UpdateMineCount(INT BombAdjust)
{
        g_RemainingMines += BombAdjust;
        RefreshMineDisplay();
}
