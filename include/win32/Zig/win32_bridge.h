#ifndef ROSETTA3_WIN32_BRIDGE_H
#define ROSETTA3_WIN32_BRIDGE_H

#include "win32/windows_base.h"
#include "win32/windows_modular.h"
#include "mmsystem.h"

#ifndef _RTL_BARRIER_DEFINED
#define _RTL_BARRIER_DEFINED
typedef struct _RTL_BARRIER {
    ULONG_PTR Reserved[5];
} RTL_BARRIER, *PRTL_BARRIER;
#endif

/*
 * The broader ABI handshake suite needs a few symbols that are present in the
 * reference Win32 headers but not consistently surfaced through the current
 * shim translation umbrella. We declare the missing reference-backed surface
 * here so Zig can validate it without forcing the full upstream windows.h
 * through translate-c on macOS.
 */

#ifndef _AMD64_
#if defined(__x86_64__) || defined(__aarch64__) || defined(__arm64__)
#define _AMD64_ 1
#endif
#endif

#ifndef ROSETTA3_BRIDGE_FORCEINLINE
#define ROSETTA3_BRIDGE_FORCEINLINE static inline
#endif

/* ------------------------------------------------------------------------- */
/* intrin / atomic                                                           */
/* ------------------------------------------------------------------------- */
#ifndef ROSETTA3_BRIDGE_INTRIN_DECLS
#define ROSETTA3_BRIDGE_INTRIN_DECLS
extern void _mm_pause(void);
ROSETTA3_BRIDGE_FORCEINLINE void _ReadWriteBarrier(void) {
    __atomic_signal_fence(__ATOMIC_SEQ_CST);
}
ROSETTA3_BRIDGE_FORCEINLINE void __faststorefence(void) {
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}
#endif

#ifndef ROSETTA3_BRIDGE_ATOMIC8_DECLS
#define ROSETTA3_BRIDGE_ATOMIC8_DECLS
extern char _InterlockedExchange8(char volatile *Target, char Value);
extern char _InterlockedExchangeAdd8(char volatile *Addend, char Value);
extern char _InterlockedExchangeAnd8(char volatile *Destination, char Value);
extern char _InterlockedExchangeOr8(char volatile *Destination, char Value);
extern char _InterlockedExchangeXor8(char volatile *Destination, char Value);
extern char _InterlockedDecrement8(char volatile *Addend);
extern char _InterlockedIncrement8(char volatile *Addend);
extern char _InterlockedCompareExchange8(char volatile *Destination, char Exchange, char Comparand);

#ifndef InterlockedExchange8
#define InterlockedExchange8 _InterlockedExchange8
#endif

#ifndef ROSETTA3_BRIDGE_ATOMIC16_DECLS
#define ROSETTA3_BRIDGE_ATOMIC16_DECLS
extern short _InterlockedExchange16(short volatile *Target, short Value);
extern short _InterlockedExchangeAdd16(short volatile *Addend, short Value);
extern short _InterlockedExchangeAnd16(short volatile *Destination, short Value);
extern short _InterlockedExchangeOr16(short volatile *Destination, short Value);
extern short _InterlockedExchangeXor16(short volatile *Destination, short Value);
extern short _InterlockedDecrement16(short volatile *Addend);
extern short _InterlockedIncrement16(short volatile *Addend);
extern short _InterlockedCompareExchange16(short volatile *Destination, short Exchange, short Comparand);

#ifndef InterlockedExchange16
#define InterlockedExchange16 _InterlockedExchange16
#endif

#ifndef ROSETTA3_BRIDGE_ATOMIC32_DECLS
#define ROSETTA3_BRIDGE_ATOMIC32_DECLS
extern long _InterlockedExchange(long volatile *Target, long Value);
extern long _InterlockedExchangeAdd(long volatile *Addend, long Value);
extern long _InterlockedExchangeAnd(long volatile *Destination, long Value);
extern long _InterlockedExchangeOr(long volatile *Destination, long Value);
extern long _InterlockedExchangeXor(long volatile *Destination, long Value);
extern long _InterlockedDecrement(long volatile *Addend);
extern long _InterlockedIncrement(long volatile *Addend);
extern long _InterlockedCompareExchange(long volatile *Destination, long Exchange, long Comparand);

#ifndef InterlockedExchange
#define InterlockedExchange _InterlockedExchange
#endif
#ifndef InterlockedExchangeAdd
#define InterlockedExchangeAdd _InterlockedExchangeAdd
#endif
#ifndef InterlockedExchangeAnd
#define InterlockedExchangeAnd _InterlockedExchangeAnd
#endif
#ifndef InterlockedExchangeOr
#define InterlockedExchangeOr _InterlockedExchangeOr
#endif
#ifndef InterlockedExchangeXor
#define InterlockedExchangeXor _InterlockedExchangeXor
#endif
#ifndef InterlockedDecrement
#define InterlockedDecrement _InterlockedDecrement
#endif
#ifndef InterlockedIncrement
#define InterlockedIncrement _InterlockedIncrement
#endif
#ifndef InterlockedCompareExchange
#define InterlockedCompareExchange _InterlockedCompareExchange
#endif
#endif
#ifndef InterlockedExchangeAdd16
#define InterlockedExchangeAdd16 _InterlockedExchangeAdd16
#endif
#ifndef InterlockedExchangeAnd16
#define InterlockedExchangeAnd16 _InterlockedExchangeAnd16
#endif
#ifndef InterlockedExchangeOr16
#define InterlockedExchangeOr16 _InterlockedExchangeOr16
#endif
#ifndef InterlockedExchangeXor16
#define InterlockedExchangeXor16 _InterlockedExchangeXor16
#endif
#ifndef InterlockedDecrement16
#define InterlockedDecrement16 _InterlockedDecrement16
#endif
#ifndef InterlockedIncrement16
#define InterlockedIncrement16 _InterlockedIncrement16
#endif
#ifndef InterlockedCompareExchange16
#define InterlockedCompareExchange16 _InterlockedCompareExchange16
#endif
#endif
#ifndef InterlockedExchangeAdd8
#define InterlockedExchangeAdd8 _InterlockedExchangeAdd8
#endif
#ifndef InterlockedExchangeAnd8
#define InterlockedExchangeAnd8 _InterlockedExchangeAnd8
#endif
#ifndef InterlockedExchangeOr8
#define InterlockedExchangeOr8 _InterlockedExchangeOr8
#endif
#ifndef InterlockedExchangeXor8
#define InterlockedExchangeXor8 _InterlockedExchangeXor8
#endif
#ifndef InterlockedDecrement8
#define InterlockedDecrement8 _InterlockedDecrement8
#endif
#ifndef InterlockedIncrement8
#define InterlockedIncrement8 _InterlockedIncrement8
#endif
#ifndef InterlockedCompareExchange8
#define InterlockedCompareExchange8 _InterlockedCompareExchange8
#endif
#ifndef MemoryBarrier
#define MemoryBarrier __faststorefence
#endif
#ifndef YieldProcessor
#define YieldProcessor _mm_pause
#endif
#endif

/* ------------------------------------------------------------------------- */
/* dbghelp                                                                   */
/* ------------------------------------------------------------------------- */
#ifndef EXCEPTION_MAXIMUM_PARAMETERS
#define EXCEPTION_MAXIMUM_PARAMETERS 15
#endif
#ifndef CONTEXT_AMD64
#define CONTEXT_AMD64 0x100000
#endif
#ifndef TH32CS_SNAPTHREAD
#define TH32CS_SNAPTHREAD 0x00000004
#endif
#ifndef IMAGE_FILE_MACHINE_I386
#define IMAGE_FILE_MACHINE_I386 0x014c
#endif
#ifndef IMAGE_FILE_MACHINE_AMD64
#define IMAGE_FILE_MACHINE_AMD64 0x8664
#endif
#ifndef EXCEPTION_EXECUTE_HANDLER
#define EXCEPTION_EXECUTE_HANDLER 0x1
#endif
#ifndef EXCEPTION_CONTINUE_EXECUTION
#define EXCEPTION_CONTINUE_EXECUTION 0xFFFFFFFF
#endif
#ifndef EXCEPTION_CONTINUE_SEARCH
#define EXCEPTION_CONTINUE_SEARCH 0x0
#endif
#ifndef EXCEPTION_ACCESS_VIOLATION
#define EXCEPTION_ACCESS_VIOLATION 0xC0000005
#endif
#ifndef EXCEPTION_BREAKPOINT
#define EXCEPTION_BREAKPOINT 0x80000003
#endif
#ifndef EXCEPTION_SINGLE_STEP
#define EXCEPTION_SINGLE_STEP 0x80000004
#endif
#ifndef EXCEPTION_INT_DIVIDE_BY_ZERO
#define EXCEPTION_INT_DIVIDE_BY_ZERO 0xC0000094
#endif
#ifndef EXCEPTION_STACK_OVERFLOW
#define EXCEPTION_STACK_OVERFLOW 0xC00000FD
#endif
#ifndef EXCEPTION_ILLEGAL_INSTRUCTION
#define EXCEPTION_ILLEGAL_INSTRUCTION 0xC000001D
#endif
#ifndef EXCEPTION_INVALID_HANDLE
#define EXCEPTION_INVALID_HANDLE 0xC0000008
#endif
#ifndef EXCEPTION_GUARD_PAGE
#define EXCEPTION_GUARD_PAGE 0x80000001
#endif
#ifndef EXCEPTION_FLT_DIVIDE_BY_ZERO
#define EXCEPTION_FLT_DIVIDE_BY_ZERO 0xC000008E
#endif
#ifndef EXCEPTION_FLT_OVERFLOW
#define EXCEPTION_FLT_OVERFLOW 0xC0000091
#endif
#ifndef EXCEPTION_FLT_UNDERFLOW
#define EXCEPTION_FLT_UNDERFLOW 0xC0000093
#endif
#ifndef CONTROL_C_EXIT
#define CONTROL_C_EXIT 0xC000013A
#endif

#ifndef ROSETTA3_BRIDGE_CONTEXT_DEFINED
#define ROSETTA3_BRIDGE_CONTEXT_DEFINED
typedef struct _CONTEXT {
#if defined(__x86_64__) || defined(__aarch64__) || defined(__arm64__)
    BYTE _rosetta_padding[1232];
#else
    BYTE _rosetta_padding[716];
#endif
} CONTEXT, *PCONTEXT, *LPCONTEXT;
#endif

#ifndef ROSETTA3_BRIDGE_EXCEPTION_RECORD_DEFINED
#define ROSETTA3_BRIDGE_EXCEPTION_RECORD_DEFINED
typedef struct _EXCEPTION_RECORD {
    BYTE _rosetta_padding[152];
} EXCEPTION_RECORD, *PEXCEPTION_RECORD;
#endif

#ifndef ROSETTA3_BRIDGE_EXCEPTION_POINTERS_DEFINED
#define ROSETTA3_BRIDGE_EXCEPTION_POINTERS_DEFINED
typedef struct _EXCEPTION_POINTERS {
    PEXCEPTION_RECORD ExceptionRecord;
    PCONTEXT ContextRecord;
} EXCEPTION_POINTERS, *PEXCEPTION_POINTERS;
#endif

#ifndef ROSETTA3_BRIDGE_NT_TIB_DEFINED
#define ROSETTA3_BRIDGE_NT_TIB_DEFINED
typedef struct _NT_TIB {
#if defined(__x86_64__) || defined(__aarch64__) || defined(__arm64__)
    BYTE _rosetta_padding[56];
#else
    BYTE _rosetta_padding[28];
#endif
} NT_TIB, *PNT_TIB;
#endif

/* ------------------------------------------------------------------------- */
/* DDS                                                                       */
/* ------------------------------------------------------------------------- */
#ifndef FOURCC_DDS
#define FOURCC_DDS 0x20534444
#endif
#ifndef DDPF_FOURCC
#define DDPF_FOURCC 0x00000004
#endif
#ifndef FMT_DX10
#define FMT_DX10 0x30315844
#endif
#ifndef FMT_DXT1
#define FMT_DXT1 0x31545844
#endif
#ifndef FMT_DXT3
#define FMT_DXT3 0x33545844
#endif
#ifndef FMT_DXT5
#define FMT_DXT5 0x35545844
#endif
#ifndef DDSD_CAPS
#define DDSD_CAPS 0x00000001
#endif
#ifndef DDSD_HEIGHT
#define DDSD_HEIGHT 0x00000002
#endif
#ifndef DDSD_WIDTH
#define DDSD_WIDTH 0x00000004
#endif
#ifndef DDSD_PITCH
#define DDSD_PITCH 0x00000008
#endif
#ifndef DDSD_PIXELFORMAT
#define DDSD_PIXELFORMAT 0x00001000
#endif
#ifndef DDSD_MIPMAPCOUNT
#define DDSD_MIPMAPCOUNT 0x00020000
#endif
#ifndef DDSD_LINEARSIZE
#define DDSD_LINEARSIZE 0x00080000
#endif
#ifndef DDSD_DEPTH
#define DDSD_DEPTH 0x00800000
#endif
#ifndef DDSCAPS_COMPLEX
#define DDSCAPS_COMPLEX 0x00000008
#endif
#ifndef DDSCAPS_MIPMAP
#define DDSCAPS_MIPMAP 0x04000000
#endif
#ifndef DDSCAPS_TEXTURE
#define DDSCAPS_TEXTURE 0x00001000
#endif
#ifndef BLOCKSIZE_DXT1
#define BLOCKSIZE_DXT1 0x8
#endif
#ifndef BLOCKSIZE_DXT3
#define BLOCKSIZE_DXT3 0x10
#endif
#ifndef BLOCKSIZE_DXT5
#define BLOCKSIZE_DXT5 0x10
#endif
#ifndef DXGI_FORMAT_UNKNOWN
#define DXGI_FORMAT_UNKNOWN 0
#endif
#ifndef DXGI_FORMAT_R32G32B32A32_FLOAT
#define DXGI_FORMAT_R32G32B32A32_FLOAT 2
#endif
#ifndef DXGI_FORMAT_R8G8B8A8_UNORM
#define DXGI_FORMAT_R8G8B8A8_UNORM 28
#endif
#ifndef DXGI_FORMAT_BC1_UNORM
#define DXGI_FORMAT_BC1_UNORM 71
#endif
#ifndef DXGI_FORMAT_BC3_UNORM
#define DXGI_FORMAT_BC3_UNORM 78
#endif
#ifndef DXGI_FORMAT_BC7_UNORM
#define DXGI_FORMAT_BC7_UNORM 98
#endif
#ifndef DXGI_FORMAT_FORCE_UINT
#define DXGI_FORMAT_FORCE_UINT 0xffffffffU
#endif

#ifndef ROSETTA3_BRIDGE_DDS_TYPES_DEFINED
#define ROSETTA3_BRIDGE_DDS_TYPES_DEFINED
typedef struct _DDS_PIXELFORMAT {
    DWORD dwSize;
    DWORD dwFlags;
    DWORD dwFourCC;
    DWORD dwRGBBitCount;
    DWORD dwRBitMask;
    DWORD dwGBitMask;
    DWORD dwBBitMask;
    DWORD dwABitMask;
} DDS_PIXELFORMAT;

typedef struct _DDS_HEADER {
    DWORD dwSize;
    DWORD dwFlags;
    DWORD dwHeight;
    DWORD dwWidth;
    DWORD dwPitchOrLinearSize;
    DWORD dwDepth;
    DWORD dwMipMapCount;
    DWORD dwReserved1[11];
    DDS_PIXELFORMAT ddspf;
    DWORD dwCaps;
    DWORD dwCaps2;
    DWORD dwCaps3;
    DWORD dwCaps4;
    DWORD dwReserved2;
} DDS_HEADER;

typedef struct _DDS_HEADER_DXT10 {
    DWORD dxgiFormat;
    DWORD resourceDimension;
    DWORD miscFlag;
    DWORD arraySize;
    DWORD miscFlags2;
} DDS_HEADER_DXT10;
#endif

/* ------------------------------------------------------------------------- */
/* fiber / synchapi                                                          */
/* ------------------------------------------------------------------------- */
#ifndef FLS_OUT_OF_INDEXES
#define FLS_OUT_OF_INDEXES ((DWORD)0xFFFFFFFF)
#endif
#ifndef SYNCHRONIZATION_BARRIER_FLAGS_SPIN_ONLY
#define SYNCHRONIZATION_BARRIER_FLAGS_SPIN_ONLY 0x1
#endif
#ifndef SYNCHRONIZATION_BARRIER_FLAGS_BLOCK_ONLY
#define SYNCHRONIZATION_BARRIER_FLAGS_BLOCK_ONLY 0x2
#endif
#ifndef SYNCHRONIZATION_BARRIER_FLAGS_NO_DELETE
#define SYNCHRONIZATION_BARRIER_FLAGS_NO_DELETE 0x4
#endif

#ifndef ROSETTA3_BRIDGE_FIBER_TYPES_DEFINED
#define ROSETTA3_BRIDGE_FIBER_TYPES_DEFINED
typedef void (WINAPI *PFIBER_START_ROUTINE)(LPVOID lpFiberParameter);
typedef void (WINAPI *PFLS_CALLBACK_FUNCTION)(LPVOID lpFlsData);
#endif

/* ------------------------------------------------------------------------- */
/* file                                                                      */
/* ------------------------------------------------------------------------- */
#ifndef FILE_SHARE_DELETE
#define FILE_SHARE_DELETE 0x00000004
#endif
#ifndef FILE_SHARE_READ
#define FILE_SHARE_READ 0x00000001
#endif
#ifndef FILE_SHARE_WRITE
#define FILE_SHARE_WRITE 0x00000002
#endif

#ifndef ROSETTA3_BRIDGE_FINDDATA_DEFINED
#define ROSETTA3_BRIDGE_FINDDATA_DEFINED
typedef struct _WIN32_FIND_DATAA {
    BYTE _rosetta_padding[592];
} WIN32_FIND_DATAA, *PWIN32_FIND_DATAA, *LPWIN32_FIND_DATAA;

typedef struct _WIN32_FIND_DATAW {
    BYTE _rosetta_padding[592];
} WIN32_FIND_DATAW, *PWIN32_FIND_DATAW, *LPWIN32_FIND_DATAW;
#endif

#ifndef ROSETTA3_BRIDGE_FILE_SUPPLEMENT_TYPES_DEFINED
#define ROSETTA3_BRIDGE_FILE_SUPPLEMENT_TYPES_DEFINED
typedef struct _FILE_BASIC_INFO {
    BYTE _rosetta_padding[40];
} FILE_BASIC_INFO, *PFILE_BASIC_INFO;

typedef struct _FILE_ID_128 {
    BYTE Identifier[16];
} FILE_ID_128;

typedef struct _FILE_ID_DESCRIPTOR {
    DWORD dwSize;
    DWORD Type;
    FILE_ID_128 FileId;
} FILE_ID_DESCRIPTOR, *LPFILE_ID_DESCRIPTOR;
#endif

/* ------------------------------------------------------------------------- */
/* gdi                                                                       */
/* ------------------------------------------------------------------------- */
#ifndef HOLLOW_BRUSH
#define HOLLOW_BRUSH 5
#endif
#ifndef DC_BRUSH
#define DC_BRUSH 18
#endif
#ifndef DC_PEN
#define DC_PEN 19
#endif

/* ------------------------------------------------------------------------- */
/* io / process / threads                                                    */
/* ------------------------------------------------------------------------- */
#ifndef GENERIC_ALL
#define GENERIC_ALL 0x10000000
#endif
#ifndef GENERIC_EXECUTE
#define GENERIC_EXECUTE 0x20000000
#endif
#ifndef GENERIC_READ
#define GENERIC_READ 0x80000000
#endif
#ifndef GENERIC_WRITE
#define GENERIC_WRITE 0x40000000
#endif
#ifndef HANDLE_FLAG_INHERIT
#define HANDLE_FLAG_INHERIT 0x00000001
#endif
#ifndef HANDLE_FLAG_PROTECT_FROM_CLOSE
#define HANDLE_FLAG_PROTECT_FROM_CLOSE 0x00000002
#endif
#ifndef ATTACH_PARENT_PROCESS
#define ATTACH_PARENT_PROCESS ((DWORD)-1)
#endif
#ifndef INFINITE
#define INFINITE 0xffffffffU
#endif
#ifndef STANDARD_RIGHTS_REQUIRED
#define STANDARD_RIGHTS_REQUIRED 0x000F0000
#endif
#ifndef SYNCHRONIZE
#define SYNCHRONIZE 0x00100000
#endif
#ifndef CTRL_C_EVENT
#define CTRL_C_EVENT 0
#endif
#ifndef CTRL_BREAK_EVENT
#define CTRL_BREAK_EVENT 1
#endif
#ifndef CTRL_CLOSE_EVENT
#define CTRL_CLOSE_EVENT 2
#endif

#ifndef ROSETTA3_BRIDGE_STARTUPINFOW_DEFINED
#define ROSETTA3_BRIDGE_STARTUPINFOW_DEFINED
typedef struct _STARTUPINFOW {
    DWORD cb;
    LPWSTR lpReserved;
    LPWSTR lpDesktop;
    LPWSTR lpTitle;
    DWORD dwX;
    DWORD dwY;
    DWORD dwXSize;
    DWORD dwYSize;
    DWORD dwXCountChars;
    DWORD dwYCountChars;
    DWORD dwFillAttribute;
    DWORD dwFlags;
    WORD wShowWindow;
    WORD cbReserved2;
    LPBYTE lpReserved2;
    HANDLE hStdInput;
    HANDLE hStdOutput;
    HANDLE hStdError;
} STARTUPINFOW, *LPSTARTUPINFOW;

typedef struct _STARTUPINFOEXW {
    STARTUPINFOW StartupInfo;
    LPVOID lpAttributeList;
} STARTUPINFOEXW, *LPSTARTUPINFOEXW;

typedef struct _STARTUPINFOEXA {
    STARTUPINFOA StartupInfo;
    LPVOID lpAttributeList;
} STARTUPINFOEXA, *LPSTARTUPINFOEXA;

typedef struct _PROCESS_INFORMATION {
    HANDLE hProcess;
    HANDLE hThread;
    DWORD dwProcessId;
    DWORD dwThreadId;
} PROCESS_INFORMATION, *LPPROCESS_INFORMATION;
#endif

#ifndef ROSETTA3_BRIDGE_IMAGE_TLS_DIRECTORY32_DEFINED
#define ROSETTA3_BRIDGE_IMAGE_TLS_DIRECTORY32_DEFINED
typedef struct _IMAGE_TLS_DIRECTORY32 {
    DWORD StartAddressOfRawData;
    DWORD EndAddressOfRawData;
    DWORD AddressOfIndex;
    DWORD AddressOfCallBacks;
    DWORD SizeOfZeroFill;
    DWORD Characteristics;
} IMAGE_TLS_DIRECTORY32, *PIMAGE_TLS_DIRECTORY32;

typedef struct _IMAGE_TLS_DIRECTORY64 {
    ULONGLONG StartAddressOfRawData;
    ULONGLONG EndAddressOfRawData;
    ULONGLONG AddressOfIndex;
    ULONGLONG AddressOfCallBacks;
    DWORD SizeOfZeroFill;
    DWORD Characteristics;
} IMAGE_TLS_DIRECTORY64, *PIMAGE_TLS_DIRECTORY64;

typedef struct _LIST_ENTRY {
    struct _LIST_ENTRY *Flink;
    struct _LIST_ENTRY *Blink;
} LIST_ENTRY, *PLIST_ENTRY;
#endif

/* ------------------------------------------------------------------------- */
/* window                                                                    */
/* ------------------------------------------------------------------------- */
#ifndef MB_ABORTRETRYIGNORE
#define MB_ABORTRETRYIGNORE 0x00000002L
#endif
#ifndef MB_YESNOCANCEL
#define MB_YESNOCANCEL 0x00000003L
#endif
#ifndef MB_RETRYCANCEL
#define MB_RETRYCANCEL 0x00000005L
#endif

#ifndef ROSETTA3_BRIDGE_WNDCLASSEX_DEFINED
#define ROSETTA3_BRIDGE_WNDCLASSEX_DEFINED
typedef struct tagWNDCLASSEXA {
    UINT cbSize;
    UINT style;
    WNDPROC lpfnWndProc;
    int cbClsExtra;
    int cbWndExtra;
    HINSTANCE hInstance;
    HICON hIcon;
    HCURSOR hCursor;
    HBRUSH hbrBackground;
    LPCSTR lpszMenuName;
    LPCSTR lpszClassName;
    HICON hIconSm;
} WNDCLASSEXA, *PWNDCLASSEXA, *NPWNDCLASSEXA, *LPWNDCLASSEXA;

typedef struct tagWNDCLASSEXW {
    UINT cbSize;
    UINT style;
    WNDPROC lpfnWndProc;
    int cbClsExtra;
    int cbWndExtra;
    HINSTANCE hInstance;
    HICON hIcon;
    HCURSOR hCursor;
    HBRUSH hbrBackground;
    LPCWSTR lpszMenuName;
    LPCWSTR lpszClassName;
    HICON hIconSm;
} WNDCLASSEXW, *PWNDCLASSEXW, *NPWNDCLASSEXW, *LPWNDCLASSEXW;
#endif

#endif /* ROSETTA3_WIN32_BRIDGE_H */
