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
        { "windows_base", rosetta3_print_abi_report, rosetta3_validate_abi, rosetta3_abi_failure_name },
        { "sysinfo", rosetta3_print_sysinfo_report, rosetta3_validate_sysinfo, rosetta3_sysinfo_failure_name },
        { "behavior", rosetta3_print_behavior_report, rosetta3_validate_behavior, rosetta3_behavior_failure_name },
        { "console_window_abi", rosetta3_print_console_window_abi_report, rosetta3_validate_console_window_abi, rosetta3_console_window_abi_failure_name },
        { "mmsystem", rosetta3_print_mmsystem_report, rosetta3_validate_mmsystem, rosetta3_mmsystem_failure_name },
        { "atomic", rosetta3_print_atomic_report, rosetta3_validate_atomic, rosetta3_atomic_failure_name },
        { "dbghelp", rosetta3_print_dbghelp_report, rosetta3_validate_dbghelp, rosetta3_dbghelp_failure_name },
        { "dds", rosetta3_print_dds_report, rosetta3_validate_dds, rosetta3_dds_failure_name },
        { "fiber", rosetta3_print_fiber_report, rosetta3_validate_fiber, rosetta3_fiber_failure_name },
        { "file", rosetta3_print_file_report, rosetta3_validate_file, rosetta3_file_failure_name },
        { "gdi", rosetta3_print_gdi_report, rosetta3_validate_gdi, rosetta3_gdi_failure_name },
        { "intrin", rosetta3_print_intrin_report, rosetta3_validate_intrin, rosetta3_intrin_failure_name },
        { "io", rosetta3_print_io_report, rosetta3_validate_io, rosetta3_io_failure_name },
        { "process", rosetta3_print_process_report, rosetta3_validate_process, rosetta3_process_failure_name },
        { "synchapi", rosetta3_print_synchapi_report, rosetta3_validate_synchapi, rosetta3_synchapi_failure_name },
        { "threads", rosetta3_print_threads_report, rosetta3_validate_threads, rosetta3_threads_failure_name },
        { "window", rosetta3_print_window_report, rosetta3_validate_window, rosetta3_window_failure_name },
        { "shim_surface", rosetta3_print_shim_surface_report, rosetta3_validate_shim_surface, rosetta3_shim_surface_failure_name },
    };

    for (size_t i = 0; i < sizeof(reports) / sizeof(reports[0]); ++i) {
        const int rc = print_zig_report(&reports[i]);
        if (rc != 0) {
            return rc;
        }
    }

    const int rc = rosetta3_validate_handshake_suite();
    printf("\n");
    if (rc == 0) {
        printf("aggregate ABI handshake suite: OK\n");
    } else {
        printf("aggregate ABI handshake suite: FAIL (code %d, module %s)\n",
               rc, rosetta3_handshake_suite_failure_name(rc));
    }
    return rc;
}
