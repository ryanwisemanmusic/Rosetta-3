#ifndef ROSETTE_SHIMS_WIN32_STRONGNAME_H
#define ROSETTE_SHIMS_WIN32_STRONGNAME_H

#include "windows.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Note: Wine's mscoree defines these with BOOLEAN (unsigned char), not BOOL. */

BOOLEAN WINAPI StrongNameSignatureVerificationEx(LPCWSTR wszFilePath, BOOLEAN fForceVerification, BOOLEAN *pfWasVerified);
BOOLEAN WINAPI StrongNameSignatureVerification(LPCWSTR wszFilePath, DWORD dwFlags, DWORD *pdwLastError);
BOOLEAN WINAPI StrongNameTokenFromAssembly(LPCWSTR wszFilePath, BYTE **ppbStrongNameToken, DWORD *pcbStrongNameToken);
BOOL   WINAPI StrongNameTokenFromPublicKey(BYTE *pbPublicKeyBlob, DWORD cbPublicKeyBlob,
                BYTE **ppbStrongNameToken, DWORD *pcbStrongNameToken);
void   WINAPI StrongNameFreeBuffer(BYTE *pbMemory);

#ifdef __cplusplus
}
#endif

#endif
