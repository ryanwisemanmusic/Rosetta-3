#include <stdio.h>
#include <inttypes.h>
#include "win32/windows_base.h"
#include "win32/Zig/zig_bridge.h"

int main(void) {
    printf("Win32 header basic checks:\n");
    printf("  sizeof(INT32) = %zu\n", sizeof(INT32));
    printf("  sizeof(INT64) = %zu\n", sizeof(INT64));
    printf("  sizeof(INT_PTR) = %zu\n", sizeof(INT_PTR));
    printf("  PATH_MAX = %d\n", PATH_MAX);
    printf("  MAX_PATH = %d\n", MAX_PATH);
#if defined(_WIN64) || defined(__LP64__) || defined(__aarch64__) || defined(__arm64__) || defined(_M_ARM64)
    printf("  Detected 64-bit pointer model at runtime (compile-time define present)\n");
#else
    printf("  Detected 32-bit pointer model at runtime (compile-time define present)\n");
#endif

    /* Sanity: sizes of pointer types */
    printf("  sizeof(LONG_PTR) = %zu\n", sizeof(LONG_PTR));
    printf("  sizeof(ULONG_PTR) = %zu\n", sizeof(ULONG_PTR));

    /* Basic types sizes from C perspective */
    printf("Win32 C Header Type Sizes:\n");
    printf("  sizeof(CHAR) = %zu, sizeof(SHORT) = %zu, sizeof(INT) = %zu\n", sizeof(CHAR), sizeof(SHORT), sizeof(INT));
    printf("  sizeof(LONG) = %zu, sizeof(ULONG) = %zu, sizeof(LONGLONG) = %zu\n", sizeof(LONG), sizeof(ULONG), sizeof(LONGLONG));
    printf("  sizeof(FLOAT) = %zu, sizeof(WCHAR) = %zu, sizeof(BOOL) = %zu\n", sizeof(FLOAT), sizeof(WCHAR), sizeof(BOOL));
    printf("  sizeof(BYTE) = %zu, sizeof(WORD) = %zu, sizeof(DWORD) = %zu\n", sizeof(BYTE), sizeof(WORD), sizeof(DWORD));
    printf("  sizeof(DWORD64) = %zu, sizeof(ULONG64) = %zu\n", sizeof(DWORD64), sizeof(ULONG64));
    printf("Win32 C Header Struct Sizes:\n");
    printf("  sizeof(LARGE_INTEGER) = %zu, sizeof(ULARGE_INTEGER) = %zu\n", sizeof(LARGE_INTEGER), sizeof(ULARGE_INTEGER));
    printf("  sizeof(FILETIME) = %zu, sizeof(OVERLAPPED) = %zu\n", sizeof(FILETIME), sizeof(OVERLAPPED));
    printf("  sizeof(SECURITY_ATTRIBUTES) = %zu, sizeof(GUID) = %zu\n", sizeof(SECURITY_ATTRIBUTES), sizeof(GUID));

    /* Win32 macros tests from C perspective */
    printf("Win32 C Header Macro Verification:\n");
    uint64_t test_val = 0x123456789abcdef0ULL;
    printf("  LOWORD(0x123456789abcdef0) = 0x%04" PRIx16 "\n", LOWORD(test_val));
    printf("  HIWORD(0x123456789abcdef0) = 0x%04" PRIx16 "\n", HIWORD(test_val));
    uint16_t test_word = 0x5678U;
    printf("  LOBYTE(0x5678) = 0x%02" PRIx8 "\n", LOBYTE(test_word));
    printf("  HIBYTE(0x5678) = 0x%02" PRIx8 "\n", HIBYTE(test_word));
    printf("  MAKEWORD(0x12, 0x34) = 0x%04" PRIx16 "\n", MAKEWORD(0x12, 0x34));
    printf("  MAKELONG(0x1234, 0x5678) = 0x%08" PRIx32 "\n", MAKELONG(0x1234, 0x5678));

    HRESULT hr_win32 = HRESULT_FROM_WIN32(2);
    printf("  HRESULT_FROM_WIN32(2) = 0x%08" PRIx32 "\n", (uint32_t)hr_win32);
    printf("  HRESULT_IS_FAILURE(0x80070002) = %s\n", HRESULT_IS_FAILURE(hr_win32) ? "true" : "false");
    printf("  HRESULT_IS_WIN32(0x80070002) = %s\n", HRESULT_IS_WIN32(hr_win32) ? "true" : "false");
    printf("  HRESULT_FACILITY(0x80070002) = %" PRIu32 "\n", (uint32_t)HRESULT_FACILITY(hr_win32));
    printf("  HRESULT_CODE(0x80070002) = %" PRIu32 "\n", (uint32_t)HRESULT_CODE(hr_win32));

    fflush(stdout);
    rosetta3_print_abi_report();

    int rc = rosetta3_validate_abi();
    if (rc == 0) {
        printf("Rosetta 3 ABI validation: OK\n");
    } else {
        printf("Rosetta 3 ABI validation: FAIL (code %d, %s)\n",
               rc, rosetta3_abi_failure_name(rc));
    }
    return rc;
}
