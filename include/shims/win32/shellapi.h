#ifndef ROSETTA3_SHIMS_WIN32_SHELLAPI_H
#define ROSETTA3_SHIMS_WIN32_SHELLAPI_H

#include "windows.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifndef ExtractIcon
#define ExtractIcon ExtractIconA
#endif

#ifndef ShellAbout
#define ShellAbout ShellAboutA
#endif

#ifndef _EXTRACTICON_DEFINED
FORCEINLINE HICON WINAPI ExtractIconA(HINSTANCE hInst, LPCSTR pszExeFileName, UINT nIconIndex) {
    (void)hInst;
    if (!pszExeFileName) return (HICON)0;
    return (HICON)(ULONG_PTR)rosetta3_dll_extract_icon_a(pszExeFileName, (int)nIconIndex);
}
#endif

FORCEINLINE INT WINAPI ShellAboutA(HWND hWnd, LPCSTR szApp, LPCSTR szOtherStuff, HICON hIcon) {
    (void)hWnd;
    (void)szApp;
    (void)szOtherStuff;
    (void)hIcon;
    return TRUE;
}

#ifdef __cplusplus
}
#endif

#endif /* ROSETTA3_SHIMS_WIN32_SHELLAPI_H */
