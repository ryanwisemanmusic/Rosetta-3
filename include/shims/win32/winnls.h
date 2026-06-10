#ifndef ROSETTE_SHIMS_WIN32_WINNLS_H
#define ROSETTE_SHIMS_WIN32_WINNLS_H

#include "windows.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifndef CP_ACP
#define CP_ACP          0
#endif
#ifndef CP_UTF8
#define CP_UTF8         65001
#endif

int WINAPI WideCharToMultiByte(UINT CodePage, DWORD dwFlags, LPCWSTR lpWideCharStr,
                int cchWideChar, LPSTR lpMultiByteStr, int cbMultiByte,
                LPCSTR lpDefaultChar, LPBOOL lpUsedDefaultChar);
int WINAPI MultiByteToWideChar(UINT CodePage, DWORD dwFlags, LPCSTR lpMultiByteStr,
                int cbMultiByte, LPWSTR lpWideCharStr, int cchWideChar);

#ifdef __cplusplus
}
#endif

#endif
