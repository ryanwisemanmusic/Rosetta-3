/****************************************************************************
    PROGRAM: Minesweeper
    AUTHOR:  Marek Wesolowski
****************************************************************************/

/*
 * Main application module - Win32 window management and message processing
 * 
 * Architecture:
 * - Standard WndProc message pump pattern
 * - Mouse capture for drag operations with chord mode support
 * - DWM integration for Windows 11 visual features (rounded corners, Mica)
 * - Menu state synchronization and accelerator handling
 * 
 * Key features:
 * - Icon extraction from moricons.dll (index 80 - bomb icon)
 * - Multi-monitor aware window positioning
 * - Dynamic menu height calculation for multi-line layouts
 * - XYZZY cheat code implementation (state machine pattern)
 * 
 * Platform support:
 * - Minimum: Windows XP (Common Controls v6.0 via manifest)
 * - Optimal: Windows 11 (DWM rounded corners, Mica backdrop)
 * - Graceful degradation when modern features unavailable
 */

/* ========================================================================
   SYSTEM INCLUDES - Windows API Headers
   ======================================================================== */
#include <windows.h>
#include <windowsx.h>
#include <shellapi.h>
#include <commctrl.h>
#include <dwmapi.h>

/* ========================================================================
   LIBRARY LINKAGE - Import required Windows libraries
   ======================================================================== */
#pragma comment(lib, "moricons.lib")
#pragma comment(lib, "dwmapi.lib")
#pragma comment(lib, "comctl32.lib")

/* ========================================================================
   APPLICATION INCLUDES - Project-specific headers
   ======================================================================== */
#include "main.h"
#include "game.h"
#include "graphics.h"
#include "resource.h"
#include "preferences.h"
#include "utilities.h"
#include "sound.h"

/* ========================================================================
   PLATFORM COMPATIBILITY DEFINITIONS
   ======================================================================== */
#ifndef WM_ENTERMENULOOP
#define WM_ENTERMENULOOP 0x0211
#define WM_EXITMENULOOP  0x0212
#endif

BOOL bInitMinimized;  /* Prevents MoveWindow/InvalidateRect when initially minimized */

/* Core application handles */
HANDLE g_AppInstance;
HWND   g_MainWindow;
HMENU  g_MenuHandle;

/* Application icon loaded from moricons.dll */
HICON   hIconMain;

/* Mouse button state tracking for chord mode */
BOOL g_LeftButtonDown = FALSE;
BOOL g_ChordMode       = FALSE;
BOOL fIgnoreClick = FALSE;

/* System metrics cached for performance */
INT dypCaption;
INT dypMenu;
INT dypBorder;
INT dxpBorder;

/* Game state flags (bitmasked: fPlay|fPause|fIcon|fDemo) */
INT  g_GameStatus = (fDemo + fIcon);
BOOL fLocalPause = FALSE;

/* Window title string (shared with class name) */
TCHAR g_WindowClass[cchNameMax];
#define szWindowTitle g_WindowClass

/* String resources loaded at startup */
TCHAR szTime[cchNameMax];
TCHAR szDefaultName[cchNameMax];


extern BOOL g_SettingsDirty;

extern INT g_CursorX;
extern INT g_CursorY;
extern INT g_CurrentButton;

extern INT g_GridWidth;
extern INT g_GridHeight;

extern PREF g_GameConfig;
extern INT  g_RevealedCells;

INT g_WindowWidth;
INT g_WindowHeight;
INT dypCaption;
INT dypMenu;
INT dypAdjust;


INT idRadCurr = 0;

#define iPrefMax 3
#define idRadMax 3

INT	rgPrefEditID[iPrefMax] =
	{ID_EDIT_MINES, ID_EDIT_HEIGHT, ID_EDIT_WIDTH};

INT	rgLevelData[idRadMax][iPrefMax] = {
	{10, MINHEIGHT,  MINWIDTH, },
	{40, 16, 16,},
	{99, 16, 30,}
	};


#ifndef DEBUG
#define XYZZY
#define cchXYZZY 5
INT     iXYZZY = 0;
TCHAR   szXYZZY[cchXYZZY+1] = TEXT("XYZZY");
extern  CHAR g_GameGrid[cBlkMax];
#endif


LRESULT  APIENTRY WindowMessageHandler(HWND,  UINT, WPARAM, LPARAM);
INT_PTR  APIENTRY PreferencesDialogHandler(HWND,  UINT, WPARAM, LPARAM);
INT_PTR  APIENTRY HighScoresDialogHandler(HWND,  UINT, WPARAM, LPARAM);
INT_PTR  APIENTRY NameEntryDialogHandler(HWND,  UINT, WPARAM, LPARAM);


/****** E N A B L E  M O D E R N  S T Y L E ******/

/*
 * Apply Windows 11 visual enhancements
 * 
 * Features:
 * 1. Rounded window corners (DWMWA_WINDOW_CORNER_PREFERENCE)
 * 2. Mica backdrop effect (DWMWA_SYSTEMBACKDROP_TYPE)
 * 
 * Compatibility:
 * - Constants defined locally for older SDK compatibility
 * - DwmSetWindowAttribute fails gracefully on Windows 10 and earlier
 * - No error checking needed - purely cosmetic enhancement
 * 
 * Visual impact:
 * - Rounded corners: Available on Windows 11 21H2+
 * - Mica effect: Available on Windows 11 22H2+
 */

VOID ApplyModernWindowStyle(HWND hwnd)
{
    /* Enable rounded corners on Windows 11 */
    #ifndef DWMWA_WINDOW_CORNER_PREFERENCE
    #define DWMWA_WINDOW_CORNER_PREFERENCE 33
    #endif
    #ifndef DWMWCP_ROUND
    #define DWMWCP_ROUND 2
    #endif
    
    /* Enable Mica background effect (Windows 11 22H2+) */
    #ifndef DWMWA_SYSTEMBACKDROP_TYPE
    #define DWMWA_SYSTEMBACKDROP_TYPE 38
    #endif
    #ifndef DWMSBT_MAINWINDOW
    #define DWMSBT_MAINWINDOW 2  /* Mica effect */
    #endif

    DWORD cornerPref = DWMWCP_ROUND;
    DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE,
                          &cornerPref, sizeof(cornerPref));
    
    /* Apply Mica backdrop - graceful fallback on older Windows */
    DWORD backdropType = DWMSBT_MAINWINDOW;
    DwmSetWindowAttribute(hwnd, DWMWA_SYSTEMBACKDROP_TYPE,
                          &backdropType, sizeof(backdropType));
}


/****** W I N  M A I N ******/

/* Forward declaration for the application logic */
int WINAPI WinMineApp(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow);

/* 
 * Custom entry point to support /NODEFAULTLIB (No CRT)
 * This function initializes the necessary startup info and calls the main application logic.
 */
void WINAPI WinMineEntry(void)
{
    /* Get the instance handle for the current module */
    HINSTANCE hInstance = GetModuleHandle(NULL);
    
    /* Get command line arguments (ANSI version to match LPSTR) */
    /* Note: This returns the full command line including the executable path. */
    LPSTR lpCmdLine = GetCommandLineA();
    
    /* Determine the initial window show state */
    STARTUPINFOA si;
    INT nCmdShow = SW_SHOWDEFAULT;

    si.cb = sizeof(si);  /* GetStartupInfoA fills the rest — no zeroing needed */

    GetStartupInfoA(&si);
    if (si.dwFlags & STARTF_USESHOWWINDOW) {
        nCmdShow = si.wShowWindow;
    }

    /* Transfer control to the main application logic */
    ExitProcess(WinMineApp(hInstance, NULL, lpCmdLine, nCmdShow));
}

int WINAPI WinMineApp(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	MSG msg;
	HANDLE hAccel;

	g_AppInstance = hInstance;

	InitializeConstants();

    bInitMinimized = (nCmdShow == SW_SHOWMINNOACTIVE) ||
                     (nCmdShow == SW_SHOWMINIMIZED) ;


	{
	WNDCLASS  wc;
	INITCOMMONCONTROLSEX icc;   // common control registration.

	// Register the common controls.
	icc.dwSize = sizeof(INITCOMMONCONTROLSEX);
	icc.dwICC  = ICC_ANIMATE_CLASS | ICC_BAR_CLASSES | ICC_COOL_CLASSES | ICC_HOTKEY_CLASS | ICC_LISTVIEW_CLASSES | 
			ICC_PAGESCROLLER_CLASS | ICC_PROGRESS_CLASS | ICC_TAB_CLASSES | ICC_UPDOWN_CLASS | ICC_USEREX_CLASSES;
	InitCommonControlsEx(&icc);


	/* Extract smile icon from moricons.dll - icon index 22 */
	HICON hExtractedIcon = ExtractIconA(g_AppInstance, "moricons.dll", 22);

	/* Fallback to default application icon if extraction fails */
	if ((UINT_PTR)hExtractedIcon <= 1) {
		hIconMain = LoadIcon(NULL, IDI_APPLICATION);
	} else {
		hIconMain = hExtractedIcon;
	}

	wc.style = 0;
	wc.lpfnWndProc   = WindowMessageHandler;
	wc.cbClsExtra    = 0;
	wc.cbWndExtra    = 0;
	wc.hInstance     = g_AppInstance;
	wc.hIcon         = hIconMain;
	wc.hCursor       = LoadCursor(NULL, IDC_ARROW);
	wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
	wc.lpszMenuName  = NULL;
	wc.lpszClassName = g_WindowClass;

	if (!RegisterClass(&wc))
		return FALSE;
	}

	g_MenuHandle = LoadMenu(g_AppInstance, MAKEINTRESOURCE(ID_MENU));
	hAccel = LoadAccelerators(g_AppInstance, MAKEINTRESOURCE(ID_MENU_ACCEL));


	LoadConfiguration();

	{
	RECT rc = {0, 0, g_WindowWidth, g_WindowHeight};
	AdjustWindowRect(&rc, WS_OVERLAPPED | WS_MINIMIZEBOX | WS_CAPTION | WS_SYSMENU, TRUE);
	g_MainWindow = CreateWindow(g_WindowClass, szWindowTitle,
		WS_OVERLAPPED | WS_MINIMIZEBOX | WS_CAPTION | WS_SYSMENU,
		g_GameConfig.xWindow, g_GameConfig.yWindow,
		rc.right - rc.left, rc.bottom - rc.top,
		NULL, NULL, g_AppInstance, NULL);
	}

	if (!g_MainWindow)
		{
		DisplayErrorMessage(1000);
		return FALSE;
		}

	/* Enable Windows 11 modern styling (rounded corners) */
	ApplyModernWindowStyle(g_MainWindow);

	ResizeGameWindow(fCalc);


	if (!InitializeGraphics())
		{
		DisplayErrorMessage(ID_ERR_MEM);
		return FALSE;
		}

	SetMenuVisibility(g_GameConfig.fMenu);

	InitializeGameBoard();

	ShowWindow(g_MainWindow, SW_SHOWNORMAL);
	UpdateWindow(g_MainWindow);

    bInitMinimized = FALSE;

	while (GetMessage(&msg, NULL, 0, 0))
		{
		if (!TranslateAccelerator(g_MainWindow, hAccel, &msg))
			{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
			}
		}

	ReleaseResources();

    if (g_SettingsDirty)
        SaveConfiguration();

	/* Clean up extracted icon if it was dynamically loaded */
	if (hIconMain && hIconMain != LoadIcon(NULL, IDI_APPLICATION)) {
		DestroyIcon(hIconMain);
	}

	return ((INT) msg.wParam);
}


/****** F  L O C A L  B U T T O N ******/

BOOL HandleSmileyButtonClick(LPARAM lParam)
{
	BOOL fDown = TRUE;
	RECT rcCapt;
	MSG msg;

	msg.pt.x = LOWORD(lParam);
	msg.pt.y = HIWORD(lParam);

	rcCapt.right  = dxButton + (rcCapt.left = (g_WindowWidth-dxButton) >> 1);
	rcCapt.bottom = dyButton +	(rcCapt.top = dyTopLed);

	if (!PtInRect(&rcCapt, msg.pt))
		return FALSE;

	SetCapture(g_MainWindow);

	RefreshControlButton(iButtonDown);

	MapWindowPoints(g_MainWindow , NULL , (LPPOINT) &rcCapt , 2);

	while (TRUE)
		{
      if (PeekMessage(&msg, g_MainWindow, WM_MOUSEFIRST, WM_MOUSELAST, PM_REMOVE))
			{

		switch (msg.message)
			{
	   case WM_LBUTTONUP:
			if (fDown)
				{
				if (PtInRect(&rcCapt, msg.pt))
					{
					RefreshControlButton(g_CurrentButton = iButtonHappy);
					InitializeGameBoard();
					}
				}
			ReleaseCapture();
			return TRUE;

	   case WM_MOUSEMOVE:
			if (PtInRect(&rcCapt, msg.pt))
		   	{
				if (!fDown)
					{
               fDown = TRUE;
					RefreshControlButton(iButtonDown);
					}
				}
			else
				{
				if (fDown)
					{
               fDown = FALSE;
					RefreshControlButton(g_CurrentButton);
					}
				}
		default:
			;
			}	/* switch */
		}	

    	}	/* while */
}



/****** F I X  M E N U S ******/

VOID UpdateMenuStates(VOID)
{
	SetMenuCheckmark(IDM_BEGIN,  g_GameConfig.wGameType == wGameBegin);
	SetMenuCheckmark(IDM_INTER,  g_GameConfig.wGameType == wGameInter);
	SetMenuCheckmark(IDM_EXPERT, g_GameConfig.wGameType == wGameExpert);
	SetMenuCheckmark(IDM_CUSTOM, g_GameConfig.wGameType == wGameOther);

	SetMenuCheckmark(IDM_MARK,   g_GameConfig.fMark);
	SetMenuCheckmark(IDM_SOUND,  g_GameConfig.fSound);
}



/****** D O  P R E F ******/

VOID ShowPreferencesDialog(VOID)
{

	DialogBox(g_AppInstance, MAKEINTRESOURCE(ID_DLG_PREF), g_MainWindow, PreferencesDialogHandler);

    g_GameConfig.wGameType = wGameOther;
	UpdateMenuStates();
	g_SettingsDirty = TRUE;
	InitializeGameBoard();
}


/****** D O  E N T E R  N A M E ******/

VOID ShowNameEntryDialog(VOID)
{
	DialogBox(g_AppInstance, MAKEINTRESOURCE(ID_DLG_ENTER), g_MainWindow, NameEntryDialogHandler);
	g_SettingsDirty = TRUE;
}


/****** D O  D I S P L A Y  B E S T ******/

VOID ShowHighScoresDialog(VOID)
{
	DialogBox(g_AppInstance, MAKEINTRESOURCE(ID_DLG_BEST), g_MainWindow, HighScoresDialogHandler);
}

				
/****** M A I N  W N D  P R O C ******/

LRESULT  APIENTRY WindowMessageHandler(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{

	switch (message)
		{
	case WM_WINDOWPOSCHANGED:
		if (!fStatusIcon)
			{
			g_GameConfig.xWindow = ((LPWINDOWPOS) (lParam))->x;
			g_GameConfig.yWindow = ((LPWINDOWPOS) (lParam))->y;
			g_SettingsDirty = TRUE;
			}	
		break;

	case WM_SYSCOMMAND:
		switch (wParam & 0xFFF0)
			{
		case SC_MINIMIZE:

            		SuspendGameState();
			SetStatusPause;
			SetStatusIcon;
			break;
			
		case SC_RESTORE:
			ClrStatusPause;
			ClrStatusIcon;
			RestoreGameState();

//Japan Bug fix: 1/19/93 Enable the first click after restoring from icon.
			fIgnoreClick = FALSE;
			break;

		default:
			break;
			}
			
		break;


	case WM_COMMAND:
	    {
	    switch(LOWORD(wParam)) {

	    case IDM_NEW:
		    InitializeGameBoard();
		    break;
						
	    /** IDM_NEW **/
	    case IDM_EXIT:
		    ShowWindow(g_MainWindow, SW_HIDE);
#ifdef ORGCODE
		    goto LExit;
#else
            SendMessage(g_MainWindow, WM_SYSCOMMAND, SC_CLOSE, 0);
            return(0);
#endif
	    /** IDM_SKILL **/
	    case IDM_BEGIN:
	    case IDM_INTER:
	    case IDM_EXPERT:
		    g_GameConfig.wGameType = (WORD)(LOWORD(wParam) - IDM_BEGIN);
		    g_GameConfig.Mines  = rgLevelData[g_GameConfig.wGameType][0];
		    g_GameConfig.Height = rgLevelData[g_GameConfig.wGameType][1];
		    g_GameConfig.Width  = rgLevelData[g_GameConfig.wGameType][2];
		    g_SettingsDirty = TRUE;
		    InitializeGameBoard();   /* ResizeGameWindow is called at the end */
		    UpdateMenuStates();      /* only refresh checkmarks, no extra resize */
		    break;

	    case IDM_CUSTOM:
		    ShowPreferencesDialog();
		    break;

	    /** IDM_OPTIONS **/
	    case IDM_SOUND:
		    if (g_GameConfig.fSound)
			    {
			    ShutdownAudioSystem();
			    g_GameConfig.fSound = FALSE;
			    }
		    else
			    {
			    g_GameConfig.fSound = InitializeAudioSystem();
			    }
		    goto LUpdateMenu;

	    case IDM_MARK:
		    g_GameConfig.fMark = !g_GameConfig.fMark;
	    /* IE	goto LUpdateMenu;	*/

    LUpdateMenu:
		    g_SettingsDirty = TRUE;
		    SetMenuVisibility(g_GameConfig.fMenu);
		    break;

	    case IDM_BEST:
		    ShowHighScoresDialog();
		    break;


	    /** IDM_HELP **/
	    case IDM_HELP_ABOUT:
		    ShowAboutDialog();
		    return 0;

	    default:
		    break;
	    }

	} /**** END OF MENUS ****/

		break;



	case WM_KEYDOWN:
		switch (wParam)
			{

#if 0
		case VK_F1:
			ShowHelpSystem(HELP_INDEX, 0L);
			break;

		case VK_F2:
			InitializeGameBoard();
			break;

		case VK_F3:
			break;

#endif
		case VK_F4:
			if (FSoundSwitchable())
				if (FSoundOn())
					{
					ShutdownAudioSystem();
					g_GameConfig.fSound = fsoundOff;
					}
				else
					g_GameConfig.fSound = InitializeAudioSystem();
			break;

		case VK_F5:
			if (FMenuSwitchable())
				SetMenuVisibility(fmenuOff);
			break;

		case VK_F6:
			if (FMenuSwitchable())
				SetMenuVisibility(fmenuOn);
			break;

#ifdef XYZZY
	case VK_SHIFT:
		if (iXYZZY >= cchXYZZY)
			{
			iXYZZY ^= 20;
			/* Restore happy face when exiting cheat mode */
			RefreshControlButton(iButtonHappy);
			}
		break;

		default:
			if (iXYZZY < cchXYZZY)
				iXYZZY = (szXYZZY[iXYZZY] == (TCHAR) wParam) ? iXYZZY+1 : 0;
			break;

#else
		default:
			break;
#endif
			}	
		break;

/*  	case WM_QUERYENDSESSION:    SHOULDNT BE USED (JAP)*/

	case WM_DESTROY:
//LExit:
        KillTimer(g_MainWindow, ID_TIMER);
    	PostQuitMessage(0);
	    break;

	case WM_MBUTTONDOWN:
		if (fIgnoreClick)
			{
			fIgnoreClick = FALSE;
			return 0;
			}

		if (!fStatusPlay)
			break;

		g_ChordMode = TRUE;
		goto LBigStep;

	case WM_LBUTTONDOWN:

		if (fIgnoreClick)
			{
			fIgnoreClick = FALSE;
			return 0;
			}

		if (HandleSmileyButtonClick(lParam))
			return 0;

		if (!fStatusPlay)
			break;
		g_ChordMode = (wParam & (MK_SHIFT | MK_RBUTTON)) ? TRUE : FALSE;

LBigStep:
		SetCapture(hWnd);
		g_LeftButtonDown = TRUE;

		g_CursorX = -1;
		g_CursorY = -1;
		RefreshControlButton(iButtonCaution);

case WM_MOUSEMOVE:
    if (g_LeftButtonDown)
        {
        if (g_GameStatus & fPlay)
            UpdateCursorPosition(xBoxFromXpos(LOWORD(lParam)), yBoxFromYpos(HIWORD(lParam)) );
        else
            goto LFixTimeOut;
        }
	#ifdef XYZZY
    /* XYZZY cheat mode: show scared face when hovering over mine */
    else if (iXYZZY != 0)
        if (((iXYZZY == cchXYZZY) && (wParam & MK_CONTROL))
           ||(iXYZZY > cchXYZZY))
        {
        static INT g_LastCheatButton = -1;
        
        g_CursorX = xBoxFromXpos(LOWORD(lParam));
        g_CursorY = yBoxFromYpos(HIWORD(lParam));
        
        if (IsValidPosition(g_CursorX, g_CursorY))
            {
            INT newButton = HasMine(g_CursorX, g_CursorY) ? iButtonCaution : iButtonHappy;
            
            /* Only redraw if state changed to avoid flicker */
            if (newButton != g_LastCheatButton)
                {
                RefreshControlButton(newButton);
                g_LastCheatButton = newButton;
                }
            }
        else
            {
            /* Cursor outside grid - restore happy face */
            if (g_LastCheatButton != iButtonHappy)
                {
                RefreshControlButton(iButtonHappy);
                g_LastCheatButton = iButtonHappy;
                }
            }
        }
#endif
    break;

	case WM_RBUTTONUP:
	case WM_MBUTTONUP:
	case WM_LBUTTONUP:
		if (g_LeftButtonDown)
			{
LFixTimeOut:
			g_LeftButtonDown = FALSE;
			ReleaseCapture();
			if (g_GameStatus & fPlay)
				HandleLeftButtonRelease();
			else
				UpdateCursorPosition(-2,-2);
			}
		break;

	case WM_RBUTTONDOWN:
		if (fIgnoreClick)
			{
			fIgnoreClick = FALSE;
			return 0;
			}

		if(!fStatusPlay)
			break;

		if (g_LeftButtonDown)
			{
			UpdateCursorPosition(-3,-3);
			g_ChordMode = TRUE;
			PostMessage(g_MainWindow, WM_MOUSEMOVE, wParam, lParam);
			}
		else if (wParam & MK_LBUTTON)
			goto LBigStep;
		else if (!fLocalPause)
			ToggleCellMarker(xBoxFromXpos(LOWORD(lParam)), yBoxFromYpos(HIWORD(lParam)) );
		return 0;

	case WM_ACTIVATE:
		/* Window is being activated by a mouse click */
		if (LOWORD(wParam) == 2)
			fIgnoreClick = TRUE;
		break;

	case WM_TIMER:
#ifdef CHEAT
		if (!fLocalPause)
#endif
			UpdateGameTimer();
		return 0;

	case WM_ENTERMENULOOP:
		fLocalPause = TRUE;
		break;

	case WM_EXITMENULOOP:
		fLocalPause = FALSE;
		break;

	case WM_PAINT:
		{
		PAINTSTRUCT ps;
		HDC hDC = BeginPaint(hWnd,&ps);
		PaintWindow(hDC);
		EndPaint(hWnd, &ps);
		}
		return 0;

	default:
		break;

    }

	return (DefWindowProc(hWnd, message, wParam, lParam));
}




/****** DIALOG PROCEDURES ******/

/*** P R E F  D L G  P R O C ***/

INT_PTR  APIENTRY PreferencesDialogHandler(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	switch (message)
		{
	case WM_INITDIALOG:
		SetDlgItemInt(hDlg, ID_EDIT_HEIGHT, g_GameConfig.Height ,FALSE);
		SetDlgItemInt(hDlg, ID_EDIT_WIDTH,  g_GameConfig.Width  ,FALSE);
		SetDlgItemInt(hDlg, ID_EDIT_MINES,  g_GameConfig.Mines  ,FALSE);
		return (TRUE);

	case WM_COMMAND:
		switch(LOWORD(wParam)) {
		case ID_BTN_OK:
		case IDOK:
			{

			g_GameConfig.Height = GetDialogInteger(hDlg, ID_EDIT_HEIGHT, MINHEIGHT, 24);
			g_GameConfig.Width  = GetDialogInteger(hDlg, ID_EDIT_WIDTH,  MINWIDTH,  30);
			g_GameConfig.Mines  = GetDialogInteger(hDlg, ID_EDIT_MINES,  10,
				min(999, (g_GameConfig.Height-1) * (g_GameConfig.Width-1) ) );

			}

			/* Fall Through & Exit */
		case ID_BTN_CANCEL:
		case IDCANCEL:
			EndDialog(hDlg, TRUE);	      /* Exits the dialog box	     */
			return TRUE;

		default:
			break;
			}
        break;
		}

    return (FALSE);			/* Didn't process a message    */
}


/*** S E T  D T E X T ***/

VOID SetBestTimeDialogText(HWND hDlg, INT id, INT time, TCHAR FAR * szName)
{
	TCHAR sz[cchNameMax];

	FormatTime(sz, time);
	SetDlgItemText(hDlg, id, sz);
	SetDlgItemText(hDlg, id+1, szName);
}


/****** B E S T  D L G  P R O C ******/

INT_PTR  APIENTRY HighScoresDialogHandler(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	switch (message)
		{
	case WM_INITDIALOG:
		/* Set dialog icon to match main window */
		SendMessage(hDlg, WM_SETICON, ICON_SMALL, (LPARAM)hIconMain);
		SendMessage(hDlg, WM_SETICON, ICON_BIG, (LPARAM)hIconMain);
		
LReset:	
		SetBestTimeDialogText(hDlg, ID_TIME_BEGIN, g_GameConfig.rgTime[wGameBegin], g_GameConfig.szBegin);
		SetBestTimeDialogText(hDlg, ID_TIME_INTER, g_GameConfig.rgTime[wGameInter],  g_GameConfig.szInter);
		SetBestTimeDialogText(hDlg, ID_TIME_EXPERT, g_GameConfig.rgTime[wGameExpert], g_GameConfig.szExpert);
		return (TRUE);

	case WM_COMMAND:
		switch(LOWORD(wParam)) {
		case ID_BTN_RESET:
			g_GameConfig.rgTime[wGameBegin] = g_GameConfig.rgTime[wGameInter]
				= g_GameConfig.rgTime[wGameExpert] = 999;
			lstrcpy(g_GameConfig.szBegin,  szDefaultName);
			lstrcpy(g_GameConfig.szInter,  szDefaultName);
			lstrcpy(g_GameConfig.szExpert, szDefaultName);
			g_SettingsDirty = TRUE;
			goto LReset;
			
		case ID_BTN_OK:
		case IDOK:
		case ID_BTN_CANCEL:
		case IDCANCEL:
			EndDialog(hDlg, TRUE);	      /* Exits the dialog box	     */
			return TRUE;

		default:
			break;
			}
        break;
		}

	return (FALSE);			/* Didn't process a message    */
}

/****** E N T E R  D L G  P R O C ******/

INT_PTR  APIENTRY NameEntryDialogHandler(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{

	switch (message)
		{
	case WM_INITDIALOG:
		{
		TCHAR sz[cchMsgMax];

		LoadStringResource((WORD)(g_GameConfig.wGameType+ID_MSG_BEGIN), sz, ARRAYSIZE(sz));

		SetDlgItemText(hDlg, ID_TEXT_BEST, sz);

		SendMessage(GetDlgItem(hDlg, ID_EDIT_NAME), EM_SETLIMITTEXT, cchNameMax, 0L);

		SetDlgItemText(hDlg, ID_EDIT_NAME,
			(g_GameConfig.wGameType == wGameBegin) ? g_GameConfig.szBegin :
			(g_GameConfig.wGameType == wGameInter) ? g_GameConfig.szInter :
			 g_GameConfig.szExpert);
		}
		return (TRUE);

	case WM_COMMAND:
		switch(LOWORD(wParam)) {
		case ID_BTN_OK:
		case IDOK:
		case ID_BTN_CANCEL:
		case IDCANCEL:

			GetDlgItemText(hDlg, ID_EDIT_NAME,
				(g_GameConfig.wGameType == wGameBegin) ? g_GameConfig.szBegin :
				(g_GameConfig.wGameType == wGameInter) ? g_GameConfig.szInter :
				 g_GameConfig.szExpert, cchNameMax);

			EndDialog(hDlg, TRUE);	      /* Exits the dialog box	     */
			return TRUE;

		default:
			break;
			}
		}

	return (FALSE);			/* Didn't process a message    */
}





/****** A D J U S T  W I N D O W ******/

// Our verion of GetSystemMetrics
// 
// Tries to return whole screen (include other monitor) info
//

INT GetDisplayMetrics( INT nIndex )
{
    INT Result=0;

    switch( nIndex )
    {
    case SM_CXSCREEN:
        Result= GetSystemMetrics( SM_CXVIRTUALSCREEN );
        if( !Result )
            Result= GetSystemMetrics( SM_CXSCREEN );
        break;

    case SM_CYSCREEN:
        Result= GetSystemMetrics( SM_CYVIRTUALSCREEN );
        if( !Result )
            Result= GetSystemMetrics( SM_CYSCREEN );
        break;

    default:
        Result= GetSystemMetrics( nIndex );
        break;
    }

    return( Result );
}

VOID ResizeGameWindow(INT fAdjust)
{
	INT t;
	RECT rect;
    BOOL bDiffLevel = FALSE;
    RECT rectGame, rectHelp;

	// an extra check
	if (!g_MainWindow)
		return;

	dypAdjust = dypCaption;

	if (FMenuOn())
        {
        // dypMenu is initialized to GetSystemMetrics(SM_CYMENU) + 1,
        // which is the height of one menu line
        dypAdjust += dypMenu;

        // If the menu extends on two lines (because of the large-size
        // font the user has chosen for the menu), increase the size
        // of the window.

        // The two menus : "Game" and "Help" are on the same line, if
        // their enclosing rectangles top match. In that case, we don't
        // need to extend the window size.
        // If the tops do not match, that means they are on two lines.
        // In that case, extend the size of the window by size of
        // one menu line.

        if (g_MenuHandle && GetMenuItemRect(g_MainWindow, g_MenuHandle, 0, &rectGame) &&
                GetMenuItemRect(g_MainWindow, g_MenuHandle, 1, &rectHelp))
            {
            if (rectGame.top != rectHelp.top)
                {
                dypAdjust += dypMenu;
                bDiffLevel = TRUE;
                }
            }
        }

	g_WindowWidth = dxBlk * g_GridWidth + dxGridOff + dxRightSpace;
	g_WindowHeight = dyBlk * g_GridHeight + dyGridOff + dyBottomSpace;

	if ((t = g_GameConfig.xWindow+g_WindowWidth - GetDisplayMetrics(SM_CXSCREEN)) > 0)
		{
		fAdjust |= fResize;
		g_GameConfig.xWindow -= t;
		}

	if ((t = g_GameConfig.yWindow+g_WindowHeight - GetDisplayMetrics(SM_CYSCREEN)) > 0)
		{
		fAdjust |= fResize;
		g_GameConfig.yWindow -= t;
		}

    if (!bInitMinimized)
        {
    	if (fAdjust & fResize)
    		{
			RECT rc = {0, 0, g_WindowWidth, g_WindowHeight};
			AdjustWindowRect(&rc, WS_OVERLAPPED | WS_MINIMIZEBOX | WS_CAPTION | WS_SYSMENU, FMenuOn());
    		MoveWindow(g_MainWindow, g_GameConfig.xWindow, g_GameConfig.yWindow,
    			rc.right - rc.left, rc.bottom - rc.top, TRUE);
    		}

        // after the window is adjusted, the "Game" and "Help" may move to the
        // same line creating extra space at the bottom. so check again!

        if (bDiffLevel && g_MenuHandle && GetMenuItemRect(g_MainWindow, g_MenuHandle, 0, &rectGame) &&
                GetMenuItemRect(g_MainWindow, g_MenuHandle, 1, &rectHelp))
            {
            if (rectGame.top == rectHelp.top)
                {
                dypAdjust -= dypMenu;
				RECT rc = {0, 0, g_WindowWidth, g_WindowHeight};
				AdjustWindowRect(&rc, WS_OVERLAPPED | WS_MINIMIZEBOX | WS_CAPTION | WS_SYSMENU, FMenuOn());
    		    MoveWindow(g_MainWindow, g_GameConfig.xWindow, g_GameConfig.yWindow,
    			    rc.right - rc.left, rc.bottom - rc.top, TRUE);
                }
            }

    	if (fAdjust & fDisplay)
    		{
    		SetRect(&rect, 0, 0, g_WindowWidth, g_WindowHeight);
    		InvalidateRect(g_MainWindow, &rect, TRUE);
    		}


        }
}
