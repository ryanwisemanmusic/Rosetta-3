#ifndef ROSETTA3_SHIMS_WIN32_MMSYSTEM_H
#define ROSETTA3_SHIMS_WIN32_MMSYSTEM_H

#include <game/debug_runtime.h>
#include "windows.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifndef MMRESULT
typedef UINT MMRESULT;
#endif

#ifndef MMSYSERR_NOERROR
#define MMSYSERR_NOERROR    0
#endif

/* PlaySound / sound flags */
#ifndef SND_FILENAME
#define SND_FILENAME                0x00020000
#endif
#ifndef SND_ALIAS
#define SND_ALIAS           0x00010000L
#endif
#ifndef SND_ASYNC
#define SND_ASYNC                   0x00000001
#endif
#ifndef SND_NODEFAULT
#define SND_NODEFAULT       0x00000002
#endif
#ifndef SND_NOSTOP
#define SND_NOSTOP          0x00000010
#endif
#ifndef SND_LOOP
#define SND_LOOP            0x00000008
#endif
#ifndef SND_NOWAIT
#define SND_NOWAIT          0x00002000
#endif
#ifndef SND_PURGE
#define SND_PURGE           0x00000040L
#endif
#ifndef SND_APPLICATION
#define SND_APPLICATION     0x00000080
#endif
#ifndef SND_ALIAS_ID
#define SND_ALIAS_ID        0x00110000
#endif
#ifndef SND_RESOURCE
#define SND_RESOURCE        0x00040004
#endif
#ifndef SND_SYSTEM
#define SND_SYSTEM          0x00200000
#endif

/* MCI constants */
#ifndef MM_MCINOTIFY
#define MM_MCINOTIFY        0x03B9
#endif

#ifndef MCI_OPEN
#define MCI_OPEN            0x0803
#define MCI_CLOSE           0x0804
#define MCI_PLAY            0x0806
#define MCI_STOP            0x0808
#define MCI_PAUSE           0x0809
#define MCI_SEEK            0x080B
#define MCI_SET             0x080D
#define MCI_STATUS          0x0814
#endif

#ifndef MCI_NOTIFY
#define MCI_NOTIFY          0x00000001
#define MCI_WAIT            0x00000002
#define MCI_FROM            0x00000004
#define MCI_TO              0x00000008
#define MCI_OPEN_TYPE       0x00002000
#define MCI_OPEN_ELEMENT    0x00000200
#define MCI_PLAY_ALIAS      0x00000400
#define MCI_SET_DOOR_OPEN   0x00000100
#define MCI_SET_DOOR_CLOSED 0x00000200
#define MCI_STATUS_LENGTH   0x00000001
#define MCI_STATUS_POSITION 0x00000002
#define MCI_STATUS_MODE     0x00000008
#define MCI_MODE_STOP       0x04CD
#define MCI_MODE_PLAY       0x04CE
#define MCI_MODE_PAUSE      0x04CF
#define MCI_MODE_OPEN       0x04D2
#define MCI_ALL_DEVICES_ID  0xFFFFFFFF
#endif

/* PlaySound function */
#ifndef _PLAYSOUND_DEFINED
#define _PLAYSOUND_DEFINED
FORCEINLINE BOOL WINAPI PlaySoundA(LPCSTR pszSound, HANDLE hmod, DWORD fdwSound) {
    char rosetta3_detail[512];
    snprintf(rosetta3_detail, sizeof(rosetta3_detail),
             "PlaySoundA sound=\"%s\" flags=0x%lx",
             pszSound ? pszSound : "",
             (unsigned long)fdwSound);
    rosetta3_debug_log_host_call("ARM64", "mmsystem", rosetta3_detail);
#ifdef ROSETTA_WINDOW_MODE
    return (BOOL)rosetta_gdi_play_sound_a(
        pszSound, (void *)hmod, (unsigned long)fdwSound);
#else
    (void)pszSound; (void)hmod; (void)fdwSound; return TRUE;
#endif
}
FORCEINLINE BOOL WINAPI PlaySoundW(LPCWSTR pszSound, HANDLE hmod, DWORD fdwSound) {
    rosetta3_debug_log_host_call("ARM64", "mmsystem", "PlaySoundW wide-sound request");
#ifdef ROSETTA_WINDOW_MODE
    return (BOOL)rosetta_gdi_play_sound_w(
        pszSound, (void *)hmod, (unsigned long)fdwSound);
#else
    (void)pszSound; (void)hmod; (void)fdwSound; return TRUE;
#endif
}
#ifdef UNICODE
#define PlaySound PlaySoundW
#else
#define PlaySound PlaySoundA
#endif
#endif

/* mciSendString function */
#ifndef MCISENDSTRING_DEFINED
#define MCISENDSTRING_DEFINED
FORCEINLINE MMRESULT WINAPI mciSendStringA(
    LPCSTR lpstrCommand, LPSTR lpstrReturnString,
    UINT uReturnLength, HANDLE hwndCallback)
{
    char rosetta3_detail[512];
    snprintf(rosetta3_detail, sizeof(rosetta3_detail),
             "mciSendStringA cmd=\"%s\" return_len=%u",
             lpstrCommand ? lpstrCommand : "",
             (unsigned int)uReturnLength);
    rosetta3_debug_log_host_call("ARM64", "mmsystem", rosetta3_detail);
#ifdef ROSETTA_WINDOW_MODE
    return (MMRESULT)rosetta_gdi_mci_send_string_a(
        lpstrCommand, lpstrReturnString, uReturnLength, (void *)hwndCallback);
#else
    (void)lpstrCommand; (void)lpstrReturnString;
    (void)uReturnLength; (void)hwndCallback;
    return 0;
#endif
}
FORCEINLINE MMRESULT WINAPI mciSendStringW(
    LPCWSTR lpstrCommand, LPWSTR lpstrReturnString,
    UINT uReturnLength, HANDLE hwndCallback)
{
    rosetta3_debug_log_host_call("ARM64", "mmsystem", "mciSendStringW wide-command request");
#ifdef ROSETTA_WINDOW_MODE
    (void)lpstrReturnString;
    return (MMRESULT)rosetta_gdi_mci_send_string_a(
        "", NULL, 0, (void *)hwndCallback);
#else
    (void)lpstrCommand; (void)lpstrReturnString;
    (void)uReturnLength; (void)hwndCallback;
    return 0;
#endif
}
#ifdef UNICODE
#define mciSendString mciSendStringW
#else
#define mciSendString mciSendStringA
#endif
#endif

#ifdef __cplusplus
}
#endif

#endif /* ROSETTA3_SHIMS_WIN32_MMSYSTEM_H */
