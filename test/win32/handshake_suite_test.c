#include <stddef.h>
#include <stdio.h>
#include <unistd.h>

#include "win32/windows_base.h"
#include "win32/Zig/zig_bridge.h"

typedef void (*report_fn_t)(void);
typedef int (*validate_fn_t)(void);
typedef const char *(*failure_name_fn_t)(int);

typedef struct {
    const char *name;
    report_fn_t print_report;
    validate_fn_t validate;
    failure_name_fn_t failure_name;
} ZigAbiReport;

static int print_zig_report(const ZigAbiReport *report) {
    printf("\n");
    report->print_report();
    const int rc = report->validate();
    printf("%s ABI validation: %s", report->name, rc == 0 ? "OK" : "FAIL");
    if (rc != 0) {
        printf(" (code %d, field %s)", rc, report->failure_name(rc));
    }
    printf("\n");
    return rc;
}

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);
    dup2(fileno(stdout), fileno(stderr));

    static const ZigAbiReport reports[] = {
        { "windows_base", rosette_print_abi_report, rosette_validate_abi, rosette_abi_failure_name },
        { "sysinfo", rosette_print_sysinfo_report, rosette_validate_sysinfo, rosette_sysinfo_failure_name },
        { "behavior", rosette_print_behavior_report, rosette_validate_behavior, rosette_behavior_failure_name },
        { "console_window_abi", rosette_print_console_window_abi_report, rosette_validate_console_window_abi, rosette_console_window_abi_failure_name },
        { "mmsystem", rosette_print_mmsystem_report, rosette_validate_mmsystem, rosette_mmsystem_failure_name },
        { "atomic", rosette_print_atomic_report, rosette_validate_atomic, rosette_atomic_failure_name },
        { "dbghelp", rosette_print_dbghelp_report, rosette_validate_dbghelp, rosette_dbghelp_failure_name },
        { "dds", rosette_print_dds_report, rosette_validate_dds, rosette_dds_failure_name },
        { "fiber", rosette_print_fiber_report, rosette_validate_fiber, rosette_fiber_failure_name },
        { "file", rosette_print_file_report, rosette_validate_file, rosette_file_failure_name },
        { "gdi", rosette_print_gdi_report, rosette_validate_gdi, rosette_gdi_failure_name },
        { "intrin", rosette_print_intrin_report, rosette_validate_intrin, rosette_intrin_failure_name },
        { "io", rosette_print_io_report, rosette_validate_io, rosette_io_failure_name },
        { "process", rosette_print_process_report, rosette_validate_process, rosette_process_failure_name },
        { "synchapi", rosette_print_synchapi_report, rosette_validate_synchapi, rosette_synchapi_failure_name },
        { "threads", rosette_print_threads_report, rosette_validate_threads, rosette_threads_failure_name },
        { "window", rosette_print_window_report, rosette_validate_window, rosette_window_failure_name },
        { "shim_surface", rosette_print_shim_surface_report, rosette_validate_shim_surface, rosette_shim_surface_failure_name },
    };

    for (size_t i = 0; i < sizeof(reports) / sizeof(reports[0]); ++i) {
        const int rc = print_zig_report(&reports[i]);
        if (rc != 0) {
            return rc;
        }
    }

    const int rc = rosette_validate_handshake_suite();
    printf("\n");
    if (rc == 0) {
        printf("aggregate ABI handshake suite: OK\n");
        printf("ABI Validation checks: ALL Passed\n");
    } else {
        printf("aggregate ABI handshake suite: FAIL (code %d, module %s)\n",
               rc, rosette_handshake_suite_failure_name(rc));
    }
    return rc;
}
