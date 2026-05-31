/*************/
/* graphics.c */
/*************/

/*
 * Graphics rendering subsystem - pure GDI implementation
 * 
 * Architecture:
 * - Vector-based rendering (no bitmap resources)
 * - Three font handles: Segoe UI (UI text), Consolas (LED digits), Segoe UI Heavy (cell numbers)
 * - Custom brush management for distinct visual states
 * - Uses DrawEdge for 3D border effects (raised/sunken)
 * 
 * Rendering pipeline:
 * 1. Background fill with appropriate brush
 * 2. Border rendering (EDGE_RAISED for unpressed, EDGE_SUNKEN for revealed)
 * 3. Content rendering (numbers, bombs, flags)
 * 4. Text overlay with TRANSPARENT background mode
 * 
 * Performance considerations:
 * - GetDC/ReleaseDC paired in same scope
 * - Minimal redraws via targeted InvalidateRect
 * - Font selection cached per DC to avoid repeated SelectObject calls
 * 
 * Cell dimensions: 24x24 pixels (modernized from original 16x16)
 */

#include <windows.h>
#include <windowsx.h>

#include "main.h"
#include "resource.h"
#include "graphics.h"
#include "game.h"
#include "sound.h"
#include "preferences.h"

/* Fonts for text and LED rendering */
HFONT g_CellFont = NULL;      /* Segoe UI for text */
HFONT g_DigitFont = NULL;     /* Consolas for LED display */
HFONT g_NumberFont = NULL;    /* Font for cell numbers */

/* GDI object handles - must be explicitly deleted on shutdown */
HPEN hGrayPen = NULL;
HBRUSH hCellBrush = NULL;     /* Background brush for cells */
HBRUSH hRevealedBrush = NULL; /* Background for revealed cells */
HBRUSH hYellowBrush = NULL;   /* For the smiley face */
HBRUSH hBlackBrush = NULL;    /* For bombs/eyes */
HBRUSH hRedBrush = NULL;      /* For explosion/mouth */

/* Cached pens - reused per-frame instead of Create/Delete in draw calls */
HPEN hThinBlackPen = NULL;    /* 1px black - bomb body outline */
HPEN hFusePen = NULL;         /* 2px black - bomb fuse */
HPEN hWhitePen = NULL;        /* 1px white - bomb highlight */
HPEN hRedXPen = NULL;         /* 2px red   - wrong flag X */

/* Color palette for numbers 1-8 (index 0 unused) */
static const COLORREF rgNumColors[9] = {
    RGB(0, 0, 0),       /* 0: not used */
    RGB(0, 0, 255),     /* 1: blue */
    RGB(0, 128, 0),     /* 2: green */
    RGB(255, 0, 0),     /* 3: red */
    RGB(0, 0, 128),     /* 4: dark blue */
    RGB(128, 0, 0),     /* 5: dark red */
    RGB(0, 128, 128),   /* 6: teal */
    RGB(0, 0, 0),       /* 7: black */
    RGB(128, 128, 128)  /* 8: gray */
};

extern INT dypCaption;
extern INT dypMenu;
extern INT dypBorder;
extern INT dxpBorder;

/*** External Data ***/

extern HWND   g_MainWindow;
extern HANDLE g_AppInstance;

extern PREF   g_GameConfig;
extern CHAR   g_GameGrid[cBlkMax];

extern INT g_WindowWidth;
extern INT g_WindowHeight;
extern INT g_GameStatus;

extern INT g_ElapsedSeconds;
extern INT g_RemainingMines;
extern INT g_RevealedCells;
extern INT g_GridWidth;
extern INT g_GridHeight;

extern INT g_CurrentButton;


/****** F I N I T  L O C A L ******/

/* Double-buffering back surface */
static HDC     g_BackDC     = NULL;
static HBITMAP g_BackBitmap = NULL;
static INT     g_BackWidth  = 0;
static INT     g_BackHeight = 0;

static VOID EnsureBackBuffer(VOID)
{
    HDC hDC;

    if (g_BackDC && g_BackWidth == g_WindowWidth && g_BackHeight == g_WindowHeight)
        return;

    if (g_BackBitmap) DeleteObject(g_BackBitmap);
    if (g_BackDC)     DeleteDC(g_BackDC);

    hDC = GetDC(g_MainWindow);
    g_BackDC     = CreateCompatibleDC(hDC);
    g_BackBitmap = CreateCompatibleBitmap(hDC, g_WindowWidth, g_WindowHeight);
    SelectObject(g_BackDC, g_BackBitmap);
    g_BackWidth  = g_WindowWidth;
    g_BackHeight = g_WindowHeight;
    ReleaseDC(g_MainWindow, hDC);

    RenderGameWindow(g_BackDC);
}

static VOID FlushBackBuffer(VOID)
{
    HDC hDC = GetDC(g_MainWindow);
    BitBlt(hDC, 0, 0, g_BackWidth, g_BackHeight, g_BackDC, 0, 0, SRCCOPY);
    ReleaseDC(g_MainWindow, hDC);
}

VOID PaintWindow(HDC hPaintDC)
{
    EnsureBackBuffer();
    RenderGameWindow(g_BackDC);
    BitBlt(hPaintDC, 0, 0, g_BackWidth, g_BackHeight, g_BackDC, 0, 0, SRCCOPY);
}


BOOL InitializeGraphics(VOID)
{
    if (!LoadGraphicsFonts())
        return FALSE;

    ResetGameGrid();

    return TRUE;
}


/****** F L O A D  F O N T S ******/

BOOL LoadGraphicsFonts(VOID)
{
    /* Create standard font for cell text */
    g_CellFont = CreateFontW(
        20,                         /* Height */
        0,                          /* Width */
        0,                          /* Escapement */
        0,                          /* Orientation */
        FW_BOLD,                    /* Weight */
        FALSE,                      /* Italic */
        FALSE,                      /* Underline */
        FALSE,                      /* StrikeOut */
        DEFAULT_CHARSET,            /* CharSet */
        OUT_DEFAULT_PRECIS,         /* OutPrecision */
        CLIP_DEFAULT_PRECIS,        /* ClipPrecision */
        DEFAULT_QUALITY,            /* Quality */
        DEFAULT_PITCH | FF_DONTCARE,/* PitchAndFamily */
        L"Segoe UI"                 /* Face Name */
    );

    /* Create font for cell numbers */
    g_NumberFont = CreateFontW(
        18,                         /* Height */
        0,                          /* Width */
        0,                          /* Escapement */
        0,                          /* Orientation */
        FW_HEAVY,                   /* Weight - very bold */
        FALSE,                      /* Italic */
        FALSE,                      /* Underline */
        FALSE,                      /* StrikeOut */
        DEFAULT_CHARSET,            /* CharSet */
        OUT_DEFAULT_PRECIS,         /* OutPrecision */
        CLIP_DEFAULT_PRECIS,        /* ClipPrecision */
        CLEARTYPE_QUALITY,          /* Quality */
        DEFAULT_PITCH | FF_DONTCARE,/* PitchAndFamily */
        L"Segoe UI"                 /* Face Name */
    );

    /* Create LED font */
    g_DigitFont = CreateFontW(
        26,                         /* Height */
        0,                          /* Width */
        0,                          /* Escapement */
        0,                          /* Orientation */
        FW_BOLD,                    /* Weight */
        FALSE,                      /* Italic */
        FALSE,                      /* Underline */
        FALSE,                      /* StrikeOut */
        DEFAULT_CHARSET,            /* CharSet */
        OUT_DEFAULT_PRECIS,         /* OutPrecision */
        CLIP_DEFAULT_PRECIS,        /* ClipPrecision */
        CLEARTYPE_QUALITY,          /* Quality */
        FIXED_PITCH | FF_MODERN,    /* PitchAndFamily */
        L"Consolas"                 /* Face Name */
    );

    if (g_CellFont == NULL || g_DigitFont == NULL || g_NumberFont == NULL)
        return FALSE;

    /* Create brushes and pens */
    hGrayPen = CreatePen(PS_SOLID, 1, RGB(128, 128, 128));
    
    /* Slightly bluish/aesthetic gray for cells */
    hCellBrush = CreateSolidBrush(RGB(200, 200, 210));     
    hRevealedBrush = CreateSolidBrush(RGB(230, 230, 230)); 
    
    hYellowBrush = CreateSolidBrush(RGB(255, 235, 59)); /* Nice bright yellow */
    hBlackBrush = CreateSolidBrush(RGB(0, 0, 0));
    hRedBrush = CreateSolidBrush(RGB(220, 20, 60));     /* Crimson red */

    hThinBlackPen = CreatePen(PS_SOLID, 1, RGB(0, 0, 0));
    hFusePen      = CreatePen(PS_SOLID, 2, RGB(0, 0, 0));
    hWhitePen     = CreatePen(PS_SOLID, 1, RGB(255, 255, 255));
    hRedXPen      = CreatePen(PS_SOLID, 2, RGB(255, 0, 0));

    return TRUE;
}


/****** F R E E  F O N T S ******/

VOID ReleaseGraphicsFonts(VOID)
{
    if (g_CellFont != NULL) DeleteObject(g_CellFont);
    if (g_DigitFont != NULL) DeleteObject(g_DigitFont);
    if (g_NumberFont != NULL) DeleteObject(g_NumberFont);
    if (hGrayPen != NULL) DeleteObject(hGrayPen);
    if (hCellBrush != NULL) DeleteObject(hCellBrush);
    if (hRevealedBrush != NULL) DeleteObject(hRevealedBrush);
    if (hYellowBrush != NULL) DeleteObject(hYellowBrush);
    if (hBlackBrush != NULL) DeleteObject(hBlackBrush);
    if (hRedBrush != NULL) DeleteObject(hRedBrush);
    if (hThinBlackPen != NULL) DeleteObject(hThinBlackPen);
    if (hFusePen != NULL) DeleteObject(hFusePen);
    if (hWhitePen != NULL) DeleteObject(hWhitePen);
    if (hRedXPen != NULL) DeleteObject(hRedXPen);

    g_CellFont = NULL;
    g_DigitFont = NULL;
    g_NumberFont = NULL;
    hGrayPen = NULL;
    hCellBrush = NULL;
    hRevealedBrush = NULL;
    hYellowBrush = NULL;
    hBlackBrush = NULL;
    hRedBrush = NULL;
    hThinBlackPen = NULL;
    hFusePen = NULL;
    hWhitePen = NULL;
    hRedXPen = NULL;
}


/****** C L E A N  U P ******/

VOID ReleaseResources(VOID)
{
    if (g_BackBitmap) { DeleteObject(g_BackBitmap); g_BackBitmap = NULL; }
    if (g_BackDC)     { DeleteDC(g_BackDC);         g_BackDC     = NULL; }
    ReleaseGraphicsFonts();
    ShutdownAudioSystem();
}


/****** H E L P E R S ******/

/*
 * DrawBomb - Vector-based bomb rendering
 * 
 * Components:
 * 1. Main body: Black filled circle with 1px smooth outline
 * 2. Fuse: 2px thick line extending upward
 * 3. Spark: Red diamond shape at fuse tip
 * 4. Highlight: Small white circle for 3D effect
 * 
 * Antialiasing approach:
 * - SetBkMode(TRANSPARENT) for smooth edges
 * - 1px pen width prevents jagged outlines
 * - Ellipse primitive provides better quality than bitmap scaling
 * 
 * Parameters:
 * - fExploded: If TRUE, fills background with red before drawing bomb
 */

VOID DrawBomb(HDC hDC, RECT* rc, BOOL fExploded)
{
    /* Draw a vector bomb - Smooth & Perfect */
    HBRUSH hOldBrush;
    HPEN hOldPen;
    INT cx = rc->left + (rc->right - rc->left) / 2;
    INT cy = rc->top + (rc->bottom - rc->top) / 2;
    /* Increase radius for better visibility */
    INT r = (rc->right - rc->left) / 3 + 1; 

    if (fExploded) {
        /* Red background for explosion */
        FillRect(hDC, rc, hRedBrush);
    }

    /* Bomb Body (Black Circle) - with 1 pixel thin outline for smoothness */
    hOldBrush = SelectObject(hDC, hBlackBrush);
    hOldPen = SelectObject(hDC, hThinBlackPen);
    
    /* Enable antialiasing for smooth circle */
    SetBkMode(hDC, TRANSPARENT);
    
    /* Draw the bomb body - perfect smooth circle */
    Ellipse(hDC, cx - r, cy - r, cx + r + 1, cy + r + 1);
    
    SelectObject(hDC, hOldPen);

    /* Fuse (Thicker Line) */
    /* Use a thicker pen for the fuse so it's not "blurry" or faint */
    SelectObject(hDC, hFusePen);
    
    MoveToEx(hDC, cx, cy - r + 4, NULL);
    LineTo(hDC, cx, cy - r - 5);
    LineTo(hDC, cx + 4, cy - r - 7);

    SelectObject(hDC, hOldPen); /* Restore normal pen */

    /* Fuse tip (Red Spark) */
    /* Draw a small diamond or X shape for sharpness */
    SelectObject(hDC, hRedBrush);
    SelectObject(hDC, GetStockObject(NULL_PEN));
    
    POINT pts[4];
    INT tipX = cx + 4;
    INT tipY = cy - r - 7;
    pts[0].x = tipX;     pts[0].y = tipY - 3;
    pts[1].x = tipX + 3; pts[1].y = tipY;
    pts[2].x = tipX;     pts[2].y = tipY + 3;
    pts[3].x = tipX - 3; pts[3].y = tipY;
    Polygon(hDC, pts, 4);

    /* Highlight on bomb (Crisp White Dot) - also with thin pen */
    HPEN hTempPen = SelectObject(hDC, hWhitePen);
    SelectObject(hDC, GetStockObject(WHITE_BRUSH));
    Ellipse(hDC, cx - r/2 - 1, cy - r/2 - 1, cx - r/2 + 3, cy - r/2 + 3);
    
    SelectObject(hDC, hTempPen);
    SelectObject(hDC, hOldPen);
    SelectObject(hDC, hOldBrush);
}

VOID DrawFlag(HDC hDC, RECT* rc)
{
    /* Draw a simple red flag */
    INT cx = rc->left + (rc->right - rc->left) / 2;
    INT cy = rc->top + (rc->bottom - rc->top) / 2;
    HPEN hOldPen = SelectObject(hDC, GetStockObject(BLACK_PEN));
    HBRUSH hOldBrush = SelectObject(hDC, hRedBrush);

    /* Pole */
    MoveToEx(hDC, cx - 2, cy + 8, NULL);
    LineTo(hDC, cx - 2, cy - 8);
    
    /* Base */
    MoveToEx(hDC, cx - 5, cy + 8, NULL);
    LineTo(hDC, cx + 5, cy + 8);

    /* Flag triangle */
    POINT pts[3];
    pts[0].x = cx - 2; pts[0].y = cy - 8;
    pts[1].x = cx + 8; pts[1].y = cy - 4;
    pts[2].x = cx - 2; pts[2].y = cy;
    Polygon(hDC, pts, 3);

    SelectObject(hDC, hOldBrush);
    SelectObject(hDC, hOldPen);
}

/****** D R A W  C E L L ******/

/*
 * Render single cell with appropriate visual state
 * 
 * Rendering order:
 * 1. Background fill (hCellBrush for unrevealed, hRevealedBrush for revealed)
 * 2. Border (EDGE_RAISED for 3D button, EDGE_SUNKEN for flat revealed)
 * 3. Content overlay (numbers, bombs, flags, question marks)
 * 
 * Cell types:
 * - iBlk0-8: Revealed numbers showing adjacent mine count
 * - iBlkBombDn/Up: Mine (revealed/flagged)
 * - iBlkExplode: Detonated mine with red background
 * - iBlkWrong: Incorrectly flagged cell (flag with X overlay)
 * - iBlkGuessUp/Dn: Question mark marker
 * - iBlkBlankUp: Unrevealed blank cell
 * 
 * Text rendering:
 * - Numbers use color-coded palette (blue=1, green=2, red=3, etc.)
 * - GetTextExtentPoint32 for pixel-perfect centering
 * - TRANSPARENT background mode prevents rectangular artifacts
 */

VOID RenderCell(HDC hDC, INT x, INT y)
{
    INT iBlk = GET_CELL_TYPE(x, y);
    INT xPos = (x - 1) * dxBlk + dxGridOff;
    INT yPos = (y - 1) * dyBlk + dyGridOff;
    RECT rc;
    HFONT hOldFont;
    COLORREF oldColor;
    INT oldBkMode;
    SIZE sz;

    rc.left = xPos;
    rc.top = yPos;
    rc.right = xPos + dxBlk;
    rc.bottom = yPos + dyBlk;

    /* 1. Draw Background and Border */
    if (iBlk <= iBlk8 || iBlk == iBlkWrong || iBlk == iBlkExplode || iBlk == iBlkBombDn) {
        /* REVEALED: Sunken or Flat */
        FillRect(hDC, &rc, hRevealedBrush);
        /* Subtle border for revealed cells */
        DrawEdge(hDC, &rc, BDR_SUNKENOUTER, BF_RECT); 
    } else {
        /* UNREVEALED: Raised 3D */
        FillRect(hDC, &rc, hCellBrush);
        DrawEdge(hDC, &rc, EDGE_RAISED, BF_RECT);
    }

    /* 2. Draw Content */
    oldBkMode = SetBkMode(hDC, TRANSPARENT);
    hOldFont = SelectObject(hDC, g_NumberFont); // Default font

    if (iBlk >= iBlk1 && iBlk <= iBlk8) {
        /* Numbers 1-8 */
        WCHAR szNum[2];
        szNum[0] = L'0' + iBlk;
        szNum[1] = L'\0';

        oldColor = SetTextColor(hDC, rgNumColors[iBlk]);
        GetTextExtentPoint32W(hDC, szNum, 1, &sz);
        TextOutW(hDC,
                 xPos + (dxBlk - sz.cx) / 2,
                 yPos + (dyBlk - sz.cy) / 2,
                 szNum, 1);
        SetTextColor(hDC, oldColor);
    } 
    else if (iBlk == iBlkBombDn || iBlk == iBlkExplode) {
        /* Bomb */
        DrawBomb(hDC, &rc, (iBlk == iBlkExplode));
    }
    else if (iBlk == iBlkBombUp) {
        /* Flag */
        DrawFlag(hDC, &rc);
    }
    else if (iBlk == iBlkWrong) {
        /* Wrong Flag (X over bomb usually, but let's draw an X over a bomb) */
        DrawBomb(hDC, &rc, FALSE);
        /* Red X */
        HPEN hOld = SelectObject(hDC, hRedXPen);
        MoveToEx(hDC, rc.left + 4, rc.top + 4, NULL);
        LineTo(hDC, rc.right - 4, rc.bottom - 4);
        MoveToEx(hDC, rc.right - 4, rc.top + 4, NULL);
        LineTo(hDC, rc.left + 4, rc.bottom - 4);
        SelectObject(hDC, hOld);
    }
    else if (iBlk == iBlkGuessDn || iBlk == iBlkGuessUp) {
        /* Question Mark */
        oldColor = SetTextColor(hDC, RGB(0, 0, 0));
        WCHAR* q = L"?";
        GetTextExtentPoint32W(hDC, q, 1, &sz);
        TextOutW(hDC,
                 xPos + (dxBlk - sz.cx) / 2,
                 yPos + (dyBlk - sz.cy) / 2,
                 q, 1);
        SetTextColor(hDC, oldColor);
    }

    SelectObject(hDC, hOldFont);
    SetBkMode(hDC, oldBkMode);
}


VOID RefreshCell(INT x, INT y)
{
    EnsureBackBuffer();
    RenderCell(g_BackDC, x, y);
    FlushBackBuffer();
}


/****** D R A W  G R I D ******/

VOID RenderGameGrid(HDC hDC)
{
    INT x;
    INT y;

    for (y = 1; y <= g_GridHeight; y++)
    {
        for (x = 1; x <= g_GridWidth; x++)
        {
            RenderCell(hDC, x, y);
        }
    }
}

VOID RefreshGameGrid(VOID)
{
    EnsureBackBuffer();
    RenderGameGrid(g_BackDC);
    FlushBackBuffer();
}


/****** D R A W  L E D ******/

VOID RenderDigitDisplay(HDC hDC, INT x, INT iLed)
{
    WCHAR szDigit[2];
    HFONT hOldFont;
    COLORREF oldTextColor;
    COLORREF oldBkColor;
    INT oldBkMode;
    RECT rc;
    SIZE sz;

    rc.left = x;
    rc.top = dyTopLed;
    rc.right = x + dxLed;
    rc.bottom = dyTopLed + dyLed;

    /* Draw sunken border for LED */
    DrawEdge(hDC, &rc, EDGE_SUNKEN, BF_RECT);
    InflateRect(&rc, -1, -1); /* Inner area */

    /* Black background */
    oldBkColor = SetBkColor(hDC, RGB(0, 0, 0));
    oldBkMode = SetBkMode(hDC, OPAQUE);
    FillRect(hDC, &rc, hBlackBrush);

    if (iLed == iLedBlank) szDigit[0] = L' ';
    else if (iLed == iLedNegative) szDigit[0] = L'-';
    else szDigit[0] = L'0' + iLed;
    szDigit[1] = L'\0';

    /* Draw red digit */
    hOldFont = SelectObject(hDC, g_DigitFont);
    oldTextColor = SetTextColor(hDC, RGB(255, 0, 0));
    SetBkMode(hDC, TRANSPARENT);

    GetTextExtentPoint32W(hDC, szDigit, 1, &sz);
    TextOutW(hDC,
             x + (dxLed - sz.cx) / 2,
             dyTopLed + (dyLed - sz.cy) / 2,
             szDigit, 1);

    SetTextColor(hDC, oldTextColor);
    SetBkColor(hDC, oldBkColor);
    SetBkMode(hDC, oldBkMode);
    SelectObject(hDC, hOldFont);
}


/****** D R A W  B O M B  C O U N T ******/

VOID RenderMineDisplay(HDC hDC)
{
    INT iLed;
    INT cBombs;

    DWORD dwDCLayout = GetLayout(hDC);
    if (dwDCLayout & LAYOUT_RTL) SetLayout(hDC, 0);

    if (g_RemainingMines < 0) {
        iLed = iLedNegative;
        cBombs = (-g_RemainingMines) % 100;
    } else {
        iLed = g_RemainingMines / 100;
        cBombs = g_RemainingMines % 100;
    }

    RenderDigitDisplay(hDC, dxLeftBomb, iLed);
    RenderDigitDisplay(hDC, dxLeftBomb + dxLed, cBombs / 10);
    RenderDigitDisplay(hDC, dxLeftBomb + dxLed + dxLed, cBombs % 10);

    if (dwDCLayout & LAYOUT_RTL) SetLayout(hDC, dwDCLayout);
}

VOID RefreshMineDisplay(VOID)
{
    EnsureBackBuffer();
    RenderMineDisplay(g_BackDC);
    FlushBackBuffer();
}


/****** D R A W  T I M E ******/

VOID RenderTimeDisplay(HDC hDC)
{
    INT iLed = g_ElapsedSeconds;
    DWORD dwDCLayout = GetLayout(hDC);
    if (dwDCLayout & LAYOUT_RTL) SetLayout(hDC, 0);

    RenderDigitDisplay(hDC, g_WindowWidth - (dxRightTime + 3 * dxLed + dxpBorder), iLed / 100);
    RenderDigitDisplay(hDC, g_WindowWidth - (dxRightTime + 2 * dxLed + dxpBorder), (iLed %= 100) / 10);
    RenderDigitDisplay(hDC, g_WindowWidth - (dxRightTime + dxLed + dxpBorder), iLed % 10);

    if (dwDCLayout & LAYOUT_RTL) SetLayout(hDC, dwDCLayout);
}

VOID RefreshTimeDisplay(VOID)
{
    EnsureBackBuffer();
    RenderTimeDisplay(g_BackDC);
    FlushBackBuffer();
}


/****** D R A W  B U T T O N (F A C E) ******/

VOID DrawFaceFeature(HDC hDC, INT cx, INT cy, INT state)
{
    /* Common: Eyes */
    HBRUSH hOldBrush = SelectObject(hDC, hBlackBrush);
    
    if (state == iButtonLose) {
        /* X Eyes */
        HPEN hPen = CreatePen(PS_SOLID, 2, RGB(0,0,0));
        HPEN hOldPen = SelectObject(hDC, hPen);
        // Left X
        MoveToEx(hDC, cx - 8, cy - 8, NULL); LineTo(hDC, cx - 4, cy - 4);
        MoveToEx(hDC, cx - 4, cy - 8, NULL); LineTo(hDC, cx - 8, cy - 4);
        // Right X
        MoveToEx(hDC, cx + 4, cy - 8, NULL); LineTo(hDC, cx + 8, cy - 4);
        MoveToEx(hDC, cx + 8, cy - 8, NULL); LineTo(hDC, cx + 4, cy - 4);
        SelectObject(hDC, hOldPen);
        DeleteObject(hPen);
    } else if (state == iButtonWin) {
        /* Sunglasses */
        POINT ptsL[] = {{cx-10, cy-6}, {cx-2, cy-6}, {cx-4, cy+2}, {cx-10, cy+2}};
        POINT ptsR[] = {{cx+2, cy-6}, {cx+10, cy-6}, {cx+10, cy+2}, {cx+4, cy+2}};
        Polygon(hDC, ptsL, 4);
        Polygon(hDC, ptsR, 4);
        /* Bridge */
        MoveToEx(hDC, cx-2, cy-4, NULL); LineTo(hDC, cx+2, cy-4);
    } else {
        /* Normal Eyes */
        Ellipse(hDC, cx - 7, cy - 7, cx - 3, cy - 3);
        Ellipse(hDC, cx + 3, cy - 7, cx + 7, cy - 3);
    }

    /* Mouth */
    if (state == iButtonHappy || state == iButtonWin) {
        /* Smile */
        Arc(hDC, cx - 8, cy - 4, cx + 8, cy + 8, cx - 8, cy + 2, cx + 8, cy + 2);
    } else if (state == iButtonCaution) {
        /* 'O' Mouth */
        Ellipse(hDC, cx - 3, cy + 2, cx + 3, cy + 8);
    } else if (state == iButtonLose) {
        /* Frown */
        Arc(hDC, cx - 8, cy + 4, cx + 8, cy + 12, cx + 8, cy + 10, cx - 8, cy + 10);
    }

    SelectObject(hDC, hOldBrush);
}

VOID RenderControlButton(HDC hDC, INT iButton)
{
    RECT rc;
    INT xCenter = (g_WindowWidth - dxButton) / 2;
    INT yCenter = dyTopLed + dyButton / 2;
    
    rc.left = xCenter;
    rc.top = dyTopLed;
    rc.right = xCenter + dxButton;
    rc.bottom = dyTopLed + dyButton;

    /* Draw Button Border */
    if (iButton == iButtonDown) {
        DrawEdge(hDC, &rc, EDGE_SUNKEN, BF_RECT);
        InflateRect(&rc, -1, -1); // Shift content slightly
        OffsetRect(&rc, 1, 1);
    } else {
        DrawEdge(hDC, &rc, EDGE_RAISED, BF_RECT);
        InflateRect(&rc, -1, -1);
    }

    /* Fill Button Background (Standard Gray) */
    FillRect(hDC, &rc, GetStockObject(LTGRAY_BRUSH));

    /* Draw Yellow Face */
    /* Circle radius */
    INT r = (dxButton - 8) / 2;
    HBRUSH hOldBrush = SelectObject(hDC, hYellowBrush);
    
    /* THICK OUTLINE for the face */
    HPEN hFacePen = CreatePen(PS_SOLID, 1, RGB(0,0,0));
    HPEN hOldPen = SelectObject(hDC, hFacePen);

    Ellipse(hDC, xCenter + dxButton/2 - r, yCenter - r, xCenter + dxButton/2 + r, yCenter + r);
    
    SelectObject(hDC, hOldPen);
    DeleteObject(hFacePen);

    /* Draw Features */
    DrawFaceFeature(hDC, xCenter + dxButton/2, yCenter, iButton);

    SelectObject(hDC, hOldBrush);
}

VOID RefreshControlButton(INT iButton)
{
    EnsureBackBuffer();
    RenderControlButton(g_BackDC, iButton);
    FlushBackBuffer();
}


/****** D R A W  B O R D E R ******/

VOID RenderWindowBorder(HDC hDC)
{
    RECT rc;

    /* 1. Main Window Outer Frame */
    /* Draws a raised border around the entire window client area */
    GetClientRect(g_MainWindow, &rc);
    /* Invalidate just to be sure we cover everything? No, just draw edge. */
    DrawEdge(hDC, &rc, EDGE_RAISED, BF_RECT);


    /* 2. Game Grid Border - Explicitly calculated around the cells */
    /* This ensures we don't have "missing" walls */
    rc.left   = dxGridOff;
    rc.top    = dyGridOff;
    rc.right  = dxGridOff + g_GridWidth * dxBlk;
    rc.bottom = dyGridOff + g_GridHeight * dyBlk;
    
    /* Inflate to put the border *outside* the cells */
    InflateRect(&rc, 3, 3);
    
    DrawEdge(hDC, &rc, EDGE_SUNKEN, BF_RECT);

    /* 3. Bomb Counter Border */
    rc.left = dxLeftBomb - 2;
    rc.top = dyTopLed - 2;
    rc.right = dxLeftBomb + 3 * dxLed + 2;
    rc.bottom = dyTopLed + dyLed + 2;
    DrawEdge(hDC, &rc, EDGE_SUNKEN, BF_RECT);

    /* 4. Time Counter Border */
    rc.left = g_WindowWidth - (dxRightTime + 3 * dxLed + dxpBorder) - 2;
    rc.top = dyTopLed - 2;
    rc.right = rc.left + 3 * dxLed + 4;
    rc.bottom = dyTopLed + dyLed + 2;
    DrawEdge(hDC, &rc, EDGE_SUNKEN, BF_RECT);
}


/****** D R A W  S C R E E N ******/

VOID RenderGameWindow(HDC hDC)
{
    RECT rc;
    SetRect(&rc, 0, 0, g_WindowWidth, g_WindowHeight);
    FillRect(hDC, &rc, GetSysColorBrush(COLOR_WINDOW));

    RenderWindowBorder(hDC);
    RenderMineDisplay(hDC);
    RenderControlButton(hDC, g_CurrentButton);
    RenderTimeDisplay(hDC);
    RenderGameGrid(hDC);
}

VOID RefreshGameWindow(VOID)
{
    EnsureBackBuffer();
    RenderGameWindow(g_BackDC);
    FlushBackBuffer();
}