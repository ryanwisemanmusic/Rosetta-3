#ifndef ROSETTE_SHIMS_WIN32_FUSION_H
#define ROSETTE_SHIMS_WIN32_FUSION_H

#include "windows.h"
#include "ole2.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ── IAssemblyName ───────────────────────────────────────────────────── */
typedef struct IAssemblyNameVtbl IAssemblyNameVtbl;
typedef struct IAssemblyName {
    const struct IAssemblyNameVtbl *lpVtbl;
} IAssemblyName;

struct IAssemblyNameVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(IAssemblyName *, REFIID, void **);
    ULONG   (STDMETHODCALLTYPE *AddRef)(IAssemblyName *);
    ULONG   (STDMETHODCALLTYPE *Release)(IAssemblyName *);
    HRESULT (STDMETHODCALLTYPE *SetProperty)(DWORD, const void *, DWORD);
    HRESULT (STDMETHODCALLTYPE *GetProperty)(DWORD, void *, DWORD *);
    HRESULT (STDMETHODCALLTYPE *Finalize)(void);
    HRESULT (STDMETHODCALLTYPE *GetDisplayName)(LPWSTR, DWORD *);
    HRESULT (STDMETHODCALLTYPE *BindToObject)(REFIID, void *, void *, void **);
    HRESULT (STDMETHODCALLTYPE *GetName)(DWORD *, LPWSTR);
    HRESULT (STDMETHODCALLTYPE *GetVersion)(DWORD *, DWORD *);
    HRESULT (STDMETHODCALLTYPE *IsEqual)(IAssemblyName *, DWORD);
    HRESULT (STDMETHODCALLTYPE *Clone)(IAssemblyName **);
};

/* ── IAssemblyCache ──────────────────────────────────────────────────── */
typedef struct IAssemblyCacheVtbl IAssemblyCacheVtbl;
typedef struct IAssemblyCache {
    const struct IAssemblyCacheVtbl *lpVtbl;
} IAssemblyCache;

struct IAssemblyCacheVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(IAssemblyCache *, REFIID, void **);
    ULONG   (STDMETHODCALLTYPE *AddRef)(IAssemblyCache *);
    ULONG   (STDMETHODCALLTYPE *Release)(IAssemblyCache *);
    HRESULT (STDMETHODCALLTYPE *UninstallAssembly)(DWORD, LPCWSTR, void *, ULONG *);
    HRESULT (STDMETHODCALLTYPE *QueryAssemblyInfo)(DWORD, LPCWSTR, void *);
    HRESULT (STDMETHODCALLTYPE *CreateAssemblyCacheItem)(DWORD, void *, void **, LPCWSTR);
    HRESULT (STDMETHODCALLTYPE *CreateAssemblyScavenger)(void **);
    HRESULT (STDMETHODCALLTYPE *InstallAssembly)(DWORD, LPCWSTR, void *);
};

/* ── ASM_* constants ─────────────────────────────────────────────────── */
#ifndef ASM_CACHE_GAC
#define ASM_CACHE_GAC                   0x00000001
#endif
#ifndef ASM_CACHE_DOWNLOAD
#define ASM_CACHE_DOWNLOAD              0x00000002
#endif
#ifndef ASM_CACHE_ZAP
#define ASM_CACHE_ZAP                   0x00000004
#endif

/* ── IInstallReferenceEnum ───────────────────────────────────────────── */
typedef struct IInstallReferenceEnumVtbl IInstallReferenceEnumVtbl;
typedef struct IInstallReferenceEnum {
    const struct IInstallReferenceEnumVtbl *lpVtbl;
} IInstallReferenceEnum;

struct IInstallReferenceEnumVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(IInstallReferenceEnum *, REFIID, void **);
    ULONG   (STDMETHODCALLTYPE *AddRef)(IInstallReferenceEnum *);
    ULONG   (STDMETHODCALLTYPE *Release)(IInstallReferenceEnum *);
    HRESULT (STDMETHODCALLTYPE *GetNextInstallReferenceItem)(void **, DWORD, void *);
};

/* ── IInstallReferenceItem ───────────────────────────────────────────── */
typedef struct IInstallReferenceItemVtbl IInstallReferenceItemVtbl;
typedef struct IInstallReferenceItem {
    const struct IInstallReferenceItemVtbl *lpVtbl;
} IInstallReferenceItem;

struct IInstallReferenceItemVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(IInstallReferenceItem *, REFIID, void **);
    ULONG   (STDMETHODCALLTYPE *AddRef)(IInstallReferenceItem *);
    ULONG   (STDMETHODCALLTYPE *Release)(IInstallReferenceItem *);
    HRESULT (STDMETHODCALLTYPE *GetReference)(void *, DWORD);
};

#ifdef __cplusplus
}
#endif

#endif
