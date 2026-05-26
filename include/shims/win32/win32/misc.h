/*
 * Shim wrapper for misc.h.
 * Keep the real Windows header unmodified and provide compatibility here.
 */
#ifndef ROSETTA3_SHIMS_WIN32_MISC_H
#define ROSETTA3_SHIMS_WIN32_MISC_H

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

#include "../../../win32/misc.h"

#endif /* ROSETTA3_SHIMS_WIN32_MISC_H */
