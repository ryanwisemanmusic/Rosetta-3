/*
 * Rosetta 3 shim for win32/windows.h (Windows umbrella header).
 *
 * On macOS the canonical windows.h is blocked by the macOS shim's
 * pre-definition of _WINDOWS_.  This shim provides the subset of
 * types, constants and functions that applications compiled against
 * the Rosetta 3 shim layer need: base types (from windows_base.h),
 * console I/O constants and functions, and Sleep().
 *
 * Two backends:
 *   1. Default — ANSI escape codes on stdout (works in any terminal).
 *   2. ROSETTA_WINDOW_MODE — routes to the Objective‑C Cocoa window
 *      library (src/graphics/Objective_C/window_main.m).  Define
 *      ROSETTA_WINDOW_MODE before including this header and link
 *      librosetta_window.a.
 */
#ifndef ROSETTA3_SHIMS_WIN32_WINDOWS_H
#define ROSETTA3_SHIMS_WIN32_WINDOWS_H

/* Suppress known Win32-on-macOS LPCWSTR/wchar_t size mismatch */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"

#include <stdio.h>
#include <string.h>
#include <wchar.h>
#include <unistd.h>
#include <time.h>
#include "windows_base.h"
#include "synchapi.h"

#ifdef __APPLE__
/* macOS platform layer: rosetta_* bridge declarations, static state */
#include "../macos/win32/windows.h"
#endif

#ifdef __cplusplus
extern "C" {
#endif

#ifndef STD_INPUT_HANDLE
#define STD_INPUT_HANDLE        ((DWORD)-10)
#define STD_OUTPUT_HANDLE       ((DWORD)-11)
#define STD_ERROR_HANDLE        ((DWORD)-12)
#endif

#ifndef FOREGROUND_BLUE
#define FOREGROUND_BLUE         0x0001
#define FOREGROUND_GREEN        0x0002
#define FOREGROUND_RED          0x0004
#define FOREGROUND_INTENSITY    0x0008
#define BACKGROUND_BLUE         0x0010
#define BACKGROUND_GREEN        0x0020
#define BACKGROUND_RED          0x0040
#define BACKGROUND_INTENSITY    0x0080
#endif

#ifndef _COORD_DEFINED
#define _COORD_DEFINED
typedef struct _COORD {
    SHORT X;
    SHORT Y;
} COORD, *PCOORD;
#endif

#ifndef _CONSOLE_CURSOR_INFO_DEFINED
#define _CONSOLE_CURSOR_INFO_DEFINED
typedef struct _CONSOLE_CURSOR_INFO {
    DWORD dwSize;
    BOOL  bVisible;
} CONSOLE_CURSOR_INFO, *PCONSOLE_CURSOR_INFO;
#endif

#ifdef ROSETTA_WINDOW_MODE

#ifndef _GETSTDHANDLE_DEFINED
#define _GETSTDHANDLE_DEFINED
FORCEINLINE HANDLE WINAPI GetStdHandle(DWORD nStdHandle)
{
    return (HANDLE)rosetta_get_std_handle(nStdHandle);
}
#endif

#ifndef _SETCONSOLETEXTATTRIBUTE_DEFINED
#define _SETCONSOLETEXTATTRIBUTE_DEFINED
FORCEINLINE BOOL WINAPI SetConsoleTextAttribute(HANDLE hConsole,
                                                WORD wAttributes)
{
    rosetta_set_console_text_attribute((void *)hConsole, wAttributes);
    return TRUE;
}
#endif

#ifndef _SETCONSOLECURSORPOSITION_DEFINED
#define _SETCONSOLECURSORPOSITION_DEFINED
FORCEINLINE BOOL WINAPI SetConsoleCursorPosition(HANDLE hConsole,
                                                 COORD dwCursorPosition)
{
    rosetta_set_console_cursor_position(
        (void *)hConsole, (int)dwCursorPosition.X, (int)dwCursorPosition.Y);
    return TRUE;
}
#endif

#ifndef _SETCONSOLECURSORINFO_DEFINED
#define _SETCONSOLECURSORINFO_DEFINED
FORCEINLINE BOOL WINAPI SetConsoleCursorInfo(
    HANDLE hConsole, const CONSOLE_CURSOR_INFO *lpConsoleCursorInfo)
{
    rosetta_set_console_cursor_info((void *)hConsole,
                                    (void *)lpConsoleCursorInfo);
    return TRUE;
}
#endif

#ifndef _GETCONSOLECURSORINFO_DEFINED
#define _GETCONSOLECURSORINFO_DEFINED
FORCEINLINE BOOL WINAPI GetConsoleCursorInfo(
    HANDLE hConsole, PCONSOLE_CURSOR_INFO lpConsoleCursorInfo)
{
    (void)hConsole;
    lpConsoleCursorInfo->dwSize = 25;
    lpConsoleCursorInfo->bVisible = TRUE;
    return TRUE;
}
#endif

#ifndef _BEEP_DEFINED
#define _BEEP_DEFINED
FORCEINLINE BOOL WINAPI Beep(DWORD dwFreq, DWORD dwDuration)
{
    (void)dwFreq;
    (void)dwDuration;
    return TRUE;
}
#endif

/* Call Obj-C */
#ifndef _GETDC_DEFINED
#define _GETDC_DEFINED
FORCEINLINE HDC WINAPI GetDC(HWND hWnd) {
    return (HDC)(intptr_t)rosetta_gdi_get_dc((void *)hWnd);
}
#endif

#ifndef _CREATECOMPATIBLEDC_DEFINED
#define _CREATECOMPATIBLEDC_DEFINED
FORCEINLINE HDC WINAPI CreateCompatibleDC(HDC hdc) {
    return (HDC)(intptr_t)rosetta_gdi_create_compatible_dc((uint32_t)(intptr_t)hdc);
}
#endif

#ifndef _SELECTOBJECT_DEFINED
#define _SELECTOBJECT_DEFINED
FORCEINLINE HGDIOBJ WINAPI SelectObject(HDC hdc, HGDIOBJ hgdiobj) {
    return (HGDIOBJ)(intptr_t)rosetta_gdi_select_object(
        (uint32_t)(intptr_t)hdc, (uint32_t)(intptr_t)hgdiobj);
}
#endif

#ifndef _BITBLT_DEFINED
#define _BITBLT_DEFINED
FORCEINLINE BOOL WINAPI BitBlt(HDC hdcDest, int xDest, int yDest,
    int wDest, int hDest, HDC hdcSrc, int xSrc, int ySrc, DWORD dwRop)
{
    return (BOOL)rosetta_gdi_bitblt(
        (uint32_t)(intptr_t)hdcDest, xDest, yDest,
        wDest, hDest, (uint32_t)(intptr_t)hdcSrc,
        xSrc, ySrc, (uint32_t)dwRop);
}
#endif

#ifndef _DELETEOBJECT_DEFINED
#define _DELETEOBJECT_DEFINED
FORCEINLINE BOOL WINAPI DeleteObject(HGDIOBJ hgdiobj) {
    return (BOOL)rosetta_gdi_delete_object((uint32_t)(intptr_t)hgdiobj);
}
#endif

#ifndef _LOADIMAGE_DEFINED
#define _LOADIMAGE_DEFINED
FORCEINLINE HANDLE WINAPI LoadImageA(HINSTANCE hInst, LPCSTR name,
    UINT type, int cx, int cy, UINT fuLoad)
{
    return (HANDLE)(intptr_t)rosetta_gdi_load_image_a(
        (void *)hInst, name, (uint32_t)type, cx, cy, (uint32_t)fuLoad);
}
FORCEINLINE HANDLE WINAPI LoadImageW(HINSTANCE hInst, LPCWSTR name,
    UINT type, int cx, int cy, UINT fuLoad)
{
    return (HANDLE)(intptr_t)rosetta_gdi_load_image_w(
        (void *)hInst, name, (uint32_t)type, cx, cy, (uint32_t)fuLoad);
}
#ifdef UNICODE
#define LoadImage LoadImageW
#else
#define LoadImage LoadImageA
#endif
#endif

/* CLI Windowing */
#ifndef _SETCONSOLETITLE_DEFINED
#define _SETCONSOLETITLE_DEFINED
FORCEINLINE BOOL WINAPI SetConsoleTitleA(LPCSTR lpConsoleTitle) {
    rosetta_gdi_set_console_title(lpConsoleTitle); return TRUE;
}
FORCEINLINE BOOL WINAPI SetConsoleTitleW(LPCWSTR lpConsoleTitle) {
    (void)lpConsoleTitle;
    rosetta_gdi_set_console_title("Tetris"); return TRUE;
}
#ifdef UNICODE
#define SetConsoleTitle SetConsoleTitleW
#else
#define SetConsoleTitle SetConsoleTitleA
#endif
#endif

#ifndef _GETCONSOLEWINDOW_DEFINED
#define _GETCONSOLEWINDOW_DEFINED
FORCEINLINE HWND WINAPI GetConsoleWindow(void) {
    return (HWND)rosetta_gdi_get_console_window();
}
#endif

#ifndef _SETWINDOWPOS_DEFINED
#define _SETWINDOWPOS_DEFINED
FORCEINLINE BOOL WINAPI SetWindowPos(HWND hWnd, HWND hWndInsertAfter,
    int X, int Y, int cx, int cy, UINT uFlags)
{
    rosetta_gdi_set_window_pos((void *)hWnd, (void *)hWndInsertAfter,
                               X, Y, cx, cy, (unsigned int)uFlags);
    return TRUE;
}
#endif

#ifndef _GETFOREGROUNDWINDOW_DEFINED
#define _GETFOREGROUNDWINDOW_DEFINED
FORCEINLINE HWND WINAPI GetForegroundWindow(void) {
    return (HWND)rosetta_gdi_get_foreground_window();
}
#endif

#ifndef _GETCONSOLESCREENBUFFERINFO_DEFINED
#define _GETCONSOLESCREENBUFFERINFO_DEFINED
FORCEINLINE BOOL WINAPI GetConsoleScreenBufferInfo(
    HANDLE hConsoleOutput, PCONSOLE_SCREEN_BUFFER_INFO lpInfo)
{
    return (BOOL)rosetta_gdi_get_console_screen_buffer_info(
        (void *)hConsoleOutput, (void *)lpInfo);
}
#endif

#ifndef _SETCONSOLESCREENBUFFERSIZE_DEFINED
#define _SETCONSOLESCREENBUFFERSIZE_DEFINED
FORCEINLINE BOOL WINAPI SetConsoleScreenBufferSize(
    HANDLE hConsoleOutput, COORD dwSize)
{
    return (BOOL)rosetta_gdi_set_console_screen_buffer_size(
        (void *)hConsoleOutput, dwSize.X, dwSize.Y);
}
#endif

/* Monitoring */
#ifndef _MONITORFROMWINDOW_DEFINED
#define _MONITORFROMWINDOW_DEFINED
FORCEINLINE HMONITOR WINAPI MonitorFromWindow(HWND hwnd, DWORD dwFlags) {
    return (HMONITOR)rosetta_gdi_monitor_from_window(
        (void *)hwnd, (unsigned long)dwFlags);
}
#endif

#ifndef _GETMONITORINFO_DEFINED
#define _GETMONITORINFO_DEFINED
FORCEINLINE BOOL WINAPI GetMonitorInfoA(HMONITOR hMonitor, void *lpmi) {
    return (BOOL)rosetta_gdi_get_monitor_info_a((void *)hMonitor, lpmi);
}
FORCEINLINE BOOL WINAPI GetMonitorInfoW(HMONITOR hMonitor, void *lpmi) {
    return (BOOL)rosetta_gdi_get_monitor_info_a((void *)hMonitor, lpmi);
}
#ifdef UNICODE
#define GetMonitorInfo GetMonitorInfoW
#else
#define GetMonitorInfo GetMonitorInfoA
#endif
#endif

#ifndef _ENUMDISPLAYSETTINGS_DEFINED
#define _ENUMDISPLAYSETTINGS_DEFINED
FORCEINLINE BOOL WINAPI EnumDisplaySettingsA(
    LPCSTR lpszDeviceName, DWORD iModeNum, void *lpDevMode)
{
    return (BOOL)rosetta_gdi_enum_display_settings_a(
        lpszDeviceName, (unsigned int)iModeNum, lpDevMode);
}
FORCEINLINE BOOL WINAPI EnumDisplaySettingsW(
    LPCWSTR lpszDeviceName, DWORD iModeNum, void *lpDevMode)
{
    (void)lpszDeviceName;
    return (BOOL)rosetta_gdi_enum_display_settings_a(
        NULL, (unsigned int)iModeNum, lpDevMode);
}
#ifdef UNICODE
#define EnumDisplaySettings EnumDisplaySettingsW
#else
#define EnumDisplaySettings EnumDisplaySettingsA
#endif
#endif

#ifndef _GETASYNCKEYSTATE_DEFINED
#define _GETASYNCKEYSTATE_DEFINED
FORCEINLINE SHORT WINAPI GetAsyncKeyState(int vKey) {
    return rosetta_gdi_get_async_key_state(vKey);
}
#endif

#else  /* !ROSETTA_WINDOW_MODE — default ANSI escape code backend */

#ifndef _GETSTDHANDLE_DEFINED
#define _GETSTDHANDLE_DEFINED
FORCEINLINE HANDLE WINAPI GetStdHandle(DWORD nStdHandle)
{
    (void)nStdHandle;
    return (HANDLE)(LONG_PTR)0xF001;
}
#endif

#ifndef _SETCONSOLETEXTATTRIBUTE_DEFINED
#define _SETCONSOLETEXTATTRIBUTE_DEFINED
FORCEINLINE BOOL WINAPI SetConsoleTextAttribute(HANDLE hConsole,
                                                WORD wAttributes)
{
    (void)hConsole;
    static const char *const ansi_fg[8] = {
        "\x1b[30m", "\x1b[34m", "\x1b[32m", "\x1b[36m",
        "\x1b[31m", "\x1b[35m", "\x1b[33m", "\x1b[37m"
    };
    static const char *const ansi_bg[8] = {
        "\x1b[40m", "\x1b[44m", "\x1b[42m", "\x1b[46m",
        "\x1b[41m", "\x1b[45m", "\x1b[43m", "\x1b[47m"
    };
    int fg = (int)(wAttributes & 0x07);
    int bg = (int)((wAttributes >> 4) & 0x07);
    int bright = (wAttributes & 0x08) ? 1 : 0;
    printf("\x1b[%d;%dm", bright ? 1 : 22, fg);
    printf("%s%s", ansi_fg[fg], ansi_bg[bg]);
    fflush(stdout);
    return TRUE;
}
#endif

#ifndef _SETCONSOLECURSORPOSITION_DEFINED
#define _SETCONSOLECURSORPOSITION_DEFINED
FORCEINLINE BOOL WINAPI SetConsoleCursorPosition(HANDLE hConsole,
                                                 COORD dwCursorPosition)
{
    (void)hConsole;
    printf("\x1b[%d;%dH",
           (int)dwCursorPosition.Y + 1, (int)dwCursorPosition.X + 1);
    fflush(stdout);
    return TRUE;
}
#endif

#ifndef _SETCONSOLECURSORINFO_DEFINED
#define _SETCONSOLECURSORINFO_DEFINED
FORCEINLINE BOOL WINAPI SetConsoleCursorInfo(
    HANDLE hConsole, const CONSOLE_CURSOR_INFO *lpConsoleCursorInfo)
{
    (void)hConsole;
    if (lpConsoleCursorInfo->bVisible)
        printf("\x1b[?25h");
    else
        printf("\x1b[?25l");
    fflush(stdout);
    return TRUE;
}
#endif

#ifndef _GETCONSOLECURSORINFO_DEFINED
#define _GETCONSOLECURSORINFO_DEFINED
FORCEINLINE BOOL WINAPI GetConsoleCursorInfo(
    HANDLE hConsole, PCONSOLE_CURSOR_INFO lpConsoleCursorInfo)
{
    (void)hConsole;
    lpConsoleCursorInfo->dwSize = 25;
    lpConsoleCursorInfo->bVisible = TRUE;
    return TRUE;
}
#endif

#ifndef _BEEP_DEFINED
#define _BEEP_DEFINED
FORCEINLINE BOOL WINAPI Beep(DWORD dwFreq, DWORD dwDuration)
{
    (void)dwFreq;
    (void)dwDuration;
    printf("\x07");
    fflush(stdout);
    return TRUE;
}
#endif

#endif /* ROSETTA_WINDOW_MODE */

#ifdef __cplusplus
}
#endif

/* ==========================================================================  */
/* system() interception — map "cls" (Windows cmd.exe clear-screen) to ANSI    */
/* escape sequences on non-Windows platforms.  Define ROSETTA_NO_SYSTEM_CLS    */
/* before including windows.h to disable.                                      */
/*                                                                             */
/* Only applies in ANSI-escape mode; in window mode the game is linked against */
/* the ObjC library which handles "cls" at the application level.              */
/* ==========================================================================  */
#if !defined(ROSETTA_WINDOW_MODE) && !defined(ROSETTA_NO_SYSTEM_CLS)
#include <stdlib.h>

static inline int rosetta_system(const char *cmd)
{
    if (cmd && cmd[0] == 'c' && cmd[1] == 'l' && cmd[2] == 's' && cmd[3] == '\0') {
        printf("\x1b[2J\x1b[1;1H");
        return 0;
    }
    return (system)(cmd);
}
#define system rosetta_system
#endif

#ifndef _POINT_DEFINED
#define _POINT_DEFINED
typedef struct tagPOINT {
    LONG x;
    LONG y;
} POINT, *PPOINT, *LPPOINT;
#endif

#ifndef _RECT_DEFINED
#define _RECT_DEFINED
typedef struct tagRECT {
    LONG left;
    LONG top;
    LONG right;
    LONG bottom;
} RECT, *PRECT, *LPRECT;
#endif

#ifndef DECLARE_HANDLE
#define DECLARE_HANDLE(name) struct name##__{int unused;}; typedef struct name##__ *name
#endif

#ifndef LPCSTR
typedef const CHAR *LPCSTR;
typedef       CHAR *LPSTR;
#endif
#ifndef LPCWSTR
typedef const WCHAR *LPCWSTR;
typedef       WCHAR *LPWSTR;
#endif

#ifndef _SMALL_RECT_DEFINED
#define _SMALL_RECT_DEFINED
typedef struct _SMALL_RECT {
    SHORT Left;
    SHORT Top;
    SHORT Right;
    SHORT Bottom;
} SMALL_RECT, *PSMALL_RECT;
#endif

#ifndef _CONSOLE_SCREEN_BUFFER_INFO_DEFINED
#define _CONSOLE_SCREEN_BUFFER_INFO_DEFINED
typedef struct _CONSOLE_SCREEN_BUFFER_INFO {
    COORD      dwSize;
    COORD      dwCursorPosition;
    WORD       wAttributes;
    SMALL_RECT srWindow;
    COORD      dwMaximumWindowSize;
} CONSOLE_SCREEN_BUFFER_INFO, *PCONSOLE_SCREEN_BUFFER_INFO;
#endif

#ifndef _HMONITOR_DEFINED
#define _HMONITOR_DEFINED
DECLARE_HANDLE(HMONITOR);
#endif

#ifndef _MONITORINFO_DEFINED
#define _MONITORINFO_DEFINED
typedef struct tagMONITORINFO {
    DWORD cbSize;
    RECT  rcMonitor;
    RECT  rcWork;
    DWORD dwFlags;
} MONITORINFO, *LPMONITORINFO;

typedef struct tagMONITORINFOEXA {
    DWORD cbSize;
    RECT  rcMonitor;
    RECT  rcWork;
    DWORD dwFlags;
    CHAR  szDevice[32];
} MONITORINFOEXA, *LPMONITORINFOEXA;
typedef struct tagMONITORINFOEXW {
    DWORD  cbSize;
    RECT   rcMonitor;
    RECT   rcWork;
    DWORD  dwFlags;
    WCHAR  szDevice[32];
} MONITORINFOEXW, *LPMONITORINFOEXW;
#ifdef UNICODE
typedef MONITORINFOEXW MONITORINFOEX;
typedef LPMONITORINFOEXW LPMONITORINFOEX;
#else
typedef MONITORINFOEXA MONITORINFOEX;
typedef LPMONITORINFOEXA LPMONITORINFOEX;
#endif
#endif

#ifndef _DEVMODE_DEFINED
#define _DEVMODE_DEFINED
typedef struct _devicemodeA {
    CHAR  dmDeviceName[32];
    WORD  dmSpecVersion;
    WORD  dmDriverVersion;
    WORD  dmSize;
    WORD  dmDriverExtra;
    DWORD dmFields;
    short dmOrientation;
    short dmPaperSize;
    short dmPaperLength;
    short dmPaperWidth;
    short dmScale;
    short dmCopies;
    short dmDefaultSource;
    short dmPrintQuality;
    short dmColor;
    short dmDuplex;
    short dmYResolution;
    short dmTTOption;
    short dmCollate;
    CHAR  dmFormName[32];
    WORD  dmLogPixels;
    DWORD dmBitsPerPel;
    DWORD dmPelsWidth;
    DWORD dmPelsHeight;
    DWORD dmDisplayFlags;
    DWORD dmDisplayFrequency;
    DWORD dmICMMethod;
    DWORD dmICMIntent;
    DWORD dmMediaType;
    DWORD dmDitherType;
    DWORD dmReserved1;
    DWORD dmReserved2;
    DWORD dmPanningWidth;
    DWORD dmPanningHeight;
} DEVMODEA, *PDEVMODEA, *NPDEVMODEA, *LPDEVMODEA;
typedef struct _devicemodeW {
    WCHAR dmDeviceName[32];
    WORD  dmSpecVersion;
    WORD  dmDriverVersion;
    WORD  dmSize;
    WORD  dmDriverExtra;
    DWORD dmFields;
    short dmOrientation;
    short dmPaperSize;
    short dmPaperLength;
    short dmPaperWidth;
    short dmScale;
    short dmCopies;
    short dmDefaultSource;
    short dmPrintQuality;
    short dmColor;
    short dmDuplex;
    short dmYResolution;
    short dmTTOption;
    short dmCollate;
    WCHAR dmFormName[32];
    WORD  dmLogPixels;
    DWORD dmBitsPerPel;
    DWORD dmPelsWidth;
    DWORD dmPelsHeight;
    DWORD dmDisplayFlags;
    DWORD dmDisplayFrequency;
    DWORD dmICMMethod;
    DWORD dmICMIntent;
    DWORD dmMediaType;
    DWORD dmDitherType;
    DWORD dmReserved1;
    DWORD dmReserved2;
    DWORD dmPanningWidth;
    DWORD dmPanningHeight;
} DEVMODEW, *PDEVMODEW, *NPDEVMODEW, *LPDEVMODEW;
#ifdef UNICODE
typedef DEVMODEW DEVMODE;
typedef LPDEVMODEW LPDEVMODE;
#else
typedef DEVMODEA DEVMODE;
typedef LPDEVMODEA LPDEVMODE;
#endif
#endif

#ifndef HBITMAP
DECLARE_HANDLE(HBITMAP);
#endif
#ifndef HPEN
DECLARE_HANDLE(HPEN);
#endif
#ifndef HFONT
DECLARE_HANDLE(HFONT);
#endif
#ifndef COLORREF_DEFINED
#define COLORREF_DEFINED
typedef DWORD COLORREF;
#endif

#ifndef IMAGE_BITMAP
#define IMAGE_BITMAP                0
#endif
#ifndef LR_LOADFROMFILE
#define LR_LOADFROMFILE             0x00000010
#endif
#ifndef SRCCOPY
#define SRCCOPY                     0x00CC0020
#endif
#ifndef BLACK_BRUSH
#define BLACK_BRUSH                 4
#endif

#ifndef MONITOR_DEFAULTTOPRIMARY
#define MONITOR_DEFAULTTOPRIMARY    0x00000001
#endif
#ifndef ENUM_CURRENT_SETTINGS
#define ENUM_CURRENT_SETTINGS       ((DWORD)-1)
#endif
#ifndef HWND_TOP
#define HWND_TOP                    ((HWND)0)
#endif
#ifndef SWP_NOMOVE
#define SWP_NOMOVE                  0x0002
#endif

/* ------------------------------------------------------------------ */
/* Win32 constants — window messages, styles, virtual keys, etc.       */
/* ------------------------------------------------------------------ */

#ifndef IDI_APPLICATION
#define IDI_APPLICATION  MAKEINTRESOURCE(32512)
#define IDI_HAND         MAKEINTRESOURCE(32513)
#define IDI_QUESTION     MAKEINTRESOURCE(32514)
#define IDI_EXCLAMATION  MAKEINTRESOURCE(32515)
#define IDI_ASTERISK     MAKEINTRESOURCE(32516)
#define IDC_ARROW        MAKEINTRESOURCE(32512)
#define IDC_IBEAM        MAKEINTRESOURCE(32513)
#endif

#ifndef MB_OK
#define MB_OK             0x00000000L
#define MB_OKCANCEL       0x00000001L
#define MB_YESNO          0x00000004L
#define MB_ICONHAND       0x00000010L
#define MB_ICONQUESTION   0x00000020L
#define MB_ICONEXCLAMATION 0x00000030L
#define MB_ICONASTERISK   0x00000040L
#define MB_DEFBUTTON1     0x00000000L
#define MB_DEFBUTTON2     0x00000100L
#endif

#ifndef SM_CXSCREEN
#define SM_CXSCREEN         0
#define SM_CYSCREEN         1
#define SM_CYCAPTION        4
#define SM_CXBORDER         5
#define SM_CYBORDER         6
#define SM_CYMENU           15
#define SM_CXVIRTUALSCREEN  78
#define SM_CYVIRTUALSCREEN  79
#endif

#ifndef MF_BYCOMMAND
#define MF_BYCOMMAND       0x00000000L
#define MF_BYPOSITION      0x00000400L
#define MF_CHECKED         0x00000008L
#define MF_UNCHECKED       0x00000000L
#endif

#ifndef ICON_SMALL
#define ICON_SMALL         0
#define ICON_BIG           1
#endif

#ifndef WS_OVERLAPPED
#define WS_OVERLAPPED      0x00000000L
#define WS_CAPTION         0x00C00000L
#define WS_SYSMENU         0x00080000L
#define WS_MINIMIZEBOX     0x00020000L
#define WS_CHILD           0x40000000L
#define WS_VISIBLE         0x10000000L
#define WS_BORDER          0x00800000L
#define WS_POPUP           0x80000000L
#define WS_DLGFRAME        0x00400000L
#define WS_TABSTOP         0x00010000L
#endif

#ifndef SW_HIDE
#define SW_HIDE            0
#define SW_SHOWNORMAL      1
#define SW_SHOWMINIMIZED   2
#define SW_SHOW            5
#define SW_SHOWDEFAULT     10
#define SW_SHOWMINNOACTIVE 7
#endif

#ifndef WM_CREATE
#define WM_CREATE           0x0001
#define WM_DESTROY          0x0002
#define WM_MOVE             0x0003
#define WM_SIZE             0x0005
#define WM_ACTIVATE         0x0006
#define WM_SETFOCUS         0x0007
#define WM_KILLFOCUS        0x0008
#define WM_SETTEXT          0x000C
#define WM_GETTEXT          0x000D
#define WM_GETTEXTLENGTH    0x000E
#define WM_PAINT            0x000F
#define WM_CLOSE            0x0010
#define WM_QUIT             0x0012
#define WM_ERASEBKGND       0x0014
#define WM_SYSCOLORCHANGE   0x0015
#define WM_SHOWWINDOW       0x0018
#define WM_WINDOWPOSCHANGED 0x0047
#define WM_WINDOWPOSCHANGING 0x0046
#define WM_KEYDOWN          0x0100
#define WM_KEYUP            0x0101
#define WM_CHAR             0x0102
#define WM_SYSKEYDOWN       0x0104
#define WM_SYSKEYUP         0x0105
#define WM_SYSCHAR          0x0106
#define WM_INITDIALOG       0x0110
#define WM_NULL             0x0000
#define WM_COMMAND          0x0111
#define WM_SYSCOMMAND       0x0112
#define WM_TIMER            0x0113
#define WM_HSCROLL          0x0114
#define WM_VSCROLL          0x0115
#define WM_ENTERMENULOOP    0x0211
#define WM_EXITMENULOOP     0x0212
#define WM_USER             0x0400
#define WM_LBUTTONDOWN      0x0201
#define WM_LBUTTONUP        0x0202
#define WM_MBUTTONDOWN      0x0207
#define WM_MBUTTONUP        0x0208
#define WM_RBUTTONDOWN      0x0204
#define WM_RBUTTONUP        0x0205
#define WM_MOUSEMOVE        0x0200
#define WM_MOUSEWHEEL       0x020A
#define WM_MOUSEFIRST       0x0200
#define WM_MOUSELAST        0x020D
#define WM_SETICON          0x0080
#define WM_GETMINMAXINFO    0x0024
#endif

#ifndef VK_SHIFT
#define VK_SHIFT         0x10
#define VK_CONTROL       0x11
#define VK_F2            0x71
#define VK_F4            0x73
#define VK_F5            0x74
#define VK_F6            0x75
#endif

#ifndef MK_LBUTTON
#define MK_LBUTTON       0x0001
#define MK_RBUTTON       0x0002
#define MK_SHIFT         0x0004
#define MK_CONTROL       0x0008
#define MK_MBUTTON       0x0010
#endif

#ifndef PM_REMOVE
#define PM_REMOVE        0x0001
#endif

#ifndef SC_MINIMIZE
#define SC_MINIMIZE      0xF020
#define SC_RESTORE       0xF120
#define SC_CLOSE         0xF060
#endif

#ifndef IDOK
#define IDOK              1
#define IDCANCEL          2
#define IDABORT           3
#define IDRETRY           4
#define IDIGNORE          5
#define IDYES             6
#define IDNO              7
#endif

#ifndef EM_SETLIMITTEXT
#define EM_SETLIMITTEXT   0x00C5
#endif

#ifndef SWP_NOSIZE
#define SWP_NOSIZE        0x0001
#define SWP_NOZORDER      0x0004
#define SWP_SHOWWINDOW    0x0040
#endif

#ifndef COLOR_WINDOW
#define COLOR_WINDOW      5
#endif

#ifndef STARTF_USESHOWWINDOW
#define STARTF_USESHOWWINDOW 0x00000001
#endif

#ifndef _SETCONSOLETITLE_DEFINED
#define _SETCONSOLETITLE_DEFINED
FORCEINLINE BOOL WINAPI SetConsoleTitleA(LPCSTR lpConsoleTitle) {
    (void)lpConsoleTitle; return TRUE;
}
FORCEINLINE BOOL WINAPI SetConsoleTitleW(LPCWSTR lpConsoleTitle) {
    (void)lpConsoleTitle; return TRUE;
}
#ifdef UNICODE
#define SetConsoleTitle SetConsoleTitleW
#else
#define SetConsoleTitle SetConsoleTitleA
#endif
#endif

#ifndef _GETCONSOLEWINDOW_DEFINED
#define _GETCONSOLEWINDOW_DEFINED
FORCEINLINE HWND WINAPI GetConsoleWindow(void) {
    return (HWND)(LONG_PTR)0xBEEF;
}
#endif

#ifndef _GETCONSOLESCREENBUFFERINFO_DEFINED
#define _GETCONSOLESCREENBUFFERINFO_DEFINED
FORCEINLINE BOOL WINAPI GetConsoleScreenBufferInfo(
    HANDLE hConsoleOutput, PCONSOLE_SCREEN_BUFFER_INFO lpInfo)
{
    (void)hConsoleOutput;
    if (lpInfo) {
        lpInfo->dwSize.X = 80;
        lpInfo->dwSize.Y = 25;
        lpInfo->dwCursorPosition.X = 0;
        lpInfo->dwCursorPosition.Y = 0;
        lpInfo->wAttributes = 0x07;
        lpInfo->srWindow.Left = 0;
        lpInfo->srWindow.Top = 0;
        lpInfo->srWindow.Right = 79;
        lpInfo->srWindow.Bottom = 24;
        lpInfo->dwMaximumWindowSize.X = 80;
        lpInfo->dwMaximumWindowSize.Y = 25;
    }
    return TRUE;
}
#endif

#ifndef _SETCONSOLESCREENBUFFERSIZE_DEFINED
#define _SETCONSOLESCREENBUFFERSIZE_DEFINED
FORCEINLINE BOOL WINAPI SetConsoleScreenBufferSize(
    HANDLE hConsoleOutput, COORD dwSize)
{
    (void)hConsoleOutput; (void)dwSize; return TRUE;
}
#endif

#ifndef _MONITORFROMWINDOW_DEFINED
#define _MONITORFROMWINDOW_DEFINED
FORCEINLINE HMONITOR WINAPI MonitorFromWindow(HWND hwnd, DWORD dwFlags) {
    (void)hwnd; (void)dwFlags; return (HMONITOR)(LONG_PTR)0xCAFE;
}
#endif

#ifndef _GETMONITORINFO_DEFINED
#define _GETMONITORINFO_DEFINED
FORCEINLINE BOOL WINAPI GetMonitorInfoA(HMONITOR hMonitor, void *lpmi) {
    (void)hMonitor;
    if (lpmi) {
        DWORD *cb = (DWORD *)lpmi;
        if (*cb >= sizeof(MONITORINFO)) {
            MONITORINFO *mi = (MONITORINFO *)lpmi;
            mi->rcMonitor.left = 0;
            mi->rcMonitor.top = 0;
            mi->rcMonitor.right = 1920;
            mi->rcMonitor.bottom = 1080;
            mi->rcWork = mi->rcMonitor;
            mi->dwFlags = 1;
        }
    }
    return TRUE;
}
FORCEINLINE BOOL WINAPI GetMonitorInfoW(HMONITOR hMonitor, void *lpmi) {
    return GetMonitorInfoA(hMonitor, lpmi);
}
#ifdef UNICODE
#define GetMonitorInfo GetMonitorInfoW
#else
#define GetMonitorInfo GetMonitorInfoA
#endif
#endif

#ifndef _ENUMDISPLAYSETTINGS_DEFINED
#define _ENUMDISPLAYSETTINGS_DEFINED
FORCEINLINE BOOL WINAPI EnumDisplaySettingsA(
    LPCSTR lpszDeviceName, DWORD iModeNum, LPDEVMODEA lpDevMode)
{
    (void)lpszDeviceName;
    if (iModeNum == ENUM_CURRENT_SETTINGS && lpDevMode) {
        lpDevMode->dmSize = sizeof(DEVMODEA);
        lpDevMode->dmPelsWidth = 1920;
        lpDevMode->dmPelsHeight = 1080;
        lpDevMode->dmBitsPerPel = 32;
        lpDevMode->dmDisplayFrequency = 60;
        return TRUE;
    }
    return FALSE;
}
FORCEINLINE BOOL WINAPI EnumDisplaySettingsW(
    LPCWSTR lpszDeviceName, DWORD iModeNum, LPDEVMODEW lpDevMode)
{
    (void)lpszDeviceName;
    if (iModeNum == ENUM_CURRENT_SETTINGS && lpDevMode) {
        lpDevMode->dmSize = sizeof(DEVMODEW);
        lpDevMode->dmPelsWidth = 1920;
        lpDevMode->dmPelsHeight = 1080;
        lpDevMode->dmBitsPerPel = 32;
        lpDevMode->dmDisplayFrequency = 60;
        return TRUE;
    }
    return FALSE;
}
#ifdef UNICODE
#define EnumDisplaySettings EnumDisplaySettingsW
#else
#define EnumDisplaySettings EnumDisplaySettingsA
#endif
#endif

#ifndef _SETWINDOWPOS_DEFINED
#define _SETWINDOWPOS_DEFINED
FORCEINLINE BOOL WINAPI SetWindowPos(HWND hWnd, HWND hWndInsertAfter,
    int X, int Y, int cx, int cy, UINT uFlags)
{
    (void)hWnd; (void)hWndInsertAfter;
    (void)X; (void)Y; (void)cx; (void)cy; (void)uFlags;
    return TRUE;
}
#endif

#ifndef _GETFOREGROUNDWINDOW_DEFINED
#define _GETFOREGROUNDWINDOW_DEFINED
FORCEINLINE HWND WINAPI GetForegroundWindow(void) {
    return GetConsoleWindow();
}
#endif

#ifndef _GETASYNCKEYSTATE_DEFINED
#define _GETASYNCKEYSTATE_DEFINED
FORCEINLINE SHORT WINAPI GetAsyncKeyState(int vKey) {
    (void)vKey; return 0;
}
#endif

#ifndef _GETDC_DEFINED
#define _GETDC_DEFINED
FORCEINLINE HDC WINAPI GetDC(HWND hWnd) {
    (void)hWnd; return (HDC)(LONG_PTR)0xDC01;
}
#endif

#ifndef _CREATECOMPATIBLEDC_DEFINED
#define _CREATECOMPATIBLEDC_DEFINED
FORCEINLINE HDC WINAPI CreateCompatibleDC(HDC hdc) {
    (void)hdc; return (HDC)(LONG_PTR)0xDC02;
}
#endif

#ifndef _SELECTOBJECT_DEFINED
#define _SELECTOBJECT_DEFINED
FORCEINLINE HGDIOBJ WINAPI SelectObject(HDC hdc, HGDIOBJ hgdiobj) {
    (void)hdc; (void)hgdiobj; return (HGDIOBJ)(LONG_PTR)0xBEEF;
}
#endif

#ifndef _BITBLT_DEFINED
#define _BITBLT_DEFINED
FORCEINLINE BOOL WINAPI BitBlt(HDC hdcDest, int xDest, int yDest,
    int wDest, int hDest, HDC hdcSrc, int xSrc, int ySrc, DWORD dwRop)
{
    (void)hdcDest; (void)xDest; (void)yDest;
    (void)wDest; (void)hDest; (void)hdcSrc; (void)xSrc; (void)ySrc; (void)dwRop;
    return TRUE;
}
#endif

#ifndef _DELETEOBJECT_DEFINED
#define _DELETEOBJECT_DEFINED
FORCEINLINE BOOL WINAPI DeleteObject(HGDIOBJ hgdiobj) {
    (void)hgdiobj; return TRUE;
}
#endif

#ifndef _LOADIMAGE_DEFINED
#define _LOADIMAGE_DEFINED
FORCEINLINE HANDLE WINAPI LoadImageA(HINSTANCE hInst, LPCSTR name,
    UINT type, int cx, int cy, UINT fuLoad)
{
    (void)hInst; (void)name; (void)type; (void)cx; (void)cy; (void)fuLoad;
    return (HANDLE)(LONG_PTR)0xBEEF;
}
FORCEINLINE HANDLE WINAPI LoadImageW(HINSTANCE hInst, LPCWSTR name,
    UINT type, int cx, int cy, UINT fuLoad)
{
    (void)hInst; (void)name; (void)type; (void)cx; (void)cy; (void)fuLoad;
    return (HANDLE)(LONG_PTR)0xBEEF;
}
#ifdef UNICODE
#define LoadImage LoadImageW
#else
#define LoadImage LoadImageA
#endif
#endif


/* Registry API minimal stubs for Rosetta 3 */
#ifndef HKEY_CURRENT_USER
#define HKEY_CURRENT_USER ((HKEY)(LONG_PTR)0x80000001)
#endif

#ifndef REG_DWORD
#define REG_SZ 1
#define REG_DWORD 4
#endif

#ifndef KEY_READ
#define KEY_READ 0x20019
#define KEY_WRITE 0x20006
#endif

#ifndef REG_OPTION_NON_VOLATILE
#define REG_OPTION_NON_VOLATILE 0
#endif

#ifndef REG_CREATED_NEW_KEY
#define REG_CREATED_NEW_KEY 1
#define REG_OPENED_EXISTING_KEY 2
#endif

#ifndef LSTATUS
typedef LONG LSTATUS;
#endif

#ifdef __cplusplus
extern "C" {
#endif

FORCEINLINE LSTATUS WINAPI RegCreateKeyExA(HKEY hKey, LPCSTR lpSubKey, DWORD Reserved, LPSTR lpClass, DWORD dwOptions, REGSAM samDesired, const SECURITY_ATTRIBUTES *lpSecurityAttributes, PHKEY phkResult, LPDWORD lpdwDisposition) {
    (void)hKey; (void)lpSubKey; (void)Reserved; (void)lpClass; (void)dwOptions; (void)samDesired; (void)lpSecurityAttributes;
    if (phkResult) *phkResult = (HKEY)(LONG_PTR)0x1234;
    if (lpdwDisposition) *lpdwDisposition = REG_OPENED_EXISTING_KEY;
    return ERROR_SUCCESS;
}

FORCEINLINE LSTATUS WINAPI RegCreateKeyExW(HKEY hKey, LPCWSTR lpSubKey, DWORD Reserved, LPWSTR lpClass, DWORD dwOptions, REGSAM samDesired, const SECURITY_ATTRIBUTES *lpSecurityAttributes, PHKEY phkResult, LPDWORD lpdwDisposition) {
    (void)hKey; (void)lpSubKey; (void)Reserved; (void)lpClass; (void)dwOptions; (void)samDesired; (void)lpSecurityAttributes;
    if (phkResult) *phkResult = (HKEY)(LONG_PTR)0x1234;
    if (lpdwDisposition) *lpdwDisposition = REG_OPENED_EXISTING_KEY;
    return ERROR_SUCCESS;
}

FORCEINLINE LSTATUS WINAPI RegQueryValueExA(HKEY hKey, LPCSTR lpValueName, LPDWORD lpReserved, LPDWORD lpType, LPBYTE lpData, LPDWORD lpcbData) {
    (void)hKey; (void)lpValueName; (void)lpReserved; (void)lpType; (void)lpData; (void)lpcbData;
    return ERROR_FILE_NOT_FOUND;
}

FORCEINLINE LSTATUS WINAPI RegQueryValueExW(HKEY hKey, LPCWSTR lpValueName, LPDWORD lpReserved, LPDWORD lpType, LPBYTE lpData, LPDWORD lpcbData) {
    (void)hKey; (void)lpValueName; (void)lpReserved; (void)lpType; (void)lpData; (void)lpcbData;
    return ERROR_FILE_NOT_FOUND;
}

FORCEINLINE LSTATUS WINAPI RegSetValueExA(HKEY hKey, LPCSTR lpValueName, DWORD Reserved, DWORD dwType, const BYTE *lpData, DWORD cbData) {
    (void)hKey; (void)lpValueName; (void)Reserved; (void)dwType; (void)lpData; (void)cbData;
    return ERROR_SUCCESS;
}

FORCEINLINE LSTATUS WINAPI RegSetValueExW(HKEY hKey, LPCWSTR lpValueName, DWORD Reserved, DWORD dwType, const BYTE *lpData, DWORD cbData) {
    (void)hKey; (void)lpValueName; (void)Reserved; (void)dwType; (void)lpData; (void)cbData;
    return ERROR_SUCCESS;
}

FORCEINLINE LSTATUS WINAPI RegCloseKey(HKEY hKey) {
    (void)hKey;
    return ERROR_SUCCESS;
}

#ifdef UNICODE
#define RegCreateKeyEx RegCreateKeyExW
#define RegQueryValueEx RegQueryValueExW
#define RegSetValueEx RegSetValueExW
#else
#define RegCreateKeyEx RegCreateKeyExA
#define RegQueryValueEx RegQueryValueExA
#define RegSetValueEx RegSetValueExA
#endif

#ifdef __cplusplus
}
#endif

/* ------------------------------------------------------------------ */
/* Callback types                                                      */
/* ------------------------------------------------------------------ */
#ifndef WNDPROC_DEFINED
#define WNDPROC_DEFINED
typedef LRESULT (WINAPI *WNDPROC)(HWND, UINT, WPARAM, LPARAM);
#endif
typedef INT_PTR (CALLBACK *DLGPROC)(HWND, UINT, WPARAM, LPARAM);
typedef void (CALLBACK *TIMERPROC)(HWND, UINT, UINT_PTR, DWORD);

/* ------------------------------------------------------------------ */
/* Common Win32 structs                                                */
/* ------------------------------------------------------------------ */
#ifndef _STARTUPINFOA_DEFINED
#define _STARTUPINFOA_DEFINED
typedef struct _STARTUPINFOA {
    DWORD  cb;
    LPSTR  lpReserved;
    LPSTR  lpDesktop;
    LPSTR  lpTitle;
    DWORD  dwX;
    DWORD  dwY;
    DWORD  dwXSize;
    DWORD  dwYSize;
    DWORD  dwXCountChars;
    DWORD  dwYCountChars;
    DWORD  dwFillAttribute;
    DWORD  dwFlags;
    WORD   wShowWindow;
    WORD   cbReserved2;
    LPBYTE lpReserved2;
    HANDLE hStdInput;
    HANDLE hStdOutput;
    HANDLE hStdError;
} STARTUPINFOA, *LPSTARTUPINFOA;
#endif

#ifndef _WNDCLASS_DEFINED
#define _WNDCLASS_DEFINED
typedef struct tagWNDCLASS {
    UINT      style;
    WNDPROC   lpfnWndProc;
    int       cbClsExtra;
    int       cbWndExtra;
    HINSTANCE hInstance;
    HICON     hIcon;
    HCURSOR   hCursor;
    HBRUSH    hbrBackground;
    LPCSTR    lpszMenuName;
    LPCSTR    lpszClassName;
} WNDCLASS, *PWNDCLASS, *LPWNDCLASS;
#endif

#ifndef _MSG_DEFINED
#define _MSG_DEFINED
typedef struct tagMSG {
    HWND   hwnd;
    UINT   message;
    WPARAM wParam;
    LPARAM lParam;
    DWORD  time;
    POINT  pt;
} MSG, *PMSG, *LPMSG;
#endif

#ifndef _PAINTSTRUCT_DEFINED
#define _PAINTSTRUCT_DEFINED
typedef struct tagPAINTSTRUCT {
    HDC  hdc;
    BOOL fErase;
    RECT rcPaint;
    BOOL fRestore;
    BOOL fIncUpdate;
    BYTE rgbReserved[32];
} PAINTSTRUCT, *PPAINTSTRUCT, *LPPAINTSTRUCT;
#endif

#ifndef _WINDOWPOS_DEFINED
#define _WINDOWPOS_DEFINED
typedef struct tagWINDOWPOS {
    HWND  hwnd;
    HWND  hwndInsertAfter;
    int   x;
    int   y;
    int   cx;
    int   cy;
    UINT  flags;
} WINDOWPOS, *LPWINDOWPOS, *PWINDOWPOS;
#endif

#ifndef _MINMAXINFO_DEFINED
#define _MINMAXINFO_DEFINED
typedef struct tagMINMAXINFO {
    POINT ptReserved;
    POINT ptMaxSize;
    POINT ptMaxPosition;
    POINT ptMinTrackSize;
    POINT ptMaxTrackSize;
} MINMAXINFO, *PMINMAXINFO, *LPMINMAXINFO;
#endif

#ifndef _SIZE_DEFINED
#define _SIZE_DEFINED
typedef struct tagSIZE {
    LONG cx;
    LONG cy;
} SIZE, *PSIZE, *LPSIZE;
#endif

/* ------------------------------------------------------------------ */
/* ------------------------------------------------------------------ */
/* Common Win32 macros                                                */
/* ------------------------------------------------------------------ */
#ifndef max
#define max(a,b) (((a) > (b)) ? (a) : (b))
#define min(a,b) (((a) < (b)) ? (a) : (b))
#endif

#ifndef lstrcpy
FORCEINLINE LPSTR WINAPI lstrcpyA(LPSTR lpString1, LPCSTR lpString2) { return strcpy(lpString1, lpString2); }
FORCEINLINE LPWSTR WINAPI lstrcpyW(LPWSTR lpString1, LPCWSTR lpString2) { return (LPWSTR)wcscpy((wchar_t*)lpString1, (const wchar_t*)lpString2); }
#ifdef UNICODE
#define lstrcpy lstrcpyW
#else
#define lstrcpy lstrcpyA
#endif
FORCEINLINE int WINAPI lstrlenA(LPCSTR lpString) { return (int)strlen(lpString); }
FORCEINLINE int WINAPI lstrlenW(LPCWSTR lpString) { return (int)wcslen((const wchar_t*)lpString); }
#ifdef UNICODE
#define lstrlen lstrlenW
#else
#define lstrlen lstrlenA
#endif
#endif

#ifndef _RELEASEDC_DEFINED
#define _RELEASEDC_DEFINED
FORCEINLINE int WINAPI ReleaseDC(HWND hWnd, HDC hDC) { (void)hWnd; (void)hDC; return 1; }
#endif

/* DrawEdge / button-edge constants */
#ifndef BDR_SUNKENOUTER
#define BDR_SUNKENOUTER    0x0002
#define BDR_RAISEDINNER    0x0004
#define BDR_RAISEDOUTER    0x0001
#define BDR_SUNKENINNER    0x0008
#define EDGE_RAISED        (BDR_RAISEDOUTER | BDR_RAISEDINNER)
#define EDGE_SUNKEN        (BDR_SUNKENOUTER | BDR_SUNKENINNER)
#define BF_LEFT            0x0001
#define BF_TOP             0x0002
#define BF_RIGHT           0x0004
#define BF_BOTTOM          0x0008
#define BF_TOPLEFT         (BF_TOP | BF_LEFT)
#define BF_TOPRIGHT        (BF_TOP | BF_RIGHT)
#define BF_BOTTOMLEFT      (BF_BOTTOM | BF_LEFT)
#define BF_BOTTOMRIGHT     (BF_BOTTOM | BF_RIGHT)
#define BF_RECT            (BF_LEFT | BF_TOP | BF_RIGHT | BF_BOTTOM)
#define BF_DIAGONAL        0x0010
#define BF_DIAGONAL_ENDTOPRIGHT   0x0020
#define BF_DIAGONAL_ENDTOPLEFT    0x0030
#define BF_DIAGONAL_ENDBOTTOMLEFT 0x0040
#define BF_DIAGONAL_ENDBOTTOMRIGHT 0x0050
#define BF_MIDDLE          0x0800
#define BF_SOFT            0x1000
#define BF_ADJUST          0x2000
#define BF_FLAT            0x4000
#define BF_MONO            0x8000
#endif

/* Window management — ROSETTA_WINDOW_MODE and non-window-mode share   */
/* the same simple FORCEINLINE stubs so the game can compile.          */
/* ------------------------------------------------------------------ */

/* Virtual window state for message loop simulation */
#ifdef __cplusplus
extern "C" {
#endif

#ifndef _GETMODULEHANDLE_DEFINED
#define _GETMODULEHANDLE_DEFINED
FORCEINLINE HMODULE WINAPI GetModuleHandleA(LPCSTR lpModuleName) {
    (void)lpModuleName;
    return (HMODULE)(LONG_PTR)0x400000;
}
FORCEINLINE HMODULE WINAPI GetModuleHandleW(LPCWSTR lpModuleName) {
    (void)lpModuleName;
    return (HMODULE)(LONG_PTR)0x400000;
}
#ifdef UNICODE
#define GetModuleHandle GetModuleHandleW
#else
#define GetModuleHandle GetModuleHandleA
#endif
#endif

#ifndef _GETCOMMANDLINE_DEFINED
#define _GETCOMMANDLINE_DEFINED
FORCEINLINE LPSTR WINAPI GetCommandLineA(void) { return (LPSTR)(""); }
FORCEINLINE LPWSTR WINAPI GetCommandLineW(void) { return (LPWSTR)L""; }
#ifdef UNICODE
#define GetCommandLine GetCommandLineW
#else
#define GetCommandLine GetCommandLineA
#endif
#endif

#ifndef _GETSTARTUPINFO_DEFINED
#define _GETSTARTUPINFO_DEFINED
FORCEINLINE void WINAPI GetStartupInfoA(LPSTARTUPINFOA lpStartupInfo) {
    if (lpStartupInfo) { memset(lpStartupInfo, 0, sizeof(STARTUPINFOA)); lpStartupInfo->cb = sizeof(STARTUPINFOA); }
}
#endif

#ifndef _EXITPROCESS_DEFINED
#define _EXITPROCESS_DEFINED
FORCEINLINE void WINAPI ExitProcess(UINT uExitCode) { exit((int)uExitCode); }
#endif

#ifndef _LOADICON_DEFINED
#define _LOADICON_DEFINED
FORCEINLINE HICON WINAPI LoadIconA(HINSTANCE hInst, LPCSTR lpIconName) {
    (void)hInst; (void)lpIconName;
    return (HICON)(LONG_PTR)0xCAFE;
}
FORCEINLINE HICON WINAPI LoadIconW(HINSTANCE hInst, LPCWSTR lpIconName) {
    (void)hInst; (void)lpIconName;
    return (HICON)(LONG_PTR)0xCAFE;
}
#ifdef UNICODE
#define LoadIcon LoadIconW
#else
#define LoadIcon LoadIconA
#endif
#endif

#ifndef _LOADCURSOR_DEFINED
#define _LOADCURSOR_DEFINED
FORCEINLINE HCURSOR WINAPI LoadCursorA(HINSTANCE hInst, LPCSTR lpCursorName) {
    (void)hInst; (void)lpCursorName;
    return (HCURSOR)(LONG_PTR)0xCAF0;
}
FORCEINLINE HCURSOR WINAPI LoadCursorW(HINSTANCE hInst, LPCWSTR lpCursorName) {
    (void)hInst; (void)lpCursorName;
    return (HCURSOR)(LONG_PTR)0xCAF0;
}
#ifdef UNICODE
#define LoadCursor LoadCursorW
#else
#define LoadCursor LoadCursorA
#endif
#endif

#ifndef _LOADSTRING_DEFINED
#define _LOADSTRING_DEFINED
FORCEINLINE int WINAPI LoadStringA(HINSTANCE hInstance, UINT uID, LPSTR lpBuffer, int cchBufferMax) {
    (void)hInstance; (void)uID; (void)lpBuffer; (void)cchBufferMax;
    return 0;
}
FORCEINLINE int WINAPI LoadStringW(HINSTANCE hInstance, UINT uID, LPWSTR lpBuffer, int cchBufferMax) {
    (void)hInstance; (void)uID; (void)lpBuffer; (void)cchBufferMax;
    return 0;
}
#ifdef UNICODE
#define LoadString LoadStringW
#else
#define LoadString LoadStringA
#endif
#endif

#ifndef _DESTROYICON_DEFINED
#define _DESTROYICON_DEFINED
FORCEINLINE BOOL WINAPI DestroyIcon(HICON hIcon) { (void)hIcon; return TRUE; }
#endif

#ifndef _MESSAGEBOX_DEFINED
#define _MESSAGEBOX_DEFINED
FORCEINLINE int WINAPI MessageBoxA(HWND hWnd, LPCSTR lpText, LPCSTR lpCaption, UINT uType) {
    (void)hWnd; (void)lpText; (void)lpCaption; (void)uType;
    return IDOK;
}
FORCEINLINE int WINAPI MessageBoxW(HWND hWnd, LPCWSTR lpText, LPCWSTR lpCaption, UINT uType) {
    (void)hWnd; (void)lpText; (void)lpCaption; (void)uType;
    return IDOK;
}
#ifdef UNICODE
#define MessageBox MessageBoxW
#else
#define MessageBox MessageBoxA
#endif
#endif

#ifndef _GETTICKCOUNT64_DEFINED
#define _GETTICKCOUNT64_DEFINED
#include <time.h>
FORCEINLINE ULONGLONG WINAPI GetTickCount64(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (ULONGLONG)ts.tv_sec * 1000ULL + (ULONGLONG)(ts.tv_nsec / 1000000L);
}
#endif

#ifndef _GETSYSTEMMETRICS_DEFINED
#define _GETSYSTEMMETRICS_DEFINED
FORCEINLINE int WINAPI GetSystemMetrics(int nIndex) {
    switch (nIndex) {
        case SM_CXSCREEN: return 1920;
        case SM_CYSCREEN: return 1080;
        case SM_CYCAPTION: return 30;
        case SM_CYMENU: return 20;
        case SM_CXBORDER: return 1;
        case SM_CYBORDER: return 1;
        case SM_CXVIRTUALSCREEN: return 1920;
        case SM_CYVIRTUALSCREEN: return 1080;
        default: return 0;
    }
}
#endif

#ifndef _CHECKMENUITEM_DEFINED
#define _CHECKMENUITEM_DEFINED
FORCEINLINE DWORD WINAPI CheckMenuItem(HMENU hMenu, UINT uIDCheckItem, UINT uCheck) {
    return rosetta_gdi_check_menu_item((void *)hMenu, uIDCheckItem, uCheck);
}
#endif

#ifndef _SETMENU_DEFINED
#define _SETMENU_DEFINED
FORCEINLINE BOOL WINAPI SetMenu(HWND hWnd, HMENU hMenu) {
    return (BOOL)rosetta_gdi_set_menu((void *)hWnd, (void *)hMenu);
}
#endif

#ifndef _GETMENUITEMRECT_DEFINED
#define _GETMENUITEMRECT_DEFINED
FORCEINLINE BOOL WINAPI GetMenuItemRect(HWND hWnd, HMENU hMenu, UINT uItem, LPRECT lprc) {
    return (BOOL)rosetta_gdi_get_menu_item_rect((void *)hWnd, (void *)hMenu, uItem, (void *)lprc);
}
#endif

#ifndef _REGISTERCLASS_DEFINED
#define _REGISTERCLASS_DEFINED
static WNDPROC g_wndproc = NULL;
static HINSTANCE g_wndproc_instance = NULL;
#ifndef UNICODE
#define RegisterClass RegisterClassA
#define DefWindowProc DefWindowProcA
#define DispatchMessage DispatchMessageA
#endif
__attribute__((unused)) static ATOM RegisterClassA(const WNDCLASS *lpWndClass) {
    if (lpWndClass) { g_wndproc = lpWndClass->lpfnWndProc; g_wndproc_instance = lpWndClass->hInstance; }
    return 1;
}
#endif

#ifndef _CREATEWINDOWEX_DEFINED
#define _CREATEWINDOWEX_DEFINED
static HWND g_main_hwnd = NULL;
__attribute__((unused)) static HWND CreateWindowExA(DWORD dwExStyle, LPCSTR lpClassName, LPCSTR lpWindowName,
    DWORD dwStyle, int X, int Y, int nWidth, int nHeight,
    HWND hWndParent, HMENU hMenu, HINSTANCE hInstance, LPVOID lpParam) {
    (void)dwExStyle; (void)lpClassName; (void)lpWindowName;
    (void)dwStyle; (void)X; (void)Y; (void)nWidth; (void)nHeight;
    (void)hWndParent; (void)hMenu; (void)hInstance; (void)lpParam;
    if (!g_main_hwnd) g_main_hwnd = (HWND)(LONG_PTR)0xDEAD;
    return g_main_hwnd;
}
#define CreateWindowA(lpClassName, lpWindowName, dwStyle, X, Y, nWidth, nHeight, hWndParent, hMenu, hInstance, lpParam) \
    CreateWindowExA(0L, lpClassName, lpWindowName, dwStyle, X, Y, nWidth, nHeight, hWndParent, hMenu, hInstance, lpParam)
#ifdef UNICODE
#define CreateWindowEx CreateWindowExW
#define CreateWindow  CreateWindowW
#else
#define CreateWindowEx CreateWindowExA
#define CreateWindow  CreateWindowA
#endif
#endif

#ifdef ROSETTA_WINDOW_MODE

/* ── GDI color table ── */
/* Stores COLORREF values for GDI handles (brushes, pens, stock objects).
   The C shim decodes handles→colors in FillRect, LineTo, etc. before
   passing resolved ARGB colors to the ObjC framebuffer layer. */

#define GDI_COLOR_TABLE_SIZE 128
static uint32_t g_gdi_color_handles[GDI_COLOR_TABLE_SIZE];
static uint32_t g_gdi_color_values[GDI_COLOR_TABLE_SIZE];
static int      g_gdi_color_count = 0;
static int      g_gdi_color_inited = 0;

/* COLORREF (0x00BBGGRR) → framebuffer ARGB (0xAARRGGBB) */
#define COLORREF_TO_FB(cr)                                     \
    ((uint32_t)(0xFF000000 | ((cr) & 0x0000FF00)              \
                           | (((cr) & 0x000000FF) << 16)       \
                           | (((cr) & 0x00FF0000) >> 16)))

static void gdi_color_register(uint32_t handle, COLORREF color) {
    if (g_gdi_color_count < GDI_COLOR_TABLE_SIZE) {
        g_gdi_color_handles[g_gdi_color_count] = handle;
        g_gdi_color_values[g_gdi_color_count]  = COLORREF_TO_FB(color);
        g_gdi_color_count++;
    }
}

static uint32_t gdi_color_lookup(uint32_t handle) {
    for (int i = 0; i < g_gdi_color_count; i++) {
        if (g_gdi_color_handles[i] == handle)
            return g_gdi_color_values[i];
    }
    return 0x00FFFFFF; /* default white */
}

static void gdi_init_stock_colors(void) {
    if (g_gdi_color_inited) return;
    g_gdi_color_inited = 1;
    /* Stock objects live at GDI_HANDLE_BASE + 100 + fnObject
       (above the created-object range 0xDE01–0xDE40). */
    gdi_color_register(GDI_HANDLE_BASE + 100 + 0, 0x00FFFFFF); /* WHITE_BRUSH */
    gdi_color_register(GDI_HANDLE_BASE + 100 + 1, 0x00C0C0C0); /* LTGRAY_BRUSH */
    gdi_color_register(GDI_HANDLE_BASE + 100 + 2, 0x00808080); /* GRAY_BRUSH */
    gdi_color_register(GDI_HANDLE_BASE + 100 + 3, 0x00404040); /* DKGRAY_BRUSH */
    gdi_color_register(GDI_HANDLE_BASE + 100 + 4, 0x00000000); /* BLACK_BRUSH */
    gdi_color_register(GDI_HANDLE_BASE + 100 + 5, 0x00FFFFFF); /* NULL_BRUSH  */
    gdi_color_register(GDI_HANDLE_BASE + 100 + 6, 0x00FFFFFF); /* WHITE_PEN   */
    gdi_color_register(GDI_HANDLE_BASE + 100 + 7, 0x00000000); /* BLACK_PEN   */
    gdi_color_register(GDI_HANDLE_BASE + 100 + 8, 0x00000000); /* NULL_PEN    */
    gdi_color_register(GDI_HANDLE_BASE + 100 + 9, 0x00FFFFFF); /* COLOR_WINDOW brush  */
    gdi_color_register(GDI_HANDLE_BASE + 100 + 10, 0x00C0C0C0);/* COLOR_3DFACE brush  */
}

/* GDI handle creation (window mode: created objects start after stock) */
#define GDI_MAX_OBJECTS 64
#define GDI_HANDLE_BASE 0xDE00
static uint32_t g_next_gdi_handle = 12;
__attribute__((unused)) static uint32_t gdi_create_handle(void) {
    uint32_t h = g_next_gdi_handle++;
    if (g_next_gdi_handle >= GDI_MAX_OBJECTS) g_next_gdi_handle = 12;
    return GDI_HANDLE_BASE + h;
}

#else

/* GDI object tracking — simple static arrays (non-window mode stub) */
#define GDI_MAX_OBJECTS 64
#define GDI_HANDLE_BASE 0xDE00
static uint32_t g_next_gdi_handle = 1;
__attribute__((unused)) static uint32_t gdi_create_handle(void) {
    uint32_t h = g_next_gdi_handle++;
    if (g_next_gdi_handle >= GDI_MAX_OBJECTS) g_next_gdi_handle = 1;
    return GDI_HANDLE_BASE + h;
}

#endif /* ROSETTA_WINDOW_MODE */

#if defined(ROSETTA_WINDOW_MODE)

#ifndef _CREATESOLIDBRUSH_DEFINED
#define _CREATESOLIDBRUSH_DEFINED
FORCEINLINE HBRUSH WINAPI CreateSolidBrush(COLORREF crColor) {
    gdi_init_stock_colors();
    uint32_t h = gdi_create_handle();
    gdi_color_register(h, crColor);
    rosetta_gdi_register_color_object(h, crColor);
    rosetta_gdi_register_object_kind(h, 1);
    return (HBRUSH)(ULONG_PTR)h;
}
#endif

#ifndef _CREATEPEN_DEFINED
#define _CREATEPEN_DEFINED
FORCEINLINE HPEN WINAPI CreatePen(int fnPenStyle, int nWidth, COLORREF crColor) {
    (void)fnPenStyle; (void)nWidth;
    gdi_init_stock_colors();
    uint32_t h = gdi_create_handle();
    gdi_color_register(h, crColor);
    rosetta_gdi_register_color_object(h, crColor);
    rosetta_gdi_register_object_kind(h, 2);
    return (HPEN)(ULONG_PTR)h;
}
#endif

#ifndef _CREATEFONT_DEFINED
#define _CREATEFONT_DEFINED
FORCEINLINE HFONT WINAPI CreateFontW(int cHeight, int cWidth, int cEscapement, int cOrientation,
    DWORD cWeight, DWORD bItalic, DWORD bUnderline, DWORD bStrikeOut,
    DWORD iCharSet, DWORD iOutPrecision, DWORD iClipPrecision,
    DWORD iQuality, DWORD iPitchAndFamily, LPCWSTR pszFaceName) {
    (void)cWidth; (void)cEscapement; (void)cOrientation;
    (void)bUnderline; (void)bStrikeOut;
    (void)iCharSet; (void)iOutPrecision; (void)iClipPrecision;
    (void)iQuality; (void)iPitchAndFamily;
    return (HFONT)(ULONG_PTR)rosetta_gdi_create_font(cHeight, (int)cWeight, (int)bItalic, pszFaceName);
}
FORCEINLINE HFONT WINAPI CreateFontA(int cHeight, int cWidth, int cEscapement, int cOrientation,
    DWORD cWeight, DWORD bItalic, DWORD bUnderline, DWORD bStrikeOut,
    DWORD iCharSet, DWORD iOutPrecision, DWORD iClipPrecision,
    DWORD iQuality, DWORD iPitchAndFamily, LPCSTR pszFaceName) {
    (void)cWidth; (void)cEscapement; (void)cOrientation;
    (void)bUnderline; (void)bStrikeOut;
    (void)iCharSet; (void)iOutPrecision; (void)iClipPrecision;
    (void)iQuality; (void)iPitchAndFamily;
    return (HFONT)(ULONG_PTR)rosetta_gdi_create_font(cHeight, (int)cWeight, 0, (const uint16_t *)pszFaceName);
}
#ifdef UNICODE
#define CreateFont CreateFontW
#else
#define CreateFont CreateFontA
#endif
#endif

#ifndef _CREATEPEN_DEFINED
#define _CREATEPEN_DEFINED
FORCEINLINE HPEN WINAPI CreatePen(int fnPenStyle, int nWidth, COLORREF crColor) {
    gdi_init_stock_colors();
    (void)fnPenStyle; (void)nWidth;
    uint32_t h = gdi_create_handle();
    gdi_color_register(h, crColor);
    return (HPEN)(ULONG_PTR)h;
}
#endif

#ifndef _CREATEFONT_DEFINED
#define _CREATEFONT_DEFINED
FORCEINLINE HFONT WINAPI CreateFontW(int cHeight, int cWidth, int cEscapement, int cOrientation,
    DWORD cWeight, DWORD bItalic, DWORD bUnderline, DWORD bStrikeOut,
    DWORD iCharSet, DWORD iOutPrecision, DWORD iClipPrecision,
    DWORD iQuality, DWORD iPitchAndFamily, LPCWSTR pszFaceName) {
    (void)cHeight; (void)cWidth; (void)cEscapement; (void)cOrientation;
    (void)cWeight; (void)bItalic; (void)bUnderline; (void)bStrikeOut;
    (void)iCharSet; (void)iOutPrecision; (void)iClipPrecision;
    (void)iQuality; (void)iPitchAndFamily; (void)pszFaceName;
    return (HFONT)(ULONG_PTR)gdi_create_handle();
}
FORCEINLINE HFONT WINAPI CreateFontA(int cHeight, int cWidth, int cEscapement, int cOrientation,
    DWORD cWeight, DWORD bItalic, DWORD bUnderline, DWORD bStrikeOut,
    DWORD iCharSet, DWORD iOutPrecision, DWORD iClipPrecision,
    DWORD iQuality, DWORD iPitchAndFamily, LPCSTR pszFaceName) {
    (void)cHeight; (void)cWidth; (void)cEscapement; (void)cOrientation;
    (void)cWeight; (void)bItalic; (void)bUnderline; (void)bStrikeOut;
    (void)iCharSet; (void)iOutPrecision; (void)iClipPrecision;
    (void)iQuality; (void)iPitchAndFamily; (void)pszFaceName;
    return (HFONT)(ULONG_PTR)gdi_create_handle();
}
#ifdef UNICODE
#define CreateFont CreateFontW
#else
#define CreateFont CreateFontA
#endif
#endif

#ifndef _FILLRECT_DEFINED
#define _FILLRECT_DEFINED
FORCEINLINE int WINAPI FillRect(HDC hDC, const RECT *lprc, HBRUSH hbr) {
    if (lprc) {
        uint32_t color = gdi_color_lookup((uint32_t)(uintptr_t)hbr);
        rosetta_gdi_fill_rect((uint32_t)(intptr_t)hDC,
                               lprc->left, lprc->top,
                               lprc->right, lprc->bottom,
                               color);
    }
    return 1;
}
#endif

#ifndef _DRAWEDGE_DEFINED
#define _DRAWEDGE_DEFINED
FORCEINLINE BOOL WINAPI DrawEdge(HDC hdc, LPRECT qrc, UINT edge, UINT grfFlags) {
    if (qrc) {
        return (BOOL)rosetta_gdi_draw_edge((uint32_t)(intptr_t)hdc,
                                            qrc->left, qrc->top,
                                            qrc->right, qrc->bottom,
                                            (uint32_t)edge, (uint32_t)grfFlags);
    }
    return TRUE;
}
#endif

#ifndef _MOVETOEX_DEFINED
#define _MOVETOEX_DEFINED
FORCEINLINE BOOL WINAPI MoveToEx(HDC hdc, int X, int Y, LPPOINT lpPoint) {
    rosetta_gdi_move_to_ex((uint32_t)(intptr_t)hdc, X, Y);
    if (lpPoint) { lpPoint->x = X; lpPoint->y = Y; }
    return TRUE;
}
#endif

#ifndef _LINETO_DEFINED
#define _LINETO_DEFINED
FORCEINLINE BOOL WINAPI LineTo(HDC hdc, int X, int Y) {
    uint32_t pen  = rosetta_gdi_get_selected_pen((uint32_t)(intptr_t)hdc);
    uint32_t color = gdi_color_lookup(pen);
    return (BOOL)rosetta_gdi_line_to((uint32_t)(intptr_t)hdc, X, Y, color);
}
#endif

#ifndef _GETSTOCKOBJECT_DEFINED
#define _GETSTOCKOBJECT_DEFINED
#define NULL_PEN     8
#define BLACK_PEN    7
#define WHITE_PEN    6
#define NULL_BRUSH   5
#define WHITE_BRUSH  0
#define LTGRAY_BRUSH 1
#define GRAY_BRUSH   2
#define DKGRAY_BRUSH 3
#define BLACK_BRUSH  4
FORCEINLINE HGDIOBJ WINAPI GetStockObject(int fnObject) {
    gdi_init_stock_colors();
    return (HGDIOBJ)(ULONG_PTR)(GDI_HANDLE_BASE + 100 + (uint32_t)fnObject);
}
#endif

#ifndef _GETSYSCOLORBRUSH_DEFINED
#define _GETSYSCOLORBRUSH_DEFINED
FORCEINLINE HBRUSH WINAPI GetSysColorBrush(int nIndex) {
    gdi_init_stock_colors();
    (void)nIndex;
    return (HBRUSH)(ULONG_PTR)(GDI_HANDLE_BASE + 100 + 9); /* COLOR_WINDOW brush */
}
#endif

#else /* !ROSETTA_WINDOW_MODE — non-window stubs */

#ifndef _CREATESOLIDBRUSH_DEFINED
#define _CREATESOLIDBRUSH_DEFINED
FORCEINLINE HBRUSH WINAPI CreateSolidBrush(COLORREF crColor) {
    (void)crColor;
    return (HBRUSH)(ULONG_PTR)gdi_create_handle();
}
#endif

#ifndef _CREATEPEN_DEFINED
#define _CREATEPEN_DEFINED
FORCEINLINE HPEN WINAPI CreatePen(int fnPenStyle, int nWidth, COLORREF crColor) {
    (void)fnPenStyle; (void)nWidth; (void)crColor;
    return (HPEN)(ULONG_PTR)gdi_create_handle();
}
#endif

#ifndef _CREATEFONT_DEFINED
#define _CREATEFONT_DEFINED
FORCEINLINE HFONT WINAPI CreateFontW(int cHeight, int cWidth, int cEscapement, int cOrientation,
    DWORD cWeight, DWORD bItalic, DWORD bUnderline, DWORD bStrikeOut,
    DWORD iCharSet, DWORD iOutPrecision, DWORD iClipPrecision,
    DWORD iQuality, DWORD iPitchAndFamily, LPCWSTR pszFaceName) {
    (void)cHeight; (void)cWidth; (void)cEscapement; (void)cOrientation;
    (void)cWeight; (void)bItalic; (void)bUnderline; (void)bStrikeOut;
    (void)iCharSet; (void)iOutPrecision; (void)iClipPrecision;
    (void)iQuality; (void)iPitchAndFamily; (void)pszFaceName;
    return (HFONT)(ULONG_PTR)gdi_create_handle();
}
FORCEINLINE HFONT WINAPI CreateFontA(int cHeight, int cWidth, int cEscapement, int cOrientation,
    DWORD cWeight, DWORD bItalic, DWORD bUnderline, DWORD bStrikeOut,
    DWORD iCharSet, DWORD iOutPrecision, DWORD iClipPrecision,
    DWORD iQuality, DWORD iPitchAndFamily, LPCSTR pszFaceName) {
    (void)cHeight; (void)cWidth; (void)cEscapement; (void)cOrientation;
    (void)cWeight; (void)bItalic; (void)bUnderline; (void)bStrikeOut;
    (void)iCharSet; (void)iOutPrecision; (void)iClipPrecision;
    (void)iQuality; (void)iPitchAndFamily; (void)pszFaceName;
    return (HFONT)(ULONG_PTR)gdi_create_handle();
}
#ifdef UNICODE
#define CreateFont CreateFontW
#else
#define CreateFont CreateFontA
#endif
#endif

#ifndef _FILLRECT_DEFINED
#define _FILLRECT_DEFINED
FORCEINLINE int WINAPI FillRect(HDC hDC, const RECT *lprc, HBRUSH hbr) {
    (void)hDC; (void)lprc; (void)hbr;
    return 1;
}
#endif

#ifndef _DRAWEDGE_DEFINED
#define _DRAWEDGE_DEFINED
FORCEINLINE BOOL WINAPI DrawEdge(HDC hdc, LPRECT qrc, UINT edge, UINT grfFlags) {
    (void)hdc; (void)qrc; (void)edge; (void)grfFlags;
    return TRUE;
}
#endif

#ifndef _MOVETOEX_DEFINED
#define _MOVETOEX_DEFINED
FORCEINLINE BOOL WINAPI MoveToEx(HDC hdc, int X, int Y, LPPOINT lpPoint) {
    (void)hdc; (void)X; (void)Y;
    if (lpPoint) { lpPoint->x = X; lpPoint->y = Y; }
    return TRUE;
}
#endif

#ifndef _LINETO_DEFINED
#define _LINETO_DEFINED
FORCEINLINE BOOL WINAPI LineTo(HDC hdc, int X, int Y) {
    (void)hdc; (void)X; (void)Y;
    return TRUE;
}
#endif

#ifndef _GETSTOCKOBJECT_DEFINED
#define _GETSTOCKOBJECT_DEFINED
#define NULL_PEN     8
#define BLACK_PEN    7
#define WHITE_PEN    6
#define NULL_BRUSH   5
#define WHITE_BRUSH  0
#define LTGRAY_BRUSH 1
#define GRAY_BRUSH   2
#define DKGRAY_BRUSH 3
#define BLACK_BRUSH  4
FORCEINLINE HGDIOBJ WINAPI GetStockObject(int fnObject) {
    (void)fnObject;
    return (HGDIOBJ)(ULONG_PTR)GDI_HANDLE_BASE;
}
#endif

#ifndef _GETSYSCOLORBRUSH_DEFINED
#define _GETSYSCOLORBRUSH_DEFINED
FORCEINLINE HBRUSH WINAPI GetSysColorBrush(int nIndex) {
    (void)nIndex;
    return (HBRUSH)(ULONG_PTR)GDI_HANDLE_BASE;
}
#endif

#endif /* ROSETTA_WINDOW_MODE */

/* ── Common drawing stubs (same in both modes) ── */

#ifndef _SETBKMODE_DEFINED
#define _SETBKMODE_DEFINED
#define TRANSPARENT 1
#define OPAQUE      2
FORCEINLINE int WINAPI SetBkMode(HDC hdc, int mode) {
#ifdef ROSETTA_WINDOW_MODE
    return rosetta_gdi_set_bk_mode((uint32_t)(uintptr_t)hdc, mode);
#endif
    (void)hdc; (void)mode;
    return OPAQUE;
}
#endif

#ifndef _SETBKCOLOR_DEFINED
#define _SETBKCOLOR_DEFINED
FORCEINLINE COLORREF WINAPI SetBkColor(HDC hdc, COLORREF crColor) {
#ifdef ROSETTA_WINDOW_MODE
    uint32_t old = rosetta_gdi_set_bk_color((uint32_t)(uintptr_t)hdc, COLORREF_TO_FB(crColor));
    return (COLORREF)(((old & 0x0000FF00))
                    | ((old & 0x00FF0000) >> 16)
                    | ((old & 0x000000FF) << 16));
#endif
    (void)hdc; (void)crColor;
    return 0;
}
#endif

#ifndef _SETTEXTCOLOR_DEFINED
#define _SETTEXTCOLOR_DEFINED
FORCEINLINE COLORREF WINAPI SetTextColor(HDC hdc, COLORREF crColor) {
#ifdef ROSETTA_WINDOW_MODE
    uint32_t old = rosetta_gdi_set_text_color((uint32_t)(uintptr_t)hdc, COLORREF_TO_FB(crColor));
    return (COLORREF)(((old & 0x0000FF00))
                    | ((old & 0x00FF0000) >> 16)
                    | ((old & 0x000000FF) << 16));
#endif
    (void)hdc; (void)crColor;
    return 0;
}
#endif

#ifndef _GETTEXTEXTENTPOINT32_DEFINED
#define _GETTEXTEXTENTPOINT32_DEFINED
FORCEINLINE BOOL WINAPI GetTextExtentPoint32W(HDC hdc, LPCWSTR lpString, int c, LPSIZE psizl) {
    if (!psizl) return TRUE;
#ifdef ROSETTA_WINDOW_MODE
    return rosetta_gdi_get_text_extent_point_32w((uint32_t)(uintptr_t)hdc, lpString, c, &psizl->cx, &psizl->cy);
#else
    psizl->cx = c * 8; psizl->cy = 16;
    return TRUE;
#endif
}
#endif

#ifndef _TEXTOUT_DEFINED
#define _TEXTOUT_DEFINED
FORCEINLINE BOOL WINAPI TextOutW(HDC hdc, int x, int y, LPCWSTR lpString, int c) {
#ifdef ROSETTA_WINDOW_MODE
    return rosetta_gdi_text_out_w((uint32_t)(uintptr_t)hdc, x, y, lpString, c);
#else
    (void)hdc; (void)x; (void)y; (void)lpString; (void)c;
    return TRUE;
#endif
}
#endif

#ifndef _ELLIPSE_DEFINED
#define _ELLIPSE_DEFINED
FORCEINLINE BOOL WINAPI Ellipse(HDC hdc, int left, int top, int right, int bottom) {
#ifdef ROSETTA_WINDOW_MODE
    return rosetta_gdi_ellipse((uint32_t)(uintptr_t)hdc, left, top, right, bottom);
#else
    (void)hdc; (void)left; (void)top; (void)right; (void)bottom;
    return TRUE;
#endif
}
#endif

#ifndef _ARC_DEFINED
#define _ARC_DEFINED
FORCEINLINE BOOL WINAPI Arc(HDC hdc, int left, int top, int right, int bottom,
    int xStart, int yStart, int xEnd, int yEnd) {
#ifdef ROSETTA_WINDOW_MODE
    return rosetta_gdi_arc((uint32_t)(uintptr_t)hdc, left, top, right, bottom, xStart, yStart, xEnd, yEnd);
#else
    (void)hdc; (void)left; (void)top; (void)right; (void)bottom;
    (void)xStart; (void)yStart; (void)xEnd; (void)yEnd;
    return TRUE;
#endif
}
#endif

#ifndef _POLYGON_DEFINED
#define _POLYGON_DEFINED
FORCEINLINE BOOL WINAPI Polygon(HDC hdc, const POINT *apt, int cpt) {
#ifdef ROSETTA_WINDOW_MODE
    return rosetta_gdi_polygon((uint32_t)(uintptr_t)hdc, (const void *)apt, cpt);
#else
    (void)hdc; (void)apt; (void)cpt;
    return TRUE;
#endif
}
#endif

#ifndef _GETLAYOUT_DEFINED
#define _GETLAYOUT_DEFINED
#define LAYOUT_RTL 0x00000001
FORCEINLINE DWORD WINAPI GetLayout(HDC hdc) { (void)hdc; return 0; }
FORCEINLINE DWORD WINAPI SetLayout(HDC hdc, DWORD dwLayout) { (void)hdc; (void)dwLayout; return 0; }
#endif

#ifndef _BEGINPAINT_DEFINED
#define _BEGINPAINT_DEFINED
FORCEINLINE HDC WINAPI BeginPaint(HWND hWnd, LPPAINTSTRUCT lpPaint) {
    (void)hWnd;
    if (lpPaint) { memset(lpPaint, 0, sizeof(PAINTSTRUCT)); }
    return (HDC)(LONG_PTR)0xDC01;
}
#endif

#ifndef _ENDPAINT_DEFINED
#define _ENDPAINT_DEFINED
FORCEINLINE BOOL WINAPI EndPaint(HWND hWnd, const PAINTSTRUCT *lpPaint) {
    (void)hWnd; (void)lpPaint;
    return TRUE;
}
#endif

#ifndef _INVALIDATERECT_DEFINED
#define _INVALIDATERECT_DEFINED
static int g_paint_pending = 1;
FORCEINLINE BOOL WINAPI InvalidateRect(HWND hWnd, const RECT *lpRect, BOOL bErase) {
    (void)hWnd; (void)lpRect; (void)bErase;
    g_paint_pending = 1;
    return TRUE;
}
#endif

#ifndef _GETCLIENTRECT_DEFINED
#define _GETCLIENTRECT_DEFINED
FORCEINLINE BOOL WINAPI GetClientRect(HWND hWnd, LPRECT lpRect) {
    (void)hWnd;
    if (lpRect) { lpRect->left = 0; lpRect->top = 0; lpRect->right = 240; lpRect->bottom = 290; }
    return TRUE;
}
#endif

#ifndef _SHOWWINDOW_DEFINED
#define _SHOWWINDOW_DEFINED
FORCEINLINE BOOL WINAPI ShowWindow(HWND hWnd, int nCmdShow) {
    (void)hWnd; (void)nCmdShow;
    return TRUE;
}
#endif

#ifndef _UPDATEWINDOW_DEFINED
#define _UPDATEWINDOW_DEFINED
FORCEINLINE BOOL WINAPI UpdateWindow(HWND hWnd) { (void)hWnd; return TRUE; }
#endif

#ifndef _MOVEHWND_DEFINED
#define _MOVEHWND_DEFINED
FORCEINLINE BOOL WINAPI MoveWindow(HWND hWnd, int X, int Y, int nWidth, int nHeight, BOOL bRepaint) {
    (void)hWnd; (void)X; (void)Y; (void)nWidth; (void)nHeight; (void)bRepaint;
    return TRUE;
}
#endif

#ifndef _ADJUSTWINDOWRECT_DEFINED
#define _ADJUSTWINDOWRECT_DEFINED
FORCEINLINE BOOL WINAPI AdjustWindowRect(LPRECT lpRect, DWORD dwStyle, BOOL bMenu) {
    (void)lpRect; (void)dwStyle; (void)bMenu;
    return TRUE;
}
#endif

#ifndef _DEFWINDOWPROC_DEFINED
#define _DEFWINDOWPROC_DEFINED
FORCEINLINE LRESULT WINAPI DefWindowProcA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam) {
    (void)hWnd; (void)Msg; (void)wParam; (void)lParam;
    return 0;
}
#endif

#ifndef _POSTQUITMESSAGE_DEFINED
#define _POSTQUITMESSAGE_DEFINED
static int g_quit_message = 0;
FORCEINLINE void WINAPI PostQuitMessage(int nExitCode) {
    (void)nExitCode;
    g_quit_message = 1;
}
#endif

#ifndef _SETCAPTURE_DEFINED
#define _SETCAPTURE_DEFINED
FORCEINLINE HWND WINAPI SetCapture(HWND hWnd) { (void)hWnd; return hWnd; }
FORCEINLINE BOOL WINAPI ReleaseCapture(void) { return TRUE; }
#endif

#ifndef _MAPWINDOWPOINTS_DEFINED
#define _MAPWINDOWPOINTS_DEFINED
FORCEINLINE int WINAPI MapWindowPoints(HWND hWndFrom, HWND hWndTo, LPPOINT lpPoints, UINT cPoints) {
    (void)hWndFrom; (void)hWndTo; (void)lpPoints; (void)cPoints;
    return 0;
}
#endif

#ifndef _LOADMENU_DEFINED
#define _LOADMENU_DEFINED
FORCEINLINE HMENU WINAPI LoadMenuA(HINSTANCE hInstance, LPCSTR lpMenuName) {
    return (HMENU)rosetta_gdi_load_menu_a((void *)hInstance, lpMenuName);
}
FORCEINLINE HMENU WINAPI LoadMenuW(HINSTANCE hInstance, LPCWSTR lpMenuName) {
    return (HMENU)rosetta_gdi_load_menu_w((void *)hInstance, lpMenuName);
}
#ifdef UNICODE
#define LoadMenu LoadMenuW
#else
#define LoadMenu LoadMenuA
#endif
#endif

#ifndef _LOADACCELERATORS_DEFINED
#define _LOADACCELERATORS_DEFINED
FORCEINLINE HANDLE WINAPI LoadAcceleratorsA(HINSTANCE hInstance, LPCSTR lpTableName) {
    (void)hInstance; (void)lpTableName;
    return (HANDLE)(LONG_PTR)0xACCE;
}
FORCEINLINE HANDLE WINAPI LoadAcceleratorsW(HINSTANCE hInstance, LPCWSTR lpTableName) {
    (void)hInstance; (void)lpTableName;
    return (HANDLE)(LONG_PTR)0xACCE;
}
#ifdef UNICODE
#define LoadAccelerators LoadAcceleratorsW
#else
#define LoadAccelerators LoadAcceleratorsA
#endif
#endif

#ifndef _TRANSLATEACCELERATOR_DEFINED
#define _TRANSLATEACCELERATOR_DEFINED
FORCEINLINE int WINAPI TranslateAccelerator(HWND hWnd, HANDLE hAccTable, LPMSG lpMsg) {
    (void)hWnd; (void)hAccTable; (void)lpMsg;
    return 0;
}
#endif

#ifndef _SETTIMER_DEFINED
#define _SETTIMER_DEFINED
static ULONGLONG g_timer_start = 0;
static UINT g_timer_id = 0;
static UINT g_timer_interval = 0;
FORCEINLINE UINT_PTR WINAPI SetTimer(HWND hWnd, UINT_PTR nIDEvent, UINT uElapse, TIMERPROC lpTimerFunc) {
    (void)hWnd; (void)lpTimerFunc;
    g_timer_id = (UINT)nIDEvent;
    g_timer_interval = uElapse;
    g_timer_start = GetTickCount64();
    return nIDEvent;
}
FORCEINLINE BOOL WINAPI KillTimer(HWND hWnd, UINT_PTR uIDEvent) {
    (void)hWnd; (void)uIDEvent;
    g_timer_id = 0;
    return TRUE;
}
#endif

#ifndef _SENDMESSAGE_DEFINED
#define _SENDMESSAGE_DEFINED
FORCEINLINE LRESULT WINAPI SendMessageA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam) {
    if (Msg == WM_SETICON && g_main_hwnd == hWnd) {}
    if (g_wndproc && hWnd == g_main_hwnd) return g_wndproc(hWnd, Msg, wParam, lParam);
    (void)wParam; (void)lParam;
    return 0;
}
FORCEINLINE LRESULT WINAPI SendMessageW(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam) {
    return SendMessageA(hWnd, Msg, wParam, lParam);
}
#ifdef UNICODE
#define SendMessage SendMessageW
#else
#define SendMessage SendMessageA
#endif
#endif

#ifndef _POSTMESSAGE_DEFINED
#define _POSTMESSAGE_DEFINED
FORCEINLINE BOOL WINAPI PostMessageA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam) {
    return (BOOL)rosetta_gdi_post_message((void *)hWnd, Msg, (uintptr_t)wParam, (intptr_t)lParam);
}
FORCEINLINE BOOL WINAPI PostMessageW(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam) {
    return PostMessageA(hWnd, Msg, wParam, lParam);
}
#ifdef UNICODE
#define PostMessage PostMessageW
#else
#define PostMessage PostMessageA
#endif
#endif

#ifndef _GETMESSAGE_DEFINED
#define _GETMESSAGE_DEFINED
/* Polling message pump — synthesizes messages from system state */
FORCEINLINE BOOL WINAPI GetMessage(LPMSG lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax) {
    (void)hWnd; (void)wMsgFilterMin; (void)wMsgFilterMax;
    if (!lpMsg) return FALSE;

    if (rosetta_gdi_pop_message((void *)lpMsg)) {
        return lpMsg->message != WM_QUIT;
    }

    /* Check if quit was posted */
    if (g_quit_message) {
        g_quit_message = 0;
        lpMsg->message = WM_QUIT;
        return FALSE;
    }

    /* Synthesize WM_PAINT */
    if (g_paint_pending) {
        g_paint_pending = 0;
        lpMsg->hwnd = g_main_hwnd;
        lpMsg->message = WM_PAINT;
        lpMsg->wParam = 0;
        lpMsg->lParam = 0;
        lpMsg->time = (DWORD)GetTickCount64();
        return TRUE;
    }

    /* Synthesize WM_TIMER */
    if (g_timer_id && g_timer_interval) {
        ULONGLONG now = GetTickCount64();
        if (now - g_timer_start >= g_timer_interval) {
            g_timer_start = now;
            lpMsg->hwnd = g_main_hwnd;
            lpMsg->message = WM_TIMER;
            lpMsg->wParam = g_timer_id;
            lpMsg->lParam = 0;
            lpMsg->time = (DWORD)now;
            return TRUE;
        }
    }

    /* Synthesize mouse messages from ObjC state */
    static int prev_mx = 0, prev_my = 0, prev_mb = 0;
    int cur_mx = rosetta_gdi_get_mouse_x();
    int cur_my = rosetta_gdi_get_mouse_y();
    int cur_mb = rosetta_gdi_get_mouse_buttons();

    /* Left button transitions */
    if ((cur_mb & 1) && !(prev_mb & 1)) {
        prev_mb = cur_mb;
        prev_mx = cur_mx; prev_my = cur_my;
        lpMsg->hwnd = g_main_hwnd;
        lpMsg->message = WM_LBUTTONDOWN;
        lpMsg->wParam = MK_LBUTTON;
        lpMsg->lParam = MAKELPARAM(cur_mx, cur_my);
        lpMsg->time = (DWORD)GetTickCount64();
        return TRUE;
    }
    if (!(cur_mb & 1) && (prev_mb & 1)) {
        prev_mb = cur_mb;
        prev_mx = cur_mx; prev_my = cur_my;
        lpMsg->hwnd = g_main_hwnd;
        lpMsg->message = WM_LBUTTONUP;
        lpMsg->wParam = 0;
        lpMsg->lParam = MAKELPARAM(cur_mx, cur_my);
        lpMsg->time = (DWORD)GetTickCount64();
        return TRUE;
    }

    /* Right button transitions */
    if ((cur_mb & 2) && !(prev_mb & 2)) {
        prev_mb = cur_mb;
        prev_mx = cur_mx; prev_my = cur_my;
        lpMsg->hwnd = g_main_hwnd;
        lpMsg->message = WM_RBUTTONDOWN;
        lpMsg->wParam = MK_RBUTTON;
        lpMsg->lParam = MAKELPARAM(cur_mx, cur_my);
        lpMsg->time = (DWORD)GetTickCount64();
        return TRUE;
    }
    if (!(cur_mb & 2) && (prev_mb & 2)) {
        prev_mb = cur_mb;
        prev_mx = cur_mx; prev_my = cur_my;
        lpMsg->hwnd = g_main_hwnd;
        lpMsg->message = WM_RBUTTONUP;
        lpMsg->wParam = 0;
        lpMsg->lParam = MAKELPARAM(cur_mx, cur_my);
        lpMsg->time = (DWORD)GetTickCount64();
        return TRUE;
    }

    /* Mouse movement (always, for cell highlighting) */
    if (cur_mx != prev_mx || cur_my != prev_my) {
        prev_mx = cur_mx; prev_my = cur_my;
        prev_mb = cur_mb;
        lpMsg->hwnd = g_main_hwnd;
        lpMsg->message = WM_MOUSEMOVE;
        lpMsg->wParam = ((cur_mb & 1) ? MK_LBUTTON : 0)
                      | ((cur_mb & 2) ? MK_RBUTTON : 0);
        lpMsg->lParam = MAKELPARAM(cur_mx, cur_my);
        lpMsg->time = (DWORD)GetTickCount64();
        return TRUE;
    }

    /* Synthesize WM_KEYDOWN for key presses */
    static int prev_vk[256] = {0};
    for (int vk = 0; vk < 256; vk++) {
        int state = GetAsyncKeyState(vk) & 0x8000;
        if (state && !prev_vk[vk]) {
            prev_vk[vk] = 1;
            lpMsg->hwnd = g_main_hwnd;
            lpMsg->message = WM_KEYDOWN;
            lpMsg->wParam = (WPARAM)vk;
            lpMsg->lParam = 0;
            lpMsg->time = (DWORD)GetTickCount64();
            return TRUE;
        }
        if (!state) prev_vk[vk] = 0;
    }

    /* No events — sleep briefly to avoid busy-wait */
    usleep(5000);
    lpMsg->hwnd = g_main_hwnd;
    lpMsg->message = WM_NULL;
    lpMsg->wParam = 0;
    lpMsg->lParam = 0;
    lpMsg->time = (DWORD)GetTickCount64();
    return TRUE;
}
#endif

#ifndef _PEEKMESSAGE_DEFINED
#define _PEEKMESSAGE_DEFINED
FORCEINLINE BOOL WINAPI PeekMessage(LPMSG lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax, UINT wRemoveMsg) {
    (void)wRemoveMsg;
    return GetMessage(lpMsg, hWnd, wMsgFilterMin, wMsgFilterMax);
}
#endif

#ifndef _TRANSLATEMESSAGE_DEFINED
#define _TRANSLATEMESSAGE_DEFINED
FORCEINLINE BOOL WINAPI TranslateMessage(const MSG *lpMsg) {
    (void)lpMsg;
    return TRUE;
}
#endif

#ifndef _DISPATCHMESSAGE_DEFINED
#define _DISPATCHMESSAGE_DEFINED
FORCEINLINE LRESULT WINAPI DispatchMessageA(const MSG *lpMsg) {
    if (g_wndproc && lpMsg->hwnd == g_main_hwnd)
        return g_wndproc(lpMsg->hwnd, lpMsg->message, lpMsg->wParam, lpMsg->lParam);
    return 0;
}
#endif

#ifndef _DIALOGBOX_DEFINED
#define _DIALOGBOX_DEFINED
FORCEINLINE INT_PTR WINAPI DialogBoxA(HINSTANCE hInstance, LPCSTR lpTemplateName, HWND hWndParent, DLGPROC lpDialogFunc) {
    (void)hInstance; (void)lpTemplateName; (void)hWndParent;
    if (lpDialogFunc) return lpDialogFunc(hWndParent, WM_INITDIALOG, 0, 0);
    return 0;
}
FORCEINLINE INT_PTR WINAPI DialogBoxW(HINSTANCE hInstance, LPCWSTR lpTemplateName, HWND hWndParent, DLGPROC lpDialogFunc) {
    (void)hInstance; (void)lpTemplateName; (void)hWndParent;
    if (lpDialogFunc) return lpDialogFunc(hWndParent, WM_INITDIALOG, 0, 0);
    return 0;
}
#ifdef UNICODE
#define DialogBox DialogBoxW
#else
#define DialogBox DialogBoxA
#endif

FORCEINLINE BOOL WINAPI EndDialog(HWND hDlg, INT_PTR nResult) {
    (void)hDlg; (void)nResult;
    return TRUE;
}

FORCEINLINE BOOL WINAPI SetDlgItemInt(HWND hDlg, int nIDDlgItem, UINT uValue, BOOL bSigned) {
    (void)hDlg; (void)nIDDlgItem; (void)uValue; (void)bSigned;
    return TRUE;
}

FORCEINLINE UINT WINAPI GetDlgItemInt(HWND hDlg, int nIDDlgItem, BOOL *lpTranslated, BOOL bSigned) {
    (void)hDlg; (void)nIDDlgItem; (void)bSigned;
    if (lpTranslated) *lpTranslated = FALSE;
    return 0;
}

FORCEINLINE BOOL WINAPI SetDlgItemTextA(HWND hDlg, int nIDDlgItem, LPCSTR lpString) {
    (void)hDlg; (void)nIDDlgItem; (void)lpString;
    return TRUE;
}
FORCEINLINE BOOL WINAPI SetDlgItemTextW(HWND hDlg, int nIDDlgItem, LPCWSTR lpString) {
    (void)hDlg; (void)nIDDlgItem; (void)lpString;
    return TRUE;
}
#ifdef UNICODE
#define SetDlgItemText SetDlgItemTextW
#else
#define SetDlgItemText SetDlgItemTextA
#endif

FORCEINLINE UINT WINAPI GetDlgItemTextA(HWND hDlg, int nIDDlgItem, LPSTR lpString, int cchMax) {
    (void)hDlg; (void)nIDDlgItem; (void)lpString; (void)cchMax;
    return 0;
}
FORCEINLINE UINT WINAPI GetDlgItemTextW(HWND hDlg, int nIDDlgItem, LPWSTR lpString, int cchMax) {
    (void)hDlg; (void)nIDDlgItem; (void)lpString; (void)cchMax;
    return 0;
}
#ifdef UNICODE
#define GetDlgItemText GetDlgItemTextW
#else
#define GetDlgItemText GetDlgItemTextA
#endif

FORCEINLINE HWND WINAPI GetDlgItem(HWND hDlg, int nIDDlgItem) {
    (void)hDlg; (void)nIDDlgItem;
    return (HWND)(LONG_PTR)0x1001;
}
#endif

#ifndef _SETCURSOR_DEFINED
#define _SETCURSOR_DEFINED
FORCEINLINE HCURSOR WINAPI SetCursor(HCURSOR hCursor) { (void)hCursor; return (HCURSOR)(LONG_PTR)0xCAF0; }
#endif

#ifndef _SETWINDOWLONG_DEFINED
#define _SETWINDOWLONG_DEFINED
#ifndef GWL_STYLE
#define GWL_STYLE   (-16)
#define GWL_EXSTYLE (-20)
#endif
FORCEINLINE LONG_PTR WINAPI SetWindowLongA(HWND hWnd, int nIndex, LONG_PTR dwNewLong) {
    (void)hWnd; (void)nIndex; (void)dwNewLong;
    return 0;
}
FORCEINLINE LONG_PTR WINAPI SetWindowLongW(HWND hWnd, int nIndex, LONG_PTR dwNewLong) {
    (void)hWnd; (void)nIndex; (void)dwNewLong;
    return 0;
}
#ifdef UNICODE
#define SetWindowLong SetWindowLongW
#else
#define SetWindowLong SetWindowLongA
#endif
#endif

#ifndef _SETWINDOWLONGPTR_DEFINED
#define _SETWINDOWLONGPTR_DEFINED
#define SetWindowLongPtrA SetWindowLongA
#define SetWindowLongPtrW SetWindowLongW
#ifdef UNICODE
#define SetWindowLongPtr SetWindowLongPtrW
#else
#define SetWindowLongPtr SetWindowLongPtrA
#endif
#endif

#ifndef _INFLATERECT_DEFINED
#define _INFLATERECT_DEFINED
FORCEINLINE BOOL WINAPI InflateRect(LPRECT lprc, int dx, int dy) {
    if (lprc) { lprc->left -= dx; lprc->right += dx; lprc->top -= dy; lprc->bottom += dy; }
    return TRUE;
}
FORCEINLINE BOOL WINAPI OffsetRect(LPRECT lprc, int dx, int dy) {
    if (lprc) { lprc->left += dx; lprc->right += dx; lprc->top += dy; lprc->bottom += dy; }
    return TRUE;
}
FORCEINLINE BOOL WINAPI SetRect(LPRECT lprc, int xLeft, int yTop, int xRight, int yBottom) {
    if (lprc) { lprc->left = xLeft; lprc->top = yTop; lprc->right = xRight; lprc->bottom = yBottom; }
    return TRUE;
}
#endif

#ifndef _PTINRECT_DEFINED
#define _PTINRECT_DEFINED
FORCEINLINE BOOL WINAPI PtInRect(const RECT *lprc, POINT pt) {
    return (BOOL)(lprc && pt.x >= lprc->left && pt.x < lprc->right && pt.y >= lprc->top && pt.y < lprc->bottom);
}
#endif

#ifndef _COPYRECT_DEFINED
#define _COPYRECT_DEFINED
FORCEINLINE BOOL WINAPI CopyRect(LPRECT lprcDst, const RECT *lprcSrc) {
    if (lprcDst && lprcSrc) *lprcDst = *lprcSrc;
    return TRUE;
}
#endif

#ifndef _ISWINDOW_DEFINED
#define _ISWINDOW_DEFINED
FORCEINLINE BOOL WINAPI IsWindow(HWND hWnd) { (void)hWnd; return TRUE; }
#endif

#ifndef _GETWINDOWTEXT_DEFINED
#define _GETWINDOWTEXT_DEFINED
FORCEINLINE int WINAPI GetWindowTextA(HWND hWnd, LPSTR lpString, int nMaxCount) {
    (void)hWnd; (void)lpString; (void)nMaxCount;
    return 0;
}
#endif

#ifndef _ENABLEWINDOW_DEFINED
#define _ENABLEWINDOW_DEFINED
FORCEINLINE BOOL WINAPI EnableWindow(HWND hWnd, BOOL bEnable) {
    (void)hWnd; (void)bEnable;
    return TRUE;
}
#endif

#ifndef _GETWINDOWRECT_DEFINED
#define _GETWINDOWRECT_DEFINED
FORCEINLINE BOOL WINAPI GetWindowRect(HWND hWnd, LPRECT lpRect) {
    (void)hWnd;
    if (lpRect) { lpRect->left = 0; lpRect->top = 0; lpRect->right = 240; lpRect->bottom = 290; }
    return TRUE;
}
#endif

#ifndef _SCREENTOCLIENT_DEFINED
#define _SCREENTOCLIENT_DEFINED
FORCEINLINE BOOL WINAPI ScreenToClient(HWND hWnd, LPPOINT lpPoint) {
    (void)hWnd; (void)lpPoint;
    return TRUE;
}
#endif

#ifndef _CLIENTTOSCREEN_DEFINED
#define _CLIENTTOSCREEN_DEFINED
FORCEINLINE BOOL WINAPI ClientToScreen(HWND hWnd, LPPOINT lpPoint) {
    (void)hWnd; (void)lpPoint;
    return TRUE;
}
#endif

#ifndef _GETCURSORPOS_DEFINED
#define _GETCURSORPOS_DEFINED
FORCEINLINE BOOL WINAPI GetCursorPos(LPPOINT lpPoint) {
    if (lpPoint) { lpPoint->x = 0; lpPoint->y = 0; }
    return TRUE;
}
#endif

#ifndef _WINDOWFROMDC_DEFINED
#define _WINDOWFROMDC_DEFINED
FORCEINLINE HWND WINAPI WindowFromDC(HDC hdc) {
    (void)hdc;
    return g_main_hwnd;
}
#endif

#ifndef _WINDOWFROMPOINT_DEFINED
#define _WINDOWFROMPOINT_DEFINED
FORCEINLINE HWND WINAPI WindowFromPoint(POINT Point) {
    (void)Point;
    return g_main_hwnd;
}
#endif

#ifndef _GETCLASSINFO_DEFINED
#define _GETCLASSINFO_DEFINED
FORCEINLINE BOOL WINAPI GetClassInfoA(HINSTANCE hInstance, LPCSTR lpClassName, LPWNDCLASS lpWndClass) {
    (void)hInstance; (void)lpClassName;
    if (lpWndClass) memset(lpWndClass, 0, sizeof(WNDCLASS));
    return TRUE;
}
#endif

#ifndef _OPENCLIPBOARD_DEFINED
#define _OPENCLIPBOARD_DEFINED
FORCEINLINE BOOL WINAPI OpenClipboard(HWND hWndNewOwner) { (void)hWndNewOwner; return TRUE; }
FORCEINLINE BOOL WINAPI CloseClipboard(void) { return TRUE; }
FORCEINLINE BOOL WINAPI EmptyClipboard(void) { return TRUE; }
#endif

#ifndef _GDI_DELETEDC_DEFINED
#define _GDI_DELETEDC_DEFINED
FORCEINLINE BOOL WINAPI DeleteDC(HDC hdc) {
    (void)hdc;
    return DeleteObject((HGDIOBJ)hdc);
}
#endif

#ifndef _CREATECOMPATIBLEBITMAP_DEFINED
#define _CREATECOMPATIBLEBITMAP_DEFINED
FORCEINLINE HBITMAP WINAPI CreateCompatibleBitmap(HDC hdc, int cx, int cy) {
    (void)hdc;
    return (HBITMAP)(ULONG_PTR)rosetta_gdi_create_compatible_bitmap(cx, cy);
}
#endif

#ifndef _COLORREF_DEFINED
#define _COLORREF_DEFINED
#define RGB(r,g,b) ((COLORREF)(((BYTE)(r)|((WORD)((BYTE)(g))<<8))|(((DWORD)(BYTE)(b))<<16)))
#define GetRValue(rgb) ((BYTE)(rgb))
#define GetGValue(rgb) ((BYTE)(((WORD)(rgb)) >> 8))
#define GetBValue(rgb) ((BYTE)((rgb) >> 16))
#endif

#ifndef _DEFAULT_CHARSET
#define ANSI_CHARSET       0
#define DEFAULT_CHARSET    1
#define SYMBOL_CHARSET     2
#define OUT_DEFAULT_PRECIS  0
#define CLIP_DEFAULT_PRECIS 0
#define DEFAULT_QUALITY     0
#define CLEARTYPE_QUALITY   5
#define DEFAULT_PITCH       0
#define FIXED_PITCH         1
#define FF_DONTCARE         0
#define FF_MODERN           48
#define FW_BOLD             700
#define FW_HEAVY            900
#endif

#ifndef _PS_SOLID
#define PS_SOLID            0
#define PS_DASH             1
#define PS_DOT              2
#endif

#ifndef _NULL_PEN
#define NULL_PEN            8
#define BLACK_PEN           7
#define WHITE_PEN           6
#endif

#ifndef _EM_GETSEL
#define EM_GETSEL           0x00B0
#define EM_SETSEL           0x00B1
#define EM_REPLACESEL       0x00C2
#define EM_LIMITTEXT        0x00C5
#endif

#ifndef _CS_HREDRAW
#define CS_HREDRAW          0x0002
#define CS_VREDRAW          0x0001
#define CS_DBLCLKS          0x0008
#define CS_OWNDC            0x0020
#endif

#ifndef _CW_USEDEFAULT
#define CW_USEDEFAULT       ((int)0x80000000)
#endif

#ifndef _WA_ACTIVE
#define WA_ACTIVE           1
#define WA_CLICKACTIVE      2
#define WA_INACTIVE         0
#endif

#ifndef _SIZE_MINIMIZED
#define SIZE_MINIMIZED      1
#define SIZE_MAXIMIZED      2
#define SIZE_RESTORED       0
#endif

#ifndef _WM_DRAWITEM
#define WM_DRAWITEM         0x002B
#define WM_MEASUREITEM      0x002C
#endif

#ifndef _ODT_MENU
#define ODT_MENU            1
#define ODT_BUTTON          2
#define ODT_COMBOBOX        3
#endif

#ifndef _DIB_RGB_COLORS
#define DIB_RGB_COLORS      0
#endif

#ifndef _MIIM_STATE
#define MIIM_STATE          1
#define MIIM_ID             2
#define MIIM_SUBMENU        4
#define MIIM_TYPE           16
#define MIIM_STRING         64
#endif

#ifndef _MF_SEPARATOR
#define MF_SEPARATOR        0x00000800L
#define MF_POPUP            0x00000010L
#define MF_STRING           0x00000000L
#define MF_ENABLED          0x00000000L
#define MF_GRAYED           0x00000001L
#define MF_DISABLED         0x00000002L
#define MF_BITMAP           0x00000004L
#define MF_OWNERDRAW        0x00000100L
#define MF_MENUBARBREAK     0x00000020L
#define MF_MENUBREAK        0x00000040L
#define MF_HELP             0x00004000L
#endif

#ifndef _TPM_LEFTALIGN
#define TPM_LEFTALIGN       0x0000
#define TPM_RETURNCMD       0x0100
#endif

#ifndef _RDW_INVALIDATE
#define RDW_INVALIDATE      0x0001
#define RDW_UPDATENOW       0x0100
#define RDW_ALLCHILDREN     0x0080
#endif

#ifndef _DT_LEFT
#define DT_LEFT             0x00000000
#define DT_CENTER           0x00000001
#define DT_RIGHT            0x00000002
#define DT_VCENTER          0x00000004
#define DT_SINGLELINE       0x00000020
#define DT_NOCLIP           0x00000100
#endif

#ifndef _WS_EX_CLIENTEDGE
#define WS_EX_CLIENTEDGE    0x00000200
#define WS_EX_WINDOWEDGE    0x00000100
#define WS_EX_OVERLAPPEDWINDOW (WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE)
#endif

#ifndef _WS_OVERLAPPEDWINDOW
#define WS_OVERLAPPEDWINDOW (WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX)
#define WS_POPUPWINDOW      (WS_POPUP | WS_BORDER | WS_SYSMENU)
#endif

#ifndef _LBS_NOTIFY
#define LBS_NOTIFY          0x0001
#define LBS_SORT            0x0002
#define LBS_STANDARD        (LBS_NOTIFY | LBS_SORT | WS_BORDER | WS_VSCROLL)
#endif

#ifndef _CBS_DROPDOWN
#define CBS_DROPDOWN        2
#define CBS_DROPDOWNLIST    3
#endif

#ifndef _SBS_HORZ
#define SBS_HORZ            0
#define SBS_VERT            1
#endif

#ifndef _PBS_SMOOTH
#define PBS_SMOOTH          1
#endif

#ifndef _PROGRESS_CLASS
#define PROGRESS_CLASS      "msctls_progress32"
#endif

#ifndef _TRACKBAR_CLASS
#define TRACKBAR_CLASS      "msctls_trackbar32"
#endif

#ifndef _UPDOWN_CLASS
#define UPDOWN_CLASS        "msctls_updown32"
#endif

#ifndef _HINSTANCE_COMMCTRL
#define HINSTANCE_COMMCTRL  ((HINSTANCE)(LONG_PTR)-1)
#endif

#ifndef _WC_EDIT
#define WC_EDIT             "Edit"
#define WC_BUTTON           "Button"
#define WC_STATIC           "Static"
#define WC_LISTBOX          "ListBox"
#define WC_COMBOBOX         "ComboBox"
#define WC_SCROLLBAR        "ScrollBar"
#endif

#ifndef _ES_LEFT
#define ES_LEFT             0x0000
#define ES_CENTER           0x0001
#define ES_RIGHT            0x0002
#define ES_MULTILINE        0x0004
#define ES_AUTOHSCROLL      0x0080
#define ES_AUTOVSCROLL      0x0040
#define ES_NUMBER           0x2000
#define ES_READONLY         0x0800
#endif

#ifndef _SS_LEFT
#define SS_LEFT             0x00000000
#define SS_CENTER           0x00000001
#define SS_RIGHT            0x00000002
#define SS_SUNKEN           0x00001000
#define SS_BITMAP           0x0000000E
#define SS_ICON             0x00000003
#endif

#ifndef _BS_PUSHBUTTON
#define BS_PUSHBUTTON       0x00000000
#define BS_DEFPUSHBUTTON    0x00000001
#define BS_CHECKBOX         0x00000002
#define BS_AUTOCHECKBOX     0x00000003
#define BS_RADIOBUTTON      0x00000004
#define BS_GROUPBOX         0x00000007
#define BS_OWNERDRAW        0x0000000B
#define BS_TEXT             0x00000000
#endif

#ifndef _SS_BLACKFRAME
#define SS_BLACKFRAME       7
#define SS_GRAYFRAME        8
#define SS_WHITEFRAME       9
#define SS_BLACKRECT        4
#define SS_GRAYRECT         5
#define SS_WHITERECT        6
#define SS_ETCHEDHORZ       16
#define SS_ETCHEDVERT       17
#define SS_ETCHEDFRAME      18
#endif

#ifndef _WS_CHILDWINDOW
#define WS_CHILDWINDOW      (WS_CHILD)
#endif

#ifndef _WS_TILED
#define WS_TILED            WS_OVERLAPPED
#define WS_ICONIC           WS_MINIMIZE
#define WS_MAXIMIZE         0x01000000
#define WS_MAXIMIZEBOX      0x00010000
#define WS_MINIMIZE         0x20000000
#endif

#ifndef _SW_MAXIMIZE
#define SW_MAXIMIZE         3
#define SW_MINIMIZE         6
#define SW_RESTORE          9
#endif

/* Common Control styles */
#ifndef _CCS_TOP
#define CCS_TOP             0x00000001
#define CCS_NOMOVEY         0x00000002
#define CCS_BOTTOM          0x00000003
#define CCS_NORESIZE        0x00000004
#define CCS_NOPARENTALIGN   0x00000008
#define CCS_ADJUSTABLE      0x00000020
#define CCS_NODIVIDER       0x00000040
#define CCS_VERT            0x00000080
#define CCS_LEFT            (CCS_VERT | CCS_TOP)
#define CCS_RIGHT           (CCS_VERT | CCS_BOTTOM)
#endif

#ifndef _TBSTATE_CHECKED
#define TBSTATE_CHECKED      0x01
#define TBSTATE_ENABLED      0x04
#define TBSTATE_HIDDEN       0x08
#define TBSTATE_INDETERMINATE 0x10
#define TBSTATE_WRAP         0x20
#endif

#ifndef _TBSTYLE_BUTTON
#define TBSTYLE_BUTTON       0x0000
#define TBSTYLE_SEP          0x0001
#define TBSTYLE_CHECK        0x0002
#define TBSTYLE_GROUP        0x0004
#define TBSTYLE_CHECKGROUP   (TBSTYLE_CHECK | TBSTYLE_GROUP)
#define TBSTYLE_DROPDOWN     0x0008
#define TBSTYLE_AUTOSIZE     0x0010
#define TBSTYLE_TOOLTIPS     0x0100
#define TBSTYLE_WRAPABLE     0x0200
#define TBSTYLE_ALTDRAG      0x0400
#define TBSTYLE_FLAT         0x0800
#define TBSTYLE_LIST         0x1000
#define TBSTYLE_TRANSPARENT  0x8000
#endif

#ifndef _BTNS_BUTTON
#define BTNS_BUTTON          TBSTYLE_BUTTON
#define BTNS_SEP             TBSTYLE_SEP
#define BTNS_CHECK           TBSTYLE_CHECK
#define BTNS_GROUP           TBSTYLE_GROUP
#define BTNS_CHECKGROUP      TBSTYLE_CHECKGROUP
#define BTNS_DROPDOWN        TBSTYLE_DROPDOWN
#define BTNS_AUTOSIZE        TBSTYLE_AUTOSIZE
#define BTNS_SHOWTEXT        0x0040
#endif

#ifndef _TBIF_COMMAND
#define TBIF_COMMAND         0x00000020
#define TBIF_IMAGE           0x00000001
#define TBIF_STYLE           0x00000008
#define TBIF_SIZE            0x00000040
#define TBIF_STATE           0x00000004
#define TBIF_TEXT            0x00000010
#define TBIF_LPARAM          0x00000010
#endif

#ifndef _TB_GETBUTTON
#define TB_ADDBUTTONSA        0x0444
#define TB_ADDBUTTONSW        0x0454
#define TB_GETBUTTON          0x0417
#define TB_BUTTONSTRUCTSIZE   0x041E
#define TB_SETBUTTONSIZE      0x041F
#define TB_SETBITMAPSIZE      0x0420
#define TB_ADDBITMAP          0x0414
#define TB_GETTOOLTIPS        0x0423
#define TB_SETTOOLTIPS        0x0424
#define TB_AUTOSIZE           0x0421
#define TB_GETRECT            0x0433
#define TB_GETBUTTONTEXT      0x042B
#define TB_GETBUTTONINFO      0x0441
#define TB_SETBUTTONINFO      0x0442
#define TB_GETSTRING          0x045D
#endif

#ifndef _COLORREF_MAX
#define CLR_NONE             0xFFFFFFFF
#define CLR_DEFAULT          0xFF000000
#endif

#ifndef _HINSTANCE_ERROR
#define HINSTANCE_ERROR      ((HINSTANCE)(LONG_PTR)32)
#endif

#ifdef __cplusplus
}
#endif

#pragma clang diagnostic pop

#endif /* ROSETTA3_SHIMS_WIN32_WINDOWS_H */
