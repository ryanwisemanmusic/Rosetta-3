#ifndef ROSETTE_SHIM_SURFACE_BRIDGE_H
#define ROSETTE_SHIM_SURFACE_BRIDGE_H

#include "commctrl.h"
#include "dwmapi.h"
#include "misc.h"
#include "shellapi.h"
#include "tchar.h"
#include "windowsx.h"
#include "../../shims/win32/arm_compat.h"

#ifndef TIMERR_BASE
#define TIMERR_BASE 96
#endif
#ifndef TIMERR_NOERROR
#define TIMERR_NOERROR 0
#endif
#ifndef TIMERR_NOCANDO
#define TIMERR_NOCANDO (TIMERR_BASE + 1)
#endif
#ifndef CP_UTF8
#define CP_UTF8 65001
#endif
#ifndef FORMAT_MESSAGE_FROM_SYSTEM
#define FORMAT_MESSAGE_FROM_SYSTEM 0x00001000
#endif
#ifndef LANG_ENGLISH
#define LANG_ENGLISH 0x09
#endif
#ifndef SUBLANG_ENGLISH_US
#define SUBLANG_ENGLISH_US 0x01
#endif

#ifndef _ROSETTE_SYSTEMTIME_DEFINED
#define _ROSETTE_SYSTEMTIME_DEFINED
typedef struct _SYSTEMTIME {
    WORD wYear;
    WORD wMonth;
    WORD wDayOfWeek;
    WORD wDay;
    WORD wHour;
    WORD wMinute;
    WORD wSecond;
    WORD wMilliseconds;
} SYSTEMTIME, *PSYSTEMTIME;
typedef PSYSTEMTIME LPSYSTEMTIME;
#endif

#ifndef _ROSETTE_TIME_ZONE_INFORMATION_DEFINED
#define _ROSETTE_TIME_ZONE_INFORMATION_DEFINED
typedef struct _TIME_ZONE_INFORMATION {
    LONG       Bias;
    WCHAR      StandardName[32];
    SYSTEMTIME StandardDate;
    LONG       StandardBias;
    WCHAR      DaylightName[32];
    SYSTEMTIME DaylightDate;
    LONG       DaylightBias;
} TIME_ZONE_INFORMATION, *PTIME_ZONE_INFORMATION;
typedef PTIME_ZONE_INFORMATION LPTIME_ZONE_INFORMATION;
#endif

#ifndef _ROSETTE_TIMECAPS_DEFINED
#define _ROSETTE_TIMECAPS_DEFINED
typedef struct timecaps_tag {
    UINT wPeriodMin;
    UINT wPeriodMax;
} TIMECAPS, *PTIMECAPS, *NPTIMECAPS, *LPTIMECAPS;
#endif

typedef HICON (WINAPI *rosette_extract_icon_a_fn)(HINSTANCE, LPCSTR, UINT);
typedef INT (WINAPI *rosette_shell_about_a_fn)(HWND, LPCSTR, LPCSTR, HICON);
typedef int (*rosette_conio_kbhit_fn)(void);
typedef int (*rosette_conio_getch_fn)(void);
typedef int (*rosette_conio_getche_fn)(void);
typedef __int64 rosette_arm_compat_i64;
typedef __uint64 rosette_arm_compat_u64;

static inline int rosette_windowsx_get_x_lparam(long lp) {
    return GET_X_LPARAM(lp);
}

static inline int rosette_windowsx_get_y_lparam(long lp) {
    return GET_Y_LPARAM(lp);
}

#endif /* ROSETTE_SHIM_SURFACE_BRIDGE_H */
