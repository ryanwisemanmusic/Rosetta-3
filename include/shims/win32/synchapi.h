/*
 * Rosetta 3 shim for win32/synchapi.h (synchronization API).
 *
 * Provides synchronization primitives and Sleep() on macOS / Linux
 * using POSIX equivalents.
 */
#ifndef ROSETTA3_SHIMS_WIN32_SYNCHAPI_H
#define ROSETTA3_SHIMS_WIN32_SYNCHAPI_H

#include <unistd.h>
#include <time.h>
#include "windows_base.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifndef _SYNCHAPI_SLEEP_DEFINED
#define _SYNCHAPI_SLEEP_DEFINED
FORCEINLINE void Sleep(DWORD dwMilliseconds)
{
    struct timespec ts;
    ts.tv_sec  = dwMilliseconds / 1000;
    ts.tv_nsec = (long)(dwMilliseconds % 1000) * 1000000L;
    nanosleep(&ts, NULL);
}
#endif

#ifdef __cplusplus
}
#endif

#endif /* ROSETTA3_SHIMS_WIN32_SYNCHAPI_H */
