/*
 * Rosetta 3 shim for tchar.h — Microsoft generic-text mapping.
 *
 * Provides TCHAR, _T(), _TEXT(), and related macros.
 * On macOS (non-MSVC), LPTSTR etc. are resolved from windows_base.h's
 * UNICODE conditional.
 */
#ifndef ROSETTA3_SHIMS_WIN32_TCHAR_H
#define ROSETTA3_SHIMS_WIN32_TCHAR_H

#include "windows_base.h"

#ifndef _T
#define _T(x)    x
#define _TEXT(x) x
#define __T(x)   x
#endif

#endif /* ROSETTA3_SHIMS_WIN32_TCHAR_H */
