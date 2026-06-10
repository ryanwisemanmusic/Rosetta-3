#ifndef ROSETTE_SHIMS_WIN32_WINUSER_H
#define ROSETTE_SHIMS_WIN32_WINUSER_H

#include "windows.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifndef MB_OK
#define MB_OK                       0x00000000
#define MB_OKCANCEL                 0x00000001
#define MB_ICONHAND                 0x00000010
#define MB_ICONQUESTION             0x00000020
#define MB_ICONEXCLAMATION          0x00000030
#define MB_ICONASTERISK             0x00000040
#define MB_ICONINFORMATION          MB_ICONASTERISK
#define MB_ICONERROR                MB_ICONHAND
#endif

#ifndef IDOK
#define IDOK        1
#define IDCANCEL    2
#define IDABORT     3
#define IDRETRY     4
#define IDIGNORE    5
#define IDYES       6
#define IDNO        7
#endif

int WINAPI MessageBoxA(HWND hWnd, LPCSTR lpText, LPCSTR lpCaption, UINT uType);
int WINAPI MessageBoxW(HWND hWnd, LPCWSTR lpText, LPCWSTR lpCaption, UINT uType);

#ifdef UNICODE
#define MessageBox MessageBoxW
#else
#define MessageBox MessageBoxA
#endif

#ifdef __cplusplus
}
#endif

#endif
