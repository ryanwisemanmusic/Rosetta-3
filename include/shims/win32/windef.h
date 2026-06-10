#ifndef ROSETTE_SHIMS_WIN32_WINDEF_H
#define ROSETTE_SHIMS_WIN32_WINDEF_H

#include "windows.h"

#ifndef EXTERN_C
#ifdef __cplusplus
#define EXTERN_C extern "C"
#else
#define EXTERN_C extern
#endif
#endif

#ifndef min
#define min(a,b) (((a) < (b)) ? (a) : (b))
#endif
#ifndef max
#define max(a,b) (((a) > (b)) ? (a) : (b))
#endif

#ifndef CDECL
#define CDECL __cdecl
#endif

#ifndef __WINE_DEALLOC
#define __WINE_DEALLOC(x)
#endif
#ifndef __WINE_MALLOC
#define __WINE_MALLOC
#endif

#ifndef __int32
#define __int32 int
#endif

#ifndef ARRAY_SIZE
#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))
#endif

#endif
