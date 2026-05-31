/******************/
/* file: graphics.h */
/******************/

/*
 * Graphics subsystem interface
 * 
 * Defines rendering dimensions and provides function prototypes
 * for all GDI drawing operations.
 * 
 * Layout calculations:
 * - Cell grid starts at (dxGridOff, dyGridOff)
 * - LED displays positioned at fixed offsets from window edges
 * - Smiley button centered horizontally at top
 * 
 * Coordinate system:
 * - All measurements in pixels
 * - Origin (0,0) at top-left of window client area
 * - Positive X rightward, positive Y downward
 */

/*** Cell/Block Dimensions (modernized to 24x24) ***/

/* Individual element dimensions */
#define dxBlk 24   /* Cell width in pixels (modernized from 16) */
#define dyBlk 24   /* Cell height in pixels */

#define dxLed 18   /* LED digit width */
#define dyLed 30   /* LED digit height */

#define dxButton 32   /* Smiley button width */
#define dyButton 32   /* Smiley button height */

#define dxFudge 2     /* Reserved spacing adjustment */

/* Window margins and padding */
#define dxLeftSpace 12     /* Left border width */
#define dxRightSpace 12    /* Right border width */
#define dyTopSpace 12      /* Top border height */
#define dyBottomSpace 12   /* Bottom border height */

/* Grid positioning (absolute coordinates in window) */
#define dxGridOff dxLeftSpace                  /* Grid X offset */
#define dyGridOff (dyTopLed+dyLed+16)         /* Grid Y offset (below LED displays) */

/* LED display positioning */
#define dxLeftBomb  (dxLeftSpace + 5)         /* Mine counter X position */
#define dxRightTime (dxRightSpace + 5)        /* Timer X offset from right edge */
#define dyTopLed    (dyTopSpace + 4)          /* LED displays Y position */


/*** Macros ***/

#ifdef DEBUG

//-protect-#define Oops(szMsg)
//	MessageBox(NULL, szMsg, "Oops", MB_OK | MB_ICONHAND)

#else
#define Oops(szMsg)
#endif



/*** Routines ***/

BOOL InitializeGraphics(VOID);
VOID ReleaseResources(VOID);

VOID RenderCell(HDC, INT, INT);
VOID RefreshCell(INT, INT);

VOID RenderControlButton(HDC, INT);
VOID RefreshControlButton(INT);
VOID RenderGameGrid(HDC);
VOID RefreshGameGrid(VOID);
VOID RenderMineDisplay(HDC);
VOID RefreshMineDisplay(VOID);
VOID RenderTimeDisplay(HDC);
VOID RefreshTimeDisplay(VOID);
VOID RenderGameWindow(HDC);
VOID RefreshGameWindow(VOID);
VOID PaintWindow(HDC);

BOOL LoadGraphicsFonts(VOID);
VOID ReleaseGraphicsFonts(VOID);

