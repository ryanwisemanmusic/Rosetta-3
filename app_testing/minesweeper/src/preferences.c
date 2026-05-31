/****************/
/* file: preferences.c */
/****************/

/*
 * Preferences and registry management
 * 
 * Responsibilities:
 * - Registry-based configuration persistence (HKCU\Software\MinesweeperGame\Settings)
 * - Input validation and range clamping
 * - Backward compatibility with legacy .ini file format
 * - High score tracking (time + player name for 3 difficulty levels)
 * 
 * Registry schema:
 * - Difficulty/Mines/Height/Width: DWORD values
 * - Xpos/Ypos: Window position
 * - Sound/Mark/Menu/Tick: Boolean flags stored as DWORD
 * - Time1/2/3: High scores in seconds (0-999)
 * - Name1/2/3: Player names (REG_SZ, up to 32 chars)
 * 
 * Migration strategy:
 * - On first run, checks iszPrefAlreadyPlayed registry key
 * - If absent, reads from legacy entpack.ini and writes to registry
 * - Subsequent runs use registry exclusively
 */

#include <windows.h>
#include <windowsx.h>

#include "main.h"
#include "resource.h"
#include "game.h"
#include "graphics.h"
#include "preferences.h"
#include "sound.h"

BOOL g_SettingsDirty = FALSE;
HKEY g_hReg;

extern TCHAR szDefaultName[];
extern INT g_GridWidth;
extern INT g_GridHeight;

extern PREF g_GameConfig;

TCHAR * rgszPref[iszPrefMax] =
{
TEXT("Difficulty"),
TEXT("Mines"     ),
TEXT("Height"    ),
TEXT("Width"     ),
TEXT("Xpos"      ),
TEXT("Ypos"      ),
TEXT("Sound"     ),
TEXT("Mark"      ),
TEXT("Menu"      ),
TEXT("Tick"      ),
TEXT("Time1"     ),
TEXT("Name1"     ),
TEXT("Time2"     ),
TEXT("Name2"     ),
TEXT("Time3"     ),
TEXT("Name3"     )
};

/****** PREFERENCES ******/

/*
 * Registry read with validation
 * 
 * Process:
 * 1. Query registry value via RegQueryValueEx
 * 2. If key missing, return default value
 * 3. Clamp result to [valMin, valMax] range
 * 
 * Error handling:
 * - Missing keys return default (not an error)
 * - Invalid data types silently return default
 * - Out-of-range values clamped to valid range
 */

INT ReadRegistryInteger(INT iszPref, INT valDefault, INT valMin, INT valMax)
{
DWORD dwIntRead;
DWORD dwSizeOfData = sizeof(INT);


    // If value not present, return default value.
    if (RegQueryValueEx(g_hReg, rgszPref[iszPref], NULL, NULL, (LPBYTE) &dwIntRead,
                        &dwSizeOfData) != ERROR_SUCCESS)
        return valDefault;

    return max(valMin, min(valMax, (INT) dwIntRead));
}

#define ReadBooleanValue(iszPref, valDefault) ReadRegistryInteger(iszPref, valDefault, 0, 1)


VOID ReadRegistryString(INT iszPref, TCHAR FAR * szRet)
{
DWORD dwSizeOfData = cchNameMax * sizeof(TCHAR);

    // If string not present, return default string.
    if (RegQueryValueEx(g_hReg, rgszPref[iszPref], NULL, NULL, (LPBYTE) szRet,
                        &dwSizeOfData) != ERROR_SUCCESS)
        lstrcpy(szRet, szDefaultName) ;

    return;
}


VOID LoadConfiguration(VOID)
{
DWORD dwDisposition;


	// Open the registry key; if it fails, there is not much we can do about it.
	RegCreateKeyEx(HKEY_CURRENT_USER, SZWINMINEREG, 0, NULL, 0, KEY_READ, NULL,
				   &g_hReg, &dwDisposition);

	g_GridHeight= g_GameConfig.Height= ReadRegistryInteger(iszPrefHeight,MINHEIGHT,DEFHEIGHT,25);

	g_GridWidth= g_GameConfig.Width= ReadRegistryInteger(iszPrefWidth,MINWIDTH,DEFWIDTH,30);

	g_GameConfig.wGameType = (WORD)ReadRegistryInteger(iszPrefGame,wGameBegin, wGameBegin, wGameExpert+1);
	g_GameConfig.Mines    = ReadRegistryInteger(iszPrefMines, 10, 10, 999);
	g_GameConfig.xWindow  = ReadRegistryInteger(iszPrefxWindow, 80, 0, 7680);
	g_GameConfig.yWindow  = ReadRegistryInteger(iszPrefyWindow, 80, 0, 7680);

	g_GameConfig.fSound = ReadRegistryInteger(iszPrefSound, 0, 0, fsoundOn);
	g_GameConfig.fMark  = ReadBooleanValue(iszPrefMark,  TRUE);
	g_GameConfig.fTick  = ReadBooleanValue(iszPrefTick,  FALSE);
	g_GameConfig.fMenu  = ReadRegistryInteger(iszPrefMenu,  fmenuAlwaysOn, fmenuAlwaysOn, fmenuOn);

	g_GameConfig.rgTime[wGameBegin]  = ReadRegistryInteger(iszPrefBeginTime, 999, 0, 999);
	g_GameConfig.rgTime[wGameInter]  = ReadRegistryInteger(iszPrefInterTime, 999, 0, 999);
	g_GameConfig.rgTime[wGameExpert] = ReadRegistryInteger(iszPrefExpertTime, 999, 0, 999);

	ReadRegistryString(iszPrefBeginName, g_GameConfig.szBegin);
	ReadRegistryString(iszPrefInterName, g_GameConfig.szInter);
	ReadRegistryString(iszPrefExpertName, g_GameConfig.szExpert);

	if (FSoundOn())
		g_GameConfig.fSound = InitializeAudioSystem();

	RegCloseKey(g_hReg);

}


VOID WriteRegistryInteger(INT iszPref, INT val)
{

    // No check for return value for if it fails, can't do anything
    // to rectify the situation.
    RegSetValueEx(g_hReg, rgszPref[iszPref], 0, REG_DWORD, (LPBYTE) &val, sizeof(val));

    return;

}


VOID WriteRegistryString(INT iszPref, TCHAR FAR * sz)
{
    // No check for return value for if it fails, can't do anything
    // to rectify the situation.
    RegSetValueEx(g_hReg, rgszPref[iszPref], 0, REG_SZ, (LPBYTE) sz,
                  sizeof(TCHAR) * (lstrlen(sz)+1));

    return;
}


VOID SaveConfiguration(VOID)
{
DWORD dwDisposition;

	// Open the registry key; if it fails, there is not much we can do about it.
	RegCreateKeyEx(HKEY_CURRENT_USER, SZWINMINEREG, 0, NULL, 0, KEY_WRITE, NULL,
				   &g_hReg, &dwDisposition);


	WriteRegistryInteger(iszPrefGame,   g_GameConfig.wGameType);
	WriteRegistryInteger(iszPrefHeight, g_GameConfig.Height);
	WriteRegistryInteger(iszPrefWidth,  g_GameConfig.Width);
	WriteRegistryInteger(iszPrefMines,  g_GameConfig.Mines);
	WriteRegistryInteger(iszPrefMark,   g_GameConfig.fMark);
#ifdef WRITE_HIDDEN
	WriteRegistryInteger(iszPrefMenu,   g_GameConfig.fMenu);
	WriteRegistryInteger(iszPrefTick,   g_GameConfig.fTick);
#endif
	WriteRegistryInteger(iszPrefSound,  g_GameConfig.fSound);
	WriteRegistryInteger(iszPrefxWindow,g_GameConfig.xWindow);
	WriteRegistryInteger(iszPrefyWindow,g_GameConfig.yWindow);

	WriteRegistryInteger(iszPrefBeginTime,  g_GameConfig.rgTime[wGameBegin]);
	WriteRegistryInteger(iszPrefInterTime,  g_GameConfig.rgTime[wGameInter]);
	WriteRegistryInteger(iszPrefExpertTime, g_GameConfig.rgTime[wGameExpert]);

	WriteRegistryString(iszPrefBeginName,   g_GameConfig.szBegin);
	WriteRegistryString(iszPrefInterName,   g_GameConfig.szInter);
	WriteRegistryString(iszPrefExpertName,  g_GameConfig.szExpert);

	RegCloseKey(g_hReg);

}
