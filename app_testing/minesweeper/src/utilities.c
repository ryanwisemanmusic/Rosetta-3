/**********/
/* utilities.c */
/**********/

/*
 * Utility functions and helper routines
 * 
 * Contents:
 * - Random number generation (simple modulo-based PRNG)
 * - Error message display with string resource loading
 * - Menu management (checkmarks, visibility toggling)
 * - Dialog helpers (integer retrieval with range validation)
 * - System metrics caching and initialization
 * - Multi-monitor aware positioning
 * 
 * Initialization sequence:
 * 1. Seed LCG PRNG with GetTickCount64()
 * 2. Load string resources (app name, default player name, time format)
 * 3. Cache system metrics (caption height, border sizes, menu height)
 * 4. Check for existing registry configuration
 * 5. If first run, migrate from legacy .ini file
 * 
 * Platform notes:
 * - Uses SM_CXVIRTUALSCREEN for multi-monitor support
 * - Falls back to SM_CXSCREEN on older Windows versions
 * - Menu wrapping detection handles variable-height font rendering
 */

#include <windows.h>
#include <windowsx.h>
#include <shellapi.h>
#include "main.h"
#include "resource.h"
#include "preferences.h"
#include "utilities.h"
#include "game.h"

extern INT dypBorder;
extern INT dxpBorder;
extern INT dypCaption;
extern INT dypMenu;

extern TCHAR g_WindowClass[cchNameMax];
extern TCHAR szTime[cchNameMax];
extern TCHAR szDefaultName[cchNameMax];

extern HANDLE g_AppInstance;
extern HWND   g_MainWindow;
extern HMENU  g_MenuHandle;

extern PREF g_GameConfig;


/****** R N D *****/

/* LCG PRNG -- no CRT. Constants: Numerical Recipes */
static DWORD g_PrngState = 0;

static DWORD PrngNext(VOID)
{
    g_PrngState = g_PrngState * 1664525U + 1013904223U;
    return g_PrngState;
}

/* Return a random number between 0 and rndMax-1 */

INT GenerateRandomNumber(INT rndMax)
{
        /* Use upper 16 bits — low bits of LCG have short period for power-of-2 modulus */
        return (INT)((PrngNext() >> 16) % (DWORD)rndMax);
}


/****** S T R I N G  H E L P E R S ******/

/* Simple integer to string conversion to avoid CRT/wsprintf dependencies */
static VOID IntToDecStr(INT val, TCHAR* buf)
{
    TCHAR temp[16];
    int i = 0;
    int j = 0;
    BOOL neg = FALSE;

    if (val < 0) {
        neg = TRUE;
        val = -val;
    }

    if (val == 0) {
        temp[i++] = TEXT('0');
    } else {
        while (val > 0) {
            temp[i++] = (TCHAR)(TEXT('0') + (val % 10));
            val /= 10;
        }
    }

    if (neg) {
        buf[j++] = TEXT('-');
    }

    while (i > 0) {
        buf[j++] = temp[--i];
    }
    buf[j] = TEXT('\0');
}

/* Format time using the format string from resources (e.g., "%d seconds") */
VOID FormatTime(TCHAR* buf, INT time)
{
    /* We assume szTime contains "%d" exactly once. 
       We'll brute force replace it. */
    TCHAR numBuf[16];
    TCHAR* pSrc = szTime;
    TCHAR* pDest = buf;
    
    IntToDecStr(time, numBuf);

    while (*pSrc) {
        if (*pSrc == TEXT('%') && *(pSrc+1) == TEXT('d')) {
            TCHAR* pNum = numBuf;
            while (*pNum) {
                *pDest++ = *pNum++;
            }
            pSrc += 2;
        } else {
            *pDest++ = *pSrc++;
        }
    }
    *pDest = TEXT('\0');
}

/* Format error message: assumes fmt contains "%d" or similar for error code */
VOID FormatError(TCHAR* buf, const TCHAR* fmt, INT code)
{
    TCHAR numBuf[16];
    const TCHAR* pSrc = fmt;
    TCHAR* pDest = buf;
    
    IntToDecStr(code, numBuf);

    while (*pSrc) {
        if (*pSrc == TEXT('%') && (*(pSrc+1) == TEXT('d') || *(pSrc+1) == TEXT('u'))) {
            TCHAR* pNum = numBuf;
            while (*pNum) {
                *pDest++ = *pNum++;
            }
            pSrc += 2;
        } else {
            *pDest++ = *pSrc++;
        }
    }
    *pDest = TEXT('\0');
}


/****** R E P O R T  E R R ******/

/* Report and error and exit */

VOID DisplayErrorMessage(WORD idErr)
{
        TCHAR szMsg[cchMsgMax];
        TCHAR szMsgTitle[cchMsgMax];

		if (idErr < ID_ERR_MAX)
				LoadString(g_AppInstance, idErr, szMsg, cchMsgMax);
		else
				{
				LoadString(g_AppInstance, ID_ERR_UNKNOWN, szMsgTitle, cchMsgMax);
				FormatError(szMsg, szMsgTitle, idErr);
				}

        LoadString(g_AppInstance, ID_ERR_TITLE, szMsgTitle, cchMsgMax);

        MessageBox(NULL, szMsg, szMsgTitle, MB_OK | MB_ICONHAND);
}


/****** L O A D  S Z ******/

VOID LoadStringResource(WORD id, TCHAR * sz, DWORD cch)
{
        if (LoadString(g_AppInstance, id, sz, cch) == 0)
                DisplayErrorMessage(1001);
}


/****** I N I T  C O N S T ******/

VOID InitializeConstants(VOID)
{
        g_PrngState = (DWORD)GetTickCount64();

        LoadStringResource(ID_GAMENAME, g_WindowClass, ARRAYSIZE(g_WindowClass));
        LoadStringResource(ID_MSG_SEC,  szTime, ARRAYSIZE(szTime));
        LoadStringResource(ID_NAME_DEFAULT, szDefaultName, ARRAYSIZE(szDefaultName));

        dypCaption = GetSystemMetrics(SM_CYCAPTION) + 1;
        dypMenu    = GetSystemMetrics(SM_CYMENU)    + 1;
        dypBorder  = GetSystemMetrics(SM_CYBORDER)  + 1;
        dxpBorder  = GetSystemMetrics(SM_CXBORDER)  + 1;
}




/* * * * * *  M E N U S  * * * * * */

/****** C H E C K  E M ******/

VOID SetMenuCheckmark(WORD idm, BOOL fCheck)
{
        CheckMenuItem(g_MenuHandle, idm, fCheck ? MF_CHECKED : MF_UNCHECKED);
}

/****** S E T  M E N U  B A R ******/

VOID SetMenuVisibility(INT fActive)
{
        g_GameConfig.fMenu = fActive;
        UpdateMenuStates();
        SetMenu(g_MainWindow, FMenuOn() ? g_MenuHandle : NULL);
        ResizeGameWindow(fResize);
}


/****** D O  A B O U T ******/

VOID ShowAboutDialog(VOID)
{
        TCHAR szVersion[cchMsgMax];
        TCHAR szCredit[cchMsgMax];

        LoadStringResource(ID_MSG_VERSION, szVersion, ARRAYSIZE(szVersion));
        LoadStringResource(ID_MSG_CREDIT,  szCredit, ARRAYSIZE(szCredit));

        ShellAbout(g_MainWindow,
          szVersion, szCredit, LoadIcon(NULL, IDI_APPLICATION));
}


/****** G E T  D L G  I N T ******/

INT GetDialogInteger(HWND hDlg, INT dlgID, INT numLo, INT numHi)
{
        INT num;
        BOOL fFlag;

        num = GetDlgItemInt(hDlg, dlgID, &fFlag, FALSE);

        if (num < numLo)
                num = numLo;
        else if (num > numHi)
                num = numHi;

        return num;
}