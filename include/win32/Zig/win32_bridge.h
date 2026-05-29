#ifndef ROSETTA3_WIN32_BRIDGE_H
#define ROSETTA3_WIN32_BRIDGE_H

#include "win32/windows_base.h"

/* Forward declarations for types referenced but not yet sourced in the
   individual win32 headers.  These are placeholders so that Zig's
   translate-c can parse the headers; the real definitions come from
   the upstream win32 headers once they are fully sourced. */

#ifndef _RTL_BARRIER_DEFINED
#define _RTL_BARRIER_DEFINED
typedef struct _RTL_BARRIER { ULONG_PTR Reserved[5]; } RTL_BARRIER, *PRTL_BARRIER;
#endif

/* ------------------------------------------------------------------ */
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

#endif /* ROSETTA3_WIN32_BRIDGE_H */
