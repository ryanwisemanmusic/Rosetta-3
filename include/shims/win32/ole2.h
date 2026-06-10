#ifndef ROSETTE_SHIMS_WIN32_OLE2_H
#define ROSETTE_SHIMS_WIN32_OLE2_H

#include "windows.h"

/* Forward declarations */
typedef struct IUnknown IUnknown;
typedef struct IStream IStream;

#ifdef __cplusplus
extern "C" {
#endif

/* GUID-related definitions */
#ifndef REFGUID
#define REFGUID const GUID *
#endif
#ifndef REFIID
#define REFIID const IID *
#endif
#ifndef REFCLSID
#define REFCLSID const IID *
#endif

#ifndef IID_DEFINED
#define IID_DEFINED
typedef GUID IID;
#endif
#ifndef CLSID_DEFINED
#define CLSID_DEFINED
typedef GUID CLSID;
#endif
#ifndef LPCLSID
#define LPCLSID CLSID *
#endif

#ifndef IsEqualGUID
#define IsEqualGUID(r1, r2) (!memcmp(r1, r2, sizeof(GUID)))
#endif

#ifndef IsEqualIID
#define IsEqualIID(riid1, riid2) IsEqualGUID(riid1, riid2)
#endif

#ifndef IsEqualCLSID
#define IsEqualCLSID(r1, r2) IsEqualGUID(r1, r2)
#endif

/* HRESULT values */
#ifndef S_OK
#define S_OK                ((HRESULT)0x00000000L)
#endif
#ifndef S_FALSE
#define S_FALSE             ((HRESULT)0x00000001L)
#endif
#ifndef E_UNEXPECTED
#define E_UNEXPECTED        ((HRESULT)0x8000FFFFL)
#endif
#ifndef E_NOTIMPL
#define E_NOTIMPL           ((HRESULT)0x80004001L)
#endif
#ifndef E_OUTOFMEMORY
#define E_OUTOFMEMORY       ((HRESULT)0x8007000EL)
#endif
#ifndef E_INVALIDARG
#define E_INVALIDARG        ((HRESULT)0x80070057L)
#endif
#ifndef E_NOINTERFACE
#define E_NOINTERFACE       ((HRESULT)0x80004002L)
#endif
#ifndef E_POINTER
#define E_POINTER           ((HRESULT)0x80004003L)
#endif
#ifndef E_HANDLE
#define E_HANDLE            ((HRESULT)0x80070006L)
#endif
#ifndef E_ABORT
#define E_ABORT             ((HRESULT)0x80004004L)
#endif
#ifndef E_FAIL
#define E_FAIL              ((HRESULT)0x80004005L)
#endif
#ifndef E_ACCESSDENIED
#define E_ACCESSDENIED      ((HRESULT)0x80070005L)
#endif
#ifndef CLASS_E_NOAGGREGATION
#define CLASS_E_NOAGGREGATION ((HRESULT)0x80040102L)
#endif
#ifndef CO_E_NOTINITIALIZED
#define CO_E_NOTINITIALIZED ((HRESULT)0x800401F0L)
#endif
#ifndef CLASS_E_CLASSNOTAVAILABLE
#define CLASS_E_CLASSNOTAVAILABLE ((HRESULT)0x80040111L)
#endif
#ifndef REGDB_E_CLASSNOTREG
#define REGDB_E_CLASSNOTREG ((HRESULT)0x80040154L)
#endif

#ifndef SUCCEEDED
#define SUCCEEDED(hr) (((HRESULT)(hr)) >= 0)
#endif
#ifndef FAILED
#define FAILED(hr) (((HRESULT)(hr)) < 0)
#endif

/* COM base types */
#ifndef LPUNKNOWN
#define LPUNKNOWN IUnknown *
#endif

#ifndef BOOLEAN
#define BOOLEAN unsigned char
#endif

/* COM base interfaces */
typedef struct IUnknownVtbl IUnknownVtbl;
typedef struct IUnknown {
    const struct IUnknownVtbl *lpVtbl;
} IUnknown;

struct IUnknownVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(IUnknown *This, REFIID riid, void **ppvObject);
    ULONG   (STDMETHODCALLTYPE *AddRef)(IUnknown *This);
    ULONG   (STDMETHODCALLTYPE *Release)(IUnknown *This);
};

typedef struct IClassFactoryVtbl IClassFactoryVtbl;
typedef struct IClassFactory {
    const struct IClassFactoryVtbl *lpVtbl;
} IClassFactory;

struct IClassFactoryVtbl {
    HRESULT (STDMETHODCALLTYPE *QueryInterface)(IClassFactory *This, REFIID riid, void **ppvObject);
    ULONG   (STDMETHODCALLTYPE *AddRef)(IClassFactory *This);
    ULONG   (STDMETHODCALLTYPE *Release)(IClassFactory *This);
    HRESULT (STDMETHODCALLTYPE *CreateInstance)(IClassFactory *This, IUnknown *pUnkOuter, REFIID riid, void **ppvObject);
    HRESULT (STDMETHODCALLTYPE *LockServer)(IClassFactory *This, BOOL fLock);
};

#ifndef IUnknown_QueryInterface
#define IUnknown_QueryInterface(This, riid, ppvObject)  (This)->lpVtbl->QueryInterface(This, riid, ppvObject)
#endif
#ifndef IUnknown_AddRef
#define IUnknown_AddRef(This)                           (This)->lpVtbl->AddRef(This)
#endif
#ifndef IUnknown_Release
#define IUnknown_Release(This)                          (This)->lpVtbl->Release(This)
#endif

#ifndef IClassFactory_QueryInterface
#define IClassFactory_QueryInterface(This, riid, ppv)   (This)->lpVtbl->QueryInterface(This, riid, ppv)
#endif
#ifndef IClassFactory_AddRef
#define IClassFactory_AddRef(This)                      (This)->lpVtbl->AddRef(This)
#endif
#ifndef IClassFactory_Release
#define IClassFactory_Release(This)                     (This)->lpVtbl->Release(This)
#endif
#ifndef IClassFactory_CreateInstance
#define IClassFactory_CreateInstance(This, pUnkOuter, riid, ppvObject) (This)->lpVtbl->CreateInstance(This, pUnkOuter, riid, ppvObject)
#endif
#ifndef IClassFactory_LockServer
#define IClassFactory_LockServer(This, fLock)           (This)->lpVtbl->LockServer(This, fLock)
#endif

EXTERN_C const GUID IID_IUnknown;
EXTERN_C const GUID IID_IClassFactory;

/* CLSID from string */
HRESULT WINAPI CLSIDFromString(LPCWSTR lpsz, LPCLSID pclsid);

/* COM initialization */
HRESULT WINAPI CoInitialize(LPVOID pvReserved);
void    WINAPI CoUninitialize(void);
HRESULT WINAPI CoInitializeEx(LPVOID pvReserved, DWORD dwCoInit);
HRESULT WINAPI CoCreateInstance(REFCLSID rclsid, IUnknown *pUnkOuter, DWORD dwClsContext, REFIID riid, LPVOID *ppv);
LPVOID WINAPI CoTaskMemAlloc(SIZE_T cb);
void    WINAPI CoTaskMemFree(LPVOID pv);

#define CLSCTX_INPROC_SERVER    1
#define CLSCTX_INPROC_HANDLER   2
#define CLSCTX_LOCAL_SERVER     4
#define CLSCTX_REMOTE_SERVER    16
#define CLSCTX_ALL              (CLSCTX_INPROC_SERVER | CLSCTX_INPROC_HANDLER | CLSCTX_LOCAL_SERVER)

#define COINIT_APARTMENTTHREADED     0x2
#define COINIT_MULTITHREADED         0x0
#define COINIT_DISABLE_OLE1DDE       0x4
#define COINIT_SPEED_OVER_MEMORY     0x8

#ifdef __cplusplus
}
#endif

#endif
