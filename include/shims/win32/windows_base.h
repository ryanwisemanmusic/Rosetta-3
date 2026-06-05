/*
 * Shim wrapper for windows_base.h.
 * Keep the real Windows header unmodified and provide compatibility here.
 */
#ifndef ROSETTE_SHIMS_WIN32_WINDOWS_BASE_REDIRECT_H
#define ROSETTE_SHIMS_WIN32_WINDOWS_BASE_REDIRECT_H

#ifndef FORCEINLINE
#define FORCEINLINE __attribute__((always_inline)) inline
#endif

#ifndef _NODISCARD
#define _NODISCARD
#endif

#ifndef _Check_return_
#define _Check_return_
#endif

#ifndef _CRT_INSECURE_DEPRECATE_MEMORY
#define _CRT_INSECURE_DEPRECATE_MEMORY(x)
#endif

#ifndef _VCRTIMP
#define _VCRTIMP
#endif

#if defined(__cplusplus)
#include <cstddef>
#else
#include <stddef.h>
#endif

#ifndef WINDOWS_BASE_H
#include "win32/windows_base.h"
#else
#ifndef __stdcall
#define __stdcall
#endif
#ifndef WINAPI
#define WINAPI __stdcall
#endif
#ifndef BOOL
typedef int BOOL;
#endif
#endif

#endif /* ROSETTE_SHIMS_WIN32_WINDOWS_BASE_REDIRECT_H */