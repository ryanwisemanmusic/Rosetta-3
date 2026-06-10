#ifndef ROSETTE_SHIMS_WIN32_COR_H
#define ROSETTE_SHIMS_WIN32_COR_H

#include "windows.h"
#include "ole2.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Forward declarations */
typedef struct ICorConfiguration ICorConfiguration;

/* ── ICorRuntimeHost ──────────────────────────────────────────────────── */
typedef struct ICorRuntimeHostVtbl ICorRuntimeHostVtbl;
typedef struct ICorRuntimeHost {
    const struct ICorRuntimeHostVtbl *lpVtbl;
} ICorRuntimeHost;

struct ICorRuntimeHostVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(ICorRuntimeHost *, REFIID, void **);
    ULONG   (STDMETHODCALLTYPE *AddRef)(ICorRuntimeHost *);
    ULONG   (STDMETHODCALLTYPE *Release)(ICorRuntimeHost *);
    HRESULT (STDMETHODCALLTYPE *CreateLogicalThreadState)(void);
    void    (STDMETHODCALLTYPE *DeleteLogicalThreadState)(void);
    HRESULT (STDMETHODCALLTYPE *SwitchInLogicalThreadState)(void *);
    void    (STDMETHODCALLTYPE *SwitchOutLogicalThreadState)(void *);
    HRESULT (STDMETHODCALLTYPE *LocksHeldByLogicalThread)(void *);
    HRESULT (STDMETHODCALLTYPE *MapFile)(HANDLE, HANDLE *);
    HRESULT (STDMETHODCALLTYPE *GetConfiguration)(ICorConfiguration **);
    HRESULT (STDMETHODCALLTYPE *Start)(void);
    HRESULT (STDMETHODCALLTYPE *Stop)(void);
    HRESULT (STDMETHODCALLTYPE *CreateDomain)(LPCWSTR, IUnknown *, IUnknown **);
    HRESULT (STDMETHODCALLTYPE *GetDefaultDomain)(IUnknown **);
    HRESULT (STDMETHODCALLTYPE *EnumDomains)(void **);
    HRESULT (STDMETHODCALLTYPE *NextDomain)(void *, IUnknown **);
    HRESULT (STDMETHODCALLTYPE *CloseEnum)(void *);
    HRESULT (STDMETHODCALLTYPE *CreateDomainEx)(LPCWSTR, IUnknown *, IUnknown *, IUnknown **);
    HRESULT (STDMETHODCALLTYPE *CreateDomainSetup)(IUnknown **);
    HRESULT (STDMETHODCALLTYPE *CreateEvidence)(IUnknown **);
    HRESULT (STDMETHODCALLTYPE *UnloadDomain)(IUnknown *);
    HRESULT (STDMETHODCALLTYPE *CurrentDomain)(IUnknown **);
};

/* ── ICorConfiguration ────────────────────────────────────────────────── */
typedef struct ICorConfigurationVtbl ICorConfigurationVtbl;
typedef struct ICorConfiguration {
    const struct ICorConfigurationVtbl *lpVtbl;
} ICorConfiguration;

struct ICorConfigurationVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(ICorConfiguration *, REFIID, void **);
    ULONG   (STDMETHODCALLTYPE *AddRef)(ICorConfiguration *);
    ULONG   (STDMETHODCALLTYPE *Release)(ICorConfiguration *);
    HRESULT (STDMETHODCALLTYPE *SetGCThreadControl)(IUnknown *);
    HRESULT (STDMETHODCALLTYPE *SetGCHostControl)(IUnknown *);
    HRESULT (STDMETHODCALLTYPE *SetDebuggerThreadControl)(IUnknown *);
    HRESULT (STDMETHODCALLTYPE *AddDebuggerSpecialThread)(DWORD);
};

/* ── STARTUP_* flags ─────────────────────────────────────────────────── */
#ifndef STARTUP_CONCURRENT_GC
#define STARTUP_CONCURRENT_GC                0x00000001
#endif
#ifndef STARTUP_LOADER_OPTIMIZATION_MASK
#define STARTUP_LOADER_OPTIMIZATION_MASK     0x00000006
#endif
#ifndef STARTUP_LOADER_OPTIMIZATION_SINGLE_DOMAIN
#define STARTUP_LOADER_OPTIMIZATION_SINGLE_DOMAIN 0x00000002
#endif
#ifndef STARTUP_LOADER_OPTIMIZATION_MULTI_DOMAIN
#define STARTUP_LOADER_OPTIMIZATION_MULTI_DOMAIN 0x00000004
#endif
#ifndef STARTUP_LOADER_OPTIMIZATION_MULTI_DOMAIN_HOST
#define STARTUP_LOADER_OPTIMIZATION_MULTI_DOMAIN_HOST 0x00000006
#endif
#ifndef STARTUP_SINGLE_APPDOMAIN
#define STARTUP_SINGLE_APPDOMAIN             0x00000010
#endif
#ifndef STARTUP_DISABLE_COMMON_LANGUAGE_RUNTIME
#define STARTUP_DISABLE_COMMON_LANGUAGE_RUNTIME 0x00010000
#endif
#ifndef STARTUP_LEGACY_IMPERSONATION
#define STARTUP_LEGACY_IMPERSONATION         0x00000008
#endif
#ifndef STARTUP_ARM_NORMALIZE
#define STARTUP_ARM_NORMALIZE                0x00000020
#endif
#ifndef STARTUP_CLR32
#define STARTUP_CLR32                        0x00000080
#endif
#ifndef STARTUP_DISABLE_RANDOMIZED_STRING_HASHING
#define STARTUP_DISABLE_RANDOMIZED_STRING_HASHING 0x00000400
#endif
#ifndef STARTUP_SERVER_GC
#define STARTUP_SERVER_GC                    0x00001000
#endif
#ifndef STARTUP_ARM
#define STARTUP_ARM                          0x00002000
#endif
#ifndef STARTUP_HOSTMODE
#define STARTUP_HOSTMODE                     0x00000100
#endif

/* ── COR_* error codes ───────────────────────────────────────────────── */
#ifndef COR_E_APPDOMAINUNLOADED
#define COR_E_APPDOMAINUNLOADED MAKE_HRESULT(SEVERITY_ERROR, FACILITY_URT, 0x0142)
#endif

#define FACILITY_URT                     0x13
#define FACILITY_URT_W2K                0x15
#define SEVERITY_ERROR                   1

#ifdef __cplusplus
}
#endif

#endif
