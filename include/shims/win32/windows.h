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

#include <stdio.h>
#include "windows_base.h"
#include "synchapi.h"

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

void *rosetta_get_std_handle(unsigned long nStdHandle);
void  rosetta_set_console_text_attribute(void *hConsole,
                                         unsigned short wAttributes);
void  rosetta_set_console_cursor_position(void *hConsole,
                                          int x, int y);
void  rosetta_set_console_cursor_info(void *hConsole,
                                      void *lpConsoleCursorInfo);
int   rosetta_kbhit(void);
int   rosetta_getch(void);

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

extern void rosetta_cout_redirect(void);
extern void rosetta_cout_restore(void);

extern void rosetta_console_clear_screen(void);

#ifndef ROSETTA_NO_SYSTEM_CLS
#include <stdlib.h>

static inline int rosetta_system(const char *cmd)
{
    if (cmd && cmd[0] == 'c' && cmd[1] == 'l' && cmd[2] == 's' && cmd[3] == '\0') {
        rosetta_console_clear_screen();
        return 0;
    }
    return (system)(cmd);
}
#define system rosetta_system
#endif

/* window_gdi.m */
extern uint32_t rosetta_gdi_get_dc(void *hwnd);
extern uint32_t rosetta_gdi_create_compatible_dc(uint32_t hdc);
extern uint32_t rosetta_gdi_select_object(uint32_t hdc, uint32_t hgdiobj);
extern int      rosetta_gdi_bitblt(uint32_t hdc_dest, int x_dest, int y_dest,
                                   int w, int h, uint32_t hdc_src,
                                   int x_src, int y_src, uint32_t dw_rop);
extern int      rosetta_gdi_delete_object(uint32_t hgdiobj);
extern uint32_t rosetta_gdi_load_image_a(void *hInst, const char *name,
                                          uint32_t type, int cx, int cy,
                                          uint32_t fuLoad);
extern uint32_t rosetta_gdi_load_image_w(void *hInst, const unsigned short *name,
                                          uint32_t type, int cx, int cy,
                                          uint32_t fuLoad);
extern void    *rosetta_gdi_get_console_window(void);
extern void     rosetta_gdi_set_console_title(const char *title);
extern void     rosetta_gdi_set_window_pos(void *hwnd, void *insert_after,
                                            int x, int y, int cx, int cy,
                                            unsigned int flags);
extern int      rosetta_gdi_get_console_screen_buffer_info(void *handle,
                                                            void *lpInfo);
extern int      rosetta_gdi_set_console_screen_buffer_size(void *handle,
                                                            short x, short y);
extern short    rosetta_gdi_get_async_key_state(int vKey);
extern void    *rosetta_gdi_get_foreground_window(void);
extern void    *rosetta_gdi_monitor_from_window(void *hwnd, unsigned long flags);
extern int      rosetta_gdi_get_monitor_info_a(void *hMonitor, void *lpmi);
extern int      rosetta_gdi_get_monitor_info_w(void *hMonitor, void *lpmi);
extern int      rosetta_gdi_enum_display_settings_a(const char *device_name,
                                                     unsigned int mode_num,
                                                     void *lpDevMode);
extern int      rosetta_gdi_enum_display_settings_w(const unsigned short *dev,
                                                     unsigned int mode_num,
                                                     void *lpDevMode);
extern int      rosetta_gdi_play_sound_a(const char *pszSound, void *hmod,
                                          unsigned long fdwSound);
extern int      rosetta_gdi_play_sound_w(const unsigned short *pszSound,
                                          void *hmod, unsigned long fdwSound);
extern int      rosetta_gdi_mci_send_string_a(const char *command,
                                               char *ret_str,
                                               unsigned int ret_len,
                                               void *callback);
extern int      rosetta_gdi_mci_send_string_w(const unsigned short *command,
                                               unsigned short *ret_str,
                                               unsigned int ret_len,
                                               void *callback);

struct _CONSOLE_SCREEN_BUFFER_INFO;
typedef struct _CONSOLE_SCREEN_BUFFER_INFO *PCONSOLE_SCREEN_BUFFER_INFO;
struct HMONITOR__;
typedef struct HMONITOR__ *HMONITOR;
struct tagMONITORINFO;
typedef struct tagMONITORINFO *LPMONITORINFO;
struct _devicemodeA;
typedef struct _devicemodeA *LPDEVMODEA;
struct _devicemodeW;
typedef struct _devicemodeW *LPDEVMODEW;
#ifndef MMRESULT
typedef unsigned int MMRESULT;
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

#ifndef MCISENDSTRING_DEFINED
#define MCISENDSTRING_DEFINED
FORCEINLINE MMRESULT WINAPI mciSendStringA(
    LPCSTR lpstrCommand, LPSTR lpstrReturnString,
    UINT uReturnLength, HANDLE hwndCallback)
{
    return (MMRESULT)rosetta_gdi_mci_send_string_a(
        lpstrCommand, lpstrReturnString, uReturnLength, (void *)hwndCallback);
}
FORCEINLINE MMRESULT WINAPI mciSendStringW(
    LPCWSTR lpstrCommand, LPWSTR lpstrReturnString,
    UINT uReturnLength, HANDLE hwndCallback)
{
    (void)lpstrReturnString;
    return (MMRESULT)rosetta_gdi_mci_send_string_a(
        "", NULL, 0, (void *)hwndCallback);
}
#ifdef UNICODE
#define mciSendString mciSendStringW
#else
#define mciSendString mciSendStringA
#endif
#endif

#ifndef _PLAYSOUND_DEFINED
#define _PLAYSOUND_DEFINED
FORCEINLINE BOOL WINAPI PlaySoundA(LPCSTR pszSound, HANDLE hmod, DWORD fdwSound) {
    return (BOOL)rosetta_gdi_play_sound_a(
        pszSound, (void *)hmod, (unsigned long)fdwSound);
}
FORCEINLINE BOOL WINAPI PlaySoundW(LPCWSTR pszSound, HANDLE hmod, DWORD fdwSound) {
    return (BOOL)rosetta_gdi_play_sound_a(
        "", (void *)hmod, (unsigned long)fdwSound);
}
#ifdef UNICODE
#define PlaySound PlaySoundW
#else
#define PlaySound PlaySoundA
#endif
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
} POINT, *PPOINT;
#endif

#ifndef _RECT_DEFINED
#define _RECT_DEFINED
typedef struct tagRECT {
    LONG left;
    LONG top;
    LONG right;
    LONG bottom;
} RECT, *PRECT;
#endif

#ifndef DECLARE_HANDLE
#define DECLARE_HANDLE(name) struct name##__{int unused;}; typedef struct name##__ *name
#endif

#ifndef MMRESULT
typedef UINT MMRESULT;
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

#ifndef MCISENDSTRING_DEFINED
#define MCISENDSTRING_DEFINED
FORCEINLINE MMRESULT WINAPI mciSendStringA(
    LPCSTR lpstrCommand, LPSTR lpstrReturnString,
    UINT uReturnLength, HANDLE hwndCallback)
{
    (void)lpstrCommand; (void)lpstrReturnString;
    (void)uReturnLength; (void)hwndCallback;
    return 0;
}
FORCEINLINE MMRESULT WINAPI mciSendStringW(
    LPCWSTR lpstrCommand, LPWSTR lpstrReturnString,
    UINT uReturnLength, HANDLE hwndCallback)
{
    (void)lpstrCommand; (void)lpstrReturnString;
    (void)uReturnLength; (void)hwndCallback;
    return 0;
}
#ifdef UNICODE
#define mciSendString mciSendStringW
#else
#define mciSendString mciSendStringA
#endif
#endif

#ifndef SND_FILENAME
#define SND_FILENAME                0x00020000
#endif
#ifndef SND_ASYNC
#define SND_ASYNC                   0x00000001
#endif

#ifndef _PLAYSOUND_DEFINED
#define _PLAYSOUND_DEFINED
FORCEINLINE BOOL WINAPI PlaySoundA(LPCSTR pszSound, HANDLE hmod, DWORD fdwSound) {
    (void)pszSound; (void)hmod; (void)fdwSound; return TRUE;
}
FORCEINLINE BOOL WINAPI PlaySoundW(LPCWSTR pszSound, HANDLE hmod, DWORD fdwSound) {
    (void)pszSound; (void)hmod; (void)fdwSound; return TRUE;
}
#ifdef UNICODE
#define PlaySound PlaySoundW
#else
#define PlaySound PlaySoundA
#endif
#endif

#endif /* ROSETTA3_SHIMS_WIN32_WINDOWS_H */
