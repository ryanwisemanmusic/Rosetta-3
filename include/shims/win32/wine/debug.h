#ifndef __WINE_WINE_DEBUG_H
#define __WINE_WINE_DEBUG_H

#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include "windef.h"
#include "winbase.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Simplified Wine debug system — logs to stderr. */

struct __wine_debug_channel
{
    unsigned char flags;
    char name[15];
};

enum __wine_debug_class
{
    __WINE_DBCL_FIXME,
    __WINE_DBCL_ERR,
    __WINE_DBCL_WARN,
    __WINE_DBCL_TRACE,
    __WINE_DBCL_INIT = 7
};

#define WINE_DEFAULT_DEBUG_CHANNEL(name) \
    struct __wine_debug_channel __wine_dbch_##name = { 0xFF, #name }

#define WINE_DECLARE_DEBUG_CHANNEL(name) \
    extern struct __wine_debug_channel __wine_dbch_##name

#define __WINE_GET_DEBUGGING_TRACE(dbch) 1
#define __WINE_GET_DEBUGGING_WARN(dbch)  1
#define __WINE_GET_DEBUGGING_FIXME(dbch) 1
#define __WINE_GET_DEBUGGING_ERR(dbch)   1

/* Wine debug uses a two-part macro: ERR_(ch)(fmt, ...).
 * __WINE_DPRINTF expands the do-while prefix and ends with __WINE_DBG_LOG
 * (no closing parens), so the trailing (fmt, ...) are consumed as its args. */
#define __WINE_DPRINTF(dbcl, chvar) \
    do { struct __wine_debug_channel *const __dbch = (chvar); \
         fprintf(stderr, #dbcl "(%s): ", __dbch->name); \
         __WINE_DBG_LOG

#define __WINE_DBG_LOG(...) \
         fprintf(stderr, __VA_ARGS__); \
    } while(0)

#define TRACE_(ch)    __WINE_DPRINTF(__WINE_DBCL_TRACE, &__wine_dbch_##ch)
#define WARN_(ch)     __WINE_DPRINTF(__WINE_DBCL_WARN,  &__wine_dbch_##ch)
#define FIXME_(ch)    __WINE_DPRINTF(__WINE_DBCL_FIXME, &__wine_dbch_##ch)
#define ERR_(ch)      __WINE_DPRINTF(__WINE_DBCL_ERR,   &__wine_dbch_##ch)

#define TRACE(...)    TRACE_(mscoree)(__VA_ARGS__)
#define WARN(...)     WARN_(mscoree)(__VA_ARGS__)
#define FIXME(...)    FIXME_(mscoree)(__VA_ARGS__)
#define ERR(...)      ERR_(mscoree)(__VA_ARGS__)

/* Debug string helpers */
static inline const char *debugstr_w(const WCHAR *wstr)
{
    static char buf[1024];
    if (!wstr) return "(null)";
    int pos = 0;
    for (int i = 0; wstr[i] && pos < (int)sizeof(buf) - 4; i++) {
        if (wstr[i] >= 32 && wstr[i] < 127) {
            buf[pos++] = (char)wstr[i];
        } else {
            buf[pos++] = '\\';
            buf[pos++] = 'x';
            int nibble_hi = (wstr[i] >> 4) & 0xF;
            int nibble_lo = wstr[i] & 0xF;
            buf[pos++] = nibble_hi < 10 ? '0' + nibble_hi : 'A' + nibble_hi - 10;
            buf[pos++] = nibble_lo < 10 ? '0' + nibble_lo : 'A' + nibble_lo - 10;
        }
    }
    buf[pos] = 0;
    return buf;
}

static inline const char *debugstr_a(const char *str)
{
    return str ? str : "(null)";
}

static inline const char *debugstr_guid(const struct _GUID *guid)
{
    static char buf[48];
    if (!guid) return "(null)";
    snprintf(buf, sizeof(buf), "{%08lX-%04X-%04X-%02X%02X-%02X%02X%02X%02X%02X%02X}",
             guid->Data1, guid->Data2, guid->Data3,
             guid->Data4[0], guid->Data4[1], guid->Data4[2], guid->Data4[3],
             guid->Data4[4], guid->Data4[5], guid->Data4[6], guid->Data4[7]);
    return buf;
}

/* wine_dbg_printf — used by mscoree print handler */
void wine_dbg_printf(const char *format, ...);

/* __wine_register_resources / __wine_unregister_resources */
HRESULT WINAPI __wine_register_resources(void);
HRESULT WINAPI __wine_unregister_resources(void);

#ifdef __cplusplus
}
#endif

#endif
