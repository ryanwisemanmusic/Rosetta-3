#ifndef ROSETTE_SHIMS_WIN32_CORDEBUG_H
#define ROSETTE_SHIMS_WIN32_CORDEBUG_H

#include "windows.h"
#include "ole2.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Forward declarations */
typedef struct ICorDebugProcess ICorDebugProcess;
typedef struct ICorDebugProcessEnum ICorDebugProcessEnum;

/* ── ICorDebug ───────────────────────────────────────────────────────── */
typedef struct ICorDebugVtbl ICorDebugVtbl;
typedef struct ICorDebug {
    const struct ICorDebugVtbl *lpVtbl;
} ICorDebug;

struct ICorDebugVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(ICorDebug *, REFIID, void **);
    ULONG   (STDMETHODCALLTYPE *AddRef)(ICorDebug *);
    ULONG   (STDMETHODCALLTYPE *Release)(ICorDebug *);
    HRESULT (STDMETHODCALLTYPE *Initialize)(void);
    HRESULT (STDMETHODCALLTYPE *Terminate)(void);
    HRESULT (STDMETHODCALLTYPE *SetManagedHandler)(IUnknown *);
    HRESULT (STDMETHODCALLTYPE *SetUnmanagedHandler)(IUnknown *);
    HRESULT (STDMETHODCALLTYPE *CreateProcess)(IUnknown *, LPCWSTR, LPWSTR, void *, void *,
                LPCWSTR, LPCWSTR, void *, DWORD, void *, void *, void *, void *);
    HRESULT (STDMETHODCALLTYPE *DebugActiveProcess)(DWORD, BOOL, ICorDebugProcess **);
    HRESULT (STDMETHODCALLTYPE *EnumerateProcesses)(ICorDebugProcessEnum **);
    HRESULT (STDMETHODCALLTYPE *GetProcess)(DWORD, ICorDebugProcess **);
    HRESULT (STDMETHODCALLTYPE *CanLaunchOrAttach)(DWORD, BOOL);
};

/* ── ICorDebugProcess ────────────────────────────────────────────────── */
typedef struct ICorDebugProcessVtbl ICorDebugProcessVtbl;
typedef struct ICorDebugProcess {
    const struct ICorDebugProcessVtbl *lpVtbl;
} ICorDebugProcess;

struct ICorDebugProcessVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(ICorDebugProcess *, REFIID, void **);
    ULONG   (STDMETHODCALLTYPE *AddRef)(ICorDebugProcess *);
    ULONG   (STDMETHODCALLTYPE *Release)(ICorDebugProcess *);
    HRESULT (STDMETHODCALLTYPE *Stop)(DWORD);
    HRESULT (STDMETHODCALLTYPE *Continue)(BOOL);
    HRESULT (STDMETHODCALLTYPE *IsRunning)(BOOL *);
    HRESULT (STDMETHODCALLTYPE *GetID)(DWORD *);
    HRESULT (STDMETHODCALLTYPE *GetHandle)(HANDLE *);
    HRESULT (STDMETHODCALLTYPE *GetThread)(DWORD, void **);
    HRESULT (STDMETHODCALLTYPE *EnumerateObjects)(void **);
    HRESULT (STDMETHODCALLTYPE *IsTransitionStub)(ULONG64, BOOL *);
    HRESULT (STDMETHODCALLTYPE *GetHelperThreadID)(DWORD *);
};

/* ── ICorDebugProcessEnum ────────────────────────────────────────────── */
typedef struct ICorDebugProcessEnumVtbl ICorDebugProcessEnumVtbl;
typedef struct ICorDebugProcessEnum {
    const struct ICorDebugProcessEnumVtbl *lpVtbl;
} ICorDebugProcessEnum;

struct ICorDebugProcessEnumVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(ICorDebugProcessEnum *, REFIID, void **);
    ULONG   (STDMETHODCALLTYPE *AddRef)(ICorDebugProcessEnum *);
    ULONG   (STDMETHODCALLTYPE *Release)(ICorDebugProcessEnum *);
    HRESULT (STDMETHODCALLTYPE *Next)(ICorDebugProcessEnum *, ULONG, ICorDebugProcess **, ULONG *);
    HRESULT (STDMETHODCALLTYPE *Skip)(ICorDebugProcessEnum *, ULONG);
    HRESULT (STDMETHODCALLTYPE *Reset)(ICorDebugProcessEnum *);
    HRESULT (STDMETHODCALLTYPE *Clone)(ICorDebugProcessEnum **);
};

/* COBJMACROS */
#ifdef COBJMACROS
#define ICorDebug_QueryInterface(This,riid,ppv)   (This)->lpVtbl->QueryInterface(This,riid,ppv)
#define ICorDebug_AddRef(This)                    (This)->lpVtbl->AddRef(This)
#define ICorDebug_Release(This)                   (This)->lpVtbl->Release(This)
#define ICorDebug_Initialize(This)                (This)->lpVtbl->Initialize(This)
#define ICorDebug_Terminate(This)                 (This)->lpVtbl->Terminate(This)
#define ICorDebug_SetManagedHandler(This,p)       (This)->lpVtbl->SetManagedHandler(This,p)
#define ICorDebug_SetUnmanagedHandler(This,p)     (This)->lpVtbl->SetUnmanagedHandler(This,p)
#define ICorDebug_CreateProcess(This, ...)        (This)->lpVtbl->CreateProcess(This, __VA_ARGS__)
#define ICorDebug_DebugActiveProcess(This,id,f,p) (This)->lpVtbl->DebugActiveProcess(This,id,f,p)
#define ICorDebug_EnumerateProcesses(This,p)      (This)->lpVtbl->EnumerateProcesses(This,p)
#define ICorDebug_GetProcess(This,id,p)           (This)->lpVtbl->GetProcess(This,id,p)
#define ICorDebug_CanLaunchOrAttach(This,id,f)    (This)->lpVtbl->CanLaunchOrAttach(This,id,f)
#endif

/* ── ICorDebugManagedCallback ────────────────────────────────────────── */
typedef struct ICorDebugManagedCallbackVtbl ICorDebugManagedCallbackVtbl;
typedef struct ICorDebugManagedCallback {
    const struct ICorDebugManagedCallbackVtbl *lpVtbl;
} ICorDebugManagedCallback;

struct ICorDebugManagedCallbackVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(ICorDebugManagedCallback *, REFIID, void **);
    ULONG   (STDMETHODCALLTYPE *AddRef)(ICorDebugManagedCallback *);
    ULONG   (STDMETHODCALLTYPE *Release)(ICorDebugManagedCallback *);
    HRESULT (STDMETHODCALLTYPE *Breakpoint)(void *);
    HRESULT (STDMETHODCALLTYPE *StepComplete)(void *, void *);
    HRESULT (STDMETHODCALLTYPE *Break)(void *);
    HRESULT (STDMETHODCALLTYPE *Exception)(void *, void *);
    HRESULT (STDMETHODCALLTYPE *EvalComplete)(void *, void *);
    HRESULT (STDMETHODCALLTYPE *EvalException)(void *, void *);
    HRESULT (STDMETHODCALLTYPE *CreateProcess)(void *, void *);
    HRESULT (STDMETHODCALLTYPE *CreateThread)(void *, void *);
    HRESULT (STDMETHODCALLTYPE *CreateAppDomain)(void *, void *);
    HRESULT (STDMETHODCALLTYPE *LoadAssembly)(void *, void *);
    HRESULT (STDMETHODCALLTYPE *LoadClass)(void *, void *);
    HRESULT (STDMETHODCALLTYPE *UnloadClass)(void *, void *);
    HRESULT (STDMETHODCALLTYPE *UnloadAssembly)(void *, void *);
    HRESULT (STDMETHODCALLTYPE *ExitThread)(void *, void *);
    HRESULT (STDMETHODCALLTYPE *ExitProcess)(void *, void *);
};

/* ── ICorDebugManagedCallback2 ───────────────────────────────────────── */
typedef struct ICorDebugManagedCallback2Vtbl ICorDebugManagedCallback2Vtbl;
typedef struct ICorDebugManagedCallback2 {
    const struct ICorDebugManagedCallback2Vtbl *lpVtbl;
} ICorDebugManagedCallback2;

struct ICorDebugManagedCallback2Vtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(ICorDebugManagedCallback2 *, REFIID, void **);
    ULONG   (STDMETHODCALLTYPE *AddRef)(ICorDebugManagedCallback2 *);
    ULONG   (STDMETHODCALLTYPE *Release)(ICorDebugManagedCallback2 *);
    HRESULT (STDMETHODCALLTYPE *FunctionRemapOpportunity)(void *, void *, void *, void *);
    HRESULT (STDMETHODCALLTYPE *CreateConnection)(void *, void *, void *);
    HRESULT (STDMETHODCALLTYPE *ChangeConnection)(void *, void *);
    HRESULT (STDMETHODCALLTYPE *DestroyConnection)(void *, void *);
    HRESULT (STDMETHODCALLTYPE *Exception)(void *, void *, void *, void *, void *, void *,
                void *, void *, void *, void *, void *);
    HRESULT (STDMETHODCALLTYPE *ExceptionUnwind)(void *, void *, void *, void *);
    HRESULT (STDMETHODCALLTYPE *FunctionRemapComplete)(void *, void *, void *);
    HRESULT (STDMETHODCALLTYPE *MDANotification)(void *, void *);
};

EXTERN_C const GUID IID_ICorDebug;

#ifdef __cplusplus
}
#endif

#endif
