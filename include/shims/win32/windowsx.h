#ifndef ROSETTE_SHIMS_WIN32_WINDOWSX_H
#define ROSETTE_SHIMS_WIN32_WINDOWSX_H

/* windowsx.h shim for Rosette — message parameter helpers */

#ifdef __cplusplus
extern "C" {
#endif

#ifndef GET_X_LPARAM
#define GET_X_LPARAM(lp)    ((int)(short)LOWORD(lp))
#define GET_Y_LPARAM(lp)    ((int)(short)HIWORD(lp))
#endif

#ifndef FORWARD_WM_CLOSE
#define FORWARD_WM_CLOSE(hwnd, fn) ((void)(fn)((hwnd), WM_CLOSE, 0, 0L))
#endif

#ifdef __cplusplus
}
#endif

#endif /* ROSETTE_SHIMS_WIN32_WINDOWSX_H */
