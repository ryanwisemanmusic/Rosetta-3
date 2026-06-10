#ifndef ROSETTE_SHIMS_WIN32_WINREG_H
#define ROSETTE_SHIMS_WIN32_WINREG_H

#include "windows.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifndef HKEY_LOCAL_MACHINE
#define HKEY_LOCAL_MACHINE      ((HKEY)(ULONG_PTR)0x80000002)
#endif
#ifndef HKEY_CURRENT_USER
#define HKEY_CURRENT_USER       ((HKEY)(ULONG_PTR)0x80000001)
#endif
#ifndef HKEY_CLASSES_ROOT
#define HKEY_CLASSES_ROOT       ((HKEY)(ULONG_PTR)0x80000000)
#endif

#ifndef KEY_READ
#define KEY_READ                (0x20019)
#endif
#ifndef KEY_WRITE
#define KEY_WRITE               (0x20006)
#endif
#ifndef KEY_ALL_ACCESS
#define KEY_ALL_ACCESS          (0xF003F)
#endif
#ifndef KEY_WOW64_64KEY
#define KEY_WOW64_64KEY         (0x0100)
#endif
#ifndef KEY_WOW64_32KEY
#define KEY_WOW64_32KEY         (0x0200)
#endif

#ifndef REG_DWORD
#define REG_NONE                        0
#define REG_SZ                          1
#define REG_EXPAND_SZ                   2
#define REG_BINARY                      3
#define REG_DWORD                       4
#define REG_MULTI_SZ                    7
#endif

LONG WINAPI RegOpenKeyExW(HKEY hKey, LPCWSTR lpSubKey, DWORD ulOptions, REGSAM samDesired, PHKEY phkResult);
LONG WINAPI RegQueryValueExW(HKEY hKey, LPCWSTR lpValueName, LPDWORD lpReserved, LPDWORD lpType,
                LPBYTE lpData, LPDWORD lpcbData);
LONG WINAPI RegCloseKey(HKEY hKey);
LONG WINAPI RegSetValueExW(HKEY hKey, LPCWSTR lpValueName, DWORD Reserved, DWORD dwType,
                const BYTE *lpData, DWORD cbData);
/* RegCreateKeyExW is defined inline in windows.h */

#ifdef __cplusplus
}
#endif

#endif
