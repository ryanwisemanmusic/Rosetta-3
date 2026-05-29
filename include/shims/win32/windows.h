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

/* ========================================================================== */
/* Console handle constants (canonically in win32/io.h).                      */
/* ========================================================================== */
#ifndef STD_INPUT_HANDLE
#define STD_INPUT_HANDLE        ((DWORD)-10)
#define STD_OUTPUT_HANDLE       ((DWORD)-11)
#define STD_ERROR_HANDLE        ((DWORD)-12)
#endif

/* ========================================================================== */
/* Console color constants (canonically in win32/io.h).                       */
/* ========================================================================== */
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

/* ========================================================================== */
/* Console cursor and coordinate types.                                       */
/* ========================================================================== */
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

/* ========================================================================== */
/* Window-mode backend — forward declarations for the ObjC library            */
/* ========================================================================== */
#ifdef ROSETTA_WINDOW_MODE

/* The ObjC library (window_main.m) provides these C-linkage entry points. */
void *rosetta_get_std_handle(unsigned long nStdHandle);
void  rosetta_set_console_text_attribute(void *hConsole,
                                         unsigned short wAttributes);
void  rosetta_set_console_cursor_position(void *hConsole,
                                          int x, int y);
void  rosetta_set_console_cursor_info(void *hConsole,
                                      void *lpConsoleCursorInfo);
int   rosetta_kbhit(void);
int   rosetta_getch(void);

/* Shims that call the ObjC backend instead of ANSI escapes. */
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

/* ---- std::cout redirection (implemented in cout_bridge.cpp) ---- */
extern void rosetta_cout_redirect(void);
extern void rosetta_cout_restore(void);

/* ---- system("cls") intercept for Window mode ---- */
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

#else  /* !ROSETTA_WINDOW_MODE — default ANSI escape code backend */

/* ========================================================================== */
/* Console function implementations (ANSI escape codes on macOS / Linux).     */
/* ========================================================================== */

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

/* ========================================================================== */
/* system() interception — map "cls" (Windows cmd.exe clear-screen) to ANSI   */
/* escape sequences on non-Windows platforms.  Define ROSETTA_NO_SYSTEM_CLS   */
/* before including windows.h to disable.                                     */
/*                                                                             */
/* Only applies in ANSI-escape mode; in window mode the game is linked against */
/* the ObjC library which handles "cls" at the application level.              */
/* ========================================================================== */
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

#endif /* ROSETTA3_SHIMS_WIN32_WINDOWS_H */
