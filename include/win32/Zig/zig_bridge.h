#ifndef ZIG_BRIDGE_H
#define ZIG_BRIDGE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Return: 0=unknown, 1=x86_64, 2=aarch64 */
uint32_t zig_arch(void);

void        rosetta3_print_abi_report(void);
int         rosetta3_validate_abi(void);
const char *rosetta3_abi_failure_name(int code);

void        rosetta3_print_sysinfo_report(void);
int         rosetta3_validate_sysinfo(void);
const char *rosetta3_sysinfo_failure_name(int code);

void        rosetta3_print_behavior_report(void);
int         rosetta3_validate_behavior(void);
const char *rosetta3_behavior_failure_name(int code);

void        rosetta3_print_console_window_abi_report(void);
int         rosetta3_validate_console_window_abi(void);
const char *rosetta3_console_window_abi_failure_name(int code);

void        rosetta3_print_mmsystem_report(void);
int         rosetta3_validate_mmsystem(void);
const char *rosetta3_mmsystem_failure_name(int code);

void        rosetta3_print_atomic_report(void);
int         rosetta3_validate_atomic(void);
const char *rosetta3_atomic_failure_name(int code);

void        rosetta3_print_dbghelp_report(void);
int         rosetta3_validate_dbghelp(void);
const char *rosetta3_dbghelp_failure_name(int code);

void        rosetta3_print_dds_report(void);
int         rosetta3_validate_dds(void);
const char *rosetta3_dds_failure_name(int code);

void        rosetta3_print_fiber_report(void);
int         rosetta3_validate_fiber(void);
const char *rosetta3_fiber_failure_name(int code);

void        rosetta3_print_file_report(void);
int         rosetta3_validate_file(void);
const char *rosetta3_file_failure_name(int code);

void        rosetta3_print_gdi_report(void);
int         rosetta3_validate_gdi(void);
const char *rosetta3_gdi_failure_name(int code);

void        rosetta3_print_intrin_report(void);
int         rosetta3_validate_intrin(void);
const char *rosetta3_intrin_failure_name(int code);

void        rosetta3_print_io_report(void);
int         rosetta3_validate_io(void);
const char *rosetta3_io_failure_name(int code);

void        rosetta3_print_process_report(void);
int         rosetta3_validate_process(void);
const char *rosetta3_process_failure_name(int code);

void        rosetta3_print_synchapi_report(void);
int         rosetta3_validate_synchapi(void);
const char *rosetta3_synchapi_failure_name(int code);

void        rosetta3_print_threads_report(void);
int         rosetta3_validate_threads(void);
const char *rosetta3_threads_failure_name(int code);

void        rosetta3_print_window_report(void);
int         rosetta3_validate_window(void);
const char *rosetta3_window_failure_name(int code);

void        rosetta3_print_shim_surface_report(void);
int         rosetta3_validate_shim_surface(void);
const char *rosetta3_shim_surface_failure_name(int code);

void        rosetta3_print_handshake_suite_report(void);
int         rosetta3_validate_handshake_suite(void);
const char *rosetta3_handshake_suite_failure_name(int code);

void        rosetta3_gfx_scene_set_canvas_size(uint32_t width, uint32_t height);

#ifdef __cplusplus
}
#endif

#endif /* ZIG_BRIDGE_H */
