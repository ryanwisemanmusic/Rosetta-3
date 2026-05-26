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
