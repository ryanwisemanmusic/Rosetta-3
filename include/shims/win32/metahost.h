#ifndef ROSETTE_SHIMS_WIN32_METAHOST_H
#define ROSETTE_SHIMS_WIN32_METAHOST_H

#include "windows.h"
#include "ole2.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Forward declarations */
typedef struct IStream IStream;

/* ── ICLRRuntimeInfo ──────────────────────────────────────────────────── */
typedef struct ICLRRuntimeInfoVtbl ICLRRuntimeInfoVtbl;
typedef struct ICLRRuntimeInfo {
    const struct ICLRRuntimeInfoVtbl *lpVtbl;
} ICLRRuntimeInfo;

struct ICLRRuntimeInfoVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(ICLRRuntimeInfo *, REFIID, void **);
    ULONG   (STDMETHODCALLTYPE *AddRef)(ICLRRuntimeInfo *);
    ULONG   (STDMETHODCALLTYPE *Release)(ICLRRuntimeInfo *);
    HRESULT (STDMETHODCALLTYPE *GetVersionString)(ICLRRuntimeInfo *, LPWSTR, DWORD *);
    HRESULT (STDMETHODCALLTYPE *GetRuntimeDirectory)(ICLRRuntimeInfo *, LPWSTR, DWORD *);
    HRESULT (STDMETHODCALLTYPE *IsLoaded)(ICLRRuntimeInfo *, HANDLE, BOOL *);
    HRESULT (STDMETHODCALLTYPE *LoadErrorString)(ICLRRuntimeInfo *, UINT, LPWSTR, DWORD, DWORD *);
    HRESULT (STDMETHODCALLTYPE *LoadLibrary)(ICLRRuntimeInfo *, LPCWSTR, HMODULE *);
    HRESULT (STDMETHODCALLTYPE *GetProcAddress)(ICLRRuntimeInfo *, LPCSTR, LPVOID *);
    HRESULT (STDMETHODCALLTYPE *GetInterface)(ICLRRuntimeInfo *, REFCLSID, REFIID, LPVOID *);
    HRESULT (STDMETHODCALLTYPE *SetDefaultStartupFlags)(ICLRRuntimeInfo *, DWORD, LPCWSTR);
    HRESULT (STDMETHODCALLTYPE *GetDefaultStartupFlags)(ICLRRuntimeInfo *, DWORD *, LPWSTR, DWORD *);
    HRESULT (STDMETHODCALLTYPE *BindAsLegacyV2Runtime)(ICLRRuntimeInfo *);
    HRESULT (STDMETHODCALLTYPE *IsStarted)(ICLRRuntimeInfo *, BOOL *, DWORD *);
    /* GetRuntimeHost is a standalone function (Wine extension), not a COM method */
    HRESULT (STDMETHODCALLTYPE *GetStartupFlags)(ICLRRuntimeInfo *, DWORD *, LPWSTR, DWORD *);
};

/* COBJMACROS */
#ifdef COBJMACROS
#define ICLRRuntimeInfo_QueryInterface(This, riid, ppv)    (This)->lpVtbl->QueryInterface(This, riid, ppv)
#define ICLRRuntimeInfo_AddRef(This)                       (This)->lpVtbl->AddRef(This)
#define ICLRRuntimeInfo_Release(This)                      (This)->lpVtbl->Release(This)
#define ICLRRuntimeInfo_GetVersionString(This, buf, len)   (This)->lpVtbl->GetVersionString(This, buf, len)
#define ICLRRuntimeInfo_GetRuntimeDirectory(This, buf, len)(This)->lpVtbl->GetRuntimeDirectory(This, buf, len)
#define ICLRRuntimeInfo_GetInterface(This, rclsid, riid, ppv) (This)->lpVtbl->GetInterface(This, rclsid, riid, ppv)
/* ICLRRuntimeInfo_GetRuntimeHost is a standalone Wine function, not a COM macro */
#define ICLRRuntimeInfo_IsLoaded(This, hnd, loaded)        (This)->lpVtbl->IsLoaded(This, hnd, loaded)
#define ICLRRuntimeInfo_LoadLibrary(This, path, mod)       (This)->lpVtbl->LoadLibrary(This, path, mod)
#define ICLRRuntimeInfo_GetProcAddress(This, name, addr)   (This)->lpVtbl->GetProcAddress(This, name, addr)
#define ICLRRuntimeInfo_LoadErrorString(This, id, buf, sz, len) (This)->lpVtbl->LoadErrorString(This, id, buf, sz, len)
#define ICLRRuntimeInfo_SetDefaultStartupFlags(This, flags, config) (This)->lpVtbl->SetDefaultStartupFlags(This, flags, config)
#define ICLRRuntimeInfo_GetDefaultStartupFlags(This, flags, buf, len) (This)->lpVtbl->GetDefaultStartupFlags(This, flags, buf, len)
#define ICLRRuntimeInfo_BindAsLegacyV2Runtime(This)        (This)->lpVtbl->BindAsLegacyV2Runtime(This)
#define ICLRRuntimeInfo_IsStarted(This, started, flags)    (This)->lpVtbl->IsStarted(This, started, flags)
#define ICLRRuntimeInfo_GetStartupFlags(This, flags, buf, len) (This)->lpVtbl->GetStartupFlags(This, flags, buf, len)
#endif

/* ── ICLRMetaHost ─────────────────────────────────────────────────────── */
typedef struct ICLRMetaHostVtbl ICLRMetaHostVtbl;
typedef struct ICLRMetaHost {
    const struct ICLRMetaHostVtbl *lpVtbl;
} ICLRMetaHost;

typedef void (*RuntimeLoadedCallbackFnPtr)(ICLRRuntimeInfo *, void *, void *);

struct ICLRMetaHostVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(ICLRMetaHost *, REFIID, void **);
    ULONG   (STDMETHODCALLTYPE *AddRef)(ICLRMetaHost *);
    ULONG   (STDMETHODCALLTYPE *Release)(ICLRMetaHost *);
    HRESULT (STDMETHODCALLTYPE *GetRuntime)(ICLRMetaHost *, LPCWSTR, REFIID, LPVOID *);
    HRESULT (STDMETHODCALLTYPE *GetVersionFromFile)(ICLRMetaHost *, LPCWSTR, LPWSTR, DWORD *);
    HRESULT (STDMETHODCALLTYPE *EnumerateInstalledRuntimes)(ICLRMetaHost *, IUnknown **);
    HRESULT (STDMETHODCALLTYPE *EnumerateLoadedRuntimes)(ICLRMetaHost *, HANDLE, IUnknown **);
    HRESULT (STDMETHODCALLTYPE *RequestRuntimeLoadedNotification)(ICLRMetaHost *, RuntimeLoadedCallbackFnPtr);
    HRESULT (STDMETHODCALLTYPE *QueryLegacyV2RuntimeBinding)(ICLRMetaHost *, REFIID, LPVOID *);
    HRESULT (STDMETHODCALLTYPE *ExitProcess)(ICLRMetaHost *, INT32);
};

/* COBJMACROS */
#ifdef COBJMACROS
#define ICLRMetaHost_QueryInterface(This, riid, ppv)         (This)->lpVtbl->QueryInterface(This, riid, ppv)
#define ICLRMetaHost_AddRef(This)                            (This)->lpVtbl->AddRef(This)
#define ICLRMetaHost_Release(This)                           (This)->lpVtbl->Release(This)
#define ICLRMetaHost_GetRuntime(This, ver, riid, rt)         (This)->lpVtbl->GetRuntime(This, ver, riid, rt)
#define ICLRMetaHost_GetVersionFromFile(This, path, buf, len)(This)->lpVtbl->GetVersionFromFile(This, path, buf, len)
#define ICLRMetaHost_ExitProcess(This, code)                 (This)->lpVtbl->ExitProcess(This, code)
#endif

/* ── ICLRMetaHostPolicy ──────────────────────────────────────────────── */
typedef struct ICLRMetaHostPolicyVtbl ICLRMetaHostPolicyVtbl;
typedef struct ICLRMetaHostPolicy {
    const struct ICLRMetaHostPolicyVtbl *lpVtbl;
} ICLRMetaHostPolicy;

struct ICLRMetaHostPolicyVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(ICLRMetaHostPolicy *, REFIID, void **);
    ULONG   (STDMETHODCALLTYPE *AddRef)(ICLRMetaHostPolicy *);
    ULONG   (STDMETHODCALLTYPE *Release)(ICLRMetaHostPolicy *);
    HRESULT (STDMETHODCALLTYPE *GetRequestedRuntime)(ICLRMetaHostPolicy *, DWORD, LPCWSTR, IStream *,
                LPWSTR, DWORD *, LPWSTR, DWORD *, DWORD *, REFIID, LPVOID *);
};

#ifdef COBJMACROS
#define ICLRMetaHostPolicy_GetRequestedRuntime(This, flags, bin, stream, ver, vlen, imgver, ivlen, cfg, riid, ppv) \
    (This)->lpVtbl->GetRequestedRuntime(This, flags, bin, stream, ver, vlen, imgver, ivlen, cfg, riid, ppv)
#endif

/* ── ICLRDebugging ───────────────────────────────────────────────────── */
typedef struct ICLRDebuggingVtbl ICLRDebuggingVtbl;
typedef struct ICLRDebugging {
    const struct ICLRDebuggingVtbl *lpVtbl;
} ICLRDebugging;

struct ICLRDebuggingVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(ICLRDebugging *, REFIID, void **);
    ULONG   (STDMETHODCALLTYPE *AddRef)(ICLRDebugging *);
    ULONG   (STDMETHODCALLTYPE *Release)(ICLRDebugging *);
    HRESULT (STDMETHODCALLTYPE *OpenVirtualProcess)(ICLRDebugging *, ULONG64, HANDLE, void *,
                void **, DWORD *, CLSID *);
    HRESULT (STDMETHODCALLTYPE *CanUnloadNow)(ICLRDebugging *, void *);
};

/* ── IEnumUnknown ─────────────────────────────────────────────────────── */
typedef struct IEnumUnknownVtbl IEnumUnknownVtbl;
typedef struct IEnumUnknown {
    const struct IEnumUnknownVtbl *lpVtbl;
} IEnumUnknown;

struct IEnumUnknownVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(IEnumUnknown *, REFIID, void **);
    ULONG   (STDMETHODCALLTYPE *AddRef)(IEnumUnknown *);
    ULONG   (STDMETHODCALLTYPE *Release)(IEnumUnknown *);
    HRESULT (STDMETHODCALLTYPE *Next)(IEnumUnknown *, ULONG, IUnknown **, ULONG *);
    HRESULT (STDMETHODCALLTYPE *Skip)(IEnumUnknown *, ULONG);
    HRESULT (STDMETHODCALLTYPE *Reset)(IEnumUnknown *);
    HRESULT (STDMETHODCALLTYPE *Clone)(IEnumUnknown *, IEnumUnknown **);
};

/* ── RUNTIME_INFO_* flags ─────────────────────────────────────────────── */
#ifndef RUNTIME_INFO_UPGRADE_VERSION
#define RUNTIME_INFO_UPGRADE_VERSION      0x00000001
#endif
#ifndef RUNTIME_INFO_EMULATE_EXE_LAUNCH
#define RUNTIME_INFO_EMULATE_EXE_LAUNCH   0x00000002
#endif
#ifndef RUNTIME_INFO_DONT_SHOW_ERROR_DIALOG
#define RUNTIME_INFO_DONT_SHOW_ERROR_DIALOG 0x00000040
#endif

/* ── CLSID / IID declarations ────────────────────────────────────────── */
EXTERN_C const GUID CLSID_CLRMetaHost;
EXTERN_C const GUID CLSID_CLRMetaHostPolicy;
EXTERN_C const GUID CLSID_CLRDebuggingLegacy;
EXTERN_C const GUID IID_ICLRRuntimeInfo;
EXTERN_C const GUID IID_ICLRMetaHost;

#ifdef __cplusplus
}
#endif

#endif
