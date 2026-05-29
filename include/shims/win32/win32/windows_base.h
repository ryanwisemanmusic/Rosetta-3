/*
 * Shim wrapper for windows_base.h.
 * Keep the real Windows header unmodified and provide compatibility here.
 */
#ifndef ROSETTA3_SHIMS_WIN32_WINDOWS_BASE_H
#define ROSETTA3_SHIMS_WIN32_WINDOWS_BASE_H

#ifndef HAVE_WCHAR_T
#define HAVE_WCHAR_T
#endif

#if !defined(__cplusplus)
#if defined(__WCHAR_TYPE__)
typedef __WCHAR_TYPE__ wchar_t;
#else
typedef unsigned short wchar_t;
#endif
#endif

#ifndef __stdcall
#define __stdcall
#endif

#ifndef __cdecl
#define __cdecl
#endif

#ifndef __override
#define __override
#endif

#ifndef __forceinline
#define __forceinline inline __attribute__((always_inline))
#endif

#ifndef __int64
#define __int64 long long
#endif

#ifndef __uint64
#define __uint64 unsigned long long
#endif

#ifndef _WIN64
#if defined(__LP64__) || defined(__aarch64__) || defined(__arm64__) || defined(_M_ARM64)
#define _WIN64 1
#endif
#endif

/* Public LLP64 definitions — do not pull from .rosetta3 reference headers. */
#include "../../macos/win32/windows_base.h"

#endif /* ROSETTA3_SHIMS_WIN32_WINDOWS_BASE_H */
