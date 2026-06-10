#ifndef ROSETTE_SHIMS_WIN32_MSCOREE_H
#define ROSETTE_SHIMS_WIN32_MSCOREE_H

#include "windows.h"
#include "ole2.h"
#include "cor.h"

#ifndef LCID
#define LCID DWORD
#endif

#ifndef STDAPI
#define STDAPI EXTERN_C HRESULT WINAPI
#endif

#ifndef EXTERN_C
#ifdef __cplusplus
#define EXTERN_C extern "C"
#else
#define EXTERN_C extern
#endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* ── ICLRRuntimeHost ─────────────────────────────────────────────────── */
typedef struct ICLRRuntimeHostVtbl ICLRRuntimeHostVtbl;
typedef struct ICLRRuntimeHost {
    const struct ICLRRuntimeHostVtbl *lpVtbl;
} ICLRRuntimeHost;

struct ICLRRuntimeHostVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(ICLRRuntimeHost *, REFIID, void **);
    ULONG   (STDMETHODCALLTYPE *AddRef)(ICLRRuntimeHost *);
    ULONG   (STDMETHODCALLTYPE *Release)(ICLRRuntimeHost *);
    HRESULT (STDMETHODCALLTYPE *Start)(void);
    HRESULT (STDMETHODCALLTYPE *Stop)(void);
    HRESULT (STDMETHODCALLTYPE *ExecuteInDefaultAppDomain)(LPCWSTR, LPCWSTR, LPCWSTR, LPCWSTR, DWORD *);
    HRESULT (STDMETHODCALLTYPE *ExecuteInAppDomain)(void *, void *, void *);
    HRESULT (STDMETHODCALLTYPE *ExecuteApplication)(LPCWSTR, DWORD, DWORD *, void *, DWORD *);
    HRESULT (STDMETHODCALLTYPE *UnloadAppDomain)(DWORD, BOOL);
    HRESULT (STDMETHODCALLTYPE *SetHostControl)(IUnknown *);
    HRESULT (STDMETHODCALLTYPE *SetDelegateClrHost)(DWORD);
    HRESULT (STDMETHODCALLTYPE *CreateAppDomainManager)(IUnknown *, IUnknown **);
};

/* ── FLockClrVersionCallback ─────────────────────────────────────────── */
typedef HRESULT (WINAPI *FLockClrVersionCallback)(void);

/* ── CLRCreateInstance ───────────────────────────────────────────────── */
HRESULT WINAPI CLRCreateInstance(REFCLSID clsid, REFIID riid, LPVOID *ppInterface);

/* ── CorBindToRuntimeEx ──────────────────────────────────────────────── */
HRESULT WINAPI CorBindToRuntimeEx(LPWSTR szVersion, LPWSTR szBuildFlavor, DWORD nflags,
                REFCLSID rslsid, REFIID riid, LPVOID *ppv);
HRESULT WINAPI CorBindToRuntimeHost(LPCWSTR pwszVersion, LPCWSTR pwszBuildFlavor,
                LPCWSTR pwszHostConfigFile, VOID *pReserved, DWORD startupFlags,
                REFCLSID rclsid, REFIID riid, LPVOID *ppv);
HRESULT WINAPI CorBindToCurrentRuntime(LPCWSTR filename, REFCLSID rclsid, REFIID riid, LPVOID *ppv);
void    WINAPI CorExitProcess(int exitCode);

/* ── Cor* helper functions ──────────────────────────────────────────── */
HRESULT WINAPI CoInitializeCor(DWORD fFlags);
void    WINAPI CoEEShutDownCOM(void);
HRESULT WINAPI GetCORVersion(LPWSTR pbuffer, DWORD cchBuffer, DWORD *dwLength);
HRESULT WINAPI GetCORSystemDirectory(LPWSTR pbuffer, DWORD cchBuffer, DWORD *dwLength);
HRESULT WINAPI GetRequestedRuntimeInfo(LPCWSTR pExe, LPCWSTR pwszVersion, LPCWSTR pConfigurationFile,
                DWORD startupFlags, DWORD runtimeInfoFlags, LPWSTR pDirectory, DWORD dwDirectory,
                DWORD *dwDirectoryLength, LPWSTR pVersion, DWORD cchBuffer, DWORD *dwlength);
HRESULT WINAPI GetRequestedRuntimeVersion(LPWSTR pExe, LPWSTR pVersion, DWORD cchBuffer, DWORD *dwlength);
HRESULT WINAPI CorGetSvc(void *unk);
HRESULT WINAPI CorIsLatestSvc(int *unk1, int *unk2);
HRESULT WINAPI LoadLibraryShim(LPCWSTR szDllName, LPCWSTR szVersion, LPVOID pvReserved, HMODULE *phModDll);
HRESULT WINAPI LoadStringRC(UINT resId, LPWSTR pBuffer, int iBufLen, int bQuiet);
HRESULT WINAPI LoadStringRCEx(LCID culture, UINT resId, LPWSTR pBuffer, int iBufLen, int bQuiet, int *pBufLen);
HRESULT WINAPI LockClrVersion(FLockClrVersionCallback hostCallback, FLockClrVersionCallback *pBeginHostSetup, FLockClrVersionCallback *pEndHostSetup);
HRESULT WINAPI GetRealProcAddress(LPCSTR procname, void **ppv);
HRESULT WINAPI GetFileVersion(LPCWSTR szFilename, LPWSTR szBuffer, DWORD cchBuffer, DWORD *dwLength);
HRESULT WINAPI GetVersionFromProcess(HANDLE hProcess, LPWSTR pVersion, DWORD cchBuffer, DWORD *dwLength);
HRESULT WINAPI GetAssemblyMDImport(LPCWSTR szFileName, REFIID riid, IUnknown **ppIUnk);
STDAPI ClrCreateManagedInstance(LPCWSTR pTypeName, REFIID riid, void **ppObject);
HRESULT WINAPI CreateDebuggingInterfaceFromVersion(int nDebugVersion, LPCWSTR version, IUnknown **ppv);
HRESULT WINAPI CreateInterface(REFCLSID clsid, REFIID riid, LPVOID *ppInterface);

/* ── _Cor* exports ───────────────────────────────────────────────────── */
int WINAPI _CorExeMain2(PBYTE ptrMemory, DWORD cntMemory, LPWSTR imageName, LPWSTR loaderName, LPWSTR cmdLine);
VOID    WINAPI _CorImageUnloading(PVOID imageBase);
HRESULT WINAPI _CorValidateImage(PVOID *imageBase, LPCWSTR imageName);

/* ── ND_* native data access ─────────────────────────────────────────── */
INT   WINAPI ND_RU1(const void *ptr, INT offset);
INT   WINAPI ND_RI2(const void *ptr, INT offset);
INT   WINAPI ND_RI4(const void *ptr, INT offset);
INT64 WINAPI ND_RI8(const void *ptr, INT offset);
void  WINAPI ND_WU1(void *ptr, INT offset, BYTE val);
void  WINAPI ND_WI2(void *ptr, INT offset, SHORT val);
void  WINAPI ND_WI4(void *ptr, INT offset, INT val);
void  WINAPI ND_WI8(void *ptr, INT offset, INT64 val);
void  WINAPI ND_CopyObjDst(const void *src, void *dst, INT offset, INT size);
void  WINAPI ND_CopyObjSrc(const void *src, INT offset, void *dst, INT size);

/* ── COR_BIND_STARTUP flags ──────────────────────────────────────────── */
#ifndef STARTUP_FLAGS
#define COR_BIND_STARTUP_DEFAULT                   0x00000000
#define COR_BIND_STARTUP_NETFX35_SP1_PRESENT       0x00000001
#define COR_BIND_STARTUP_USE_CAP                    0x00000002
#define COR_BIND_STARTUP_ARM_PRIVATE_FIXUPS         0x00000004
#define COR_BIND_STARTUP_APPX_CAPABLE               0x00000008
#endif

/* ── CLSID / IID declarations ────────────────────────────────────────── */
EXTERN_C const GUID CLSID_CorRuntimeHost;
EXTERN_C const GUID CLSID_CLRRuntimeHost;
EXTERN_C const GUID IID_ICorRuntimeHost;
EXTERN_C const GUID IID_ICLRRuntimeHost;

#ifdef __cplusplus
}
#endif

#endif
