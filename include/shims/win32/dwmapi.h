#ifndef ROSETTE_SHIMS_WIN32_DWMAPI_H
#define ROSETTE_SHIMS_WIN32_DWMAPI_H

#include "windows.h"

#ifndef S_OK
#define S_OK 0L
#endif
#ifndef E_FAIL
#define E_FAIL 0x80004005L
#endif
#ifndef HRESULT
typedef LONG HRESULT;
#endif

#ifdef __cplusplus
extern "C" {
#endif

#ifndef DWMWA_WINDOW_CORNER_PREFERENCE
#define DWMWA_WINDOW_CORNER_PREFERENCE 33
#endif
#ifndef DWMWCP_ROUND
#define DWMWCP_ROUND 2
#endif
#ifndef DWMWA_SYSTEMBACKDROP_TYPE
#define DWMWA_SYSTEMBACKDROP_TYPE 38
#endif
#ifndef DWMSBT_MAINWINDOW
#define DWMSBT_MAINWINDOW 2
#endif

FORCEINLINE HRESULT WINAPI DwmSetWindowAttribute(HWND hwnd, DWORD dwAttribute, LPCVOID pvAttribute, DWORD cbAttribute) {
    (void)hwnd;
    (void)dwAttribute;
    (void)pvAttribute;
    (void)cbAttribute;
    return S_OK;
}

#ifdef __cplusplus
}
#endif

#endif /* ROSETTE_SHIMS_WIN32_DWMAPI_H */
