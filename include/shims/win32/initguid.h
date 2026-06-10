#ifndef ROSETTE_SHIMS_WIN32_INITGUID_H
#define ROSETTE_SHIMS_WIN32_INITGUID_H

#include "windows.h"

/* When this header is included, GUID/IID/CLSID definitions that follow
 * will allocate storage instead of just declaring extern const. */

#ifndef INITGUID
#define INITGUID
#endif

#ifndef DEFINE_GUID
#define DEFINE_GUID(name, l, w1, w2, b1, b2, b3, b4, b5, b6, b7, b8) \
    EXTERN_C const GUID name = { l, w1, w2, { b1, b2, b3, b4, b5, b6, b7, b8 } }
#endif

#endif
