#ifndef ROSETTE_SHIMS_WIN32_WINBASE_H
#define ROSETTE_SHIMS_WIN32_WINBASE_H

#include "windows.h"
#include "synchapi.h"

#ifndef CRITICAL_SECTION_DEFINED
#define CRITICAL_SECTION_DEFINED
typedef struct _RTL_CRITICAL_SECTION {
    PVOID DebugInfo;
    LONG  LockCount;
    LONG  RecursionCount;
    HANDLE OwningThread;
    HANDLE LockSemaphore;
    ULONG_PTR SpinCount;
} CRITICAL_SECTION, *PCRITICAL_SECTION, *LPCRITICAL_SECTION;
#endif

#ifdef __cplusplus
extern "C" {
#endif

#ifndef INFINITE
#define INFINITE            0xFFFFFFFF
#endif
#ifndef ERROR_SUCCESS
#define ERROR_SUCCESS       0L
#endif
#ifndef ERROR_NO_MORE_ITEMS
#define ERROR_NO_MORE_ITEMS 259L
#endif

#ifndef STARTF_USESTDHANDLES
#define STARTF_USESTDHANDLES    0x00000100
#define STARTF_USESHOWWINDOW    0x00000001
#endif

#ifndef CREATE_DEFAULT_ERROR_MODE
#define CREATE_DEFAULT_ERROR_MODE  0x04000000
#define CREATE_NEW_CONSOLE          0x00000010
#define CREATE_NEW_PROCESS_GROUP    0x00000200
#define CREATE_UNICODE_ENVIRONMENT  0x00000400
#endif

#ifndef NORMAL_PRIORITY_CLASS
#define NORMAL_PRIORITY_CLASS       0x00000020
#endif

#ifndef PROCESS_INFORMATION_DEFINED
#define PROCESS_INFORMATION_DEFINED
typedef struct _PROCESS_INFORMATION {
    HANDLE hProcess;
    HANDLE hThread;
    DWORD  dwProcessId;
    DWORD  dwThreadId;
} PROCESS_INFORMATION, *PPROCESS_INFORMATION, *LPPROCESS_INFORMATION;
#endif

#ifndef STARTUPINFOW_DEFINED
#define STARTUPINFOW_DEFINED
typedef struct _STARTUPINFOW {
    DWORD  cb;
    LPWSTR lpReserved;
    LPWSTR lpDesktop;
    LPWSTR lpTitle;
    DWORD  dwX;
    DWORD  dwY;
    DWORD  dwXSize;
    DWORD  dwYSize;
    DWORD  dwXCountChars;
    DWORD  dwYCountChars;
    DWORD  dwFillAttribute;
    DWORD  dwFlags;
    WORD   wShowWindow;
    WORD   cbReserved2;
    LPBYTE lpReserved2;
    HANDLE hStdInput;
    HANDLE hStdOutput;
    HANDLE hStdError;
} STARTUPINFOW, *LPSTARTUPINFOW;
#endif

#ifndef HLOCAL_DEFINED
#define HLOCAL_DEFINED
typedef HANDLE HLOCAL;
#endif

/* Process */
HANDLE    WINAPI GetCurrentProcess(void);
HMODULE   WINAPI GetModuleHandleA(LPCSTR lpModuleName);
HMODULE   WINAPI GetModuleHandleW(LPCWSTR lpModuleName);
FARPROC   WINAPI GetProcAddress(HMODULE hModule, LPCSTR lpProcName);
HMODULE   WINAPI LoadLibraryA(LPCSTR lpLibFileName);
HMODULE   WINAPI LoadLibraryW(LPCWSTR lpLibFileName);
BOOL      WINAPI FreeLibrary(HMODULE hLibModule);
BOOL      WINAPI CloseHandle(HANDLE hObject);
UINT      WINAPI GetSystemDirectoryW(LPWSTR lpBuffer, UINT uSize);

BOOL      WINAPI CreateProcessW(LPCWSTR lpApplicationName, LPWSTR lpCommandLine,
                LPSECURITY_ATTRIBUTES lpProcessAttributes, LPSECURITY_ATTRIBUTES lpThreadAttributes,
                BOOL bInheritHandles, DWORD dwCreationFlags, LPVOID lpEnvironment,
                LPCWSTR lpCurrentDirectory, LPSTARTUPINFOW lpStartupInfo,
                LPPROCESS_INFORMATION lpProcessInformation);

DWORD     WINAPI WaitForSingleObject(HANDLE hHandle, DWORD dwMilliseconds);

/* Thread-local storage */
DWORD     WINAPI TlsAlloc(void);
LPVOID    WINAPI TlsGetValue(DWORD dwTlsIndex);
BOOL      WINAPI TlsSetValue(DWORD dwTlsIndex, LPVOID lpTlsValue);
BOOL      WINAPI TlsFree(DWORD dwTlsIndex);

/* Interlocked */
LONG      WINAPI InterlockedIncrement(LONG volatile *Addend);
LONG      WINAPI InterlockedDecrement(LONG volatile *Addend);

/* String */
LPWSTR    WINAPI lstrcatW(LPWSTR lpString1, LPCWSTR lpString2);
LPWSTR    WINAPI lstrcpyW(LPWSTR lpString1, LPCWSTR lpString2);
int       WINAPI lstrlenW(LPCWSTR lpString);
int       WINAPI lstrcmpiW(LPCWSTR lpString1, LPCWSTR lpString2);
LPSTR     WINAPI lstrcatA(LPSTR lpString1, LPCSTR lpString2);
int       WINAPI lstrlenA(LPCSTR lpString);
int       WINAPI lstrcmpiA(LPCSTR lpString1, LPCSTR lpString2);

/* Memory */
LPVOID    WINAPI HeapAlloc(HANDLE hHeap, DWORD dwFlags, SIZE_T dwBytes);
BOOL      WINAPI HeapFree(HANDLE hHeap, DWORD dwFlags, LPVOID lpMem);
HANDLE    WINAPI GetProcessHeap(void);

/* File */
DWORD     WINAPI GetFileAttributesW(LPCWSTR lpFileName);
DWORD     WINAPI GetFileAttributesA(LPCSTR lpFileName);
BOOL      WINAPI DeleteFileW(LPCWSTR lpFileName);
BOOL      WINAPI MoveFileW(LPCWSTR lpExistingFileName, LPCWSTR lpNewFileName);
DWORD     WINAPI GetModuleFileNameW(HMODULE hModule, LPWSTR lpFilename, DWORD nSize);

/* Environment */
DWORD     WINAPI GetEnvironmentVariableW(LPCWSTR lpName, LPWSTR lpBuffer, DWORD nSize);
BOOL      WINAPI SetEnvironmentVariableW(LPCWSTR lpName, LPCWSTR lpValue);

/* Error handling */
DWORD     WINAPI GetLastError(void);
VOID      WINAPI SetLastError(DWORD dwErrCode);

/* FormatMessage */
DWORD     WINAPI FormatMessageW(DWORD dwFlags, LPCVOID lpSource, DWORD dwMessageId,
                DWORD dwLanguageId, LPWSTR lpBuffer, DWORD nSize, va_list *Arguments);
#define FORMAT_MESSAGE_ALLOCATE_BUFFER  0x00000100
#define FORMAT_MESSAGE_FROM_SYSTEM      0x00001000
#define FORMAT_MESSAGE_IGNORE_INSERTS   0x00000200

/* Local memory */
HLOCAL    WINAPI LocalFree(HLOCAL hMem);

/* TLS constants */
#ifndef TLS_OUT_OF_INDEXES
#define TLS_OUT_OF_INDEXES ((DWORD)0xFFFFFFFF)
#endif

/* Process access rights */
#ifndef PROCESS_QUERY_INFORMATION
#define PROCESS_QUERY_INFORMATION   0x0400
#endif

BOOL      WINAPI IsWow64Process(HANDLE hProcess, PBOOL Wow64Process);

/* Debug output */
VOID      WINAPI OutputDebugStringA(LPCSTR lpOutputString);
VOID      WINAPI OutputDebugStringW(LPCWSTR lpOutputString);
#ifdef UNICODE
#define OutputDebugString OutputDebugStringW
#else
#define OutputDebugString OutputDebugStringA
#endif

/* Multi-byte / wide char helpers (also in winnls.h) */
int       WINAPI WideCharToMultiByte(UINT CodePage, DWORD dwFlags, LPCWSTR lpWideCharStr,
                int cchWideChar, LPSTR lpMultiByteStr, int cbMultiByte,
                LPCSTR lpDefaultChar, LPBOOL lpUsedDefaultChar);
int       WINAPI MultiByteToWideChar(UINT CodePage, DWORD dwFlags, LPCSTR lpMultiByteStr,
                int cbMultiByte, LPWSTR lpWideCharStr, int cchWideChar);

#ifdef __cplusplus
}
#endif

#endif
