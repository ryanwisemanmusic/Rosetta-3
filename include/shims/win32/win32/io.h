/*
 * Shim wrapper for io.h.
 * Keep the real Windows header unmodified and provide compatibility here.
 *
 * On macOS the canonical io.h is blocked by _WINDOWS_ (defined by the macos
 * shim's windows_base.h), so the MEMORY_BASIC_INFORMATION types are provided
 * directly in the macos shim's windows_base.h. On other platforms,
 * __declspec(align(16)) used in the canonical is handled below.
 */
#ifndef ROSETTE_SHIMS_WIN32_IO_H
#define ROSETTE_SHIMS_WIN32_IO_H

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

/* Load windows_base.h first so all base types are available.
   On macOS this loads the macos shim (which provides MEMORY_BASIC_INFORMATION
   types and defines _WINDOWS_).
   On other platforms it loads the generic shim wrapper. */
#include "windows_base.h"

/* Handle __declspec(align(16)) used directly in the canonical io.h's
   _MEMORY_BASIC_INFORMATION64 struct definition. On macOS this is a no-op
   because the canonical is blocked by _WINDOWS_. */
#ifndef __declspec
#if !defined(_MSC_VER)
#define __declspec(x)
#endif
#endif

/* Include the canonical io.h for all remaining content.
   On macOS this is a no-op (blocked by _WINDOWS_). */
#include "win32/io.h"

#endif /* ROSETTE_SHIMS_WIN32_IO_H */
