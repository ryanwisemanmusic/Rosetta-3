#ifndef ROSETTA3_WIN32_BRIDGE_H
#define ROSETTA3_WIN32_BRIDGE_H

#include "win32/windows_base.h"

#ifndef _RTL_BARRIER_DEFINED
#define _RTL_BARRIER_DEFINED
typedef struct _RTL_BARRIER { ULONG_PTR Reserved[5]; } RTL_BARRIER, *PRTL_BARRIER;
#endif

#include "win32/atomic.h"
#include "win32/dbghelp.h"
#include "win32/dds.h"
#include "win32/fiber.h"
#include "win32/file.h"
#include "win32/gdi.h"
#include "win32/intrin.h"
#include "win32/io.h"
#include "win32/process.h"
#include "win32/synchapi.h"
#include "win32/threads.h"
#include "win32/window.h"

#ifndef _WINDOWS_STRUCTS_BRIDGE
#define _WINDOWS_STRUCTS_BRIDGE

/* window.h */
typedef struct _RECT {
    LONG left;
    LONG top;
    LONG right;
    LONG bottom;
} RECT, *PRECT, *LPRECT;

typedef struct tagPOINT {
    LONG x;
    LONG y;
} POINT, *PPOINT;

/* io.h */
typedef struct _COORD {
    SHORT X;
    SHORT Y;
} COORD, *PCOORD;

typedef struct _SMALL_RECT {
    SHORT Left;
    SHORT Top;
    SHORT Right;
    SHORT Bottom;
} SMALL_RECT;

/* console */
#ifndef _CONSOLE_CURSOR_INFO_DEFINED
#define _CONSOLE_CURSOR_INFO_DEFINED
typedef struct _CONSOLE_CURSOR_INFO {
    DWORD dwSize;
    BOOL  bVisible;
} CONSOLE_CURSOR_INFO, *PCONSOLE_CURSOR_INFO;
#endif

/* monitor */
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
#endif

#endif /* _WINDOWS_STRUCTS_BRIDGE */

#endif /* ROSETTA3_WIN32_BRIDGE_H */
